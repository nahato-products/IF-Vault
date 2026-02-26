---
name: dashboard-data-viz
description: "Dashboard UI patterns for admin panels and analytics views with Next.js App Router, Tailwind CSS, Supabase, and TanStack Table. Covers sidebar layout, KPI card grids, data tables (sorting, filtering, pagination, row selection, inline editing), chart selection (Recharts, Tremor, sparklines), real-time updates (Supabase Realtime, optimistic UI), filter patterns (faceted, date range, multi-select), loading states, and export actions (CSV, PDF, bulk). Use when building dashboards, designing admin panels, implementing data tables, creating charts or KPI cards, configuring real-time views, composing filter UIs, adding export features, or fetching Supabase data for dashboard components. Does NOT cover design tokens (design-token-system), component API design (react-component-patterns), or database schema (ansem-db-patterns)."
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

## Part 1: Dashboard Layout [CRITICAL]

### 1. Sidebar + Main Content

```tsx
// app/(dashboard)/layout.tsx
export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex h-screen overflow-hidden">
      <Sidebar />
      <main className="flex-1 overflow-y-auto bg-gray-50 dark:bg-gray-900">
        <div className="mx-auto max-w-7xl px-4 py-6 sm:px-6 lg:px-8">{children}</div>
      </main>
    </div>
  );
}
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
function KpiCard({ title, value, change, changeLabel = "前月比", sparklineData }: KpiCardProps) {
  const isPositive = change >= 0;
  return (
    <div className="rounded-lg border bg-white p-6 shadow-sm dark:bg-gray-800">
      <p className="text-sm font-medium text-gray-500">{title}</p>
      <p className="mt-2 text-3xl font-bold tracking-tight">{value}</p>
      <div className="mt-2 flex items-center gap-2">
        <span className={`text-sm font-medium ${isPositive ? "text-green-600" : "text-red-600"}`}>
          {isPositive ? "↑" : "↓"} {Math.abs(change)}%
        </span>
        <span className="text-sm text-gray-500">{changeLabel}</span>
      </div>
      {sparklineData && <MiniSparkline data={sparklineData} positive={isPositive} />}
    </div>
  );
}
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
const table = useReactTable({
  data, columns,
  state: { sorting, columnFilters, columnVisibility, rowSelection, pagination },
  onSortingChange: setSorting,
  onColumnFiltersChange: setColumnFilters,
  onColumnVisibilityChange: setColumnVisibility,
  onRowSelectionChange: setRowSelection,
  onPaginationChange: setPagination,
  getCoreRowModel: getCoreRowModel(),
  getSortedRowModel: getSortedRowModel(),
  getFilteredRowModel: getFilteredRowModel(),
  getPaginationRowModel: getPaginationRowModel(),
});
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
| **Tremor** | ダッシュボード全般（第一選択） | Tailwind統合、高レベルAPI |
| **Recharts** | カスタム要件が多い場合 | 柔軟、Tremor内部でも使用 |
| **Chart.js** | 軽量・シンプル | バンドル小、Canvas |

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
// Server Component: クライアントJSゼロ、高速
export default async function DashboardPage() {
  const supabase = await createClient();
  const [orders, users, revenue] = await Promise.all([
    supabase.from("orders").select("*", { count: "exact", head: true }),
    supabase.from("users").select("*", { count: "exact", head: true }).gte("created_at", startOfMonth),
    supabase.rpc("get_monthly_revenue"),
  ]);
  // KPIカードにデータを渡す
}
```

ポイント: `Promise.all` で並列取得、`head: true` でカウントのみ取得、RPCで集約。

### 15. TanStack Query + Supabase（Client Component）

```tsx
function useOrders(page: number, filters: OrderFilters) {
  return useQuery({
    queryKey: ["orders", page, filters],
    queryFn: async () => {
      const { data, count } = await supabase
        .from("orders").select("*, customer:customers(name)", { count: "exact" })
        .range(page * 20, (page + 1) * 20 - 1)
        .order("created_at", { ascending: false })
        .throwOnError();  // 必須: TanStack Queryがエラー検知するため
      return { data, count };
    },
    staleTime: 60_000,
  });
}
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
// app/(dashboard)/orders/loading.tsx で自動スケルトン表示
// 部分的なSuspense境界でチャートを独立ロード:
<Suspense fallback={<ChartSkeleton className="h-72" />}>
  <RevenueChart />
</Suspense>
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
