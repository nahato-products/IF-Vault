---
name: error-handling-logging
description: "Error handling and logging architecture for Next.js App Router applications. Covers error.tsx/global-error.tsx boundary hierarchy, custom AppError class hierarchy with isOperational classification, structured JSON logging with log-level strategy, Sentry integration (@sentry/nextjs) with operational error filtering, API error response standardization, notFound()/redirect() control flow, Server Action result-object pattern, middleware error containment, and user-facing error message mapping. Use when implementing error boundaries, configuring structured logging, integrating Sentry monitoring, designing API error responses, classifying operational vs programmer errors, handling middleware failures, building error recovery with retry/fallback, or mapping internal errors to user-safe messages. Does NOT cover debugging process (systematic-debugging), test writing (testing-strategy), or security vulnerabilities (security-review)."
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

```
An error occurs ->
  |
  +-- Is it expected? (validation, not found, auth failure)
  |     -> Operational Error: handle gracefully, log at INFO/WARN
  |
  +-- Is it unexpected? (null ref, type error, crash)
  |     -> Programmer Error: log at ERROR, report to Sentry, show generic message
  |
  +-- Where does it happen?
        +-- Server Component / API Route -> try-catch + structured log
        +-- Client Component -> error.tsx boundary
        +-- Middleware -> catch + NextResponse.redirect or NextResponse.next()
        +-- Server Action -> return error object (never throw)
        +-- Expected 404 -> call notFound() (renders not-found.tsx)
```

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
export class AppError extends Error {
  constructor(message, code, statusCode = 500, isOperational = true, context?)
}
```

Subclasses: `NotFoundError` (404), `ValidationError` (400), `AuthenticationError` (401), `ForbiddenError` (403), `RateLimitError` (429), `ExternalServiceError` (502). Full implementation: see [reference.md > Custom Error Classes](reference.md#custom-error-classes-full-hierarchy)

### Usage

```typescript
async function getPost(id: string) {
  const { data, error } = await supabase
    .from('posts').select('*').eq('id', id).single()
  if (error) {
    if (error.code === 'PGRST116') throw new NotFoundError('Post', id)
    throw new ExternalServiceError('Supabase', error as unknown as Error)
  }
  return data
}
```

---

## Section 2: Next.js Error Boundary Hierarchy [CRITICAL]

### File Structure

```
app/
  error.tsx           <- Catches errors in root layout's children
  global-error.tsx    <- Catches errors in root layout itself
  not-found.tsx       <- Renders when notFound() is called
  layout.tsx
  dashboard/
    error.tsx         <- Catches errors in dashboard segment
    not-found.tsx     <- Segment-specific not-found page
    settings/
      error.tsx       <- Most specific: catches settings errors
```

### Rules

```
1. error.tsx catches errors in its SIBLING page.tsx and CHILD segments
2. error.tsx does NOT catch errors in its SIBLING layout.tsx
3. To catch layout errors, place error.tsx in the PARENT segment
4. global-error.tsx catches errors in ROOT layout — MUST render <html> and <body>
5. notFound() triggers the nearest not-found.tsx (does NOT trigger error.tsx)
6. redirect() throws internally — do NOT wrap in try-catch
```

See [reference.md > error.tsx Implementation Examples](reference.md#errortsx-implementation-examples) for Root/Global/Segment error boundary code.

---

## Section 3: Server-Side Error Handling [CRITICAL]

### Server Action Pattern (Recommended)

```typescript
// GOOD: Return error state instead of throwing
'use server'

type ActionResult<T> =
  | { success: true; data: T }
  | { success: false; error: { code: string; message: string } }

export async function createPost(
  formData: FormData
): Promise<ActionResult<{ id: string }>> {
  try {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) {
      return { success: false, error: { code: 'UNAUTHORIZED', message: 'Please sign in' } }
    }

    const title = formData.get('title') as string
    if (!title || title.length < 3) {
      return {
        success: false,
        error: { code: 'VALIDATION_ERROR', message: 'Title must be at least 3 characters' },
      }
    }

    const { data, error } = await supabase
      .from('posts').insert({ title, user_id: user.id }).select('id').single()

    if (error) {
      logger.error('Failed to create post', { error: error.message, userId: user.id })
      return { success: false, error: { code: 'CREATE_FAILED', message: 'Failed to create post' } }
    }

    return { success: true, data: { id: data.id } }
  } catch (err) {
    logger.error('Unexpected error in createPost', { error: err })
    return { success: false, error: { code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' } }
  }
}
```

### Middleware Error Handling

```typescript
// middleware.ts
import { NextResponse, type NextRequest } from 'next/server'

export async function middleware(request: NextRequest) {
  try {
    const supabase = createMiddlewareClient(request)
    const { data: { session } } = await supabase.auth.getSession()
    if (!session && request.nextUrl.pathname.startsWith('/dashboard')) {
      return NextResponse.redirect(new URL('/login', request.url))
    }
    return NextResponse.next()
  } catch (err) {
    // Middleware errors must not crash — redirect to safe page
    logger.error('Middleware error', { path: request.nextUrl.pathname, error: (err as Error).message })
    return NextResponse.redirect(new URL('/error', request.url))
  }
}
```

See [reference.md > API Route Error Handler](reference.md#api-route-error-handler) and [Try-Catch Best Practices](reference.md#try-catch-best-practices) for more patterns.

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
// GOOD: Structured JSON log with context
logger.info('Post created', { postId: data.id, userId: user.id, action: 'create_post' })
logger.error('Database query failed', { query: 'posts.select', error: error.message, code: error.code })

// BAD: Unstructured string logs
console.log('Post created: ' + data.id)
console.error('Error: ' + error)
```

### Sensitive Data Rules

```
NEVER log: passwords, tokens, API keys, credit card numbers, PII
NEVER expose in error responses: stack traces, SQL errors, internal paths
GOOD: logger.info('User authenticated', { userId: user.id, method: 'email' })
BAD:  logger.info('User login', { email: user.email, password: password })
```

For comprehensive information leakage audit, see `security-review`. See [reference.md > Logger Implementation](reference.md#logger-implementation) for the full `lib/logger.ts` code.

---

## Section 5: Sentry Integration [HIGH]

Setup: `@sentry/nextjs` with 3 config files (client, server, edge) + `instrumentation.ts`

Key settings:
- `tracesSampleRate: 0.1` (10% of transactions)
- `replaysOnErrorSampleRate: 1.0` (100% on error)
- `beforeSend`: Filter out operational errors (`AppError.isOperational`)

```typescript
// Manual reporting with context
Sentry.captureException(err, {
  tags: { module: 'payments', orderId: order.id },
  extra: { orderAmount: order.amount },
  user: { id: user.id },
})
```

See [reference.md > Sentry Configuration](reference.md#sentry-configuration) for full client/server/edge config code.

---

## Section 6: API Error Response Design [HIGH]

### Standard Format

```typescript
interface ApiErrorResponse {
  error: {
    code: string       // Machine-readable: 'NOT_FOUND', 'VALIDATION_ERROR'
    message: string    // Human-readable (safe for UI)
    details?: unknown  // Optional: field-level errors, retry info
  }
}
```

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

```
1. Tell the user WHAT happened (not technical details)
2. Tell the user WHAT TO DO (action they can take)
3. Never expose stack traces, SQL errors, or internal details
4. Use appropriate tone (helpful, not alarming)
```

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
