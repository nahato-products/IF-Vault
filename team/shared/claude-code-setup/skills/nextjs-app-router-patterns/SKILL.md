---
name: nextjs-app-router-patterns
description: "Next.js 15 App Router: routing, data fetching, caching, ISR, PPR, Suspense, Server Actions, Route Handlers, Middleware"
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

主要ファイル: `layout.tsx`(共有UI), `page.tsx`(ルートUI), `loading.tsx`(Suspense fallback), `error.tsx`(Error boundary, 'use client'必須), `not-found.tsx`(404), `route.ts`(API, page.tsxと共存不可), `template.tsx`(毎回再マウント), `default.tsx`(Parallel route fallback), `opengraph-image.tsx`(OG画像)

-> ディレクトリ構造図: reference.md「File Conventions」

### error.tsx / not-found.tsx

```typescript
// error.tsx: 'use client' + Error({ error, reset }) — reset()で再試行
// not-found.tsx: notFound()で最も近いnot-found.tsxを表示
```

-> フル実装: reference.md「error.tsx / not-found.tsx Full Example」

---

## Part 2: Routing Patterns [CRITICAL]

### Dynamic Segments

| パターン | 例 | マッチ |
|---------|---|--------|
| `[slug]` | `app/blog/[slug]/page.tsx` | `/blog/hello` |
| `[...slug]` | `app/docs/[...slug]/page.tsx` | `/docs/a/b/c` |
| `[[...slug]]` | `app/shop/[[...slug]]/page.tsx` | `/shop` or `/shop/a/b` |

### Route Groups

`(marketing)/`, `(shop)/` 等の括弧付きフォルダでURLに影響しないグループ化。各グループに独自の `layout.tsx` を持てる。

-> ディレクトリ構造図: reference.md「Route Groups」

### Parallel Routes

`@analytics/`, `@team/` 等の `@slot` フォルダで並列ルート。Layout で `{ children, analytics, team }` として受け取り、各スロットが独立して loading/streaming。`default.tsx` はソフトナビ時の fallback。

-> フル実装: reference.md「Parallel Routes Full Example」

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

SC で直接 `async/await` + `fetch({ next: { tags: [...] } })` でデータ取得。`searchParams` は `Promise` で受ける（Next.js 15）。Suspense + `key={JSON.stringify(params)}` で部分的ストリーミング。

-> フル実装例: reference.md「Data Fetching Full Example」

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

ページ/レイアウト単位の制御: `dynamic`(`'force-dynamic'`/`'force-static'`), `revalidate`(ISR秒数), `fetchCache`(`'force-cache'`), `runtime`(`'edge'`)

-> コード例: reference.md「Route Segment Config Options」

### `use cache` ディレクティブ（Next.js 15, experimental: dynamicIO 必須）

`fetch` を使わないデータ取得（ORM、DB直接等）にキャッシュを適用。

```typescript
// 'use cache' + cacheLife('hours') + cacheTag('product', `product-${id}`)
// cacheLife: 'seconds'|'minutes'|'hours'|'days'|'weeks'|'max'
// revalidateTag('product') で無効化
```

-> cacheLife プリセット一覧・カスタム設定: reference.md「use cache Patterns」

### Partial Prerendering (PPR) [MEDIUM]

静的シェル + 動的ストリーミングを1リクエストで実現。

設定: `experimental: { ppr: 'incremental' }` + ページに `export const experimental_ppr = true`。Suspense 外 = 静的シェル、Suspense 内 = 動的ホール。

-> コード例: reference.md「PPR (Partial Prerendering) Setup」

Caching判断フローチャートは reference.md 参照。

---

## Part 4: Streaming with Suspense [HIGH]

```typescript
// 基本パターン: blocking fetch + 遅いデータを <Suspense> で分離
<ProductHeader product={product} />
<Suspense fallback={<ReviewsSkeleton />}><Reviews productId={id} /></Suspense>
```

**Streaming設計の原則**:
- `loading.tsx` = ページ全体の Suspense boundary
- 部分的ストリーミングには手動 `<Suspense>` を使う
- `key` prop で searchParams 変更時にSuspenseをリセット

-> フル実装例: reference.md「Streaming with Suspense Full Example」

---

## Part 5: Route Handlers [HIGH]

```typescript
// route.ts: export async function GET/POST(request: NextRequest) { ... }
// Dynamic: { params }: { params: Promise<{ id: string }> } — Next.js 15でPromise
```

**注意**: `page.tsx` と `route.ts` は同じディレクトリに共存不可。

-> フル実装例 + 認証・バリデーション付き: reference.md「Route Handlers Full Example」「Route Handler Authentication & Validation」

---

## Part 6: Metadata & SEO [HIGH]

