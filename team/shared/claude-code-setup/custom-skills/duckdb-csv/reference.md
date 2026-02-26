# duckdb-csv Reference

## DuckDB CLI オプション

```bash
duckdb [database] [options]
```

| オプション | 説明 |
|-----------|------|
| `-c "SQL"` | SQLコマンド実行 |
| `-csv` | CSV形式出力 |
| `-json` | JSON形式出力 |
| `-markdown` | Markdown テーブル出力 |
| `-line` | 行形式出力 |
| `-separator "X"` | 区切り文字指定 |
| `-header` | ヘッダー表示（デフォルトON） |
| `-noheader` | ヘッダー非表示 |

## CSV読み込みオプション

```sql
-- 自動検出（デフォルト）
SELECT * FROM '/path/to/file.csv';

-- 明示的オプション
SELECT * FROM read_csv('/path/to/file.csv',
  header = true,
  delimiter = ',',
  quote = '"',
  escape = '"',
  dateformat = '%Y-%m-%d',
  timestampformat = '%Y-%m-%d %H:%M:%S',
  sample_size = 1000,
  all_varchar = false,
  auto_detect = true
);

-- TSV読み込み
SELECT * FROM read_csv('/path/to/file.tsv', delimiter = '\t');

-- glob複数ファイル
SELECT * FROM '/path/to/sales_*.csv';
SELECT * FROM read_csv('/path/to/*.csv', union_by_name = true);
```

## CSV書き出し

```sql
COPY (SELECT * FROM '/tmp/claude/data.csv' WHERE active)
TO '/tmp/claude/output.csv' (HEADER, DELIMITER ',');
```

## 型変換

| 変換 | 構文 |
|------|------|
| 文字列→日付 | `col::DATE` / `CAST(col AS DATE)` |
| 文字列→数値 | `col::INTEGER` / `TRY_CAST(col AS DOUBLE)` |
| 日付→文字列 | `strftime(col, '%Y-%m-%d')` |
| JSON抽出 | `col::JSON->>'key'` |

## 日付関数

| 関数 | 例 |
|------|-----|
| `current_date` | 今日 |
| `date_trunc('month', d)` | 月初に切り捨て |
| `date_part('year', d)` | 年を抽出 |
| `date_diff('day', d1, d2)` | 日数差 |
| `d + INTERVAL '7 days'` | 加算 |
| `strftime(d, '%Y-%m')` | フォーマット |

## 集計関数

| 関数 | 説明 |
|------|------|
| `COUNT(*)` | 行数 |
| `SUM(col)` | 合計 |
| `AVG(col)` | 平均 |
| `MIN(col)` / `MAX(col)` | 最小/最大 |
| `MEDIAN(col)` | 中央値 |
| `STDDEV(col)` | 標準偏差 |
| `QUANTILE(col, 0.95)` | パーセンタイル |
| `APPROX_COUNT_DISTINCT(col)` | 概算ユニーク数 |
| `LIST(col)` | リスト集約 |
| `STRING_AGG(col, ',')` | 文字列結合 |

## PIVOT構文

```sql
PIVOT table_name
ON pivot_column
USING aggregate_function(value_column)
GROUP BY group_columns;
```

## 文字コード変換（前処理）

```bash
# Shift-JIS → UTF-8
iconv -f SHIFT_JIS -t UTF-8 input.csv > /tmp/claude/utf8.csv

# 文字コード判定
file -I input.csv
```
