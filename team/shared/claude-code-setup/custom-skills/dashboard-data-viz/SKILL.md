---
name: dashboard-data-viz
description: "Build data dashboards and visualizations using Chart.js, Recharts, or D3.js integrated with React and Next.js, covering time series, bar charts, pie charts, metrics cards, and responsive layout patterns. Use when building analytics dashboards, creating data visualization components, implementing real-time metrics displays, or designing KPI overview pages. Do not trigger for raw data analysis (use duckdb-csv), observability tooling (use observability), or static report generation (use pdf)."
user-invocable: false
triggers:
  - ダッシュボードを作りたい
  - グラフ・チャートを実装
  - データを可視化したい
  - KPIを表示する
  - 分析画面を設計
---

# Dashboard Data Visualization

React + Recharts を使ったダッシュボード・データビジュアライゼーション構築パターン。

## Recharts Basic Pattern

```tsx
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts'

export function MetricsChart({ data }) {
  return (
    <ResponsiveContainer width="100%" height={300}>
      <LineChart data={data}>
        <CartesianGrid strokeDasharray="3 3" />
        <XAxis dataKey="date" />
        <YAxis />
        <Tooltip />
        <Line type="monotone" dataKey="value" stroke="#3b82f6" />
      </LineChart>
    </ResponsiveContainer>
  )
}
```

## KPI Card Pattern

```tsx
export function KpiCard({ title, value, change, trend }) {
  return (
    <div className="rounded-xl border bg-card p-6">
      <p className="text-sm text-muted-foreground">{title}</p>
      <p className="text-3xl font-bold mt-1">{value}</p>
      <p className={cn("text-sm mt-1", trend === 'up' ? 'text-green-500' : 'text-red-500')}>
        {change}
      </p>
    </div>
  )
}
```

## Cross-references

- **duckdb-csv**: ダッシュボード用データの集計・変換
- **observability**: サービスメトリクスの可視化
- **react-component-patterns**: Reactコンポーネント設計パターン
