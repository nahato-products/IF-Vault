# Error Handling & Logging — Reference

Supplementary material for skill.md. Contains copy-paste-ready templates: custom error class hierarchy, error.tsx boundaries, logger, Sentry config (client/server/edge), API error handler, user message mapping, and retry/fallback patterns.

**Cross-references**: `security-review` (error info leakage audit), `systematic-debugging` (error investigation process), `nextjs-app-router-patterns` (error.tsx routing conventions), `micro-interaction-patterns` (error state UI/toast), `testing-strategy` (error scenario coverage).

---

## Custom Error Classes (Full Hierarchy)

```typescript
// lib/errors.ts

interface AppErrorOptions {
  message: string;
  code: string;
  statusCode?: number;
  isOperational?: boolean;
  context?: Record<string, unknown>;
}

export class AppError extends Error {
  public readonly code: string;
  public readonly statusCode: number;
  public readonly isOperational: boolean;
  public readonly context?: Record<string, unknown>;

  constructor(opts: AppErrorOptions) {
    super(opts.message);
    this.name = 'AppError';
    this.code = opts.code;
    this.statusCode = opts.statusCode ?? 500;
    this.isOperational = opts.isOperational ?? true;
    this.context = opts.context;

    // V8 環境 (Node.js) でスタックトレースから AppError コンストラクタを除外
    if (Error.captureStackTrace) {
      Error.captureStackTrace(this, AppError);
    }
  }
}

export class NotFoundError extends AppError {
  constructor(resource: string, id?: string) {
    super({
      message: `${resource}${id ? ` (${id})` : ''} not found`,
      code: 'NOT_FOUND',
      statusCode: 404,
      context: { resource, id },
    });
    this.name = 'NotFoundError';
  }
}

export class ValidationError extends AppError {
  public readonly fields?: Record<string, string[]>;
  constructor(message: string, fields?: Record<string, string[]>) {
    super({
      message,
      code: 'VALIDATION_ERROR',
      statusCode: 400,
      context: { fields },
    });
    this.name = 'ValidationError';
    this.fields = fields;
  }
}

export class AuthenticationError extends AppError {
  constructor(message = 'Authentication required') {
    super({ message, code: 'UNAUTHORIZED', statusCode: 401 });
    this.name = 'AuthenticationError';
  }
}

export class ForbiddenError extends AppError {
  constructor(message = 'Access denied') {
    super({ message, code: 'FORBIDDEN', statusCode: 403 });
    this.name = 'ForbiddenError';
  }
}

export class RateLimitError extends AppError {
  constructor(retryAfter?: number) {
    super({
      message: 'Too many requests',
      code: 'RATE_LIMIT',
      statusCode: 429,
      context: { retryAfter },
    });
    this.name = 'RateLimitError';
  }
}

export class ExternalServiceError extends AppError {
  constructor(service: string, originalError?: Error) {
    super({
      message: `External service error: ${service}`,
      code: 'EXTERNAL_SERVICE_ERROR',
      statusCode: 502,
      context: { service, originalMessage: originalError?.message },
    });
    this.name = 'ExternalServiceError';
  }
}
```

---

## AppError Usage Example

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

## Server Action Pattern (Full)

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

---

## Middleware Error Handling

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

---

## Structured Logging Examples

```typescript
// GOOD: Structured JSON log with context
logger.info('Post created', { postId: data.id, userId: user.id, action: 'create_post' })
logger.error('Database query failed', { query: 'posts.select', error: error.message, code: error.code })

// BAD: Unstructured string logs
console.log('Post created: ' + data.id)
console.error('Error: ' + error)
```

---

## API Error Response Interface

```typescript
interface ApiErrorResponse {
  error: {
    code: string       // Machine-readable: 'NOT_FOUND', 'VALIDATION_ERROR'
    message: string    // Human-readable (safe for UI)
    details?: unknown  // Optional: field-level errors, retry info
  }
}
```

---

## error.tsx Implementation Examples

### Root Error Boundary

