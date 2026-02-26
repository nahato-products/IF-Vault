# Next.js App Router Patterns — Reference

## Contents

- File Conventions (Directory Structure)
- error.tsx / not-found.tsx Full Example
- Route Groups (Directory Structure)
- Parallel Routes Full Example
- Route Segment Config Options
- PPR (Partial Prerendering) Setup
- Server Actions (Routing Integration) Full Example
- Intercepting Routes (Modal Pattern) — Full Implementation
- Root Layout Template
- next.config.ts Template
- Caching Decision Flowchart
- Middleware Patterns (i18n, Rate Limiting)
- generateStaticParams Patterns
- Route Handler Authentication & Validation
- Error Handling in Route Handlers
- `use cache` Patterns

---

## File Conventions (Directory Structure)

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

---

## error.tsx / not-found.tsx Full Example

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

## Route Groups (Directory Structure)

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

---

## Parallel Routes Full Example

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

---

## Route Segment Config Options

```typescript
// ページ/レイアウト単位でレンダリング制御
export const dynamic = 'force-dynamic'  // 常にDynamic
// export const dynamic = 'force-static' // 常にStatic
export const revalidate = 3600          // ISR（秒）
export const fetchCache = 'force-cache' // 全fetchをキャッシュ
export const runtime = 'edge'           // Edge Runtime
```

---

## PPR (Partial Prerendering) Setup

```typescript
// next.config.ts
const nextConfig = { experimental: { ppr: 'incremental' } }

// app/product/[id]/page.tsx
export const experimental_ppr = true  // ページ単位で有効化
// Suspense 外 = 静的シェル（ビルド時生成）
// Suspense 内 = 動的ホール（リクエスト時ストリーミング）
```

---

## Server Actions (Routing Integration) Full Example

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

---

## Intercepting Routes (Modal Pattern) — Full Implementation

### File Structure

```
app/
├── @modal/
│   ├── (.)photos/[id]/page.tsx  # Intercept
│   └── default.tsx              # return null
├── photos/
│   └── [id]/page.tsx            # Full page
└── layout.tsx
```

### Modal Intercept Component

```typescript
// app/@modal/(.)photos/[id]/page.tsx
import { Modal } from '@/components/Modal'
import { PhotoDetail } from '@/components/PhotoDetail'

export default async function PhotoModal({
  params,
}: {
  params: Promise<{ id: string }>
}) {
  const { id } = await params
  const photo = await getPhoto(id)
  return (
    <Modal>
      <PhotoDetail photo={photo} />
    </Modal>
  )
}
```

### Full Page Version

```typescript
// app/photos/[id]/page.tsx
export default async function PhotoPage({
  params,
}: {
  params: Promise<{ id: string }>
}) {
  const { id } = await params
  const photo = await getPhoto(id)
  return (
    <div className="photo-page">
      <PhotoDetail photo={photo} />
      <RelatedPhotos photoId={id} />
    </div>
  )
}
```

### Root Layout Integration

```typescript
// app/layout.tsx
export default function RootLayout({
  children,
  modal,
}: {
  children: React.ReactNode
  modal: React.ReactNode
}) {
  return (
    <html>
      <body>
        {children}
        {modal}
      </body>
    </html>
  )
}
```

### Key Points

- `(.)` same level, `(..)` one level up, `(...)` from root
- `default.tsx` in `@modal/` returns `null` to hide when inactive
- Hard refresh renders the full page version, not the modal
- Use `useRouter().back()` for modal close

---

## Root Layout Template

```typescript
// app/layout.tsx
import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'

const inter = Inter({ subsets: ['latin'], display: 'swap' })

export const metadata: Metadata = {
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL!),
  title: {
    default: 'Site Title',
    template: '%s | Site Title', // 子ページが title を設定すると自動フォーマット
  },
  description: 'Site description',
  openGraph: {
    type: 'website',
    locale: 'ja_JP',
    siteName: 'Site Title',
  },
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="ja" className={inter.className}>
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  )
}
```

**Notes**:
- `next/font` は自動 self-hosting。`display: 'swap'` でフラッシュ防止
- `metadataBase` を設定すると OG 画像等の相対 URL が自動解決
- `title.template` で子ルートの title フォーマットを統一

---

## next.config.ts Template

