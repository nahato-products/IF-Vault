---
name: nextjs-app-router-patterns
description: "Next.js 15 App Router architecture patterns for routing (parallel, intercepting, route groups, dynamic/catch-all segments), data fetching and caching (ISR, tag-based revalidation, use cache, PPR), Suspense streaming, Server Actions with revalidation, Route Handlers, generateMetadata/generateStaticParams for SEO, and Middleware. Use when building or migrating to App Router, designing nested routing, configuring caching or revalidation, implementing streaming, creating Route Handlers, optimizing SEO metadata, or writing auth/i18n middleware. Does NOT cover component design (react-component-patterns), runtime performance (vercel-react-best-practices), or error classification, logging strategy, or Sentry integration (error-handling-logging)."
user-invocable: false
---

# Next.js App Router Patterns

Next.js 15 App Router のルーティング、データフェッチ、キャッシュ、ストリーミング、ミドルウェアの実践パターン集。

## When to Apply

- App Router のルーティング設計（parallel, intercepting, route groups, dynamic segments）
- データフェッチとキャッシュ戦略（static/dynamic rendering, ISR, tag-based revalidation）
- Suspense ストリーミングの設計
- Server Actions によるデータ変更（ルーティング連携）
- Route Handlers（API エンドポイント）
- Metadata / SEO 最適化
- Middleware（認証、リダイレクト、i18n）

## When NOT to Apply

- コンポーネント設計・合成パターン・SC/CC境界設計 -> react-component-patterns
- React/Next.js パフォーマンス最適化ルール -> vercel-react-best-practices
- エラー分類・ログ戦略・Sentry連携 -> error-handling-logging（error.tsx File Convention は本スキルでカバー）
- Tailwind トークン・ユーティリティ設計 -> tailwind-design-system
- 認証・Supabase 連携 -> supabase-auth-patterns
- テスト戦略 -> testing-strategy
- CI/CD・デプロイ -> ci-cd-deployment

---

## Part 1: Rendering & File Conventions [CRITICAL]

### Rendering Modes

| Mode | Where | When to Use |
|------|-------|-------------|
| **Server Components** | Server only | データフェッチ、秘匿情報、重い計算 |
| **Client Components** | Browser | インタラクション、hooks、ブラウザAPI |
| **Static rendering** | Build time | 変更頻度が低いコンテンツ |
| **Dynamic rendering** | Request time | パーソナライズ、リアルタイムデータ |
| **Streaming** | Progressive | 大きいページ、遅いデータソース |

### File Conventions

```
app/
├── layout.tsx          # 共有UIラッパー（再マウントなし）
├── page.tsx            # ルートUI
├── loading.tsx         # Suspense fallback
├── error.tsx           # Error boundary（Client Component必須、reset()で再試行可能）
├── not-found.tsx       # 404 UI
├── route.ts            # API endpoint（page.tsxと共存不可）
├── template.tsx        # 毎回再マウントされるlayout
├── default.tsx         # Parallel route fallback
└── opengraph-image.tsx # OG画像生成
```

### error.tsx / not-found.tsx

```typescript
// error.tsx — 'use client' 必須。digest でサーバーエラーの詳細を隠蔽
'use client'
export default function Error({ error, reset }: { error: Error & { digest?: string }; reset: () => void }) {
  return <div><h2>エラーが発生しました</h2><button onClick={() => reset()}>再試行</button></div>
}

// not-found.tsx — notFound() で最も近い not-found.tsx を表示
import { notFound } from 'next/navigation'
// 動的ルート内で: if (!data) notFound()
```

---

## Part 2: Routing Patterns [CRITICAL]

### Dynamic Segments

| パターン | 例 | マッチ |
|---------|---|--------|
| `[slug]` | `app/blog/[slug]/page.tsx` | `/blog/hello` |
| `[...slug]` | `app/docs/[...slug]/page.tsx` | `/docs/a/b/c` |
| `[[...slug]]` | `app/shop/[[...slug]]/page.tsx` | `/shop` or `/shop/a/b` |

### Route Groups

