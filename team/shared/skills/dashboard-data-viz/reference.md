# Dashboard & Data Viz Reference

SKILL.md の補足資料。詳細な実装パターン、チートシート、テンプレート集。

---

## A. チャート選択フローチャート

```
データの性質は？
├── 時系列データ
│   ├── 1系列 → LineChart（シンプル）or AreaChart（量感を強調）
│   ├── 2-4系列 → AreaChart（積み上げ）or LineChart（比較）
│   └── 省スペース → SparkLine / SparkArea（KPIカード内）
├── カテゴリ比較
│   ├── 5カテゴリ以下 → BarChart（縦）
│   ├── 6-15カテゴリ → BarChart（横：ラベルが読める）
│   └── ラベルが長い → 横BarChart 一択
├── 構成比（全体に占める割合）
│   ├── 2-5カテゴリ → DonutChart
│   └── 6カテゴリ超 → BarChart + パーセント表示に変更
├── 分布・相関
│   ├── 2変数 → ScatterChart
│   └── 密度 → Heatmap
└── ランキング
    └── 横BarChart + 順位番号
```

---

## B. TanStack Table カラム定義パターン集

### B-1. テキストカラム（ソート・フィルタ付き）

```tsx
import { ColumnDef } from "@tanstack/react-table";

const columns: ColumnDef<Order>[] = [
  {
    accessorKey: "customer_name",
    header: ({ column }) => (
      <Button variant="ghost" onClick={() => column.toggleSorting(column.getIsSorted() === "asc")}>
        顧客名
        <ArrowUpDown className="ml-2 h-4 w-4" />
      </Button>
    ),
    cell: ({ row }) => <span className="font-medium">{row.getValue("customer_name")}</span>,
    filterFn: "includesString",
  },
];
```

### B-2. 数値カラム（右寄せ・フォーマット）

```tsx
{
  accessorKey: "amount",
  header: ({ column }) => (
    <div className="text-right">
      <Button variant="ghost" onClick={() => column.toggleSorting()}>
        金額 <ArrowUpDown className="ml-2 h-4 w-4" />
      </Button>
    </div>
  ),
  cell: ({ row }) => {
    const amount = parseFloat(row.getValue("amount"));
    return <div className="text-right font-mono">{amount.toLocaleString("ja-JP", { style: "currency", currency: "JPY" })}</div>;
  },
},
```

### B-3. ステータスBadgeカラム

```tsx
const STATUS_MAP: Record<string, { label: string; variant: "default" | "secondary" | "destructive" | "outline" }> = {
  pending: { label: "保留中", variant: "outline" },
  processing: { label: "処理中", variant: "secondary" },
  completed: { label: "完了", variant: "default" },
  cancelled: { label: "キャンセル", variant: "destructive" },
};

{
  accessorKey: "status",
  header: "ステータス",
  cell: ({ row }) => {
    const status = STATUS_MAP[row.getValue("status") as string];
    return <Badge variant={status.variant}>{status.label}</Badge>;
  },
  filterFn: (row, id, value) => value.includes(row.getValue(id)),
},
```

### B-4. 日時カラム（相対時間 + Tooltip）

```tsx
import { formatDistanceToNow } from "date-fns";
import { ja } from "date-fns/locale";

{
  accessorKey: "created_at",
  header: ({ column }) => (
    <Button variant="ghost" onClick={() => column.toggleSorting()}>
      作成日時 <ArrowUpDown className="ml-2 h-4 w-4" />
    </Button>
  ),
  cell: ({ row }) => {
    const date = new Date(row.getValue("created_at"));
    return (
      <Tooltip>
        <TooltipTrigger>{formatDistanceToNow(date, { addSuffix: true, locale: ja })}</TooltipTrigger>
        <TooltipContent>{date.toLocaleString("ja-JP")}</TooltipContent>
      </Tooltip>
    );
  },
},
```

### B-5. アクションカラム（ドロップダウンメニュー）

```tsx
{
  id: "actions",
  enableHiding: false,
  cell: ({ row }) => {
    const order = row.original;
    return (
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <Button variant="ghost" className="h-8 w-8 p-0">
            <MoreHorizontal className="h-4 w-4" />
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end">
          <DropdownMenuLabel>操作</DropdownMenuLabel>
          <DropdownMenuItem onClick={() => navigator.clipboard.writeText(order.id)}>
            IDをコピー
          </DropdownMenuItem>
          <DropdownMenuSeparator />
          <DropdownMenuItem onClick={() => router.push(`/orders/${order.id}`)}>
            詳細を表示
          </DropdownMenuItem>
          <DropdownMenuItem onClick={() => router.push(`/orders/${order.id}/edit`)}>
            編集
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
    );
  },
},
```

