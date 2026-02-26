---
name: vercel-react-best-practices
description: "Use when optimizing React/Next.js runtime performance, eliminating async request waterfalls, reducing JavaScript bundle size, improving Core Web Vitals (LCP, INP, CLS, TTFB), profiling React re-renders, auditing barrel imports, configuring next/image or next/font, deferring third-party scripts, tuning Server Component data fetching, parallelizing Promises, reviewing code for performance anti-patterns, analyzing Lighthouse reports, or diagnosing slow hydration. Covers 57 rules across 8 impact-ranked categories from Vercel Engineering. Does NOT cover component design (react-component-patterns), routing or caching (nextjs-app-router-patterns), or deploy pipelines (ci-cd-deployment)."
user-invocable: false
---

# Vercel React Best Practices

React/Next.js ランタイムパフォーマンス最適化。57ルール / 8カテゴリ（影響度順）。

**焦点**: 計測可能な速度改善。設計パターンやアーキテクチャではなく「速くする」ルール。

### Core Web Vitals 目標値

| メトリクス | 目標 | 主な改善カテゴリ |
|-----------|------|----------------|
| LCP | < 2.5s | Image/Font, Server-Side, Bundle |
| INP | < 200ms | Re-render, Client-Side, JS |
| CLS | < 0.1 | Image/Font, Rendering |
| TTFB | < 800ms | Server-Side, Waterfalls |

### Diagnostic Decision Tree

```
サイトが遅い → 何が遅い？
  +-- 初期表示が遅い (LCP/TTFB)
  |     +-- サーバー応答が遅い → Server-Side Performance
  |     +-- JSが大きい → Bundle Size Optimization
  |     +-- 画像が重い → Image & Font Optimization
  |     +-- API直列呼び出し → Eliminating Waterfalls
  +-- 操作が重い (INP)
  |     +-- ボタン/入力の反応遅延 → Re-render Optimization
  |     +-- スクロールがカクつく → Rendering / JS Performance
  +-- レイアウトが崩れる (CLS)
        +-- 画像/フォント読み込み → Image & Font Optimization
        +-- 動的コンテンツ挿入 → Rendering Performance
```

### When to Apply

- async/await ウォーターフォール除去
- バンドルサイズ削減（barrel imports, dynamic import, third-party defer）
- Server Component データフェッチ最適化（cache, dedup, 並列化）
- クライアント再レンダリング抑制
- next/image, next/font による LCP 改善
- JavaScript マイクロ最適化（ループ, キャッシュ, データ構造）

### When NOT to Apply

- コンポーネント設計・合成パターン -> react-component-patterns
- App Router ルーティング・キャッシュ戦略 -> nextjs-app-router-patterns
- TypeScript 型設計 -> typescript-best-practices
- CI/CD・デプロイ設定 -> ci-cd-deployment
- エラーハンドリング -> error-handling-logging
- テスト戦略 -> testing-strategy

### Cross-references

- **testing-strategy**: パフォーマンス回帰テスト（Playwright でのLCP/INP計測、レンダリング回数アサーション）
- **ci-cd-deployment**: CI でのバンドルサイズ監視（`@next/bundle-analyzer` + size-limit を GitHub Actions に統合）
- **dashboard-data-viz**: チャート描画パフォーマンス（Recharts の大量データ仮想化、memo 戦略）

---

### Eliminating Waterfalls [CRITICAL]

各 sequential await がレイテンシを加算する。最優先で除去。

**Promise.all() で並列化**

```typescript
// BAD: 3回の逐次リクエスト
const user = await fetchUser()
const posts = await fetchPosts()
const comments = await fetchComments()

// GOOD: 並列リクエスト (2-10x改善)
const [user, posts, comments] = await Promise.all([
  fetchUser(), fetchPosts(), fetchComments()
])
```

**await を使う分岐まで遅延**

```typescript
// BAD: skip=true でも待つ
async function handle(userId: string, skip: boolean) {
  const data = await fetchUserData(userId)
  if (skip) return { skipped: true }
  return process(data)
}

// GOOD: 必要な分岐でのみ await
async function handle(userId: string, skip: boolean) {
  if (skip) return { skipped: true }
  const data = await fetchUserData(userId)
  return process(data)
}
```

**Suspense で streaming**

```tsx
// BAD: データ取得がページ全体をブロック
async function Page() {
  const data = await fetchData()
  return <div><Header /><Content data={data} /></div>
}

// GOOD: Header を即座に表示、データは streaming
function Page() {
  return (
    <div>
      <Header />
      <Suspense fallback={<Skeleton />}>
        <Content />
      </Suspense>
    </div>
  )
}
```

他: `async-dependencies`, `async-api-routes` -> rules/

---

### Bundle Size Optimization [CRITICAL]

**Barrel file を避ける**

```tsx
// BAD: ライブラリ全体をロード (200-800ms)
import { Check, X } from 'lucide-react'

// GOOD: 必要なモジュールだけ
import Check from 'lucide-react/dist/esm/icons/check'
import X from 'lucide-react/dist/esm/icons/x'

// GOOD (Next.js 13.5+): optimizePackageImports で自動変換
// next.config.js: experimental.optimizePackageImports: ['lucide-react']
```

**Dynamic import で遅延ロード**

