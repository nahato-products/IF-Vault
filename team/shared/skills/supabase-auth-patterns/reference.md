# Supabase Auth & RLS — Reference

Supplementary material for skill.md. Covers Magic Link, LINE Login integration, JWT/key management, RLS advanced patterns, password reset, email change, MFA/TOTP, auth hooks, and common auth errors.

---

## Magic Link [HIGH]

```typescript
const { error } = await supabase.auth.signInWithOtp({
  email: 'user@example.com',
  options: {
    emailRedirectTo: `${origin}/auth/callback`,
    shouldCreateUser: true, // false to prevent new signups
  },
})
```

**Rate limit:** 1 email per 60 seconds per address (configurable in Supabase Dashboard > Auth > Rate Limits).

---

## LINE Login Integration [HIGH]

### Setup: LINE as Custom OIDC Provider

LINE Login is configured as a custom OIDC provider in Supabase Dashboard (Authentication > Providers > Add custom provider).

```typescript
const { data, error } = await supabase.auth.signInWithOAuth({
  provider: 'line' as any, // Custom provider registered in dashboard
  options: {
    redirectTo: `${origin}/auth/callback`,
    scopes: 'profile openid email',
  },
})
```

-> LINE Bot webhook handling, Messaging API: see `line-bot-dev`

### Linking LINE User ID to App User

```sql
CREATE TABLE public.line_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  line_user_id TEXT UNIQUE NOT NULL,
  display_name TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.line_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own line profile"
  ON public.line_profiles FOR SELECT
  USING ((SELECT auth.uid()) = user_id);
```

---

## Password Reset [HIGH]

### Step 1: Request Reset Email

```typescript
const { error } = await supabase.auth.resetPasswordForEmail(email, {
  redirectTo: `${origin}/auth/callback?next=/account/update-password`,
})
```

### Step 2: Handle Callback

The user clicks the email link, which triggers the callback route. After `exchangeCodeForSession`, the `PASSWORD_RECOVERY` event fires on the client.

### Step 3: Update Password

```typescript
const { error } = await supabase.auth.updateUser({
  password: newPassword,
})
if (!error) {
  // Password updated successfully, redirect to dashboard
}
```

---

## Email Change [MEDIUM]

```typescript
const { error } = await supabase.auth.updateUser({
  email: 'new@example.com',
})
// Supabase sends confirmation to BOTH old and new email (configurable)
// User must confirm from new email to complete the change
```

Dashboard setting: Authentication > Email > "Double confirm email changes" (enabled by default).

---

## MFA / TOTP [HIGH]

### Enroll TOTP Factor

```typescript
const { data, error } = await supabase.auth.mfa.enroll({
  factorType: 'totp',
  friendlyName: 'Authenticator App',
})
// data.totp.qr_code — base64 QR image for user to scan
// data.totp.uri — otpauth:// URI
// data.id — factor ID for challenge/verify
```

### Challenge and Verify

```typescript
const { data: challenge, error } = await supabase.auth.mfa.challenge({
  factorId: factor.id,
})

const { data: verify, error: verifyError } = await supabase.auth.mfa.verify({
  factorId: factor.id,
  challengeId: challenge.id,
  code: userInputCode, // 6-digit TOTP code
})
```

### Check MFA Status in RLS

```sql
-- Require MFA for sensitive operations
CREATE POLICY "MFA required for admin actions"
  ON public.admin_settings FOR ALL
  USING (
    (SELECT auth.jwt() ->> 'aal') = 'aal2' -- AAL2 = MFA verified
  );
```

**AAL levels:** `aal1` = password/OAuth only, `aal2` = MFA verified.

### Check MFA in Server-Side Code

```typescript
const { data: { user } } = await supabase.auth.getUser()
const { data: factors } = await supabase.auth.mfa.listFactors()
const hasVerifiedFactor = factors?.totp?.some(f => f.status === 'verified')

if (hasVerifiedFactor) {
  // Check AAL level
  const { data: aal } = await supabase.auth.mfa.getAuthenticatorAssuranceLevel()
  if (aal.currentLevel !== 'aal2') {
    // Redirect to MFA challenge page
  }
}
```

---

## JWT & Key Management [CRITICAL]

### anon key vs service_role key

| Key | Use Case | RLS | Exposure |
|-----|---------|-----|----------|
| `anon` key | Client-side, browser, SSR with user context | Enforced | Public (safe to expose) |
| `service_role` key | Server-side admin operations only | **Bypassed** | NEVER expose to client |

```typescript
// GOOD: service_role for admin operations (server-side only)
import { createClient } from '@supabase/supabase-js'

const supabaseAdmin = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!, // No NEXT_PUBLIC_ prefix
  { auth: { autoRefreshToken: false, persistSession: false } }
)
const { data } = await supabaseAdmin.auth.admin.listUsers()
```

```typescript
// BAD: service_role key in client code
const supabase = createClient(url, process.env.NEXT_PUBLIC_SERVICE_ROLE_KEY!)
// Exposes full DB access to browser — bypasses ALL RLS
```

-> Security auditing for key exposure: see `security-review`

### JWT Claims in RLS

