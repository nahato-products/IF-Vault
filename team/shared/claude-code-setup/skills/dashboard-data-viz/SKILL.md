---
name: dashboard-data-viz
description: "Dashboard UI: KPI cards, TanStack Table, Recharts/Tremor charts, Supabase Realtime, filters, loading/empty states, CSV export"
user-invocable: false
---

# Dashboard & Data Visualization Patterns

Next.js App Router + Tailwind CSS + Supabase でダッシュボード・管理画面を構築するための実装パターン集。

## When to Apply

- ダッシュボード・管理画面のレイアウト設計
- KPIカード・サマリーパネルの実装
- データテーブル（ソート・フィルタ・ページネーション）
- チャート・グラフの選択と実装
- リアルタイムデータ更新の設計
- フィルタ・検索UIの構築
- データのエクスポート・一括操作

## Scope & Cross-references

**このスキルの守備範囲**: ダッシュボードUI実装パターン（レイアウト・KPI・テーブル・チャート・フィルタ・リアルタイム・エクスポート）

**対象外 → 該当スキルへ委譲**:

| 領域 | このスキル | 委譲先スキル |
|------|-----------|------------|
| DB設計・DDL | UIコンポーネント・表示 | `ansem-db-patterns` |
| SQLクエリ最適化・RLS | クライアント側データ取得 | `supabase-postgres-best-practices`（リアルタイムクエリ最適化も） |
| 認知心理学・UX原則 | 実装パターン（何をどう作るか） | `ux-psychology`（ダッシュボードの情報密度・Hick's Law等の「なぜ」） |
| チャート描画パフォーマンス | チャート選択・データ構造 | `vercel-react-best-practices`（dynamic import・バンドル最適化・再レンダリング抑制） |
| ローディング・トースト・アニメーション | スケルトン仕様・Empty State定義 | `micro-interaction-patterns`（Framer Motion実装・シマー効果） |
| Reactコンポーネント設計 | ダッシュボード用構成 | `react-component-patterns`（合成・CVA・SC/CC境界） |
| デザインシステム全般 | ダッシュボードレイアウト・グリッド | `tailwind-design-system`（トークン・テーマ） |

マーケティングLP・純粋なAPIエンドポイント設計はスコープ外。

---

## Decision Tree

```
レイアウト → Part 1 | KPI → Part 2 | テーブル → Part 3 | チャート → Part 4
データ取得(SC/TanStack/Realtime) → Part 5-6 | フィルタ → Part 7
ローディング → Part 8 | エクスポート → Part 9
```

---

## Part 1: Dashboard Layout [CRITICAL]

### 1. Sidebar + Main Content

```tsx
// flex h-screen: <Sidebar /> + <main className="flex-1 overflow-y-auto">
// max-w-7xl px-4 py-6 でコンテンツ幅制限
// 完全コード → reference.md J-1
```

- デスクトップ: 折りたたみ可能（アイコン ↔ フルラベル）、状態は `localStorage` + Context
- モバイル: Sheet/Drawerで表示（`lg:hidden` で切り替え）

### 2. ダッシュボードページ構成

```
[Header: タイトル + 日付レンジピッカー + アクション]
[KPIカード行: grid-cols-1 sm:grid-cols-2 lg:grid-cols-4]
[チャートエリア: lg:grid-cols-3 (メイン2/3 + サブ1/3)]
[データテーブル: フルワイド]
```

配置の原則: KPIカード（全体状況）→ チャート（トレンド詳細）→ テーブル（ドリルダウン）

---

## Part 2: KPI Cards [CRITICAL]

### 3. KPIカード構成要素

必須: タイトル、値、前期比（%）、変化方向インジケーター
推奨: スパークライン、アイコン、比較期間ラベル

```tsx
// KpiCard: title, value, change(%), sparklineData
// green/red 色分け + ↑↓ インジケーター + オプションのスパークライン
// 完全コード → reference.md J-2
```

### 4. トレンドインジケーター

| change値 | 表示 | 色 |
|----------|------|-----|
| > 0 | ↑ +X% | `text-green-600` |
| = 0 | → 0% | `text-gray-500` |
| < 0 | ↓ -X% | `text-red-600` |

**色反転**: 離脱率・エラー率等「下降が良い」指標は `invertColor` propで緑赤を逆にする。

### 5. スパークライン

Tremorの `SparkAreaChart` を推奨。省スペースでトレンドを可視化。実装例は [reference.md](reference.md) B-8参照。

---

## Part 3: Data Tables [HIGH]

### 6. TanStack Table セットアップ

```tsx
// useReactTable({ data, columns, state: { sorting, filters, pagination... } })
// + getCoreRowModel, getSortedRowModel, getFilteredRowModel, getPaginationRowModel
// 完全コード → reference.md J-3
```

