---
name: vercel-react-best-practices
description: "Optimize React/Next.js runtime performance covering Core Web Vitals, bundle size, re-render optimization, Lighthouse analysis. Use when optimizing page load speed, reducing bundle size, fixing re-render issues, or improving Lighthouse scores."
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
初期表示遅い(LCP/TTFB) → Server-Side / Bundle / Image&Font / Waterfalls
操作重い(INP) → Re-render / Rendering&JS
レイアウト崩れ(CLS) → Image&Font / Rendering
```

### When to Apply

- async/await ウォーターフォール除去
- バンドルサイズ削減（barrel imports, dynamic import, third-party defer）
- Server Component データフェッチ最適化（cache, dedup, 並列化）
- クライアント再レンダリング抑制
- next/image, next/font による LCP 改善
- JavaScript マイクロ最適化（ループ, キャッシュ, データ構造）

### When NOT to Apply

- コンポーネント設計・合成パターン -> `react-component-patterns`
- App Router ルーティング・キャッシュ戦略 -> `nextjs-app-router-patterns`
- TypeScript 型設計 -> `typescript-best-practices`
- CI/CD・デプロイ設定 -> `ci-cd-deployment`
- エラーハンドリング -> `error-handling-logging`
- テスト戦略 -> `testing-strategy`

## Cross-references [MEDIUM]

- **testing-strategy**: パフォーマンス回帰テスト（Playwright でのLCP/INP計測、レンダリング回数アサーション）
- **ci-cd-deployment**: CI でのバンドルサイズ監視（`@next/bundle-analyzer` + size-limit を GitHub Actions に統合）
- **dashboard-data-viz**: チャート描画パフォーマンス（Recharts の大量データ仮想化、memo 戦略）

### Referenced by

- **_web-design-guidelines**: Core Web Vitals 最適化の実装詳細
- **nextjs-app-router-patterns**: App Router パフォーマンス最適化
- **react-component-patterns**: コンポーネントレベルのパフォーマンス改善

---

### Eliminating Waterfalls [CRITICAL]

各 sequential await がレイテンシを加算する。最優先で除去。

**核心ルール:**
- 独立した fetch は `Promise.all()` で並列化（2-10x改善）
- await を使う分岐まで遅延（不要な await をスキップ）
- Suspense で streaming（Header を即座に表示、データは非同期）

コード例 -> reference.md > Eliminating Waterfalls パターン

他: `async-dependencies`, `async-api-routes` （個別ルールファイル参照）

---

### Bundle Size Optimization [CRITICAL]

**核心ルール:**
- Barrel file を避ける: 直接 import path か `optimizePackageImports` で対応
- Dynamic import で遅延ロード: `next/dynamic` + `{ ssr: false }` で初期バンドル削減
- Third-party を hydration 後にロード: Analytics 等は `ssr: false` で遅延

コード例・対応ライブラリ一覧 -> reference.md

他: `bundle-conditional`, `bundle-preload` （個別ルールファイル参照）

---

### Server-Side Performance [HIGH]

**核心ルール:**
- `React.cache()` でリクエスト内重複排除（注意: インラインオブジェクト引数はキャッシュミス）
- RSC 境界でのシリアライズ最小化（必要なフィールドだけクライアントに渡す）
- コンポーネント構造で並列フェッチ（各コンポーネントが独立取得 + Suspense）

コード例 -> reference.md > Server-Side Performance パターン

他: `server-auth-actions`, `server-cache-lru`, `server-after-nonblocking` （個別ルールファイル参照）

---

### Image & Font Optimization [HIGH]

**next/image で LCP 改善:**
- `priority`: LCP 画像に設定（自動 preload）
- `sizes`: レスポンシブ画像で過剰ダウンロード防止
- `placeholder="blur"`: CLS 防止 + 知覚速度向上

**next/font でレイアウトシフト防止:**
- `display: 'swap'` + `subsets` 指定で FOIT/FOUT/CLS 排除
- layout.tsx で `className` 適用

props 選択ガイド・設定パターン・よくある間違い -> reference.md > next/image 設定リファレンス

---

### Client-Side Data Fetching [MEDIUM]

- **SWR で自動重複排除**: 同じキーの複数 `useSWR` が1リクエストに集約
- **Passive event listeners**: scroll/touch に `{ passive: true }` でメインスレッド解放
- **localStorage スキーマ管理**: バージョン付きキー、最小フィールド、try-catch 必須

詳細コード例 -> reference.md

---

### Re-render Optimization [MEDIUM]

**核心ルール:**
- 派生ステートはレンダリング中に計算（useEffect + setState 禁止）
- コールバック専用値は `useRef`（購読を回避）
- `useState(() => compute())` で遅延初期化
- `setCount(prev => prev + 1)` で依存配列削減
- useEffect の依存配列にオブジェクト → プリミティブに分解
- 非緊急更新は `startTransition`

判断フローチャート -> reference.md > Re-render Optimization 判断フロー

全12ルール （個別ルールファイル参照） (`rerender-*`)

---

### Rendering / JS / Advanced [MEDIUM-LOW]

**Rendering** (9 rules): `content-visibility: auto`, SVG ラッパー div, 静的 JSX hoist, 三項演算子（falsy 0 回避）

**JavaScript** (12 rules): `Set`/`Map` O(1) ルックアップ, DOM バッチ化, ループ最適化, `toSorted()`

**Advanced** (3 rules): init-once, event-handler-refs, use-latest

チェックリスト・コード例 -> reference.md

全ルール （個別ルールファイル参照） または AGENTS.md

---

### Performance Improvement Checklist

- [ ] LCP 画像に `priority` 属性が付いているか
- [ ] `sizes` 属性でレスポンシブ画像の過剰DLを防いでいるか
- [ ] barrel import を避け、直接 import しているか
- [ ] 独立した fetch を `Promise.all()` で並列化しているか
- [ ] 重いコンポーネントを `dynamic()` で遅延ロードしているか
- [ ] Server Component で `React.cache()` を使い重複排除しているか
- [ ] RSC → Client に渡すデータを最小化しているか
- [ ] `useEffect` + `setState` で派生ステートを計算していないか
- [ ] Third-party スクリプトを `ssr: false` で遅延ロードしているか
- [ ] next/font で `display: 'swap'` を設定しているか

---

### Rule Lookup

`<prefix>-<name>.md` — 個別ルール（BAD/GOOD 例付き）。`AGENTS.md` — 全ルール展開版。

Prefixes: `async-` | `bundle-` | `server-` | `client-` | `rerender-` | `rendering-` | `js-` | `advanced-`

---

### Reference

[reference.md](reference.md) の内容:

- Eliminating Waterfalls コード例（Promise.all, await 遅延, Suspense streaming）
- Server-Side Performance コード例（React.cache, RSC シリアライズ, 並列フェッチ）
- Bundle Size コード例（barrel import, dynamic import, third-party defer）
- Client-Side Data Fetching 実装パターン（SWR, イベントリスナー, localStorage）
- Re-render 判断フローチャート
- Rendering / JS パフォーマンスチェックリスト
- Barrel import 対応ライブラリ一覧
- next/image 設定リファレンス
- パフォーマンス計測（Web Vitals, React Profiler, Bundle 分析）
- Cross-skill 連携パターン
