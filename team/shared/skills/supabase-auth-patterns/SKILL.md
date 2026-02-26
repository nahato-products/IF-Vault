---
name: supabase-auth-patterns
description: "Supabase Auth and RLS patterns for Next.js App Router. Covers authentication flows (email/password, OAuth, Magic Link, LINE Login OIDC), session management with @supabase/ssr cookies, JWT validation (getUser vs getSession), RLS policy design (USING vs WITH CHECK, user-owns-row, org/team, role-based), middleware auth guard, Server Action and API Route protection, anon vs service_role key separation, PKCE flow, MFA/TOTP, password reset, and auth hooks. Use when implementing authentication, designing RLS policies, configuring login flows, protecting API routes or Server Actions, integrating LINE Login, setting up auth middleware, managing JWT claims, enrolling MFA, or debugging auth errors. Does NOT cover query performance (supabase-postgres-best-practices), schema design (ansem-db-patterns), or security auditing (security-review)."
user-invocable: false
---

# Supabase Auth & RLS Patterns

## When to Apply [HIGH]

Reference this skill when:
- Implementing authentication flows (email/password, OAuth, Magic Link)
- Designing or debugging RLS (Row Level Security) policies
- Managing sessions, cookies, and JWT tokens with `@supabase/ssr`
- Protecting API routes or Server Actions with auth
- Integrating LINE Login with Supabase Auth
- Choosing between `anon` key and `service_role` key
- Configuring MFA/TOTP or password reset flows
- Debugging auth errors (RLS violations, JWT expired, session issues)

## Scope & Relationship to Other Skills [MEDIUM]

| Topic | This Skill | Other Skill |
|-------|-----------|-------------|
| Auth flows, RLS policies, session management | **Here** | - |
| SQL query performance, indexing, RLS wrapping `(SELECT auth.uid())` | - | `supabase-postgres-best-practices` |
| Auth error classification (operational vs programmer) | - | `error-handling-logging` |
| Auth vulnerability detection (bypass, token leaks) | - | `security-review` |
| LINE Login OAuth + LINE user sync | **Here** (auth flow) | `line-bot-dev` (Messaging API, webhooks) |
| Next.js middleware structure and routing | **Here** (auth guard logic) | `nextjs-app-router-patterns` (routing, caching) |

---

## Decision Tree: Which Auth Flow? [HIGH]

```
Need authentication?
  +-- Email/password? -> Section 1
  +-- Social login (Google, GitHub)? -> Section 2
  +-- Passwordless? -> Magic Link (reference.md)
  +-- LINE integration? -> LINE Login (reference.md)
  +-- MFA required? -> reference.md MFA/TOTP section
  +-- Password reset / email change? -> reference.md
```

---

## Section 1: Email/Password Authentication [CRITICAL]

### Sign Up

```typescript
const { data, error } = await supabase.auth.signUp({
  email: 'user@example.com',
  password: 'securePassword123!',
  options: {
    data: { display_name: 'User Name' }, // stored in raw_user_meta_data
  },
})

if (error) {
  if (error.message.includes('already registered')) {
    showGenericMessage('Check your email for confirmation') // Don't reveal existence
  }
  return
}

if (data.user && !data.session) {
  // Email confirmation required
  showMessage('Please check your email to confirm')
}
```

### Sign In (Server Action)

```typescript
'use server'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'

export async function signIn(formData: FormData) {
  const supabase = await createClient()
  const { error } = await supabase.auth.signInWithPassword({
    email: formData.get('email') as string,
    password: formData.get('password') as string,
  })
  if (error) return { error: 'Invalid credentials' }
  redirect('/dashboard')
}
```

---

## Section 2: OAuth Flow [CRITICAL]

```typescript
const { data, error } = await supabase.auth.signInWithOAuth({
  provider: 'google',
  options: {
    redirectTo: `${origin}/auth/callback`,
    queryParams: { access_type: 'offline', prompt: 'consent' },
  },
})
```

### Callback Route (PKCE)

```typescript
// app/auth/callback/route.ts
import { createClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'

export async function GET(request: Request) {
  const { searchParams, origin } = new URL(request.url)
  const code = searchParams.get('code')
  const next = searchParams.get('next') ?? '/dashboard'

  if (code) {
    const supabase = await createClient()
    const { error } = await supabase.auth.exchangeCodeForSession(code)
    if (!error) return NextResponse.redirect(`${origin}${next}`)
  }
  return NextResponse.redirect(`${origin}/auth/error`)
}
```

**PKCE note:** `exchangeCodeForSession` uses PKCE (Proof Key for Code Exchange) by default in `@supabase/ssr`. The code verifier is stored in cookies automatically.

-> Magic Link, LINE Login: [reference.md](reference.md)

---

## Section 3: Session Management [CRITICAL]

### Server Client (@supabase/ssr)

```typescript
// lib/supabase/server.ts
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

export async function createClient() {
  const cookieStore = await cookies()
  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() { return cookieStore.getAll() },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            )
          } catch { /* Called from Server Component — cookies are read-only */ }
        },
      },
    }
  )
}
```