カラム定義パターン集（テキスト、数値、ステータスBadge、日時、アクション、チェックボックス、インライン編集）は [reference.md](reference.md) セクションBを参照。

### 7. Client-side vs Server-side

| 条件 | Client-side | Server-side |
|------|-------------|-------------|
| 行数 | ~5,000行以下 | 5,000行超 |
| フィルタ | テキスト・セレクト | 日付範囲・多対多 |
| ソート | メモリ内 | APIに委譲 |
| ページネーション | 全データ取得済み | offset or cursor |

Server-sideのSupabaseクエリ構築パターンは [reference.md](reference.md) セクションC参照。

### 8. ページネーション vs 無限スクロール

**管理画面のテーブルはページネーション一択**。総件数表示・特定ページジャンプが業務で必須。
無限スクロールはフィード・タイムラインのみ。

### 9. Row Selection + Bulk Actions

選択行がある時のみBulk Actionバーを表示。エクスポート・ステータス一括変更・削除等を配置。
破壊的操作には必ずAlertDialogで確認。

---

## Part 4: Chart Selection [HIGH]

### 10. チャート種別の選択基準

| データの性質 | 推奨チャート | 理由 |
|-------------|-------------|------|
| 時系列の推移 | LineChart / AreaChart | トレンドが直感的 |
| カテゴリ比較 | BarChart（横or縦） | 大きさの比較が容易 |
| 構成比 | DonutChart | 全体の割合（5カテゴリ以下） |
| 分布・相関 | ScatterChart | 2変数の関係性 |
| ランキング | 横BarChart | 長いラベルも可読 |
| KPI内トレンド | SparkLine/SparkArea | 省スペース |

避けるべき: 3Dチャート、6カテゴリ超のPieChart（→BarChart）、二重Y軸（→2つのチャートに分割）

> 上記テーブルはクイックリファレンス。データ構造から段階的にチャートを選ぶ詳細な決定フローチャートは [reference.md](reference.md) セクションA参照。

### 11. ライブラリ選択

| ライブラリ | 推奨ケース | 特徴 |
|-----------|-----------|------|
| **Tremor** | ダッシュボード全般 | Tailwind統合、高レベルAPI |
| **Recharts** | カスタム要件が多い場合 | 柔軟、Tremor内部でも使用 |
| **Chart.js** | 軽量・シンプル | バンドル小、Canvas |

> ⚠ **Tremor** はメンテナンスモード入りの兆候あり。新規プロジェクトでは **shadcn/ui charts**（Recharts ベース）も検討すること。

**パフォーマンス**: チャートは `dynamic(() => import(...), { ssr: false })` で遅延ロード必須。バンドルサイズ・再レンダリング最適化は `vercel-react-best-practices` 参照。

### 12. チャート・テーブルのアクセシビリティ

- チャート: `aria-label` で要約テキスト付与、色だけに依存しない（パターン・ラベル併用）、`role="img"` + 代替テキスト
- テーブル: `<caption>` でテーブル説明、ソートボタンに `aria-sort`、`aria-label` でアクション説明
- 色コントラスト: データ系列間のコントラスト比4.5:1以上、色覚多様性に配慮（赤緑以外の組み合わせ）

---

## Part 5: Supabase Data Fetching [CRITICAL]

### 13. クライアント構成

2つのcreateClient関数を `lib/supabase/` に配置:
- `server.ts`: `createServerClient` + cookies（Server Component / Server Action / Route Handler）
- `client.ts`: `createBrowserClient`（Client Component）

実装コードは [reference.md](reference.md) セクションC-0参照。

### 14. KPIデータ取得（Server Component）

```tsx
// Server Component: Promise.all([count query, count query, rpc]) で並列取得
// head: true でカウントのみ、RPCで集約 → クライアントJSゼロ
// 完全コード → reference.md J-4
```

ポイント: `Promise.all` で並列取得、`head: true` でカウントのみ取得、RPCで集約。

### 15. TanStack Query + Supabase（Client Component）

```tsx
// useQuery({ queryKey: ["orders", page, filters], queryFn: supabase... })
// .throwOnError() 必須 + staleTime: 60_000
// 完全コード → reference.md J-5
```

---

## Part 6: Real-time Updates [HIGH]

### 16. 更新パターンの選択

| パターン | 適用場面 | 遅延 | 複雑度 |
|---------|---------|------|--------|
| ポーリング | 更新頻度低（数分単位） | 高 | 低 |
| Supabase Realtime | 即座の反映が必要 | 低 | 中 |
| Optimistic UI | ユーザー操作の即時FB | なし | 高 |
| SWR/revalidate | バランス型 | 中 | 低 |

### 17. Supabase Realtime + TanStack Query

