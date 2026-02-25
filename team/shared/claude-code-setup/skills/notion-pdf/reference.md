# notion-pdf Reference

## 依存ツール・環境変数

| ツール / 変数 | 用途 | 備考 |
|--------------|------|------|
| `NOTION_TOKEN_V2` | Notion内部API認証 | Primary方式のみ。約90日で失効 |
| `pandoc` | Markdown→PDF変換 | Fallback方式で使用 |
| PDFエンジン | pandoc のバックエンド | 優先順位: `typst` > `wkhtmltopdf` > `lualatex` |
| `curl` | Notion API呼び出し・ファイルDL | enqueueTask / getTasks / S3 DL |
| Notion MCP | ページ内容取得 | Fallback方式（MCP経由でMD取得→pandoc変換） |

### token_v2 の取得手順

1. ブラウザで notion.so にログイン
2. DevTools を開く（F12 / Cmd+Opt+I）
3. Application タブ → Cookies → www.notion.so
4. `token_v2` の Value をコピー
5. `export NOTION_TOKEN_V2="<value>"` で設定

注意: トークンは約90日で失効。定期的に更新が必要。

## コマンドリファレンス

### Notion内部API — enqueueTask

```
POST https://www.notion.so/api/v3/enqueueTask
Cookie: token_v2=<NOTION_TOKEN_V2>
Content-Type: application/json

{
  "task": {
    "eventName": "exportBlock",
    "request": {
      "block": { "id": "<blockId>" },
      "recursive": false,
      "exportOptions": {
        "exportType": "pdf",
        "pdfFormat": "A4",
        "locale": "ja",
        "timeZone": "Asia/Tokyo"
      }
    }
  }
}
```

レスポンス: `{ "taskId": "<taskId>" }`

### Notion内部API — getTasks

```
POST https://www.notion.so/api/v3/getTasks
Cookie: token_v2=<NOTION_TOKEN_V2>
Content-Type: application/json

{ "taskIds": ["<taskId>"] }
```

レスポンス:
```json
{
  "results": [{
    "id": "<taskId>",
    "state": "success",
    "status": { "exportURL": "https://s3.us-west-2.amazonaws.com/..." }
  }]
}
```

### ページID変換

```bash
# Notion URL → ページID（末尾32文字がID）
# https://www.notion.so/workspace/Page-Title-abc123def456
# → abc123def456

# ページID → ブロックID（ハイフン除去）
echo "abc12345-6789-0abc-def0-123456789abc" | tr -d '-'
```

### pandoc — 基本構文

```bash
pandoc input.md -o output.pdf [options]
```

### pandoc — PDFエンジン

| エンジン | インストール | 日本語 | 品質 |
|---------|------------|--------|------|
| `typst` | `brew install typst` | OK | 高 |
| `wkhtmltopdf` | `brew install wkhtmltopdf` | OK | 中 |
| `lualatex` | `brew install texlive` | 要設定 | 高 |

### PDFエンジン判定フロー

```bash
# エンジン自動選択
if command -v typst >/dev/null 2>&1; then
  PDF_ENGINE="typst"
elif command -v wkhtmltopdf >/dev/null 2>&1; then
  PDF_ENGINE="wkhtmltopdf"
elif command -v lualatex >/dev/null 2>&1; then
  PDF_ENGINE="lualatex"
else
  echo "Error: PDFエンジンが見つかりません"
  echo "brew install typst を実行してください"
  exit 1
fi
```

### pandoc — 日本語PDF用オプション

```bash
pandoc input.md -o output.pdf \
  --pdf-engine=typst \
  -V mainfont="Hiragino Sans" \
  -V fontsize=11pt \
  -V geometry:margin=2cm \
  -V lang=ja \
  -V documentclass=article \
  --toc \
  --highlight-style=tango
```

### macOS 日本語フォント

| フォント名 | 用途 |
|-----------|------|
| `Hiragino Sans` | ゴシック体（本文向け） |
| `Hiragino Mincho ProN` | 明朝体（フォーマル文書） |
| `Hiragino Maru Gothic ProN` | 丸ゴシック |

### ファイル名 slugify ルール

```bash
# slugify: スペース→ハイフン、特殊文字除去、30文字制限
SLUG=$(echo "$TITLE" | sed 's/ /-/g; s/[\/\\:*?"<>|]//g' | cut -c1-30)
FILENAME="$(date +%Y-%m-%d)-${SLUG}.pdf"
# 例: 2025-01-20-プロジェクトAlpha-議事録.pdf
```

## パターン辞書

### ページID抽出パターン

```regex
# Notion URL からページIDを抽出
https://www\.notion\.so/[^/]+/[^-]+-([a-f0-9]{32})

# UUID形式のページID（ハイフン付き）
[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}
```

### ファイル名パターン

```
YYYY-MM-DD-{slugified-title}.pdf
```

### APIレスポンスステート

```
not_started → in_progress → success / failure
```

## トラブルシューティング

| エラー | 原因 | 対処 |
|--------|------|------|
| 401 Unauthorized | token_v2 失効 | ブラウザから再取得 |
| 403 Forbidden | ページへのアクセス権なし | ワークスペース確認 |
| task state: failure | エクスポート失敗 | ページサイズ確認、Fallbackへ |
| pandoc not found | 未インストール | `brew install pandoc` |
| typst not found | PDFエンジン未インストール | `brew install typst` |
| 日本語文字化け | フォント未指定 | `mainfont` オプション追加 |
| ポーリングタイムアウト（60秒超） | Notionサーバー負荷 | Fallback方式に切替 |
| PDFが空白 | ページ内容が画像のみ | Fallback方式（Notion MCP→pandoc） |
| ファイル名に特殊文字 | タイトルに`/:\`等含む | slugifyルールで自動除去 |