### B-6. チェックボックスカラム（行選択）

```tsx
{
  id: "select",
  header: ({ table }) => (
    <Checkbox
      checked={table.getIsAllPageRowsSelected() || (table.getIsSomePageRowsSelected() && "indeterminate")}
      onCheckedChange={(value) => table.toggleAllPageRowsSelected(!!value)}
      aria-label="全選択"
    />
  ),
  cell: ({ row }) => (
    <Checkbox
      checked={row.getIsSelected()}
      onCheckedChange={(value) => row.toggleSelected(!!value)}
      aria-label="行を選択"
    />
  ),
  enableSorting: false,
  enableHiding: false,
},
```

### B-7. インライン編集カラム

```tsx
{
  accessorKey: "note",
  header: "メモ",
  cell: ({ row, table }) => {
    const initialValue = row.getValue("note") as string;
    const [value, setValue] = useState(initialValue);
    const [isEditing, setIsEditing] = useState(false);

    const onBlur = async () => {
      setIsEditing(false);
      if (value !== initialValue) {
        await updateNote(row.original.id, value);  // Server Action or API call
        table.options.meta?.updateData(row.index, "note", value);
      }
    };

    return isEditing ? (
      <Input value={value} onChange={(e) => setValue(e.target.value)} onBlur={onBlur} autoFocus className="h-8" />
    ) : (
      <span onDoubleClick={() => setIsEditing(true)} className="cursor-pointer hover:bg-muted rounded px-1">
        {value || <span className="text-muted-foreground italic">クリックして入力</span>}
      </span>
    );
  },
},
```

### B-8. スパークラインカラム

```tsx
import { SparkAreaChart } from "@tremor/react";

{
  accessorKey: "trend",
  header: "トレンド",
  cell: ({ row }) => {
    const data = row.getValue("trend") as { date: string; value: number }[];
    const latest = data[data.length - 1]?.value ?? 0;
    const first = data[0]?.value ?? 0;
    const isPositive = latest >= first;
    return (
      <SparkAreaChart
        data={data}
        categories={["value"]}
        index="date"
        colors={[isPositive ? "emerald" : "red"]}
        className="h-8 w-20"
      />
    );
  },
  enableSorting: false,
},
```

---

## C. Supabase クエリビルダー ヘルパー集

### C-0. Supabase クライアント構成

> Supabase クライアント構成はプロジェクト共通知識として省略。`supabase-postgres-best-practices` / `supabase-auth-patterns` 参照

### C-1. ページネーション + ソート + フィルタ統合

```tsx
interface QueryParams {
  page?: number;
  pageSize?: number;
  sort?: string;        // "column.asc" or "column.desc"
  search?: string;
  filters?: Record<string, string | string[]>;
}

function buildSupabaseQuery(
  table: string,
  select: string,
  params: QueryParams
) {
  const supabase = createClient();
  const { page = 0, pageSize = 20, sort, search, filters } = params;

  let query = supabase.from(table).select(select, { count: "exact" });

  // フィルタ適用
  if (filters) {
    Object.entries(filters).forEach(([key, value]) => {
      if (Array.isArray(value)) {
        query = query.in(key, value);
      } else if (value) {
        query = query.eq(key, value);
      }
    });
  }

  // テキスト検索
  if (search) {
    query = query.or(`name.ilike.%${search}%,email.ilike.%${search}%`);
  }

  // ソート
  if (sort) {
    const [column, direction] = sort.split(".");
    query = query.order(column, { ascending: direction === "asc" });
  } else {
    query = query.order("created_at", { ascending: false });
  }

  // ページネーション
  const from = page * pageSize;
  query = query.range(from, from + pageSize - 1);

  return query;
}
```

### C-2. 集計RPCパターン（KPIデータ取得）