```typescript
// next.config.ts
import type { NextConfig } from 'next'

const nextConfig: NextConfig = {
  // 画像最適化
  images: {
    remotePatterns: [
      { protocol: 'https', hostname: '**.supabase.co' },
      { protocol: 'https', hostname: '**.example.com' },
    ],
    formats: ['image/avif', 'image/webp'],
  },

  // リダイレクト
  async redirects() {
    return [
      { source: '/old-path', destination: '/new-path', permanent: true },
    ]
  },

  // リライト（プロキシ）
  async rewrites() {
    return [
      { source: '/api/proxy/:path*', destination: 'https://external.api/:path*' },
    ]
  },

  // セキュリティヘッダー
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          { key: 'X-Frame-Options', value: 'DENY' },
          { key: 'X-Content-Type-Options', value: 'nosniff' },
          { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
        ],
      },
    ]
  },

  // 実験的機能
  experimental: {
    typedRoutes: true,        // 型安全リンク
    serverActions: {
      bodySizeLimit: '2mb',   // Server Action のボディサイズ上限
    },
  },

  // Webpack カスタム（必要時のみ）
  // webpack: (config) => { return config },
}

export default nextConfig
```

---

## Caching Decision Flowchart

```
データフェッチの判断フロー:

1. データは全ユーザー共通？
   ├─ YES → 更新頻度は？
   │   ├─ ほぼ変わらない → cache: 'force-cache' (Static)
   │   ├─ 定期更新あり → next: { revalidate: N } (ISR)
   │   └─ イベント駆動で更新 → next: { tags: ['xxx'] } + revalidateTag (On-demand)
   └─ NO → パーソナライズ/リアルタイム
       └─ fetch(url) ※デフォルト no-store (Dynamic)

2. ページ単位でレンダリングを強制？
   ├─ export const dynamic = 'force-dynamic'  → 常に SSR
   ├─ export const dynamic = 'force-static'   → 常に SSG
   └─ export const revalidate = N             → ISR

3. 特定キャッシュを即座に無効化？
   ├─ revalidateTag('tag')  → タグに紐づく全 fetch を無効化
   └─ revalidatePath('/path') → 特定パスのキャッシュを再検証
```

**判断の優先順位**: Static > ISR > On-demand > Dynamic（パフォーマンス順）

---

## Middleware Patterns

### i18n Locale Detection

```typescript
// middleware.ts
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'
import { match } from '@formatjs/intl-localematcher'
import Negotiator from 'negotiator'

const locales = ['ja', 'en']
const defaultLocale = 'ja'

function getLocale(request: NextRequest): string {
  const headers = { 'accept-language': request.headers.get('accept-language') || '' }
  const languages = new Negotiator({ headers }).languages()
  return match(languages, locales, defaultLocale)
}

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl
  const hasLocale = locales.some(
    (locale) => pathname.startsWith(`/${locale}/`) || pathname === `/${locale}`
  )
  if (hasLocale) return NextResponse.next()

  const locale = getLocale(request)
  return NextResponse.redirect(new URL(`/${locale}${pathname}`, request.url))
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
}
```

### Rate Limiting (Simple Token Bucket)

```typescript
// middleware.ts — rate limiting 部分
const rateLimit = new Map<string, { count: number; resetTime: number }>()

function isRateLimited(ip: string, limit = 100, windowMs = 60_000): boolean {
  const now = Date.now()
  const record = rateLimit.get(ip)
  if (!record || now > record.resetTime) {
    rateLimit.set(ip, { count: 1, resetTime: now + windowMs })
    return false
  }
  record.count++
  return record.count > limit
}

// middleware 内で使用
export function middleware(request: NextRequest) {
  const ip = request.headers.get('x-forwarded-for') ?? 'unknown'
  if (isRateLimited(ip)) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }
  return NextResponse.next()
}
```

**注意**: この実装はサーバーインスタンス単位。分散環境では Redis (Upstash) 等の外部ストアを使用。

---

## generateStaticParams Patterns

### 基本: 全ページ事前ビルド

```typescript
// app/blog/[slug]/page.tsx
export async function generateStaticParams() {
  const posts = await db.post.findMany({ select: { slug: true } })
  return posts.map((post) => ({ slug: post.slug }))
}
```

### ネストされた動的ルート

```typescript
// app/[lang]/blog/[slug]/page.tsx
export async function generateStaticParams() {
  const posts = await db.post.findMany({ select: { slug: true } })
  return ['ja', 'en'].flatMap((lang) =>
    posts.map((post) => ({ lang, slug: post.slug }))
  )
}
```

