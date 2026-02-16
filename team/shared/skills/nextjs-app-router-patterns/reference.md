# Next.js App Router Patterns — Reference

## Contents

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

  // 型安全リンク（Next.js 15 で stable）
  typedRoutes: true,

  // 実験的機能
  experimental: {
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