```tsx
// BAD: 初期バンドルに含まれる
import HeavyEditor from '@/components/heavy-editor'

// GOOD: 必要時にロード
const HeavyEditor = dynamic(() => import('@/components/heavy-editor'), {
  loading: () => <Skeleton className="h-[400px]" />,
  ssr: false,
})
```

**Third-party を hydration 後にロード**

```tsx
const Analytics = dynamic(
  () => import('@vercel/analytics').then(m => m.Analytics),
  { ssr: false }
)
```

他: `bundle-conditional`, `bundle-preload` -> rules/

---

### Server-Side Performance [HIGH]

**React.cache() でリクエスト内重複排除**

```typescript
import { cache } from 'react'

export const getCurrentUser = cache(async () => {
  const session = await auth()
  if (!session?.user?.id) return null
  return db.user.findUnique({ where: { id: session.user.id } })
})
// 注意: インラインオブジェクト引数はキャッシュミス。プリミティブ値を使う。
```

**RSC 境界でのシリアライズ最小化**

```tsx
// BAD: オブジェクト全体をクライアントに渡す
<ClientComponent user={fullUser} />

// GOOD: 必要なフィールドだけ
<ClientComponent userName={user.name} userAvatar={user.avatar} />
```

**コンポーネント構造で並列フェッチ**

```tsx
// BAD: 逐次（親が子のデータも取得）
async function Dashboard() {
  const user = await getUser()
  const posts = await getPosts(user.id)
  return <PostList posts={posts} />
}

// GOOD: 各コンポーネントが独立取得
async function Dashboard() {
  return (
    <>
      <Suspense fallback={<UserSkeleton />}><UserCard /></Suspense>
      <Suspense fallback={<PostSkeleton />}><PostList /></Suspense>
    </>
  )
}
```

他: `server-auth-actions`, `server-cache-lru`, `server-after-nonblocking` -> rules/

---

### Image & Font Optimization [HIGH]

**next/image で LCP 改善**

```tsx
import Image from 'next/image'

// priority: LCP 画像に設定（自動 preload）
<Image src="/hero.jpg" width={1200} height={600} alt="Hero" priority />

// sizes: レスポンシブ画像で過剰ダウンロード防止
<Image src="/card.jpg" width={400} height={300} alt="Card"
  sizes="(max-width: 768px) 100vw, 400px" />

// placeholder="blur": CLS 防止 + 知覚速度向上
<Image src={img} alt="Photo" placeholder="blur" blurDataURL={blurUrl} />
```

**next/font でレイアウトシフト防止**

```tsx
import { Inter } from 'next/font/google'
const inter = Inter({ subsets: ['latin'], display: 'swap' })

// layout.tsx で適用 -> FOIT/FOUT/CLS を排除
export default function RootLayout({ children }) {
  return <html className={inter.className}>{children}</html>
}
```

---

### Client-Side Data Fetching [MEDIUM]

- **SWR で自動重複排除**: 同じキーの複数 `useSWR` が1リクエストに集約
- **Passive event listeners**: scroll/touch に `{ passive: true }` でメインスレッド解放
- **localStorage スキーマ管理**: バージョン付きキー、最小フィールド、try-catch 必須

詳細コード例 -> reference.md

---

### Re-render Optimization [MEDIUM]

```tsx
// 1. 派生ステートはレンダリング中に計算
const fullName = firstName + ' ' + lastName  // NOT useEffect + setState

// 2. コールバック専用値は useRef
const countRef = useRef(0)  // NOT useState if only in onClick

// 3. useState 遅延初期化
const [data] = useState(() => expensiveCompute())

// 4. functional setState で依存配列削減
setCount(prev => prev + 1)  // NOT setCount(count + 1)
```

全12ルール -> rules/ (`rerender-*`)

---

### Rendering / JS / Advanced [MEDIUM-LOW]

**Rendering** (9 rules)

- `content-visibility: auto` で画面外レンダリングスキップ
- SVG アニメーションはラッパー div で（レイアウト再計算回避）
- 静的 JSX をコンポーネント外に hoist
- 条件レンダリング: `&&` でなく三項演算子（falsy 0 の問題回避）

**JavaScript** (12 rules)

- `Set`/`Map` で O(1) ルックアップ
- DOM 操作は `classList`/`cssText` でバッチ化
- ループ内プロパティアクセスをキャッシュ
- `toSorted()` でイミュータブルソート

**Advanced** (3 rules)

- `advanced-init-once`: アプリ初期化を一度だけ
- `advanced-event-handler-refs`: ハンドラを ref に格納
- `advanced-use-latest`: 安定コールバック参照

全ルール -> rules/ または AGENTS.md

---

### Rule Lookup

```
rules/<prefix>-<name>.md   # 個別ルール（BAD/GOOD 例付き）
AGENTS.md                  # 全ルール展開版
```

Prefixes: `async-` | `bundle-` | `server-` | `client-` | `rerender-` | `rendering-` | `js-` | `advanced-`

---

### Reference

[reference.md](reference.md) の内容:

- Client-Side Data Fetching 実装パターン（SWR, イベントリスナー, localStorage）
- Re-render 判断フローチャート
- Rendering / JS パフォーマンスチェックリスト
- Barrel import 対応ライブラリ一覧
- next/image 設定リファレンス
- パフォーマンス計測（Web Vitals, React Profiler, Bundle 分析）
- Cross-skill 連携パターン