```
app/
├── (marketing)/       # URLに影響しないグループ化
│   ├── layout.tsx      # marketing用レイアウト
│   ├── about/page.tsx  # /about
│   └── blog/page.tsx   # /blog
├── (shop)/
│   ├── layout.tsx      # shop用レイアウト
│   └── products/page.tsx # /products
└── layout.tsx          # root layout
```

### Parallel Routes

```typescript
// app/dashboard/layout.tsx
export default function DashboardLayout({
  children,
  analytics,
  team,
}: {
  children: React.ReactNode
  analytics: React.ReactNode
  team: React.ReactNode
}) {
  return (
    <div className="dashboard-grid">
      <main>{children}</main>
      <aside>{analytics}</aside>
      <aside>{team}</aside>
    </div>
  )
}

// app/dashboard/@analytics/page.tsx — 独立したloading.tsxで個別ストリーミング
// app/dashboard/@analytics/loading.tsx
// app/dashboard/@team/page.tsx
// app/dashboard/@team/default.tsx — ソフトナビ時のfallback
```

### Client Navigation Hooks

| Hook | 用途 | 注意 |
|------|------|------|
| `useRouter()` | `push`/`replace`/`back`/`refresh` | Client Component のみ |
| `usePathname()` | 現在パス名 (`/products/123`) | - |
| `useSearchParams()` | クエリパラメータ (読み取り専用) | Suspense 内で使用 |
| `useParams()` | 動的セグメント値 (`{ slug: 'hello' }`) | - |

全て `'next/navigation'` からimport。コード例は reference.md 参照。

### Intercepting Routes (Modal Pattern)

ファイル構造と実装例 -> reference.md「Intercepting Routes」参照

**Key rules**:
- `(.)` 同階層、`(..)` 1階層上、`(...)` rootから
- `default.tsx` は `null` を返して非アクティブ時にモーダルを非表示
- ハードリフレッシュ時はフルページ版が描画される

---

## Part 3: Data Fetching & Caching [CRITICAL]

### Server Component でのデータフェッチ

```typescript
// app/products/page.tsx
import { Suspense } from 'react'

export default async function ProductsPage({
  searchParams,
}: {
  searchParams: Promise<{ category?: string; page?: string }>
}) {
  const params = await searchParams

  return (
    <div className="flex gap-8">
      <FilterSidebar />
      <Suspense
        key={JSON.stringify(params)}
        fallback={<ProductListSkeleton />}
      >
        <ProductList
          category={params.category}
          page={Number(params.page) || 1}
        />
      </Suspense>
    </div>
  )
}

// components/products/ProductList.tsx — Server Component
async function getProducts(filters: ProductFilters) {
  const res = await fetch(
    `${process.env.API_URL}/products?${new URLSearchParams(filters)}`,
    { next: { tags: ['products'] } }
  )
  if (!res.ok) throw new Error('Failed to fetch products')
  return res.json()
}

export async function ProductList({ category, page }: ProductFilters) {
  const { products, totalPages } = await getProducts({ category, page })
  return (
    <div>
      <div className="grid grid-cols-3 gap-4">
        {products.map((p) => <ProductCard key={p.id} product={p} />)}
      </div>
      <Pagination currentPage={page} totalPages={totalPages} />
    </div>
  )
}
```

### Caching Strategy（Next.js 15）

Next.js 15 では fetch のデフォルトが `no-store` に変更。明示的なキャッシュ設定が必要。

**判断ルール**: Static > ISR > On-demand > Dynamic（パフォーマンス順に検討）
- 全ユーザー共通 + ほぼ不変 -> `cache: 'force-cache'`
- 全ユーザー共通 + 定期更新 -> `next: { revalidate: N }`
- 全ユーザー共通 + イベント駆動 -> `next: { tags: [...] }` + `revalidateTag()`
- パーソナライズ/リアルタイム -> `fetch(url)` (デフォルト no-store)

See reference.md > Caching Decision Flowchart for complete fetch option examples.

### Revalidation の使い分け

- `revalidateTag('tag')` — タグに紐づく全 fetch/cache を無効化（推奨: 影響範囲が明確）
- `revalidatePath('/path')` — 特定パスのページを再検証（ページ全体が対象）
- **判断基準**: データモデル単位の無効化は Tag、ページ単位の再生成は Path