```sql
-- Supabase SQL Editor で作成するRPC
CREATE OR REPLACE FUNCTION get_dashboard_kpis(
  p_start_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
  p_end_date DATE DEFAULT CURRENT_DATE
)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'total_orders', (SELECT COUNT(*) FROM orders WHERE created_at BETWEEN p_start_date AND p_end_date),
    'total_revenue', (SELECT COALESCE(SUM(amount), 0) FROM orders WHERE created_at BETWEEN p_start_date AND p_end_date AND status = 'completed'),
    'new_users', (SELECT COUNT(*) FROM users WHERE created_at BETWEEN p_start_date AND p_end_date),
    'avg_order_value', (SELECT COALESCE(AVG(amount), 0) FROM orders WHERE created_at BETWEEN p_start_date AND p_end_date AND status = 'completed'),
    'prev_total_orders', (SELECT COUNT(*) FROM orders WHERE created_at BETWEEN p_start_date - (p_end_date - p_start_date) AND p_start_date - INTERVAL '1 day'),
    'prev_total_revenue', (SELECT COALESCE(SUM(amount), 0) FROM orders WHERE created_at BETWEEN p_start_date - (p_end_date - p_start_date) AND p_start_date - INTERVAL '1 day' AND status = 'completed')
  ) INTO result;
  RETURN result;
END;
$$ LANGUAGE plpgsql STABLE;
```

```tsx
// フロントエンドでの呼び出し
const { data } = await supabase.rpc("get_dashboard_kpis", {
  p_start_date: startDate,   // e.g. "2025-01-01"
  p_end_date: endDate,       // e.g. "2025-01-31"
});

// 前期比の計算
const change = data.prev_total_revenue > 0
  ? ((data.total_revenue - data.prev_total_revenue) / data.prev_total_revenue * 100).toFixed(1)
  : 0;
```

### C-3. チャートデータ用 時系列クエリ

```sql
-- 日別売上推移（欠損日を0埋め）
CREATE OR REPLACE FUNCTION get_daily_revenue(
  p_start_date DATE,
  p_end_date DATE
)
RETURNS TABLE(date DATE, revenue NUMERIC, order_count BIGINT) AS $$
BEGIN
  RETURN QUERY
  SELECT
    d.date,
    COALESCE(SUM(o.amount), 0) AS revenue,
    COUNT(o.id) AS order_count
  FROM generate_series(p_start_date, p_end_date, '1 day'::interval) AS d(date)
  LEFT JOIN orders o ON o.created_at::date = d.date AND o.status = 'completed'
  GROUP BY d.date
  ORDER BY d.date;
END;
$$ LANGUAGE plpgsql STABLE;
```

---

## D. フィルタコンポーネント バリエーション

### D-1. ステータスフィルタ（マルチセレクト）

```tsx
function StatusFilter({ column }: { column: Column<any, unknown> }) {
  const facets = column.getFacetedUniqueValues();
  const selectedValues = new Set(column.getFilterValue() as string[]);

  return (
    <Popover>
      <PopoverTrigger asChild>
        <Button variant="outline" size="sm" className="h-8">
          <PlusCircle className="mr-2 h-4 w-4" />
          ステータス
          {selectedValues.size > 0 && (
            <Badge variant="secondary" className="ml-2">{selectedValues.size}</Badge>
          )}
        </Button>
      </PopoverTrigger>
      <PopoverContent className="w-48 p-0" align="start">
        <Command>
          <CommandInput placeholder="検索..." />
          <CommandList>
            <CommandEmpty>見つかりません</CommandEmpty>
            <CommandGroup>
              {Object.entries(STATUS_MAP).map(([value, { label }]) => {
                const isSelected = selectedValues.has(value);
                return (
                  <CommandItem
                    key={value}
                    onSelect={() => {
                      if (isSelected) selectedValues.delete(value);
                      else selectedValues.add(value);
                      column.setFilterValue(
                        selectedValues.size ? Array.from(selectedValues) : undefined
                      );
                    }}
                  >
                    <div className={`mr-2 flex h-4 w-4 items-center justify-center rounded-sm border ${
                      isSelected ? "bg-primary text-primary-foreground" : "opacity-50"
                    }`}>
                      {isSelected && <Check className="h-3 w-3" />}
                    </div>
                    {label}
                    <span className="ml-auto text-xs text-muted-foreground">
                      {facets.get(value) ?? 0}
                    </span>
                  </CommandItem>
                );
              })}
            </CommandGroup>
          </CommandList>
        </Command>
      </PopoverContent>
    </Popover>
  );
}
```

### D-2. 日付範囲フィルタ