```typescript
// app/error.tsx
'use client'

import { useEffect } from 'react'
import * as Sentry from '@sentry/nextjs'

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  useEffect(() => {
    Sentry.captureException(error)
  }, [error])

  return (
    <div className="flex min-h-[400px] flex-col items-center justify-center gap-4">
      <h2 className="text-xl font-semibold">Something went wrong</h2>
      <p className="text-muted-foreground">
        An unexpected error occurred. Please try again.
      </p>
      <button
        onClick={() => reset()}
        className="rounded-md bg-primary px-4 py-2 text-white"
      >
        Try again
      </button>
    </div>
  )
}
```

### Global Error Boundary

```typescript
// app/global-error.tsx — MUST include <html> and <body>
'use client'

import * as Sentry from '@sentry/nextjs'
import { useEffect } from 'react'

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  useEffect(() => {
    Sentry.captureException(error)
  }, [error])

  return (
    <html>
      <body>
        <div className="flex min-h-screen items-center justify-center">
          <div className="text-center">
            <h2 className="text-xl font-semibold">Something went wrong</h2>
            <button onClick={() => reset()}>Try again</button>
          </div>
        </div>
      </body>
    </html>
  )
}
```

### Not Found Page

```tsx
// app/not-found.tsx
import Link from 'next/link'

export default function NotFound() {
  return (
    <div className="flex min-h-[50vh] flex-col items-center justify-center gap-4">
      <h2 className="text-2xl font-bold">ページが見つかりません</h2>
      <p className="text-muted-foreground">お探しのページは存在しないか、移動した可能性があります。</p>
      <Link href="/" className="text-primary underline">トップに戻る</Link>
    </div>
  )
}
```

### Segment-Specific Error Boundary

```typescript
// app/dashboard/error.tsx
'use client'

import { useEffect } from 'react'
import * as Sentry from '@sentry/nextjs'
import Link from 'next/link'

export default function DashboardError({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  useEffect(() => {
    Sentry.captureException(error, {
      tags: { segment: 'dashboard' },
    })
  }, [error])

  return (
    <div className="p-8">
      <h2>Dashboard failed to load</h2>
      <p>Your data might be temporarily unavailable.</p>
      <div className="flex gap-2">
        <button onClick={() => reset()}>Retry</button>
        <Link href="/">Go Home</Link>
      </div>
    </div>
  )
}
```

---

## API Route Error Handler

```typescript
// app/api/posts/[id]/route.ts
import { NextResponse } from 'next/server'
import { AppError, NotFoundError } from '@/lib/errors'
import { logger } from '@/lib/logger'

export async function GET(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params
  try {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      return NextResponse.json(
        { error: { code: 'UNAUTHORIZED', message: 'Authentication required' } },
        { status: 401 }
      )
    }
    const { data: post, error } = await supabase
      .from('posts').select('*').eq('id', id).single()
    if (error) throw new NotFoundError('Post', id)
    return NextResponse.json(post)
  } catch (err) {
    return handleApiError(err)
  }
}

function handleApiError(err: unknown): NextResponse {
  if (err instanceof AppError) {
    logger.warn('Operational error', {
      code: err.code, message: err.message,
      statusCode: err.statusCode, context: err.context,
    })
    return NextResponse.json(
      { error: { code: err.code, message: err.isOperational ? err.message : 'Internal server error' } },
      { status: err.statusCode }
    )
  }
  logger.error('Unexpected error', {
    error: err instanceof Error ? err.message : 'Unknown error',
    stack: err instanceof Error ? err.stack : undefined,
  })
  return NextResponse.json(
    { error: { code: 'INTERNAL_ERROR', message: 'Internal server error' } },
    { status: 500 }
  )
}
```

---

## Try-Catch Best Practices

```typescript
// GOOD: Specific catch with context
try {
  const data = await fetchExternalAPI()
  return processData(data)
} catch (err) {
  if (err instanceof AppError) throw err
  throw new ExternalServiceError('payment-api', err instanceof Error ? err : undefined)
}

// BAD: Swallowing errors silently
try {
  const data = await fetchExternalAPI()
} catch (err) {
  console.log(err)  // No structured logging
  return null        // Caller has no idea something failed
}

// BAD: Catching too broadly
try {
  const user = await getUser()
  const posts = await getPosts(user.id)
  const comments = await getComments(posts.map(p => p.id))
} catch (err) {
  return { error: 'Something went wrong' }  // Which operation failed?
}

// GOOD: Narrow try-catch
const user = await getUser() // Let auth errors propagate
try {
  const posts = await getPosts(user.id)
  return posts
} catch (err) {
  throw new ExternalServiceError('posts-service', err as Error)
}
```

