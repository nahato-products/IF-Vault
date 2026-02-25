---
name: duckdb-csv
description: "Analyze CSV files using DuckDB CLI with SQL queries for aggregation, transformation, joins, pivots, and one-liner analytics. Use when aggregating CSV data, performing data analysis on spreadsheet exports, running SQL queries on CSV files, creating pivot tables, joining multiple CSV datasets, analyzing data from Google Sheets exports, or building quick data reports. Do not trigger for database performance optimization (use supabase-postgres-best-practices) or general data visualization (use dashboard-data-viz). Invoke with /duckdb-csv."
user-invocable: true
---

# duckdb-csv

DuckDB CLI を使って CSV ファイルに SQL を実行するスキル。集計・変換・結合・ピボットをカバー。

## 前提

- `duckdb` CLI がインストール済み（`brew install duckdb`）
- CSV は `/tmp/claude/` に配置推奨

## 基本構文

```bash
# 直接SQLを実行
duckdb -c "SELECT * FROM '/tmp/claude/data.csv' LIMIT 10"

# ファイルからSQL実行
duckdb < /tmp/claude/query.sql

# 結果をCSV出力
duckdb -csv -c "SELECT * FROM '/tmp/claude/data.csv'" > /tmp/claude/result.csv

# 結果をJSON出力
duckdb -json -c "SELECT * FROM '/tmp/claude/data.csv'"
```

## よく使うパターン

### データ確認

```bash
# 先頭10行
duckdb -c "SELECT * FROM '/tmp/claude/data.csv' LIMIT 10"

# 行数カウント
duckdb -c "SELECT COUNT(*) AS total FROM '/tmp/claude/data.csv'"

# カラム一覧と型
duckdb -c "DESCRIBE SELECT * FROM '/tmp/claude/data.csv'"

# ユニーク値
duckdb -c "SELECT DISTINCT category FROM '/tmp/claude/data.csv' ORDER BY category"

# NULL件数
duckdb -c "SELECT
  COUNT(*) - COUNT(name) AS name_nulls,
  COUNT(*) - COUNT(email) AS email_nulls
FROM '/tmp/claude/data.csv'"
```

### 集計

```bash
# グループ集計
duckdb -c "
SELECT department, COUNT(*) AS count, AVG(salary) AS avg_salary
FROM '/tmp/claude/employees.csv'
GROUP BY department
ORDER BY avg_salary DESC
"

# 月別集計
duckdb -c "
SELECT strftime(date::DATE, '%Y-%m') AS month, SUM(amount) AS total
FROM '/tmp/claude/sales.csv'
GROUP BY month ORDER BY month
"

# TOP N
duckdb -c "
SELECT product, SUM(quantity) AS total_qty
FROM '/tmp/claude/orders.csv'
GROUP BY product ORDER BY total_qty DESC LIMIT 10
"
```

### フィルタリング

```bash
# 条件抽出 → 新CSV
duckdb -csv -c "
SELECT * FROM '/tmp/claude/data.csv'
WHERE status = 'active' AND created_at >= '2025-01-01'
" > /tmp/claude/active.csv

# LIKE検索
duckdb -c "
SELECT * FROM '/tmp/claude/contacts.csv'
WHERE name LIKE '%田中%'
"
```

### 結合（JOIN）

```bash
# 2つのCSVを結合
duckdb -csv -c "
SELECT a.*, b.department_name
FROM '/tmp/claude/employees.csv' a
JOIN '/tmp/claude/departments.csv' b ON a.dept_id = b.id
" > /tmp/claude/joined.csv
```

### 変換

```bash
# カラム追加・変換
duckdb -csv -c "
SELECT *,
  price * quantity AS subtotal,
  CASE WHEN status = '完了' THEN true ELSE false END AS is_done
FROM '/tmp/claude/orders.csv'
" > /tmp/claude/transformed.csv

# 日付フォーマット変換
duckdb -csv -c "
SELECT *, strftime(date::DATE, '%Y年%m月%d日') AS formatted_date
FROM '/tmp/claude/data.csv'
" > /tmp/claude/formatted.csv
```

### ピボット・クロス集計

```bash
# ピボット
duckdb -c "
PIVOT '/tmp/claude/sales.csv'
ON month
USING SUM(amount)
GROUP BY product
"
```

### ウィンドウ関数

```bash
# 順位付け
duckdb -c "
SELECT *, RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS rank
FROM '/tmp/claude/employees.csv'
"

# 累積合計
duckdb -c "
SELECT *, SUM(amount) OVER (ORDER BY date) AS cumulative
FROM '/tmp/claude/sales.csv'
"
```

## 出力形式

| フラグ | 形式 | 用途 |
|--------|------|------|
| (なし) | テーブル | 人間向け表示 |
| `-csv` | CSV | ファイル出力、他ツール連携 |
| `-json` | JSON | API連携、jq処理 |
| `-markdown` | Markdown | ドキュメント埋め込み |
| `-line` | 1行1フィールド | デバッグ |

## ワークフロー例

### Google Sheets → 集計 → レポート

```bash
# Step 1: Sheets → CSV（gog-drive連携）
gog drive download <fileId> --format csv --out "/tmp/claude/sales.csv"

# Step 2: DuckDBで集計
duckdb -markdown -c "
SELECT
  strftime(date::DATE, '%Y-%m') AS 月,
  SUM(amount) AS 売上合計,
  COUNT(*) AS 件数,
  ROUND(AVG(amount)) AS 平均単価
FROM '/tmp/claude/sales.csv'
GROUP BY 月 ORDER BY 月
"

# Step 3: 結果をCSV出力 → Sheets にUL
duckdb -csv -c "..." > /tmp/claude/summary.csv
gog drive upload "/tmp/claude/summary.csv" --parent <folderId>
```

### 複数CSV結合して分析

```bash
# glob で複数ファイル読み込み
duckdb -c "
SELECT * FROM '/tmp/claude/sales_*.csv'
"
```

## 便利な関数

| 関数 | 例 | 説明 |
|------|-----|------|
| `strftime` | `strftime(d, '%Y-%m')` | 日付フォーマット |
| `date_trunc` | `date_trunc('month', d)` | 日付切り捨て |
| `regexp_extract` | `regexp_extract(s, '\d+')` | 正規表現抽出 |
| `list_agg` | `list_agg(name)` | 値をリスト化 |
| `string_agg` | `string_agg(name, ', ')` | 文字列結合 |
| `COALESCE` | `COALESCE(a, b, 0)` | NULL代替 |
| `TRY_CAST` | `TRY_CAST(s AS INTEGER)` | 安全型変換 |

## 注意事項

- CSVの文字コードはUTF-8推奨。Shift-JISの場合は `iconv` で変換
- 巨大ファイル（100MB超）もDuckDBなら高速処理可能
- 一時ファイルは `/tmp/claude/` に出力

## Cross-References

### Referenced by

- **dashboard-data-viz**: CSV分析結果のダッシュボード可視化
- **supabase-postgres-best-practices**: SQL知識の共有・クエリパターン
- **xurl-twitter-ops**: Xデータの CSV エクスポート → DuckDB で集計・分析
- **gog-drive**: Drive CSV ファイルのダウンロード → DuckDB で分析

### Outgoing

- **xurl-twitter-ops**: X エクスポートデータの SQL 分析
- **gog-drive**: Drive CSV のダウンロード→分析パイプライン
- **_dashboard-data-viz**: 分析結果のダッシュボード可視化
