---
name: api-design-patterns
description: "Design RESTful and RPC APIs with consistent naming conventions, HTTP method semantics, error response formats, pagination patterns, versioning strategies, and OpenAPI 3.1 documentation. Use when designing API endpoints, defining request/response schemas, implementing error handling for APIs, setting up API versioning, creating OpenAPI specs, reviewing API contracts, or building Route Handlers in Next.js App Router. Do not trigger for frontend component design (use react-component-patterns) or database schema design (use supabase-postgres-best-practices)."
user-invocable: false
triggers:
  - APIを設計したい
  - RESTful API
  - OpenAPI
  - エンドポイントを定義する
  - APIのエラーレスポンス形式
---

# API Design Patterns

RESTful API の設計原則、命名規約、エラーレスポンス、ページネーション、バージョニング、Next.js Route Handler 実装パターン。

## Scope & Relationship to Other Skills

| Topic | This Skill | Other Skill |
|-------|-----------|-------------|
| API endpoint naming & HTTP semantics | Here | - |
| Error response JSON format | Here: API response structure | `error-handling-logging` (AppError class, logging) |
| Route Handler implementation | Here: API design patterns | `nextjs-app-router-patterns` (file conventions, routing) |
| Input validation schemas | Here: request validation pattern | `typescript-best-practices` (Zod patterns) |
| Auth token verification in APIs | Here: pattern overview | `supabase-auth-patterns` (full auth flow) |
| API security audit | Here: design-time best practices | `_security-review` (vulnerability detection) |

---

## Section 1: Resource Naming [CRITICAL]

### Rules

1. **Plural nouns** for collections: `/users`, `/posts`, `/order-items`
2. **kebab-case** for multi-word: `/order-items` (not `orderItems` or `order_items`)
3. **Nouns, not verbs**: `/users/{id}` (not `/getUser/{id}`)
4. **Nesting max 2 levels**: `/users/{id}/posts` (not `/users/{id}/posts/{pid}/comments/{cid}`)
5. **Filter via query params**: `/posts?status=published&author=123`

```
GOOD: GET  /api/v1/users/{id}/posts?status=published
BAD:  GET  /api/v1/getUserPosts?userId=123&status=published
BAD:  POST /api/v1/users/{id}/deletePost  (use DELETE method)
```

