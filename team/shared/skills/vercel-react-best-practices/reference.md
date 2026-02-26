# Vercel React Best Practices -- Reference

SKILL.md の補足情報。個別ルールは `rules/`、全ルール展開版は `AGENTS.md` を参照。

---

## Client-Side Data Fetching パターン

### SWR で自動重複排除

```tsx
import useSWR from 'swr'
const fetcher = (url: string) => fetch(url).then(r => r.json())

function UserList() {
  const { data: users, error, isLoading } = useSWR('/api/users', fetcher)
  if (isLoading) return <Skeleton />
  if (error) return <ErrorMessage />
  return <ul>{users.map(u => <li key={u.id}>{u.name}</li>)}</ul>
}

// Immutable data: 再検証しない
const { data } = useSWR('/api/config', fetcher, {
  revalidateOnFocus: false,
  revalidateOnReconnect: false,
  revalidateIfStale: false,
})

// Mutation
import { useSWRMutation } from 'swr/mutation'
const { trigger } = useSWRMutation('/api/user', updateUser)
```

### イベントリスナー重複排除

`useSWRSubscription` でグローバルリスナーを1つに集約。N 個のインスタンスが共有。

```tsx
import useSWRSubscription from 'swr/subscription'

const keyCallbacks = new Map<string, Set<() => void>>()

function useKeyboardShortcut(key: string, callback: () => void) {
  useEffect(() => {
    if (!keyCallbacks.has(key)) keyCallbacks.set(key, new Set())
    keyCallbacks.get(key)!.add(callback)
    return () => {
      const set = keyCallbacks.get(key)
      if (set) { set.delete(callback); if (set.size === 0) keyCallbacks.delete(key) }
    }
  }, [key, callback])

  useSWRSubscription('global-keydown', () => {
    const handler = (e: KeyboardEvent) => {
      if (e.metaKey && keyCallbacks.has(e.key))
        keyCallbacks.get(e.key)!.forEach(cb => cb())
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  })
}
```

### Passive Event Listeners

scroll/touch/wheel に `{ passive: true }` でスクロール即時開始。`preventDefault` が必要な場合（カスタムスワイプ等）は使わない。

```typescript
document.addEventListener('touchstart', handler, { passive: true })
document.addEventListener('wheel', handler, { passive: true })
```

### localStorage スキーマ管理

```typescript
const VERSION = 'v2'

function saveConfig(config: { theme: string; language: string }) {
  try {
    localStorage.setItem(`userConfig:${VERSION}`, JSON.stringify(config))
  } catch {} // incognito, quota exceeded, disabled
}

function loadConfig() {
  try {
    const data = localStorage.getItem(`userConfig:${VERSION}`)
    return data ? JSON.parse(data) : null
  } catch { return null }
}
```

バージョンプレフィックス付きキー、最小フィールド、try-catch 必須。

---

## Re-render Optimization 判断フロー

```
値が props/state から計算可能?
  -> Yes: レンダリング中に直接計算（useEffect + setState 禁止）
  -> No: useState/useReducer

state をコールバック内でのみ使用?
  -> Yes: useRef（購読を回避）
  -> No: useState

useState の初期値が高コスト?
  -> Yes: useState(() => compute()) で遅延初期化
  -> No: useState(value)

setState が useCallback 内?
  -> Yes: functional update setCount(prev => prev + 1) で依存配列削減
  -> No: 直接更新

useEffect の依存配列にオブジェクト?
  -> Yes: プリミティブに分解（obj.id, obj.name）
  -> No: そのまま

更新が非緊急（検索候補表示など）?
  -> Yes: startTransition(() => setState(val))
  -> No: 直接更新
```

---

## Rendering Performance チェックリスト

| ルール | 条件 | 対応 |
|--------|------|------|
| content-visibility | 長いリスト（100+ items） | `content-visibility: auto; contain-intrinsic-size: 0 80px` |
| SVG animation | SVG 要素をアニメーション | ラッパー `<div>` を対象に |
| Static JSX hoist | JSX が props/state 非依存 | コンポーネント外に定数定義 |
| SVG precision | SVG 座標の桁数が多い | 小数点以下 1-2 桁に丸め |
| Hydration flicker | クライアント限定データで初期ちらつき | inline `<script>` でデータ注入 |
| Conditional render | `{count && <C />}` | 三項演算子 `{count > 0 ? <C /> : null}` |
| Activity | 表示/非表示切り替え | `<Activity mode={show ? "visible" : "hidden"}>` |
| useTransition | 手動 `isLoading` state | `const [isPending, startTransition] = useTransition()` |

---

## JavaScript Performance パターン

### Set/Map で O(1) ルックアップ

```typescript
// BAD: O(n) 毎回
const isAllowed = allowedIds.includes(id)

// GOOD: O(1)
const allowedSet = new Set(allowedIds)
const isAllowed = allowedSet.has(id)
```

### DOM 操作バッチ化

```typescript
// BAD: 3 回のスタイル再計算
el.style.width = '100px'
el.style.height = '100px'
el.style.background = 'red'

// GOOD: 1 回
el.classList.add('box-style')
// or: el.style.cssText = 'width:100px;height:100px;background:red'
```

### ループ最適化

```typescript
// プロパティアクセスをキャッシュ
const len = items.length
for (let i = 0; i < len; i++) { /* ... */ }

// filter + map を 1 ループに統合
const result: Output[] = []
for (const item of items) {
  if (item.active) result.push(transform(item))
}

// RegExp をループ外に hoist
const pattern = /^user_\d+$/
for (const key of keys) { if (pattern.test(key)) { /* ... */ } }
```

### イミュータブルソート

```typescript
// BAD: 元配列を変更
const sorted = items.sort((a, b) => a.score - b.score)

// GOOD: 新しい配列を返す
const sorted = items.toSorted((a, b) => a.score - b.score)
```