---

## Logger Implementation

```typescript
// lib/logger.ts
type LogLevel = 'debug' | 'info' | 'warn' | 'error'

interface LogEntry {
  level: LogLevel
  message: string
  timestamp: string
  [key: string]: unknown
}

function createLogEntry(level: LogLevel, message: string, meta?: Record<string, unknown>): LogEntry {
  return { level, message, timestamp: new Date().toISOString(), ...meta }
}

// NOTE: この logger は最小限の shim 実装。本番環境では pino や winston 等の構造化ロガーを推奨。
export const logger = {
  debug(message: string, meta?: Record<string, unknown>) {
    if (process.env.NODE_ENV === 'development') {
      console.debug(JSON.stringify(createLogEntry('debug', message, meta)))
    }
  },
  info(message: string, meta?: Record<string, unknown>) {
    console.log(JSON.stringify(createLogEntry('info', message, meta)))
  },
  warn(message: string, meta?: Record<string, unknown>) {
    console.warn(JSON.stringify(createLogEntry('warn', message, meta)))
  },
  error(message: string, meta?: Record<string, unknown>) {
    console.error(JSON.stringify(createLogEntry('error', message, meta)))
  },
}
```

---

## Sentry Configuration

### Client Config

```typescript
// sentry.client.config.ts
import * as Sentry from '@sentry/nextjs'

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  tracesSampleRate: 0.1,
  replaysSessionSampleRate: 0.1,
  replaysOnErrorSampleRate: 1.0,
  environment: process.env.NODE_ENV,
  integrations: [Sentry.replayIntegration()],
  beforeSend(event) {
    if (event.exception?.values?.[0]?.type === 'NotFoundError') return null
    return event
  },
})
```

### Server Config

```typescript
// sentry.server.config.ts
import * as Sentry from '@sentry/nextjs'

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  tracesSampleRate: 0.1,
  environment: process.env.NODE_ENV,
})
```

### Edge Config

```typescript
// sentry.edge.config.ts
import * as Sentry from '@sentry/nextjs'

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  tracesSampleRate: 0.1,
  environment: process.env.NODE_ENV,
})
```

### Instrumentation

```typescript
// instrumentation.ts
import * as Sentry from '@sentry/nextjs'

export async function register() {
  if (process.env.NEXT_RUNTIME === 'nodejs') await import('./sentry.server.config')
  if (process.env.NEXT_RUNTIME === 'edge') await import('./sentry.edge.config')
}
export const onRequestError = Sentry.captureRequestError
```

### Manual Error Reporting

```typescript
try {
  await processPayment(order)
} catch (err) {
  Sentry.captureException(err, {
    tags: { module: 'payments', orderId: order.id },
    extra: { orderAmount: order.amount, paymentMethod: order.method },
    user: { id: user.id },
  })
  throw err
}
```

### Sentry + Custom Errors Filter (Server-Side)

Use `hint.originalException` for reliable type checking on the server side where `AppError` instances are available directly:

```typescript
// sentry.server.config.ts — enhanced beforeSend
Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  tracesSampleRate: 0.1,
  beforeSend(event, hint) {
    const error = hint.originalException
    if (error instanceof AppError && error.isOperational) return null
    return event
  },
})
```

---

## Client-Side API Error Handling

```typescript
async function fetchPost(id: string) {
  const res = await fetch(`/api/posts/${id}`)
  if (!res.ok) {
    const body = await res.json().catch(() => null)
    const errorMessage = body?.error?.message ?? 'An error occurred'
    switch (res.status) {
      case 401: redirect('/login'); break
      case 404: notFound(); break
      case 429: throw new Error(`Rate limited. Retry after ${body?.error?.details?.retryAfter}s`)
      default: throw new Error(errorMessage)
    }
  }
  return res.json()
}
```

---

## User Message Mapping

