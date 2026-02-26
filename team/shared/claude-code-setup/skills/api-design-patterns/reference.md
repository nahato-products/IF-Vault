# API Design Patterns — Reference

Copy-paste-ready templates: OpenAPI 3.1 spec, error response schemas, pagination (cursor + offset), rate limit middleware, Next.js Route Handler examples, naming antipatterns, status code decision tree.

**Cross-references**: `nextjs-app-router-patterns` (Route Handler routing), `error-handling-logging` (AppError class), `typescript-best-practices` (Zod validation), `_security-review` (API vulnerability audit).

---

## API Naming Antipatterns

| Antipattern | Example | Fix |
|-------------|---------|-----|
| Verb in URL | `GET /getUsers` | `GET /users` |
| Singular noun | `GET /user/123` | `GET /users/123` |
| camelCase path | `/orderItems` | `/order-items` |
| Action in URL | `POST /users/123/delete` | `DELETE /users/123` |
| Deep nesting | `/users/1/posts/2/comments/3/likes` | `/comments/3/likes` or flatten |
| Query in path | `/users/status/active` | `/users?status=active` |
| Inconsistent plural | `/user/123/posts` | `/users/123/posts` |
| ID in body for GET | `GET /users` body: `{id:1}` | `GET /users/1` |
| File extension | `/users.json` | `Accept: application/json` header |

---

## Status Code Decision Tree

```
Request received
├── Auth header present?
│   ├── No  → 401 Unauthorized
│   └── Yes → Token valid?
│       ├── No  → 401 Unauthorized
│       └── Yes → Has permission?
│           ├── No  → 403 Forbidden
│           └── Yes → continue
├── Request body valid? (Zod parse)
│   ├── No  → 400 Bad Request (VALIDATION_ERROR)
│   └── Yes → continue
├── Resource exists?
│   ├── No  → 404 Not Found
│   └── Yes → continue
├── Business rule conflict? (duplicate email, etc.)
│   ├── Yes → 409 Conflict
│   └── No  → continue
├── Rate limit exceeded?
│   ├── Yes → 429 Too Many Requests + Retry-After
│   └── No  → continue
├── Process request
│   ├── External service failure → 502 Bad Gateway
│   ├── Unexpected error → 500 Internal Server Error
│   └── Success
│       ├── GET/PUT/PATCH → 200 OK
│       ├── POST (created) → 201 Created + Location header
│       └── DELETE → 204 No Content
```

---

## Error Response Examples

### 400 Validation Error

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input",
    "details": {
      "email": ["Invalid email format"],
      "password": ["Must be at least 8 characters"]
    }
  }
}
```

### 401 Unauthorized

```json
{
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Authentication required"
  }
}
```

### 403 Forbidden

```json
{
  "error": {
    "code": "FORBIDDEN",
    "message": "You do not have permission to access this resource"
  }
}
```

### 404 Not Found

```json
{
  "error": {
    "code": "NOT_FOUND",
    "message": "Post not found"
  }
}
```

### 409 Conflict

```json
{
  "error": {
    "code": "CONFLICT",
    "message": "A user with this email already exists"
  }
}
```

### 429 Rate Limited

```json
{
  "error": {
    "code": "RATE_LIMITED",
    "message": "Too many requests. Please retry after 60 seconds.",
    "details": { "retry_after": 60 }
  }
}
```

### 500 Internal Error

```json
{
  "error": {
    "code": "INTERNAL_ERROR",
    "message": "Internal server error"
  }
}
```

---

## API Response Type Definitions

```typescript
// lib/api/types.ts

/** Successful response wrapper */
export type ApiSuccessResponse<T> = {
  data: T;
  pagination?: CursorPagination | OffsetPagination;
};

/** Error response wrapper */
export type ApiErrorResponse = {
  error: {
    code: string;
    message: string;
    details?: Record<string, string[]> | unknown;
  };
};

/** Union type for all API responses */
export type ApiResponse<T> = ApiSuccessResponse<T> | ApiErrorResponse;