```tsx
import { DateRange } from "react-day-picker";
import { format } from "date-fns";
import { ja } from "date-fns/locale";

function DateRangeFilter({ onSelect }: { onSelect: (range: DateRange | undefined) => void }) {
  const [date, setDate] = useState<DateRange | undefined>();

  // プリセット
  const presets = [
    { label: "今日", range: { from: startOfToday(), to: endOfToday() } },
    { label: "過去7日", range: { from: subDays(new Date(), 7), to: new Date() } },
    { label: "過去30日", range: { from: subDays(new Date(), 30), to: new Date() } },
    { label: "今月", range: { from: startOfMonth(new Date()), to: new Date() } },
    { label: "先月", range: { from: startOfMonth(subMonths(new Date(), 1)), to: endOfMonth(subMonths(new Date(), 1)) } },
  ];

  return (
    <Popover>
      <PopoverTrigger asChild>
        <Button variant="outline" size="sm">
          <CalendarIcon className="mr-2 h-4 w-4" />
          {date?.from ? (
            date.to ? (
              <>{format(date.from, "yyyy/MM/dd")} - {format(date.to, "yyyy/MM/dd")}</>
            ) : format(date.from, "yyyy/MM/dd")
          ) : "期間を選択"}
        </Button>
      </PopoverTrigger>
      <PopoverContent className="w-auto p-0" align="start">
        <div className="flex">
          <div className="border-r p-2">
            {presets.map((preset) => (
              <Button
                key={preset.label}
                variant="ghost"
                size="sm"
                className="w-full justify-start"
                onClick={() => { setDate(preset.range); onSelect(preset.range); }}
              >
                {preset.label}
              </Button>
            ))}
          </div>
          <Calendar
            mode="range"
            selected={date}
            onSelect={(range) => { setDate(range); onSelect(range); }}
            locale={ja}
            numberOfMonths={2}
          />
        </div>
      </PopoverContent>
    </Popover>
  );
}
```

---

## E. エクスポート詳細パターン

### E-1. Server Action経由の大量データCSVエクスポート

```tsx
// app/actions/export.ts
"use server";
import { createClient } from "@/lib/supabase/server";

export async function exportOrdersCSV(filters: Record<string, string>) {
  const supabase = await createClient();

  // 全件取得（ページネーションなし）
  let query = supabase.from("orders").select("id, customer_name, amount, status, created_at");

  if (filters.status) query = query.eq("status", filters.status);
  if (filters.dateFrom) query = query.gte("created_at", filters.dateFrom);
  if (filters.dateTo) query = query.lte("created_at", filters.dateTo);

  const { data, error } = await query.order("created_at", { ascending: false });
  if (error) throw error;

  // CSV生成
  const headers = ["ID", "顧客名", "金額", "ステータス", "作成日時"];
  const rows = data.map((row) => [
    row.id,
    row.customer_name,
    row.amount,
    row.status,
    new Date(row.created_at).toLocaleString("ja-JP"),
  ]);

  const csv = [headers, ...rows].map((r) => r.join(",")).join("\n");
  return "\uFEFF" + csv; // BOM付きUTF-8
}
```

### E-2. PDFエクスポート（ブラウザ印刷ダイアログ）

```tsx
function PrintButton() {
  const handlePrint = () => {
    // 印刷用CSSクラスを適用
    document.body.classList.add("printing");
    window.print();
    document.body.classList.remove("printing");
  };

  return <Button variant="outline" onClick={handlePrint}>PDF出力</Button>;
}
```

```css
/* globals.css */
@media print {
  /* サイドバー・ヘッダーを非表示 */
  nav, header, .no-print { display: none !important; }

  /* テーブルを全幅 */
  main { width: 100% !important; margin: 0 !important; padding: 0 !important; }

  /* ページ区切り */
  .page-break { page-break-before: always; }
}
```

---

## F. Supabase Realtime 設定チェックリスト

- [ ] テーブルのRealtimeを有効化（Supabase Dashboard → Table Editor → Realtime ON）
- [ ] RLSポリシーがRealtime対象テーブルに設定済み
- [ ] チャンネル名はテーブルごとにユニーク（`orders-changes`, `users-changes`）
- [ ] useEffect内でsubscribe、クリーンアップでremoveChannel
- [ ] 大量の変更が予想されるテーブルはフィルタで絞る:

```tsx
.on("postgres_changes", {
  event: "INSERT",
  schema: "public",
  table: "orders",
  filter: "status=eq.pending",  // 条件付きリッスン
}, handler)
```

- [ ] Realtimeの接続数上限を考慮（Free: 200同時接続、Pro: 500）

---

## G. パフォーマンス最適化チェックリスト

### テーブル
- [ ] 5,000行超 → server-sideページネーションに切り替え
- [ ] `useMemo` でdata / columns をメモ化
- [ ] 100行超の表示 → `@tanstack/react-virtual` で仮想化
- [ ] カラムの `size` / `minSize` / `maxSize` を明示

### チャート
- [ ] `dynamic(() => import(...), { ssr: false })` で遅延ロード
- [ ] 1000データポイント超 → サーバーサイドで集約してから渡す
- [ ] `ResponsiveContainer` でリサイズ対応（Recharts）
- [ ] Tremorの `showAnimation={false}` でアニメーション無効化（大量データ時）

### KPIカード
- [ ] Server Componentで取得（クライアントJSゼロ）
- [ ] `Promise.all` で並列取得
- [ ] キャッシュが効くRPCで集約（個別クエリを避ける）

### フィルタ
- [ ] テキスト入力は300msデバウンス
- [ ] URLのsearchParamsに同期（共有・ブックマーク対応）
- [ ] フィルタ変更時にページを1にリセット

---

## H. ダッシュボードページ テンプレート

```tsx
// app/(dashboard)/overview/page.tsx
import { Suspense } from "react";
import { createClient } from "@/lib/supabase/server";

export default async function OverviewPage() {
  return (
    <div className="space-y-6">
      {/* ヘッダー */}
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">ダッシュボード</h1>
        <DateRangePicker />
      </div>

      {/* KPI・チャート・テーブル各セクションを Suspense で分割 */}
      {/* スケルトンUI (KpiGridSkeleton, ChartSkeleton, TableSkeleton) → `micro-interaction-patterns` 参照 */}
      <Suspense fallback={<KpiGridSkeleton />}><KpiGrid /></Suspense>

      <div className="grid gap-6 lg:grid-cols-3">
        <div className="lg:col-span-2">
          <Suspense fallback={<ChartSkeleton className="h-80" />}><RevenueChart /></Suspense>
        </div>
        <div>
          <Suspense fallback={<ChartSkeleton className="h-80" />}><CategoryBreakdown /></Suspense>
        </div>
      </div>

      <Suspense fallback={<TableSkeleton rows={5} columns={5} />}><RecentOrdersTable /></Suspense>
    </div>
  );
}

async function KpiGrid() {
  const supabase = await createClient();
  const { data } = await supabase.rpc("get_dashboard_kpis");

  const calcChange = (current: number, previous: number) =>
    previous > 0 ? ((current - previous) / previous * 100) : 0;

  return (
    <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
      <KpiCard
        title="総売上"
        value={`¥${data.total_revenue.toLocaleString()}`}
        change={calcChange(data.total_revenue, data.prev_total_revenue)}
      />
      {/* ... 他のKPIカード */}
    </div>
  );
}
```

---

## I. アンチパターン集

| アンチパターン | 問題 | 改善 |
|--------------|------|------|
| クライアントで全件取得してフィルタ | 初期ロードが遅い、メモリ圧迫 | server-sideフィルタ + ページネーション |
| チャートをSSRでレンダリング | サーバー側にDOMがない | `dynamic(..., { ssr: false })` |
| KPIを個別クエリで取得 | N+1的なリクエスト | RPCで一括取得 + `Promise.all` |
| リアルタイム全テーブル監視 | 接続数上限到達、不要な再描画 | 必要なテーブル・イベントのみフィルタ |
| フィルタをuseStateのみで管理 | URL共有不可、ブラウザバック非対応 | searchParamsに同期 |
| スケルトンなしの空白ローディング | ユーザーが壊れたと感じる | → `micro-interaction-patterns` 参照 |
| CSVエクスポートで全件クライアント取得 | メモリ不足、タイムアウト | Server Action / Route Handler |
| 二重Y軸チャート | 誤読を招く | 2つのチャートに分割 |
| PieChartで6カテゴリ超 | 判別困難 | 横BarChart + パーセント表示 |
| デバウンスなしの検索 | API過負荷 | 300msデバウンス |