-> アンチパターン一覧: [reference.md > API Naming Antipatterns](reference.md#api-naming-antipatterns)

---

## Section 2: HTTP Method Semantics [CRITICAL]

| Method | Purpose | Idempotent | Request Body | Success Code |
|--------|---------|:----------:|:------------:|:------------:|
| `GET` | Read resource(s) | Yes | No | `200` |
| `POST` | Create resource | No | Yes | `201` |
| `PUT` | Full replace | Yes | Yes | `200` |
| `PATCH` | Partial update | Yes* | Yes | `200` |
| `DELETE` | Remove resource | Yes | No | `204` |

**Rules**:
- `GET` は副作用なし（キャッシュ可能）
- `POST` レスポンスに `Location` ヘッダーで新リソース URL を返す
- `DELETE` 成功時は `204 No Content`（ボディなし）
- `PUT` vs `PATCH`: フィールド全置換 vs 差分更新

---

## Section 3: Status Codes [CRITICAL]

### Success (2xx)

| Code | When |
|------|------|
| `200 OK` | GET/PUT/PATCH 成功 |
| `201 Created` | POST で新リソース作成 |
| `204 No Content` | DELETE 成功、ボディなし |

### Client Error (4xx)

| Code | When | Error Code |
|------|------|-----------|
| `400 Bad Request` | バリデーションエラー | `VALIDATION_ERROR` |
| `401 Unauthorized` | 認証なし/トークン期限切れ | `UNAUTHORIZED` |
| `403 Forbidden` | 認可失敗（権限なし） | `FORBIDDEN` |
| `404 Not Found` | リソース存在しない | `NOT_FOUND` |
| `409 Conflict` | 重複、競合 | `CONFLICT` |
| `422 Unprocessable Entity` | 構文OK だがセマンティクスNG | `UNPROCESSABLE` |
| `429 Too Many Requests` | レート制限超過 | `RATE_LIMITED` |

### Server Error (5xx)

| Code | When | Error Code |
|------|------|-----------|
| `500 Internal Server Error` | 予期しないエラー | `INTERNAL_ERROR` |
| `502 Bad Gateway` | 外部サービス障害 | `EXTERNAL_SERVICE_ERROR` |
| `503 Service Unavailable` | メンテナンス/過負荷 | `SERVICE_UNAVAILABLE` |

---

## Section 4: Error Response Format [CRITICAL]

全 API エンドポイントで統一フォーマットを使用。

```typescript
// lib/api/types.ts
type ApiErrorResponse = {
  error: {
    code: string;        // 機械可読コード (UPPER_SNAKE_CASE)
    message: string;     // 人間可読メッセージ
    details?: unknown;   // バリデーションエラーのフィールド詳細等
  };
};

// 400 バリデーションエラー例
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input",
    "details": { "email": ["Invalid email format"], "name": ["Required"] }
  }
}
```

**Rules**:
- 本番で stack trace を返さない
- `code` は機械可読（フロント側の条件分岐に使う）
- `message` はユーザーに表示可能な文言
- `details` はバリデーション時のみ（フィールド単位エラー）

-> 全ステータスのレスポンス例: [reference.md > Error Response Examples](reference.md#error-response-examples)

---

## Section 5: Pagination [HIGH]

### Cursor-based（推奨）

無限スクロール、リアルタイムデータ、大規模データセットに最適。

```typescript
// Request:  GET /api/posts?limit=20&cursor=eyJpZCI6MTAwfQ
// Response:
{
  "data": [...],
  "pagination": {
    "next_cursor": "eyJpZCI6MTIwfQ",  // base64 encoded
    "has_more": true
  }
}
```

### Offset-based

管理画面、ページ番号ナビゲーションが必要な場合。

```typescript
// Request:  GET /api/posts?page=2&per_page=20
// Response:
{
  "data": [...],
  "pagination": {
    "page": 2,
    "per_page": 20,
    "total": 156,
    "total_pages": 8
  }
}
```

**判断基準**: リアルタイム/大規模 -> Cursor | ページ番号UI必要 -> Offset

-> 実装例: [reference.md > Pagination Implementation](reference.md#pagination-implementation)

---

## Section 6: Versioning [HIGH]

### URL Path（推奨）

```
/api/v1/users
/api/v2/users
```

**理由**: 明示的、ブラウザでテスト容易、キャッシュしやすい。

### Header（代替）

```
Accept: application/vnd.myapp.v2+json
```

**判断基準**: 社内API/BFF -> URL Path | 公開API + 柔軟性重視 -> Header

**運用ルール**:
- 破壊的変更時のみメジャーバージョンを上げる
- 旧バージョンは最低6ヶ月の廃止猶予（`Sunset` ヘッダー）
- `Deprecation: true` + `Link: </api/v2/users>; rel="successor-version"` で移行案内

---

## Section 7: Authentication & Rate Limiting [HIGH]

### Authentication

```typescript
// Bearer Token（JWT）
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...

// API Key（サービス間通信）
X-API-Key: ${process.env.API_KEY}
```

**Rules**:
- JWT は `Authorization: Bearer` ヘッダー。クエリパラメータに入れない
- API Key はヘッダー経由。URL に含めない（ログに残る）
- 認証エラーは `401`、認可エラーは `403`（区別する）

### Rate Limiting Headers

```
X-RateLimit-Limit: 100        // 上限
X-RateLimit-Remaining: 42     // 残り
X-RateLimit-Reset: 1672531200 // リセット時刻 (Unix epoch)
Retry-After: 60               // 429 時の待機秒数
```

-> ミドルウェア実装: [reference.md > Rate Limit Middleware](reference.md#rate-limit-middleware)

---

## Section 8: Next.js Route Handler Patterns [CRITICAL]

### 基本構造

```typescript
// app/api/posts/route.ts
import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
  const { searchParams } = request.nextUrl;
  const page = Number(searchParams.get('page') ?? '1');

  const posts = await getPosts({ page });
  return NextResponse.json({ data: posts });
}

export async function POST(request: NextRequest) {
  const body = await request.json();
  const parsed = createPostSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: { code: 'VALIDATION_ERROR', message: 'Invalid input', details: parsed.error.flatten().fieldErrors } },
      { status: 400 }
    );
  }
  const post = await createPost(parsed.data);
  return NextResponse.json({ data: post }, { status: 201 });
}
```

### Dynamic Route

```typescript
// app/api/posts/[id]/route.ts  — Next.js 15: params は Promise
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  // ...
}
```

### 共通エラーハンドラ

```typescript
// lib/api/handler.ts — Route Handler をラップして統一エラー処理
export function apiHandler(fn: (req: NextRequest, ctx: any) => Promise<NextResponse>) {
  return async (req: NextRequest, ctx: any) => {
    try {
      return await fn(req, ctx);
    } catch (error) {
      if (error instanceof AppError) {
        return NextResponse.json(
          { error: { code: error.code, message: error.message } },
          { status: error.statusCode }
        );
      }
      console.error('Unhandled API error:', error);
      return NextResponse.json(
        { error: { code: 'INTERNAL_ERROR', message: 'Internal server error' } },
        { status: 500 }
      );
    }
  };
}
```

-> フル実装例: [reference.md > Route Handler Examples](reference.md#route-handler-examples)

---

## Section 9: OpenAPI 3.1 [MEDIUM]

API 仕様を先に定義（API-First Design）してからRoute Handler を実装。

**最小構成**:

```yaml
openapi: "3.1.0"
info:
  title: My API
  version: "1.0.0"
paths:
  /api/v1/posts:
    get:
      summary: List posts
      parameters:
        - name: cursor
          in: query
          schema: { type: string }
      responses:
        "200":
          description: Success
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/PostListResponse"
```

**Tips**:
- `$ref` でスキーマを再利用（DRY）
- Zod スキーマから OpenAPI を自動生成（`zod-to-openapi`）
- CI で OpenAPI spec と実装の乖離を検出

-> テンプレート: [reference.md > OpenAPI Template](reference.md#openapi-template)

---

## Cross-references

- **nextjs-app-router-patterns**: Route Handler のファイル配置・ルーティング規約・キャッシュ設定
- **error-handling-logging**: AppError クラス階層・構造化ログ・Sentry 連携
- **typescript-best-practices**: Zod スキーマ駆動バリデーション・型安全なリクエスト/レスポンス型
- **_security-review**: API エンドポイントの脆弱性検知・認証バイパス・入力検証の監査

## Checklist

### [CRITICAL] Naming & Semantics
- [ ] リソース名は複数形名詞 + kebab-case
- [ ] HTTP メソッドが正しいセマンティクス（GET=読取、POST=作成、etc.）
- [ ] ステータスコードが適切（201 for POST、204 for DELETE、etc.）

### [CRITICAL] Error Handling
- [ ] 全エンドポイントで `{ error: { code, message } }` 統一フォーマット
- [ ] バリデーションエラーに `details`（フィールド単位）を含む
- [ ] 本番環境で stack trace / 内部パスを返さない

### [HIGH] Pagination & Versioning
- [ ] リスト API にページネーション実装（cursor or offset）
- [ ] API バージョンを URL パスに含む（`/api/v1/...`）
- [ ] Rate limit ヘッダーを返す

### [HIGH] Next.js Route Handlers
- [ ] Zod で request body をバリデーション
- [ ] `apiHandler` ラッパーで統一エラー処理
- [ ] Next.js 15: `params` を `Promise` として await

## Reference

コード例・テンプレートは [reference.md](reference.md) 参照（OpenAPI テンプレート、ページネーション実装、Rate Limit ミドルウェア、Route Handler フル実装、アンチパターン表）

## Cross-references

- **api-design-principles**: REST/GraphQL設計原則の概念レベル判断（こちらは実装パターン集）
- **_supabase-postgres-best-practices**: API設計と連携するDB設計・クエリ最適化
- **nextjs-app-router-patterns**: Next.js Route HandlersでのAPI実装
- **_security-best-practices**: APIのセキュリティ（認証・認可・入力バリデーション）
- **typescript-best-practices**: Zodバリデーション・型安全なAPIスキーマ設計