/** Cursor-based pagination metadata */
export type CursorPagination = {
  next_cursor: string | null;
  has_more: boolean;
};

/** Offset-based pagination metadata */
export type OffsetPagination = {
  page: number;
  per_page: number;
  total: number;
  total_pages: number;
};
```

---

## Pagination Implementation

### Cursor-based (Recommended)

```typescript
// lib/api/pagination.ts
import { z } from 'zod';

export const cursorPaginationSchema = z.object({
  cursor: z.string().optional(),
  limit: z.coerce.number().min(1).max(100).default(20),
});

export type CursorPaginationInput = z.infer<typeof cursorPaginationSchema>;

/**
 * Decode cursor (base64-encoded JSON)
 * Cursor format: { id: string, created_at: string }
 */
export function decodeCursor(cursor: string): Record<string, unknown> {
  try {
    return JSON.parse(Buffer.from(cursor, 'base64url').toString('utf-8'));
  } catch {
    throw new ValidationError('Invalid cursor format', { cursor: ['Malformed cursor'] });
  }
}

export function encodeCursor(data: Record<string, unknown>): string {
  return Buffer.from(JSON.stringify(data)).toString('base64url');
}

// Usage in Route Handler
// app/api/posts/route.ts
export async function GET(request: NextRequest) {
  const { searchParams } = request.nextUrl;
  const { cursor, limit } = cursorPaginationSchema.parse({
    cursor: searchParams.get('cursor') ?? undefined,
    limit: searchParams.get('limit') ?? undefined,
  });

  let query = supabase
    .from('posts')
    .select('id, title, created_at')
    .order('created_at', { ascending: false })
    .limit(limit + 1); // +1 to check has_more

  if (cursor) {
    const decoded = decodeCursor(cursor);
    query = query.lt('created_at', decoded.created_at);
  }

  const { data, error } = await query;
  if (error) throw new ExternalServiceError('Supabase', error as unknown as Error);

  const has_more = data.length > limit;
  const items = has_more ? data.slice(0, limit) : data;
  const next_cursor = has_more
    ? encodeCursor({ id: items.at(-1)!.id, created_at: items.at(-1)!.created_at })
    : null;

  return NextResponse.json({
    data: items,
    pagination: { next_cursor, has_more },
  });
}
```

### Offset-based

```typescript
// lib/api/pagination.ts
export const offsetPaginationSchema = z.object({
  page: z.coerce.number().min(1).default(1),
  per_page: z.coerce.number().min(1).max(100).default(20),
});

// Usage in Route Handler
export async function GET(request: NextRequest) {
  const { searchParams } = request.nextUrl;
  const { page, per_page } = offsetPaginationSchema.parse({
    page: searchParams.get('page') ?? undefined,
    per_page: searchParams.get('per_page') ?? undefined,
  });

  const from = (page - 1) * per_page;
  const to = from + per_page - 1;

  const { data, error, count } = await supabase
    .from('posts')
    .select('id, title, created_at', { count: 'exact' })
    .order('created_at', { ascending: false })
    .range(from, to);

  if (error) throw new ExternalServiceError('Supabase', error as unknown as Error);

  const total = count ?? 0;
  return NextResponse.json({
    data,
    pagination: {
      page,
      per_page,
      total,
      total_pages: Math.ceil(total / per_page),
    },
  });
}
```

---

## Rate Limit Middleware

```typescript
// lib/api/rate-limit.ts
// NOTE: Map-based は単一サーバーのみ有効。本番は Upstash Redis 等を使う

import { NextRequest, NextResponse } from 'next/server';

type RateLimitConfig = {
  limit: number;       // requests per window
  windowMs: number;    // window duration in ms
};

// --- Development / single-instance only ---
const requests = new Map<string, { count: number; resetTime: number }>();