| API | 用途 |
|-----|------|
| `generateMetadata({ params })` | 動的 title, description, openGraph |
| `generateStaticParams()` | 静的パス事前ビルド |
| `metadata.title.template` | 子ルート title の統一フォーマット（`'%s | Site'`） |

Metadata の継承: 子ルートの metadata が親をマージ上書き。

-> フル実装例: reference.md「Metadata & generateStaticParams Full Example」
-> generateStaticParams 応用（ネスト、部分ビルド、dynamicParams）: reference.md「generateStaticParams Patterns」

---

## Part 7: Middleware [HIGH]

```typescript
// middleware.ts: export function middleware(request: NextRequest) { ... }
// export const config = { matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'] }
```

-> フル実装（認証ガード、i18n、rate limiting）: reference.md「Middleware Patterns」

**注意**: Middleware は Edge Runtime で動作。Node.js API は使えない。認証の詳細は supabase-auth-patterns 参照。追加パターン（i18n、rate limiting）は reference.md 参照。

> ⚠ **Rate Limiting 警告**: Map ベースの rate limiting はサーバーレス/Edge 環境では機能しない（各インスタンスが独立した Map を持つ）。本番では Upstash Rate Limit や Vercel KV 等の外部ストアを使用すること。

---

## Part 8: Server Actions（ルーティング連携）[HIGH]

コンポーネント設計の詳細（useOptimistic, useActionState 等）は react-component-patterns 参照。ここではルーティング連携パターンのみ。

パターン: `'use server'` + `cookies()`/`redirect()` + `revalidateTag()` + try/catch で `{ success }` or `{ error }` を返す。

### `next/after`（15.1+）

レスポンス送信後の非同期処理（ログ記録、分析送信等）。Server Actions / Route Handlers 内で使用:
```typescript
import { after } from 'next/after';
// handler 内で: after(() => { await logAnalytics(data); });
```

-> フル実装: reference.md「Server Actions (Routing Integration) Full Example」

**Server Actions の重要ルール**:
- `redirect()` は内部で例外を throw する。try/catch 内で呼ぶとキャッチされてリダイレクトが失敗する
- Progressive Enhancement: `<form action={serverAction}>` は JS 無効でも動作する（HTML フォーム送信にフォールバック）

---

## Best Practices

### Turbopack

- `next dev --turbopack` — Next.js 15+ でデフォルト化が進む開発サーバー。HMR 大幅高速化。本番ビルド（`next build --turbopack`）は experimental。

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

## Decision Tree

データ取得 → 静的で十分？ → generateStaticParams + ISR / ユーザー依存？ → Dynamic rendering + no-store / 混在？ → PPR（static shell + dynamic holes）

キャッシュ戦略 → データモデル単位の無効化？ → revalidateTag / ページ単位の再生成？ → revalidatePath / 完全動的？ → `export const dynamic = 'force-dynamic'`

ルーティング → モーダルオーバーレイ？ → Intercepting Routes / 独立ローディング？ → Parallel Routes / 認証ガード？ → Middleware + layout

## Cross-references [MEDIUM]

- **vercel-react-best-practices**: React/Next.jsランタイムパフォーマンス最適化・レンダリング戦略
- **supabase-auth-patterns**: Middleware認証ガード・Server ComponentでのSupabaseセッション管理
- **react-component-patterns**: SC/CC境界設計・Server Actions（useOptimistic, useActionState）のコンポーネント実装

## Checklist

- [ ] 全ページにキャッシュ戦略を明示設定（Next.js 15デフォルトno-store）
- [ ] 遅いデータソースは `<Suspense>` でストリーミング分離
- [ ] `loading.tsx` / `error.tsx` / `not-found.tsx` をルートに配置
- [ ] `route.ts` と `page.tsx` が同ディレクトリに共存していない
- [ ] Middleware はEdge Runtime対応の軽量処理のみ
- [ ] `generateStaticParams` で既知パスを事前ビルド
- [ ] `generateMetadata` でSEO metadata設定済み

## Reference

詳細なコード例・設定テンプレートは [reference.md](reference.md) を参照:

- Intercepting Routes のフル実装例（Modal Pattern）
- Root Layout テンプレート（next/font, metadataBase, title.template）
- next.config.ts 設定テンプレート（images, redirects, rewrites, headers, typedRoutes（experimental）, experimental）
- Caching 判断フローチャート（Static / ISR / On-demand / Dynamic）
- Middleware パターン集（i18n locale detection, rate limiting）
- generateStaticParams の応用パターン（ネスト、部分ビルド、dynamicParams）
- Route Handler の認証・バリデーション・エラーハンドリング
- `use cache` パターン（cacheLife プリセット一覧、カスタム設定、fetch cache との使い分け）