### Route Segment Config

```typescript
// ページ/レイアウト単位でレンダリング制御
export const dynamic = 'force-dynamic'  // 常にDynamic
// export const dynamic = 'force-static' // 常にStatic
export const revalidate = 3600          // ISR（秒）
export const fetchCache = 'force-cache' // 全fetchをキャッシュ
export const runtime = 'edge'           // Edge Runtime
```

### `use cache` ディレクティブ（Next.js 15, experimental: dynamicIO 必須）

`fetch` を使わないデータ取得（ORM、DB直接等）にキャッシュを適用。

```typescript
// ORM / 直接DBクエリのキャッシュ
async function getProducts() {
  'use cache'
  return db.product.findMany()
}

// キャッシュ寿命とタグの制御
import { cacheLife, cacheTag } from 'next/cache'

async function getProduct(id: string) {
  'use cache'
  cacheLife('hours')  // 'seconds' | 'minutes' | 'hours' | 'days' | 'weeks' | 'max'
  cacheTag('product', `product-${id}`)
  return db.product.findUnique({ where: { id } })
}
```

### Partial Prerendering (PPR) [MEDIUM]

静的シェル + 動的ストリーミングを1リクエストで実現。

```typescript
// next.config.ts
const nextConfig = { experimental: { ppr: 'incremental' } }

// app/product/[id]/page.tsx
export const experimental_ppr = true  // ページ単位で有効化
// Suspense 外 = 静的シェル（ビルド時生成）
// Suspense 内 = 動的ホール（リクエスト時ストリーミング）
```

Caching判断フローチャートは reference.md 参照。

---

## Part 4: Streaming with Suspense [HIGH]

```typescript
// app/product/[id]/page.tsx
export default async function ProductPage({
  params,
}: {
  params: Promise<{ id: string }>
}) {
  const { id } = await params
  const product = await getProduct(id) // blocking fetch

  return (
    <div>
      <ProductHeader product={product} />
      {/* 遅いデータをストリーミング */}
      <Suspense fallback={<ReviewsSkeleton />}>
        <Reviews productId={id} />
      </Suspense>
      <Suspense fallback={<RecommendationsSkeleton />}>
        <Recommendations productId={id} />
      </Suspense>
    </div>
  )
}

// 各コンポーネントが独立してデータフェッチ
async function Reviews({ productId }: { productId: string }) {
  const reviews = await getReviews(productId)
  return <ReviewList reviews={reviews} />
}
```

**Streaming設計の原則**:
- `loading.tsx` = ページ全体の Suspense boundary
- 部分的ストリーミングには手動 `<Suspense>` を使う
- `key` prop で searchParams 変更時にSuspenseをリセット

---

## Part 5: Route Handlers [HIGH]

```typescript
// app/api/products/route.ts
import { NextRequest, NextResponse } from 'next/server'

export async function GET(request: NextRequest) {
  const category = request.nextUrl.searchParams.get('category')
  const products = await db.product.findMany({
    where: category ? { category } : undefined,
    take: 20,
  })
  return NextResponse.json(products)
}

export async function POST(request: NextRequest) {
  const body = await request.json()
  const product = await db.product.create({ data: body })
  return NextResponse.json(product, { status: 201 })
}
```

```typescript
// Dynamic route: app/api/products/[id]/route.ts
export async function GET(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params
  const product = await db.product.findUnique({ where: { id } })
  if (!product) return NextResponse.json({ error: 'Not found' }, { status: 404 })
  return NextResponse.json(product)
}
```

**注意**: `page.tsx` と `route.ts` は同じディレクトリに共存不可。認証・バリデーション付き Route Handler は reference.md 参照。

---

## Part 6: Metadata & SEO [HIGH]