export function rateLimit(config: RateLimitConfig) {
  return (request: NextRequest): NextResponse | null => {
    const ip = request.headers.get('x-forwarded-for') ?? 'unknown';
    const now = Date.now();
    const record = requests.get(ip);

    if (!record || now > record.resetTime) {
      requests.set(ip, { count: 1, resetTime: now + config.windowMs });
      return null; // allow
    }

    record.count++;
    if (record.count > config.limit) {
      const retryAfter = Math.ceil((record.resetTime - now) / 1000);
      return NextResponse.json(
        { error: { code: 'RATE_LIMITED', message: `Too many requests. Retry after ${retryAfter}s.`, details: { retry_after: retryAfter } } },
        {
          status: 429,
          headers: {
            'Retry-After': String(retryAfter),
            'X-RateLimit-Limit': String(config.limit),
            'X-RateLimit-Remaining': '0',
            'X-RateLimit-Reset': String(Math.ceil(record.resetTime / 1000)),
          },
        }
      );
    }

    return null; // allow
  };
}

// --- Production: Upstash Redis pattern ---
// import { Ratelimit } from '@upstash/ratelimit';
// import { Redis } from '@upstash/redis';
//
// const redis = new Redis({ url: process.env.UPSTASH_REDIS_URL!, token: process.env.UPSTASH_REDIS_TOKEN! });
// const limiter = new Ratelimit({ redis, limiter: Ratelimit.slidingWindow(100, '1 m') });
//
// export async function rateLimitUpstash(request: NextRequest) {
//   const ip = request.headers.get('x-forwarded-for') ?? 'unknown';
//   const { success, limit, remaining, reset } = await limiter.limit(ip);
//   if (!success) {
//     return NextResponse.json(
//       { error: { code: 'RATE_LIMITED', message: 'Too many requests' } },
//       { status: 429, headers: { 'X-RateLimit-Limit': String(limit), 'X-RateLimit-Remaining': String(remaining), 'X-RateLimit-Reset': String(reset) } }
//     );
//   }
//   return null;
// }
```

---

## Route Handler Examples

### Full CRUD Example

```typescript
// app/api/v1/posts/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { apiHandler } from '@/lib/api/handler';
import { createPost, getPosts } from '@/features/posts/lib/queries';
import { cursorPaginationSchema, decodeCursor, encodeCursor } from '@/lib/api/pagination';

const createPostSchema = z.object({
  title: z.string().min(1).max(200),
  body: z.string().min(1),
  published: z.boolean().default(false),
});

// GET /api/v1/posts?limit=20&cursor=xxx
export const GET = apiHandler(async (request: NextRequest) => {
  const { searchParams } = request.nextUrl;
  const { cursor, limit } = cursorPaginationSchema.parse({
    cursor: searchParams.get('cursor') ?? undefined,
    limit: searchParams.get('limit') ?? undefined,
  });

  const { items, has_more, next_cursor } = await getPosts({ cursor, limit });

  return NextResponse.json({
    data: items,
    pagination: { next_cursor, has_more },
  });
});

// POST /api/v1/posts
export const POST = apiHandler(async (request: NextRequest) => {
  // Auth check
  const user = await getAuthUser(request);
  if (!user) {
    return NextResponse.json(
      { error: { code: 'UNAUTHORIZED', message: 'Authentication required' } },
      { status: 401 }
    );
  }

  // Validate
  const body = await request.json();
  const parsed = createPostSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: { code: 'VALIDATION_ERROR', message: 'Invalid input', details: parsed.error.flatten().fieldErrors } },
      { status: 400 }
    );
  }

  // Create
  const post = await createPost({ ...parsed.data, author_id: user.id });

  return NextResponse.json(
    { data: post },
    {
      status: 201,
      headers: { Location: `/api/v1/posts/${post.id}` },
    }
  );
});
```

### Dynamic Route (GET / PUT / DELETE)

```typescript
// app/api/v1/posts/[id]/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { apiHandler } from '@/lib/api/handler';
import { getPost, updatePost, deletePost } from '@/features/posts/lib/queries';
import { NotFoundError } from '@/lib/errors';

type RouteContext = { params: Promise<{ id: string }> };