---

## next/image 設定リファレンス

### props 選択ガイド

| prop | 用途 | 効果 |
|------|------|------|
| `priority` | LCP 画像（hero, above-the-fold） | 自動 preload、lazy 無効化 |
| `sizes` | レスポンシブ画像 | 適切なサイズの srcset 選択、過剰DL防止 |
| `placeholder="blur"` | 大きな画像 | CLS 防止 + 知覚速度向上 |
| `quality` | 画質調整（default: 75） | 低い値 = 小さいファイル |
| `loading="eager"` | above-the-fold 非 LCP 画像 | lazy 無効化（priority より軽量） |

### 設定パターン

```typescript
// next.config.js: 外部画像ドメイン許可
const nextConfig = {
  images: {
    remotePatterns: [
      { protocol: 'https', hostname: '**.example.com' },
    ],
    formats: ['image/avif', 'image/webp'], // AVIF 優先
  },
}
```

### よくある間違い

- `fill` 使用時に親要素に `position: relative` がない -> 画像が溢れる
- LCP 画像に `priority` を付けない -> LCP 悪化
- `sizes` なしで大画面用画像をモバイルにも配信 -> 帯域浪費

---

## Barrel Import 対応ライブラリ一覧

barrel file による import コストが高いライブラリ。直接 import or `optimizePackageImports` で対応。

| ライブラリ | 直接 import パス例 |
|-----------|-------------------|
| `lucide-react` | `lucide-react/dist/esm/icons/<name>` |
| `@mui/material` | `@mui/material/<Component>` |
| `@mui/icons-material` | `@mui/icons-material/<Icon>` |
| `@tabler/icons-react` | `@tabler/icons-react/dist/esm/icons/<Name>` |
| `react-icons` | `react-icons/<pack>/<Icon>` |
| `lodash` | `lodash/<function>` |
| `date-fns` | `date-fns/<function>` |
| `rxjs` | `rxjs/<operator>` |

Next.js 13.5+ では `experimental.optimizePackageImports` に追加で自動最適化。

---

## パフォーマンス計測

### Web Vitals 目標値

| メトリクス | 目標 | 計測方法 |
|-----------|------|---------|
| LCP | < 2.5s | `web-vitals` lib / Lighthouse |
| INP | < 200ms | Chrome DevTools Performance |
| CLS | < 0.1 | Lighthouse |
| TTFB | < 800ms | Network tab |

### React Profiler

```tsx
import { Profiler } from 'react'

function onRender(id: string, phase: string, actualDuration: number) {
  console.log(`${id} ${phase}: ${actualDuration.toFixed(1)}ms`)
}

<Profiler id="Dashboard" onRender={onRender}>
  <Dashboard />
</Profiler>
```

### Bundle 分析

```bash
ANALYZE=true next build

# next.config.js
const withBundleAnalyzer = require('@next/bundle-analyzer')({
  enabled: process.env.ANALYZE === 'true',
})
module.exports = withBundleAnalyzer(nextConfig)
```

---

## Cross-skill 連携パターン

このスキルが他スキルと交差する非自明な実践パターン。

### testing-strategy: パフォーマンス回帰テスト

```typescript
// Playwright でのパフォーマンス計測テスト
import { test, expect } from '@playwright/test'

test('LCP should be under 2.5s', async ({ page }) => {
  await page.goto('/')
  const lcp = await page.evaluate(() => {
    return new Promise<number>(resolve => {
      new PerformanceObserver(list => {
        const entries = list.getEntries()
        resolve(entries[entries.length - 1].startTime)
      }).observe({ type: 'largest-contentful-paint', buffered: true })
    })
  })
  expect(lcp).toBeLessThan(2500)
})

// React レンダリング回数のアサーション
test('list should not re-render on unrelated state change', async ({ page }) => {
  const renderCount = await page.evaluate(() =>
    Number(document.querySelector('[data-render-count]')?.getAttribute('data-render-count'))
  )
  expect(renderCount).toBeLessThanOrEqual(2)
})
```

### ci-cd-deployment: CI でのバンドルサイズ監視

```yaml
# .github/workflows/bundle-size.yml
- name: Bundle size check
  run: |
    ANALYZE=true npx next build
    npx size-limit --json > size-report.json
- name: Comment PR with size diff
  uses: andresz1/size-limit-action@v1
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
```

`size-limit` + `@next/bundle-analyzer` を CI に統合し、PR ごとにバンドルサイズ差分をコメント。

### dashboard-data-viz: チャート描画パフォーマンス

大量データのチャート描画で適用するルール:

- **仮想化**: 1000+ データポイントの Recharts グラフは `recharts` の `isAnimationActive={false}` でアニメーション無効化
- **memo**: `<ResponsiveContainer>` 内のチャートコンポーネントを `React.memo` で囲み、フィルタ変更時の不要再描画を防止
- **dynamic import**: チャートライブラリ自体を `dynamic(() => import(...), { ssr: false })` で遅延ロード

---

## ルールプレフィックス一覧

| プレフィックス | カテゴリ | 影響度 | ルール数 |
|--------------|---------|--------|---------|
| `async-` | Eliminating Waterfalls | CRITICAL | 5 |
| `bundle-` | Bundle Size Optimization | CRITICAL | 5 |
| `server-` | Server-Side Performance | HIGH | 7 |
| `client-` | Client-Side Data Fetching | MEDIUM | 4 |
| `rerender-` | Re-render Optimization | MEDIUM | 12 |
| `rendering-` | Rendering Performance | MEDIUM | 9 |
| `js-` | JavaScript Performance | LOW-MEDIUM | 12 |
| `advanced-` | Advanced Patterns | LOW | 3 |