```sql
-- auth.uid()        -> UUID of authenticated user
-- auth.jwt()        -> Full JWT payload
-- auth.role()       -> 'authenticated' or 'anon'
-- auth.email()      -> User's email

-- Custom claim example (set via auth hooks or admin API)
CREATE POLICY "Admin access"
  ON public.admin_settings FOR ALL
  USING (((SELECT auth.jwt()) -> 'app_metadata' ->> 'role') = 'admin');
```

### Setting Custom Claims (Admin API)

```typescript
// Server-side only — assign role via admin API
await supabaseAdmin.auth.admin.updateUserById(userId, {
  app_metadata: { role: 'admin' },
})
// The role claim appears in JWT on next token refresh
```

---

## Auth Hooks (Database Functions) [MEDIUM]

Supabase Auth hooks allow custom logic during auth events via Postgres functions.

### Custom Access Token Hook

```sql
-- Enrich JWT with custom claims from your database
CREATE OR REPLACE FUNCTION public.custom_access_token_hook(event JSONB)
RETURNS JSONB
LANGUAGE plpgsql STABLE
AS $$
DECLARE
  claims JSONB;
  user_role TEXT;
BEGIN
  claims := event -> 'claims';

  SELECT role INTO user_role
  FROM public.user_roles
  WHERE user_id = (event ->> 'user_id')::UUID;

  IF user_role IS NOT NULL THEN
    claims := jsonb_set(claims, '{user_role}', to_jsonb(user_role));
    event := jsonb_set(event, '{claims}', claims);
  END IF;

  RETURN event;
END;
$$;

GRANT EXECUTE ON FUNCTION public.custom_access_token_hook TO supabase_auth_admin;
```

Register in Dashboard: Authentication > Hooks > Customize Access Token.

---

## RLS Advanced Patterns [HIGH]

### Organization / Team Access

```sql
CREATE POLICY "Org members see org data"
  ON public.projects FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.org_members
      WHERE org_members.org_id = projects.org_id
        AND org_members.user_id = (SELECT auth.uid())
    )
  );
-- EXISTS is faster than IN for RLS policies
```

### Role-Based Access

```sql
CREATE POLICY "Admins can update projects"
  ON public.projects FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.org_members
      WHERE org_members.org_id = projects.org_id
        AND org_members.user_id = (SELECT auth.uid())
        AND org_members.role IN ('admin', 'owner')
    )
  );
```

### Public Read, Authenticated Write

```sql
CREATE POLICY "Public read published"
  ON public.posts FOR SELECT
  USING (status = 'published');

CREATE POLICY "Authenticated insert"
  ON public.posts FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);
```

### Service Role Bypass

```
RLS is automatically bypassed when using the service_role key.
Use supabaseAdmin (service_role) for: background jobs, webhooks, admin operations.
NEVER pass service_role key to the client.
```

### RLS Performance Tips

```sql
-- 1. Always wrap auth functions in (SELECT ...) — evaluated once, not per row
CREATE POLICY p ON orders USING ((SELECT auth.uid()) = user_id);
-- NOT: USING (auth.uid() = user_id) -- this is 100x slower

-- 2. Index columns used in RLS policies
CREATE INDEX idx_posts_user_id ON public.posts(user_id);
CREATE INDEX idx_org_members_lookup ON public.org_members(org_id, user_id);

-- 3. Use security definer functions for complex logic
CREATE OR REPLACE FUNCTION public.get_user_org_ids()
RETURNS SETOF UUID
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT org_id FROM public.org_members WHERE user_id = (SELECT auth.uid());
$$;

-- Then use in policy (evaluated once, not per row)
CREATE POLICY "Org access via function"
  ON public.projects FOR SELECT
  USING (org_id IN (SELECT public.get_user_org_ids()));
```

-> Full RLS performance optimization: see `supabase-postgres-best-practices` (Category 3: RLS Performance)

---

## Client-Side Supabase Setup [MEDIUM]

```typescript
// lib/supabase/client.ts
'use client'
import { createBrowserClient } from '@supabase/ssr'

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  )
}
```

---

## Common Auth Errors & Solutions [HIGH]

| Error | Cause | Solution |
|-------|-------|----------|
| `new row violates RLS` | INSERT without matching WITH CHECK | Ensure user_id matches `(SELECT auth.uid())` |
| `JWT expired` | Token not refreshed | Middleware calls `getUser()` to refresh |
| `invalid claim: missing sub` | Malformed JWT | Check Supabase client initialization |
| `Email not confirmed` | User hasn't verified | Enable/disable email confirmation in dashboard |
| No rows returned (not error) | RLS USING blocks access | Check policy conditions and user ownership |
| `Auth session missing` | No cookie sent or expired | Check middleware matcher includes the path |
| `invalid_grant` | PKCE code verifier mismatch | Ensure cookies persist between OAuth redirect and callback |
| `MFA verification required` | AAL2 not met | Redirect to MFA challenge page |
| `User already registered` | Duplicate sign-up | Return generic message (don't reveal existence) |

-> Error classification (operational vs programmer): see `error-handling-logging`
-> Auth error UI patterns (toast, error boundary): see `micro-interaction-patterns`