### Next.js Middleware (Auth Guard + Session Refresh)

```typescript
// middleware.ts
import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

export async function middleware(request: NextRequest) {
  let supabaseResponse = NextResponse.next({ request })
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() { return request.cookies.getAll() },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value))
          supabaseResponse = NextResponse.next({ request })
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          )
        },
      },
    }
  )

  // CRITICAL: getUser() refreshes the session token via cookies
  const { data: { user } } = await supabase.auth.getUser()

  if (!user && request.nextUrl.pathname.startsWith('/dashboard')) {
    const url = request.nextUrl.clone()
    url.pathname = '/login'
    return NextResponse.redirect(url)
  }

  return supabaseResponse
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg)$).*)'],
}
```

-> Middleware error handling: see `error-handling-logging` (middleware error containment pattern)

### getUser() vs getSession() [CRITICAL]

```typescript
// GOOD: getUser() validates JWT server-side via Supabase Auth API
const { data: { user } } = await supabase.auth.getUser()

// BAD: getSession() reads JWT from storage without server validation
const { data: { session } } = await supabase.auth.getSession()
```

**Rule:** Always use `getUser()` on the server for auth checks. Use `getSession()` only when you need the access token string (e.g., passing to external API).

-> JWT/key management (anon vs service_role): [reference.md](reference.md)

---

## Section 4: RLS Policy Design [CRITICAL]

### Enable RLS First

```sql
-- ALWAYS enable RLS on every public table
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
-- Without RLS, anon key has FULL access = #1 Supabase security mistake
```

### Pattern: User Owns Row

```sql
CREATE POLICY "Users select own posts"
  ON public.posts FOR SELECT
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users insert own posts"
  ON public.posts FOR INSERT
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users update own posts"
  ON public.posts FOR UPDATE
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users delete own posts"
  ON public.posts FOR DELETE
  USING ((SELECT auth.uid()) = user_id);
```

**Performance note:** Wrap `auth.uid()` in `(SELECT ...)` so Postgres evaluates it once, not per row. See `supabase-postgres-best-practices` for full RLS performance guide.

### USING vs WITH CHECK

```
USING       -> Filters which EXISTING rows the user can see/affect
WITH CHECK  -> Validates what the NEW/UPDATED row looks like

SELECT  -> USING only
INSERT  -> WITH CHECK only
UPDATE  -> USING (which rows) + WITH CHECK (result validation)
DELETE  -> USING only
```

-> Org/Team, Role-Based, Public Read patterns, RLS performance tips: [reference.md](reference.md)

---

## Section 5: Protecting API Routes & Server Actions [CRITICAL]

```typescript
// API Route
export async function GET() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  // RLS automatically scopes query to this user via anon key
  const { data: posts } = await supabase.from('posts').select('*')
  return NextResponse.json(posts)
}
```

```typescript
// Server Action — ALWAYS verify auth
'use server'
export async function createPost(formData: FormData) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error('Unauthorized')

  await supabase.from('posts').insert({
    title: formData.get('title'),
    user_id: user.id, // Set from SERVER, not client
  })
}
```

```typescript
// BAD: Trusting client-sent user_id
await supabase.from('posts').insert({
  user_id: formData.get('user_id'), // NEVER trust client for identity
})
```

-> Auth error handling patterns: see `error-handling-logging` (Server Action result-object pattern)
-> Auth vulnerability auditing: see `security-review` (auth bypass detection)
-> Common Auth Errors table: [reference.md](reference.md)

---

## Section 6: Auth Event Handling [HIGH]

### onAuthStateChange (Client-Side)

```typescript
'use client'
import { useEffect } from 'react'
import { createClient } from '@/lib/supabase/client'

export function AuthListener() {
  useEffect(() => {
    const supabase = createClient()
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      (event, session) => {
        if (event === 'SIGNED_IN') { /* redirect or update UI */ }
        if (event === 'SIGNED_OUT') { /* clear local state */ }
        if (event === 'TOKEN_REFRESHED') { /* session renewed */ }
        if (event === 'PASSWORD_RECOVERY') { /* show reset form */ }
      }
    )
    return () => subscription.unsubscribe()
  }, [])
  return null
}
```

**Events:** `SIGNED_IN`, `SIGNED_OUT`, `TOKEN_REFRESHED`, `USER_UPDATED`, `PASSWORD_RECOVERY`, `MFA_CHALLENGE_VERIFIED`

---

## Security Checklist [CRITICAL]

- [ ] RLS enabled on ALL public tables
- [ ] `service_role` key NEVER in client code or `NEXT_PUBLIC_` vars
- [ ] `getUser()` for server-side auth (not `getSession()`)
- [ ] Auth checked in EVERY Server Action and API route
- [ ] User identity set server-side, never from client
- [ ] Middleware refreshes session on every request
- [ ] OAuth callback validates `code` parameter (PKCE)
- [ ] Error messages don't reveal user existence
- [ ] RLS policy uses `(SELECT auth.uid())` for performance
- [ ] `service_role` admin client disables `autoRefreshToken` and `persistSession`
