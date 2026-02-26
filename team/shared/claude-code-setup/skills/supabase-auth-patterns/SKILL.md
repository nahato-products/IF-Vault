---
name: supabase-auth-patterns
description: "Supabase Auth + RLS for Next.js: OAuth, Magic Link, LINE Login, @supabase/ssr, middleware guard, MFA/TOTP"
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

- Email/password -> Section 1 | Social login (Google, GitHub) -> Section 2
- Passwordless -> Magic Link (reference.md) | LINE -> LINE Login (reference.md)
- MFA -> reference.md MFA/TOTP | Password reset / email change -> reference.md

---

## Section 1: Email/Password Authentication [CRITICAL]

### Sign Up

`supabase.auth.signUp({ email, password, options: { data: { display_name } } })` — `options.data` は `raw_user_meta_data` に格納。`data.user && !data.session` ならメール確認待ち。エラー時は既存ユーザーの存在を隠す。

-> フル実装: reference.md「Sign Up Full Example」

### Sign In (Server Action)

```typescript
// 'use server' + createClient() + signInWithPassword({ email, password })
// error時: return { error: 'Invalid credentials' } / 成功時: redirect('/dashboard')
```

-> フル実装: reference.md「Sign In Server Action Full Example」

---

## Section 2: OAuth Flow [CRITICAL]

```typescript
// signInWithOAuth({ provider: 'google', options: { redirectTo, queryParams } })
// queryParams: { access_type: 'offline', prompt: 'consent' } でリフレッシュトークン取得
```

-> フル実装: reference.md「OAuth Full Example」

### Callback Route (PKCE)

```typescript
// app/auth/callback/route.ts — GET: code取得 -> exchangeCodeForSession(code) -> redirect
// PKCE: code verifier は @supabase/ssr が cookies で自動管理
```

-> フル実装: reference.md「OAuth Callback Route (PKCE)」

-> Magic Link, LINE Login: [reference.md](reference.md)

---

## Section 3: Session Management [CRITICAL]

### Server Client (@supabase/ssr)

```typescript
// lib/supabase/server.ts: createServerClient + cookies の getAll/setAll
// SC では cookies が read-only なので setAll を try/catch で囲む
```

-> フル実装: reference.md「Server Client Full Example」

### Next.js Middleware (Auth Guard + Session Refresh)

```typescript
// middleware.ts — 要点:
// 1. createServerClient で request/response cookies を橋渡し
// 2. getUser() でセッショントークンをリフレッシュ（CRITICAL）
// 3. 未認証ユーザーを /login にリダイレクト
// 4. matcher で static assets を除外
```

-> フル実装: reference.md「Middleware Auth Guard Full Example」
-> Middleware error handling: see `error-handling-logging`

### getUser() vs getSession() [CRITICAL]

```typescript
// GOOD: getUser() — JWT をサーバー側で検証（認証チェックに必須）
// BAD:  getSession() — JWT をストレージから読むだけ（検証なし）
```

**Rule:** サーバーでは必ず `getUser()`。`getSession()` はアクセストークン文字列が必要な場合のみ。

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
-- SELECT/DELETE: USING ((SELECT auth.uid()) = user_id)
-- INSERT: WITH CHECK ((SELECT auth.uid()) = user_id)
-- UPDATE: USING + WITH CHECK 両方必要
```

**Performance note:** Wrap `auth.uid()` in `(SELECT ...)` so Postgres evaluates it once, not per row. See `supabase-postgres-best-practices` for full RLS performance guide.

### USING vs WITH CHECK

- `USING` = 既存行のフィルタ（SELECT/UPDATE/DELETE）
- `WITH CHECK` = 新規/更新行の検証（INSERT/UPDATE）
- UPDATE は両方必要: USING（対象行）+ WITH CHECK（結果検証）

-> Org/Team, Role-Based, Public Read patterns, RLS performance tips: [reference.md](reference.md)

---

## Section 5: Protecting API Routes & Server Actions [CRITICAL]

**共通パターン**: `createClient()` -> `getUser()` -> 未認証なら 401/throw -> RLS がスコープ

```typescript
// API Route: if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
// Server Action: if (!user) throw new Error('Unauthorized')
// BAD: user_id: formData.get('user_id') — クライアントのIDを信用しない
```

-> フル実装: reference.md「Protecting API Routes & Server Actions」

-> Auth error handling patterns: see `error-handling-logging` (Server Action result-object pattern)
-> Auth vulnerability auditing: see `security-review` (auth bypass detection)
-> Common Auth Errors table: [reference.md](reference.md)

---

## Section 6: Auth Event Handling [HIGH]

### onAuthStateChange (Client-Side)

```typescript
// useEffect 内で supabase.auth.onAuthStateChange((event, session) => { ... })
// クリーンアップで subscription.unsubscribe()
```

**Events:** `SIGNED_IN`, `SIGNED_OUT`, `TOKEN_REFRESHED`, `USER_UPDATED`, `PASSWORD_RECOVERY`, `MFA_CHALLENGE_VERIFIED`

-> フル実装: reference.md「Auth Event Handling Full Example」

---

## Cross-references [MEDIUM]

- **supabase-postgres-best-practices**: RLSポリシーのパフォーマンス最適化・auth.uid()サブクエリキャッシュ
- **nextjs-app-router-patterns**: Middleware認証ガード・Server Component/Route Handlerでのセッション管理
- **security-review**: 認証バイパス脆弱性の検出・トークン漏洩・RLS未設定テーブルの監査

## Checklist

- [ ] 全publicテーブルでRLS有効化済み
- [ ] `service_role` キーがクライアントコードに含まれていない
- [ ] サーバー側認証チェックは `getUser()` を使用（`getSession()` ではない）
- [ ] 全Server Action / API Routeで認証チェック実装済み
- [ ] ユーザーIDはサーバー側で設定（クライアント送信値を信用しない）
- [ ] Middlewareで毎リクエストセッションリフレッシュ実施
- [ ] OAuthコールバックでPKCE code検証済み
- [ ] エラーメッセージがユーザー存在を漏洩しない

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
