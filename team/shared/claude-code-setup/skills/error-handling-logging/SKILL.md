---
name: error-handling-logging
description: "error.tsx boundary, AppError/isOperational, structured logging, Sentry, Server Action result-object, API error responses"
user-invocable: false
---

# Error Handling & Logging Strategy

## Scope & Relationship to Other Skills

| Topic | This Skill | Other Skill |
|-------|-----------|-------------|
| Error boundary architecture (error.tsx hierarchy) | Here: placement rules, catch scope | `nextjs-app-router-patterns` (file conventions, routing) |
| Error UI visual patterns (animation, skeleton) | - | `micro-interaction-patterns` (error state UI, toast) |
| Error info leakage prevention | Here: message sanitization, log filtering | `security-review` (vulnerability audit) |
| Error investigation process | - | `systematic-debugging` (root cause tracing) |
| Error scenario test coverage | Here: what error paths exist | `testing-strategy` (how to test them) |
| Auth error handling | Here: error classification only | `supabase-auth-patterns` (auth flow design) |
| DB error handling | Here: error wrapping only | `supabase-postgres-best-practices` (query patterns) |

---

## Decision Tree: Error Handling Strategy [CRITICAL]

**Flow**: Error occurs -> Expected?(validation/404/auth) -> Operational: handle gracefully, log INFO/WARN. Unexpected?(null ref/type error) -> Programmer: log ERROR, Sentry, generic message. **Where?** SC/API Route: try-catch + log. CC: error.tsx boundary. Middleware: catch + redirect. Server Action: return error object (never throw). 404: call notFound().

---

## Section 1: Error Classification [CRITICAL]

| Type | Examples | Action | Log Level |
|------|---------|--------|-----------|
| **Operational** | Invalid input, 404, auth expired, rate limit | Handle gracefully, inform user | WARN/INFO |
| **Programmer** | TypeError, null ref, missing env var | Fix the code, report to Sentry | ERROR |

**Rule:** Operational errors are expected in production. Programmer errors are bugs.

### Custom Error Base Class

```typescript
// lib/errors.ts
interface AppErrorOptions { message: string; code: string; statusCode?: number; isOperational?: boolean; context?: Record<string, unknown>; }
export class AppError extends Error {
  constructor(opts: AppErrorOptions)  // オブジェクトパターン + Error.captureStackTrace
}
```