Realtimeで変更を検知 → `invalidateQueries` でキャッシュ無効化 → 自動再取得。
`useEffect` 内でsubscribe、クリーンアップで `removeChannel`。
フィルタで対象イベント・テーブルを絞る（接続数上限: Free 200 / Pro 500）。

Realtime設定チェックリスト・Optimistic UIの実装例は [reference.md](reference.md) セクションF参照。

---

## Part 7: Filter & Search [MEDIUM]

### 18. フィルタパターン

| 種別 | UIコンポーネント | 用途 |
|------|----------------|------|
| テキスト検索 | Input + 300msデバウンス | 名前・メールの部分一致 |
| セレクト | Select / Dropdown | ステータス・カテゴリ（単一） |
| マルチセレクト | Popover + Checkbox | タグ・複数ステータス |
| 日付範囲 | DateRangePicker + プリセット | 期間指定 |
| 数値範囲 | Slider or Input x2 | 金額・数量 |

### 19. URL同期（searchParams）

フィルタ状態をURLに同期 → ブックマーク・共有・ブラウザバック対応:
- `useSearchParams` で現在の値を取得
- `useDebouncedCallback` でURL更新（300ms）
- フィルタ変更時にページを1にリセット

Saved Filter Presets: 頻出フィルタ組み合わせをDB/localStorageに保存して再利用。

フィルタコンポーネントの詳細実装（マルチセレクト、日付範囲）は [reference.md](reference.md) セクションD参照。

---

## Part 8: Loading States [MEDIUM]

### 20. スケルトンUI

各コンポーネント専用のスケルトンを用意（実装詳細・シマー効果は `micro-interaction-patterns` 参照）:
- **KPIカード**: タイトル + 値 + 変化率の3行Skeleton
- **テーブル**: ヘッダー + N行 x M列のSkeletonグリッド
- **チャート**: 高さ固定の角丸Skeleton

### 21. Empty State

| 状況 | CTA |
|------|-----|
| 初回（データなし） | 「最初の注文を作成」 |
| フィルタ結果なし | 「フィルタをクリア」 |
| エラー | 「リトライ」 |

### 22. Next.js Suspense統合

```tsx
// loading.tsx で自動スケルトン、Suspense境界でチャート独立ロード
// 完全パターン → reference.md J-6, H
```

ダッシュボードテンプレート（Suspense境界の配置例）は [reference.md](reference.md) セクションH参照。スケルトン・シマーの実装詳細は `micro-interaction-patterns` を参照。

---

## Part 9: Export & Actions [MEDIUM]

### 23. CSVエクスポート

- クライアント側: BOM付きUTF-8（Excel対応）、Blobダウンロード
- **大量データ**: Server Action / Route Handlerで生成（クライアント全件取得は避ける）
- カンマ・改行・ダブルクォートのエスケープ処理必須

### 24. 確認ダイアログ

破壊的操作（削除、一括変更）には必ずAlertDialogで確認。件数を明示し、「取り消せない」旨を伝える。

エクスポート・PDFの実装コードは [reference.md](reference.md) セクションE参照。

---

## Dashboard Implementation Checklist

- [ ] Sidebar + Main レイアウト（モバイル: Sheet/Drawer切り替え）
- [ ] KPIカードに前期比・変化方向インジケーター
- [ ] テーブル: 5,000行超は server-side ページネーション
- [ ] テーブル: カラム定義にソート・フィルタ・型別フォーマット
- [ ] チャート: `dynamic(() => import(...), { ssr: false })` で遅延ロード
- [ ] チャート: `aria-label` + 色だけに依存しないアクセシビリティ
- [ ] KPI: Server Component + `Promise.all` で並列取得
- [ ] フィルタ: URL searchParams に同期（共有・ブックマーク対応）
- [ ] フィルタ: テキスト入力は300msデバウンス
- [ ] Suspense境界: KPI・チャート・テーブルを独立ロード
- [ ] Empty State: 初回/フィルタ結果なし/エラーの3パターン
- [ ] 破壊的操作（削除・一括変更）に確認ダイアログ
- [ ] CSVエクスポート: 大量データは Server Action で生成

---

## Reference

[reference.md](reference.md) に以下を収録:

- チャート選択フローチャート (A)
- TanStack Table カラム定義パターン集 B-1〜B-8（テキスト/数値/Badge/日時/アクション/チェックボックス/インライン編集/スパークライン）
- Supabase クライアント構成 + クエリビルダー集 C-0〜C-3
- フィルタコンポーネント バリエーション (D)
- エクスポート詳細パターン (E)
- Supabase Realtime 設定チェックリスト (F)
- パフォーマンス最適化チェックリスト (G)
- ダッシュボードページ テンプレート (H)
- アンチパターン集 (I)