```typescript
// lib/error-messages.ts
const userMessages: Record<string, { title: string; description: string; action: string }> = {
  UNAUTHORIZED: { title: 'Sign in required', description: 'You need to sign in to access this page.', action: 'Sign in' },
  FORBIDDEN: { title: 'Access denied', description: 'You do not have permission to view this content.', action: 'Go back' },
  NOT_FOUND: { title: 'Not found', description: 'The page or resource does not exist.', action: 'Go home' },
  VALIDATION_ERROR: { title: 'Invalid input', description: 'Please check your input and try again.', action: 'Fix and retry' },
  RATE_LIMIT: { title: 'Too many requests', description: 'Please wait a moment before trying again.', action: 'Wait and retry' },
  INTERNAL_ERROR: { title: 'Something went wrong', description: 'An unexpected error occurred. Our team has been notified.', action: 'Try again' },
  NETWORK_ERROR: { title: 'Connection problem', description: 'Please check your internet connection.', action: 'Retry' },
}

export function getUserMessage(code: string) {
  return userMessages[code] ?? userMessages.INTERNAL_ERROR
}
```

---

## Error Recovery Patterns

### Retry with Exponential Backoff

```typescript
async function withRetry<T>(
  fn: () => Promise<T>,
  options: { maxRetries?: number; baseDelay?: number } = {}
): Promise<T> {
  const { maxRetries = 3, baseDelay = 1000 } = options
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await fn()
    } catch (err) {
      if (err instanceof AppError && !err.isOperational) throw err
      if (err instanceof AuthenticationError) throw err
      if (attempt === maxRetries) throw err
      const delay = baseDelay * Math.pow(2, attempt)
      logger.warn('Retrying operation', { attempt: attempt + 1, delay })
      await new Promise(resolve => setTimeout(resolve, delay))
    }
  }
  throw new Error('Unreachable')
}
```

### Graceful Degradation

```typescript
async function DashboardStats() {
  try {
    const stats = await fetchStats()
    return <StatsDisplay data={stats} />
  } catch (err) {
    logger.warn('Failed to fetch stats, showing cached', { error: (err as Error).message })
    const cached = await getCachedStats()
    if (cached) {
      return (
        <div>
          <StatsDisplay data={cached} />
          <p className="text-muted-foreground text-sm">
            Showing cached data. Live data temporarily unavailable.
          </p>
        </div>
      )
    }
    throw err // No cache available - let error boundary handle
  }
}
```

---

## Error Scenario Test Checklist

Use with `testing-strategy` to ensure error paths have test coverage.

| Scenario | Test Approach | Priority |
|----------|--------------|----------|
| API returns 400 (validation) | Unit: assert `ActionResult.error.code === 'VALIDATION_ERROR'` | CRITICAL |
| API returns 401 (unauthenticated) | Integration: mock expired session | CRITICAL |
| API returns 404 (not found) | Unit: assert `NotFoundError` thrown | HIGH |
| API returns 429 (rate limit) | Unit: assert retry backoff behavior | HIGH |
| API returns 500 (unexpected) | Integration: mock DB failure | CRITICAL |
| External service timeout | Unit: assert `ExternalServiceError` + retry | HIGH |
| Middleware crash | Integration: assert redirect to `/error` | CRITICAL |
| Server Action unexpected throw | Integration: assert `INTERNAL_ERROR` returned | HIGH |
| Sentry filters operational errors | Unit: assert `beforeSend` returns null for `AppError` | MEDIUM |
| Sensitive data not in logs | Unit: assert log output excludes PII fields | CRITICAL |

---

## New Project Setup Template

Files to create when adding error handling to a new Next.js project:

```
lib/errors.ts          <- AppError + subclasses (copy from Custom Error Classes above)
lib/logger.ts          <- Structured logger (copy from Logger Implementation above)
lib/error-messages.ts  <- User message mapping (copy from User Message Mapping above)
app/error.tsx          <- Root error boundary (copy from error.tsx Examples above)
app/global-error.tsx   <- Root layout error boundary
app/not-found.tsx      <- 404 page
sentry.client.config.ts
sentry.server.config.ts
sentry.edge.config.ts
instrumentation.ts     <- Sentry registration
```