const updatePostSchema = z.object({
  title: z.string().min(1).max(200).optional(),
  body: z.string().min(1).optional(),
  published: z.boolean().optional(),
}).refine((data) => Object.keys(data).length > 0, {
  message: 'At least one field must be provided',
});

// GET /api/v1/posts/:id
export const GET = apiHandler(async (_request: NextRequest, { params }: RouteContext) => {
  const { id } = await params;
  const post = await getPost(id);
  if (!post) throw new NotFoundError('Post', id);

  return NextResponse.json({ data: post });
});

// PATCH /api/v1/posts/:id
export const PATCH = apiHandler(async (request: NextRequest, { params }: RouteContext) => {
  const { id } = await params;
  const user = await getAuthUser(request);
  if (!user) {
    return NextResponse.json(
      { error: { code: 'UNAUTHORIZED', message: 'Authentication required' } },
      { status: 401 }
    );
  }

  const body = await request.json();
  const parsed = updatePostSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: { code: 'VALIDATION_ERROR', message: 'Invalid input', details: parsed.error.flatten().fieldErrors } },
      { status: 400 }
    );
  }

  const post = await updatePost(id, parsed.data);
  if (!post) throw new NotFoundError('Post', id);

  return NextResponse.json({ data: post });
});

// DELETE /api/v1/posts/:id
export const DELETE = apiHandler(async (_request: NextRequest, { params }: RouteContext) => {
  const { id } = await params;
  const user = await getAuthUser(request);
  if (!user) {
    return NextResponse.json(
      { error: { code: 'UNAUTHORIZED', message: 'Authentication required' } },
      { status: 401 }
    );
  }

  await deletePost(id);
  return new NextResponse(null, { status: 204 });
});
```

### apiHandler Wrapper (Full Implementation)

```typescript
// lib/api/handler.ts
import { NextRequest, NextResponse } from 'next/server';
import { AppError } from '@/lib/errors';

type HandlerFn = (
  request: NextRequest,
  context: any
) => Promise<NextResponse>;

/**
 * Wraps Route Handlers with consistent error handling.
 * Catches AppError subclasses and returns proper JSON error responses.
 * Logs unexpected errors and returns generic 500.
 */
export function apiHandler(fn: HandlerFn): HandlerFn {
  return async (request, context) => {
    try {
      return await fn(request, context);
    } catch (error) {
      // Known operational errors
      if (error instanceof AppError) {
        return NextResponse.json(
          {
            error: {
              code: error.code,
              message: error.message,
              ...(error.context ? { details: error.context } : {}),
            },
          },
          { status: error.statusCode }
        );
      }

      // Zod validation errors (if thrown directly)
      if (error instanceof Error && error.name === 'ZodError') {
        return NextResponse.json(
          {
            error: {
              code: 'VALIDATION_ERROR',
              message: 'Invalid input',
              details: (error as any).flatten?.()?.fieldErrors,
            },
          },
          { status: 400 }
        );
      }

      // Unexpected errors
      console.error('[API] Unhandled error:', {
        method: request.method,
        url: request.nextUrl.pathname,
        error: error instanceof Error ? error.message : String(error),
        stack: error instanceof Error ? error.stack : undefined,
      });

      return NextResponse.json(
        { error: { code: 'INTERNAL_ERROR', message: 'Internal server error' } },
        { status: 500 }
      );
    }
  };
}
```

---

## Auth Helper for Route Handlers

```typescript
// lib/api/auth.ts
import { NextRequest } from 'next/server';
import { createClient } from '@/lib/supabase/server';

/**
 * Extract and verify the authenticated user from request.
 * Returns null if not authenticated (caller decides 401 vs. public access).
 */
export async function getAuthUser(request: NextRequest) {
  const authHeader = request.headers.get('authorization');
  if (!authHeader?.startsWith('Bearer ')) return null;

  const token = authHeader.slice(7);
  const supabase = await createClient();
  const { data: { user }, error } = await supabase.auth.getUser(token);

  if (error || !user) return null;
  return user;
}
```

---

## OpenAPI Template

```yaml
# openapi/spec.yaml
openapi: "3.1.0"
info:
  title: My App API
  description: RESTful API for My App
  version: "1.0.0"
  contact:
    name: API Support
    email: support@example.com

