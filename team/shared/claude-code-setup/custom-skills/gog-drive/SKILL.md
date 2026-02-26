---
name: gog-drive
description: "Manage Google Drive via gog CLI for searching, downloading, uploading, and exporting files. Covers file search, PDF and CSV export, sharing permission configuration, and folder hierarchy management. Use when searching Drive files, uploading documents, exporting files to PDF or CSV, configuring sharing permissions, managing Drive folders, or downloading files from Google Drive. Do not trigger for email operations (use gog-gmail) or calendar management (use gog-calendar). Invoke with /gog-drive."
user-invocable: true
triggers:
  - Google Driveを操作
  - ファイルを検索する
  - ドライブからダウンロード
  - Driveにファイルをアップロード
  - /gog-drive
---

# gog-drive

gog CLI を使った Google Drive 操作スキル。ファイル検索・DL・UL・エクスポート・共有をカバー。

## コマンド一覧

### ファイル一覧

```bash
# ルート直下
gog drive ls --json

# 特定フォルダ内
gog drive ls --parent <folderId> --json
```

### ファイル検索

```bash
# キーワード検索（全文検索）
gog drive search "議事録 2025" --json

# 複数キーワード
gog drive search "プロジェクトAlpha 提案書" --json
```

### ファイルメタデータ取得

```bash
gog drive get <fileId>
```

### ダウンロード

```bash
# 通常ファイル
gog drive download <fileId> --out "/tmp/claude/downloaded-file.pdf"

# Google Docs → PDF
gog drive download <fileId> --format pdf --out "/tmp/claude/doc.pdf"

# Google Sheets → CSV
gog drive download <fileId> --format csv --out "/tmp/claude/data.csv"

# Google Sheets → Excel
gog drive download <fileId> --format xlsx --out "/tmp/claude/data.xlsx"

# Google Slides → PDF
gog drive download <fileId> --format pdf --out "/tmp/claude/slides.pdf"

# Google Docs → テキスト
gog drive download <fileId> --format txt --out "/tmp/claude/doc.txt"

# Google Docs → Word
gog drive download <fileId> --format docx --out "/tmp/claude/doc.docx"
```

### アップロード

```bash
# 基本アップロード
gog drive upload "/path/to/file.pdf"

# フォルダ指定
gog drive upload "/path/to/report.pdf" --parent <folderId>

# ファイル名変更
gog drive upload "/path/to/local.csv" --name "月次レポート.csv" --parent <folderId>
```

### フォルダ作成

```bash
# ルートに作成
gog drive mkdir "プロジェクトAlpha"

# 特定フォルダ内に作成
gog drive mkdir "議事録" --parent <folderId>
```

### ファイル操作

```bash
# コピー
gog drive copy <fileId> "コピー_提案書" --parent <folderId>

# 移動
gog drive move <fileId> --parent <newFolderId>

# リネーム
gog drive rename <fileId> "新しいファイル名"

# 削除（ゴミ箱へ）
gog drive delete <fileId>
```

### 共有設定

```bash
# 共有（閲覧権限）
gog drive share <fileId> --email "tanaka@example.com" --role reader

# 共有（編集権限）
gog drive share <fileId> --email "team@example.com" --role writer

# 共有解除
gog drive unshare <fileId> <permissionId>

# 権限一覧
gog drive permissions <fileId> --json
```

### URL取得

```bash
gog drive url <fileId>
```

### コメント

```bash
gog drive comments list <fileId> --json
gog drive comments create <fileId> --content "確認お願いします"
```

### 共有ドライブ

```bash
gog drive drives --json
```

## エクスポート形式一覧

| ソース | 対応形式 |
|--------|---------|
| Google Docs | pdf, docx, txt, html |
| Google Sheets | pdf, csv, xlsx |
| Google Slides | pdf, pptx, png |

## ワークフロー例

### 1. Sheets → CSV → DuckDB で分析

```bash
# Step 1: Sheets検索
gog drive search "売上データ 2025" --json

# Step 2: CSVエクスポート
gog drive download <fileId> --format csv --out "/tmp/claude/sales.csv"

# Step 3: DuckDBで集計（duckdb-csv スキル連携）
duckdb -c "SELECT month, SUM(amount) FROM '/tmp/claude/sales.csv' GROUP BY month ORDER BY month"
```

### 2. 議事録PDFを作成して共有

```bash
# Step 1: Google Docsの議事録をPDF化
gog drive download <fileId> --format pdf --out "/tmp/claude/minutes.pdf"

# Step 2: メールに添付して送信（gog-gmail スキル連携）
gog gmail drafts create \
  --to "team@example.com" \
  --subject "議事録共有" \
  --body "添付にて共有します。" \
  --attach "/tmp/claude/minutes.pdf"
```

### 3. フォルダ構造の整理

```bash
# 新規プロジェクトフォルダ作成
gog drive mkdir "Project-Beta"
# → 返されたfolderIdを使ってサブフォルダ作成
gog drive mkdir "議事録" --parent <folderId>
gog drive mkdir "資料" --parent <folderId>
gog drive mkdir "成果物" --parent <folderId>
```

## 注意事項

- ダウンロード先は `/tmp/claude/` を推奨（一時ファイル）
- 大容量ファイルのUL/DLはタイムアウトに注意
- 削除はゴミ箱移動（完全削除ではない）
- `--account` で対象Googleアカウントを切り替え可能

## Cross-references

- **gog-gmail**: メール添付ファイルとの連携・Drive リンク共有
- **gog-calendar**: MTG 関連資料の検索・共有
- **notion-pdf**: PDF ファイルの Drive へのアップロード
- **duckdb-csv**: Sheets → CSV エクスポート後の SQL 分析