### 部分的な事前ビルド + dynamicParams

```typescript
// 人気ページのみ事前ビルド、残りはオンデマンド
export async function generateStaticParams() {
  const topPosts = await db.post.findMany({
    where: { views: { gte: 100 } },
    select: { slug: true },
    take: 50,
  })
  return topPosts.map((post) => ({ slug: post.slug }))
}

// true(default): 未ビルドのパスはオンデマンド生成してキャッシュ
// false: 未ビルドのパスは404
export const dynamicParams = true
```

---

## Route Handler Authentication & Validation

```typescript
// app/api/products/route.ts
import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { createClient } from '@/lib/supabase/server'

// バリデーションスキーマ
const createProductSchema = z.object({
  name: z.string().min(1).max(200),
  price: z.number().positive(),
  category: z.string().optional(),
})

export async function POST(request: NextRequest) {
  // 1. 認証チェック
  const supabase = await createClient()
  const { data: { user }, error: authError } = await supabase.auth.getUser()
  if (authError || !user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  // 2. バリデーション
  const body = await request.json()
  const result = createProductSchema.safeParse(body)
  if (!result.success) {
    return NextResponse.json(
      { error: 'Validation failed', details: result.error.flatten() },
      { status: 400 }
    )
  }

  // 3. ビジネスロジック
  const product = await db.product.create({
    data: { ...result.data, userId: user.id },
  })

  return NextResponse.json(product, { status: 201 })
}
```

**パターン**: 認証 -> バリデーション -> ビジネスロジック の3段階。認証の詳細は supabase-auth-patterns 参照。

---

## Error Handling in Route Handlers

```typescript
// lib/api-utils.ts — 共通エラーハンドリング
export function withErrorHandling(
  handler: (req: NextRequest) => Promise<NextResponse>
) {
  return async (req: NextRequest) => {
    try {
      return await handler(req)
    } catch (error) {
      if (error instanceof z.ZodError) {
        return NextResponse.json(
          { error: 'Validation failed', details: error.flatten() },
          { status: 400 }
        )
      }
      console.error('API Error:', error)
      return NextResponse.json(
        { error: 'Internal server error' },
        { status: 500 }
      )
    }
  }
}
```

エラーハンドリングの全体設計（AppError 階層、Sentry 連携、ログ戦略）は error-handling-logging 参照。

---

## `use cache` Patterns

### cacheLife プリセット一覧

| プリセット | stale | revalidate | expire | 用途 |
|-----------|-------|------------|--------|------|
| `'seconds'` | - | 1s | 60s | 高頻度更新データ |
| `'minutes'` | 5min | 1min | 1h | ダッシュボード |
| `'hours'` | 5min | 1h | 1d | 商品一覧 |
| `'days'` | 5min | 1d | 1w | ブログ記事 |
| `'weeks'` | 5min | 1w | 30d | 設定系データ |
| `'max'` | 5min | 30d | 1y | ほぼ不変データ |

### カスタム cacheLife

```typescript
// next.config.ts
const nextConfig = {
  experimental: {
    dynamicIO: true,
    cacheLife: {
      'product-listing': {
        stale: 300,      // 5分間は stale 許容
        revalidate: 3600, // 1時間で再検証
        expire: 86400,    // 1日で失効
      },
    },
  },
}

// 使用
async function getProducts() {
  'use cache'
  cacheLife('product-listing')
  return db.product.findMany()
}
```

### `use cache` vs fetch cache の使い分け

| 用途 | 手法 |
|------|------|
| 外部 API (HTTP) | `fetch(url, { next: { tags: [...] } })` |
| ORM / DB直接 | `'use cache'` + `cacheTag()` + `cacheLife()` |
| ページ全体 | Route Segment Config (`revalidate`, `dynamic`) |

---

## Data Fetching Full Example

### 並列データフェッチ（ウォーターフォール回避）

```typescript
// 複数の独立したデータを並列取得 — 逐次 await するとウォーターフォールになる
const [products, categories] = await Promise.all([
  getProducts(),
  getCategories(),
])
```

### ページコンポーネントでの使用例

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

---

## Streaming with Suspense Full Example

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

---

## Route Handlers Full Example

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

---

## Metadata & generateStaticParams Full Example

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