servers:
  - url: http://localhost:3000/api/v1
    description: Development
  - url: https://myapp.vercel.app/api/v1
    description: Production

tags:
  - name: Posts
    description: Blog post operations
  - name: Users
    description: User management

paths:
  /posts:
    get:
      tags: [Posts]
      summary: List posts
      operationId: listPosts
      parameters:
        - name: cursor
          in: query
          description: Pagination cursor
          schema:
            type: string
        - name: limit
          in: query
          description: Number of items per page
          schema:
            type: integer
            minimum: 1
            maximum: 100
            default: 20
      responses:
        "200":
          description: Paginated list of posts
          content:
            application/json:
              schema:
                type: object
                required: [data, pagination]
                properties:
                  data:
                    type: array
                    items:
                      $ref: "#/components/schemas/Post"
                  pagination:
                    $ref: "#/components/schemas/CursorPagination"
        "429":
          $ref: "#/components/responses/RateLimited"

    post:
      tags: [Posts]
      summary: Create a post
      operationId: createPost
      security:
        - BearerAuth: []
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/CreatePostInput"
      responses:
        "201":
          description: Post created
          headers:
            Location:
              schema:
                type: string
              description: URL of the created post
          content:
            application/json:
              schema:
                type: object
                properties:
                  data:
                    $ref: "#/components/schemas/Post"
        "400":
          $ref: "#/components/responses/ValidationError"
        "401":
          $ref: "#/components/responses/Unauthorized"

  /posts/{id}:
    get:
      tags: [Posts]
      summary: Get a post by ID
      operationId: getPost
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
            format: uuid
      responses:
        "200":
          description: Post details
          content:
            application/json:
              schema:
                type: object
                properties:
                  data:
                    $ref: "#/components/schemas/Post"
        "404":
          $ref: "#/components/responses/NotFound"

components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT

  schemas:
    Post:
      type: object
      required: [id, title, body, published, created_at]
      properties:
        id:
          type: string
          format: uuid
        title:
          type: string
          maxLength: 200
        body:
          type: string
        published:
          type: boolean
        created_at:
          type: string
          format: date-time

    CreatePostInput:
      type: object
      required: [title, body]
      properties:
        title:
          type: string
          minLength: 1
          maxLength: 200
        body:
          type: string
          minLength: 1
        published:
          type: boolean
          default: false

    CursorPagination:
      type: object
      required: [next_cursor, has_more]
      properties:
        next_cursor:
          type: ["string", "null"]
        has_more:
          type: boolean

    ErrorResponse:
      type: object
      required: [error]
      properties:
        error:
          type: object
          required: [code, message]
          properties:
            code:
              type: string
            message:
              type: string
            details:
              type: object

  responses:
    ValidationError:
      description: Validation error
      content:
        application/json:
          schema:
            $ref: "#/components/schemas/ErrorResponse"
          example:
            error:
              code: VALIDATION_ERROR
              message: Invalid input
              details:
                title: ["Required"]

    Unauthorized:
      description: Authentication required
      content:
        application/json:
          schema:
            $ref: "#/components/schemas/ErrorResponse"
          example:
            error:
              code: UNAUTHORIZED
              message: Authentication required

    NotFound:
      description: Resource not found
      content:
        application/json:
          schema:
            $ref: "#/components/schemas/ErrorResponse"
          example:
            error:
              code: NOT_FOUND
              message: Resource not found

    RateLimited:
      description: Rate limit exceeded
      headers:
        Retry-After:
          schema:
            type: integer
        X-RateLimit-Limit:
          schema:
            type: integer
        X-RateLimit-Remaining:
          schema:
            type: integer
        X-RateLimit-Reset:
          schema:
            type: integer
      content:
        application/json:
          schema:
            $ref: "#/components/schemas/ErrorResponse"
          example:
            error:
              code: RATE_LIMITED
              message: Too many requests
              details:
                retry_after: 60
```