Subclasses: `NotFoundError` (404), `ValidationError` (400), `AuthenticationError` (401), `ForbiddenError` (403), `RateLimitError` (429), `ExternalServiceError` (502). Full implementation: see [reference.md > Custom Error Classes](reference.md#custom-error-classes-full-hierarchy)

### Usage

```typescript
// Match Supabase error codes -> throw typed AppError subclass
if (error.code === 'PGRST116') throw new NotFoundError('Post', id)
throw new ExternalServiceError('Supabase', error as unknown as Error)
```

-> full example: [reference.md > AppError Usage Example](reference.md#apperror-usage-example)

---

## Section 2: Next.js Error Boundary Hierarchy [CRITICAL]

### File Structure

```
app/error.tsx (root children) > dashboard/error.tsx (segment) > settings/error.tsx (specific)
app/global-error.tsx (root layout itself), app/not-found.tsx (notFound() calls)
```

### Rules

**Rules**: (1) error.tsx catches sibling page.tsx + child segments (2) does NOT catch sibling layout.tsx (3) parent segment catches layout errors (4) global-error.tsx must render `<html>`+`<body>` (5) notFound() triggers not-found.tsx, not error.tsx (6) redirect() throws internally -- do NOT wrap in try-catch

See [reference.md > error.tsx Implementation Examples](reference.md#errortsx-implementation-examples) for Root/Global/Segment error boundary code.

---

## Section 3: Server-Side Error Handling [CRITICAL]

### Server Action Pattern (Recommended)

```typescript
type ActionResult<T> =
  | { success: true; data: T }
  | { success: false; error: { code: string; message: string } }
// Rule: Server Actions return ActionResult<T> — never throw to client
```

-> full pattern: [reference.md > Server Action Pattern](reference.md#server-action-pattern-full)

### Middleware Error Handling

```typescript
// Rule: wrap entire middleware in try-catch, redirect to safe page on failure
// catch (err) { logger.error(...); return NextResponse.redirect('/error') }
```

-> full pattern: [reference.md > Middleware Error Handling](reference.md#middleware-error-handling)

See also: [reference.md > API Route Error Handler](reference.md#api-route-error-handler), [Try-Catch Best Practices](reference.md#try-catch-best-practices)

---

## Section 4: Structured Logging [CRITICAL]

### Guidelines

| Level | When | Examples |
|-------|------|---------|
| **DEBUG** | Development only | Variable values, function entry/exit |
| **INFO** | Normal operations | User actions, API calls, state changes |
| **WARN** | Recoverable issues | Retry succeeded, fallback used |
| **ERROR** | Failures needing attention | Unhandled exceptions, service down |

```typescript
// GOOD: logger.info('Post created', { postId, userId, action: 'create_post' })
// BAD:  console.log('Post created: ' + data.id)
```

-> more examples: [reference.md > Structured Logging Examples](reference.md#structured-logging-examples)

### Sensitive Data Rules

```
NEVER log: passwords, tokens, API keys, credit card numbers, PII
NEVER expose in error responses: stack traces, SQL errors, internal paths
GOOD: logger.info('User authenticated', { userId: user.id, method: 'email' })
BAD:  logger.info('User login', { email: user.email, password: password })
```

For comprehensive information leakage audit, see `security-review`. See [reference.md > Logger Implementation](reference.md#logger-implementation) for the full `lib/logger.ts` code.

---

## Section 5: Observability [HIGH]

### OpenTelemetry（2026年標準）

Sentry 単体から OpenTelemetry への移行が進んでいる。分散トレーシング対応:
- `@opentelemetry/sdk-node` + `@opentelemetry/auto-instrumentations-node`
- Next.js: `instrumentation.ts` で初期化（`register()` エクスポート）
- Sentry は OpenTelemetry バックエンドとしても利用可能（`@sentry/opentelemetry`）

### Sentry Integration

Setup: `@sentry/nextjs` with 3 config files (client, server, edge) + `instrumentation.ts`

Key settings:
- `tracesSampleRate: 0.1` (10% of transactions)
- `replaysOnErrorSampleRate: 1.0` (100% on error)
- `beforeSend`: Filter out operational errors (`AppError.isOperational`)

```typescript
Sentry.captureException(err, { tags: { module, orderId }, extra: {...}, user: { id } })
```

See [reference.md > Sentry Configuration](reference.md#sentry-configuration) for full client/server/edge config code.

---

## Section 6: API Error Response Design [HIGH]

### Standard Format

```typescript
// All API errors: { error: { code: string, message: string, details?: unknown } }
```

-> interface definition: [reference.md > API Error Response Interface](reference.md#api-error-response-interface)

| Status | Code | Message |
|--------|------|---------|
| 400 | `VALIDATION_ERROR` | "Invalid input" + field details |
| 401 | `UNAUTHORIZED` | "Authentication required" |
| 404 | `NOT_FOUND` | "Post not found" |
| 429 | `RATE_LIMIT` | "Too many requests" + retryAfter |
| 500 | `INTERNAL_ERROR` | "Internal server error" |

See [reference.md > Client-Side API Error Handling](reference.md#client-side-api-error-handling) for fetch error handling patterns.

---

## Section 7: User-Facing Error Messages [HIGH]

### Rules

**Rules**: (1) Tell user WHAT happened (2) Tell user WHAT TO DO (3) Never expose stack traces/SQL/internal details (4) Helpful, not alarming tone

```
BAD:  "Error: PGRST116 - JSON object requested, multiple (or no) rows returned"
GOOD: "Post not found. It may have been deleted."
```

See [reference.md > User Message Mapping](reference.md#user-message-mapping) for the error message mapping code (`lib/error-messages.ts`).

---

## Section 8: Error Recovery [MEDIUM]

- **Retry with exponential backoff**: Don't retry programmer errors or auth failures
- **Graceful degradation**: Show cached/stale data on refresh failure

See [reference.md > Error Recovery Patterns](reference.md#error-recovery-patterns) for `withRetry` and `DashboardStats` implementation.

---

## Cross-references [MEDIUM]

- **typescript-best-practices**: 型安全なエラーハンドリング・カスタムエラー型・Result型パターン
- **testing-strategy**: エラーパステストの設計・エラーシナリオのカバレッジ確保
- **security-review**: エラーメッセージからの情報漏洩検知・スタックトレース露出の監査

## Checklist

### [CRITICAL] Error Boundaries
- [ ] `error.tsx` at app root catches children errors
- [ ] `global-error.tsx` catches root layout errors (renders `<html>` + `<body>`)
- [ ] `not-found.tsx` at app root for `notFound()` calls
- [ ] Critical segments (dashboard, settings) have own `error.tsx`

### [CRITICAL] Error Architecture
- [ ] Custom error classes extend `AppError` with `isOperational` flag
- [ ] Server Actions return `ActionResult<T>` objects (never throw to client)
- [ ] Middleware errors caught and redirected (never crash the request)
- [ ] No silently swallowed errors (`catch { return null }`)

### [HIGH] API & Logging
- [ ] API routes return `{ error: { code, message } }` format consistently
- [ ] Structured JSON logging via `logger.*` (not `console.log` strings)
- [ ] Sensitive data never logged (see `security-review` for audit)
- [ ] Sentry configured with `beforeSend` filtering operational errors

### [HIGH] User Experience
- [ ] User-facing messages: what happened + what to do (see `micro-interaction-patterns` for UI)
- [ ] Retry with exponential backoff for transient external failures
- [ ] Graceful degradation: show cached data when live fetch fails