```typescript
// app/products/[slug]/page.tsx
import { Metadata } from 'next'
import { notFound } from 'next/navigation'

type Props = { params: Promise<{ slug: string }> }

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params
  const product = await getProduct(slug)
  if (!product) return {}

  return {
    title: product.name,
    description: product.description,
    openGraph: {
      title: product.name,
      description: product.description,
      images: [{ url: product.image, width: 1200, height: 630 }],
    },
  }
}

export async function generateStaticParams() {
  const products = await db.product.findMany({ select: { slug: true } })
  return products.map((p) => ({ slug: p.slug }))
}

export default async function ProductPage({ params }: Props) {
  const { slug } = await params
  const product = await getProduct(slug)
  if (!product) notFound()
  return <ProductDetail product={product} />
}
```

Metadata の継承: 子ルートの metadata が親をマージ上書き。`title.template` で統一フォーマット。generateStaticParams の応用パターンは reference.md 参照。

---

## Part 7: Middleware [HIGH]

```typescript
// middleware.ts（プロジェクトルート）
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function middleware(request: NextRequest) {
  const token = request.cookies.get('session')?.value
  if (!token && request.nextUrl.pathname.startsWith('/dashboard')) {
    return NextResponse.redirect(new URL('/login', request.url))
  }
  return NextResponse.next()
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
}
```

**注意**: Middleware は Edge Runtime で動作。Node.js API は使えない。認証の詳細は supabase-auth-patterns 参照。追加パターン（i18n、rate limiting）は reference.md 参照。

---

## Part 8: Server Actions（ルーティング連携）[HIGH]

コンポーネント設計の詳細（useOptimistic, useActionState 等）は react-component-patterns 参照。ここではルーティング連携パターンのみ。

```typescript
// app/actions/cart.ts
'use server'
import { revalidateTag } from 'next/cache'
import { cookies } from 'next/headers'
import { redirect } from 'next/navigation'

export async function addToCart(productId: string) {
  const cookieStore = await cookies()
  const sessionId = cookieStore.get('session')?.value
  // redirect() は内部で throw するため try/catch の外で呼ぶ
  if (!sessionId) redirect('/login')

  try {
    await db.cart.upsert({
      where: { sessionId_productId: { sessionId, productId } },
      update: { quantity: { increment: 1 } },
      create: { sessionId, productId, quantity: 1 },
    })
    revalidateTag('cart')
    return { success: true }
  } catch {
    return { error: 'Failed to add item to cart' }
  }
}
```

**Server Actions の重要ルール**:
- `redirect()` は内部で例外を throw する。try/catch 内で呼ぶとキャッチされてリダイレクトが失敗する
- Progressive Enhancement: `<form action={serverAction}>` は JS 無効でも動作する（HTML フォーム送信にフォールバック）

---

## Best Practices

### Do's

- **Server Components をデフォルトに** — `'use client'` は必要な箇所だけ（-> react-component-patterns）
- **データフェッチをコロケーション** — 使う場所で取得、Suspense で並列化
- **キャッシュを明示的に設定** — Next.js 15 のデフォルト no-store を前提に設計
- **Parallel routes で独立ローディング** — 各スロットが独立して streaming
- **generateStaticParams で静的生成** — 既知のパスは事前ビルド

### Don'ts

- **fetch を Client Component で直接呼ばない** — SC または React Query/SWR を使う
- **layout.tsx を過度にネストしない** — 各 layout がコンポーネントツリーに追加される
- **loading.tsx / Suspense を省略しない** — ストリーミングの恩恵を受けられない
- **Middleware で重い処理をしない** — Edge Runtime、軽量な判定のみ
- **route.ts と page.tsx を同ディレクトリに置かない** — 共存不可

---

## Reference

詳細なコード例・設定テンプレートは [reference.md](reference.md) を参照:

- Intercepting Routes のフル実装例（Modal Pattern）
- Root Layout テンプレート（next/font, metadataBase, title.template）
- next.config.ts 設定テンプレート（images, redirects, rewrites, headers, typedRoutes, experimental）
- Caching 判断フローチャート（Static / ISR / On-demand / Dynamic）
- Middleware パターン集（i18n locale detection, rate limiting）
- generateStaticParams の応用パターン（ネスト、部分ビルド、dynamicParams）
- Route Handler の認証・バリデーション・エラーハンドリング
- `use cache` パターン（cacheLife プリセット一覧、カスタム設定、fetch cache との使い分け）
