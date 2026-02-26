---
name: notion-pdf
description: "Convert Notion pages to high-quality PDF output using Notion internal API (enqueueTask) with pandoc fallback for reliability. Use when exporting Notion pages as PDF, converting meeting minutes or proposals to PDF format, generating printable documents from Notion content, or creating PDF archives of Notion pages. Do not trigger for sharing minutes via email with PDF attachment (use share-minutes) or general document editing. Invoke with /notion-pdf."
user-invocable: true
---

# notion-pdf

Notion ページを PDF に変換するスキル。2つの方式を持ち、自動フォールバックする。

## 方式

### Primary: Notion内部API（enqueueTask）

高品質なPDFを生成。Notionのレンダリングエンジンを使うため、レイアウトが正確。

**前提**: `NOTION_TOKEN_V2` 環境変数が必要（ブラウザのCookieから取得）

```bash
# NOTION_TOKEN_V2 の取得方法:
# 1. ブラウザでNotion開く
# 2. DevTools → Application → Cookies → token_v2 の値をコピー
# 3. export NOTION_TOKEN_V2="<value>"
```

**実行フロー**:

1. ページIDからブロックIDを取得（ハイフン除去）
2. `enqueueTask` API でPDFエクスポートをキューイング
3. ポーリングでタスク完了を待機
4. 完了したらsigned URLからPDFダウンロード

```bash
# 環境変数チェック
if [ -z "$NOTION_TOKEN_V2" ]; then
  echo "⚠️ NOTION_TOKEN_V2 未設定 → Fallback方式に切り替えます"
  # Fallbackへ
fi

# Step 1: エクスポートタスク作成（HTTPステータス付き）
BLOCK_ID=$(echo "$PAGE_ID" | tr -d '-')

HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "https://www.notion.so/api/v3/enqueueTask" \
  -H "Cookie: token_v2=$NOTION_TOKEN_V2" \
  -H "Content-Type: application/json" \
  -d "{
    \"task\": {
      \"eventName\": \"exportBlock\",
      \"request\": {
        \"block\": { \"id\": \"$BLOCK_ID\" },
        \"recursive\": false,
        \"exportOptions\": {
          \"exportType\": \"pdf\",
          \"pdfFormat\": \"A4\",
          \"locale\": \"ja\",
          \"timeZone\": \"Asia/Tokyo\"
        }
      }
    }
  }")

HTTP_STATUS=$(echo "$HTTP_RESPONSE" | tail -1)
RESPONSE_BODY=$(echo "$HTTP_RESPONSE" | sed '$d')

# HTTPステータスコード判定
if [ "$HTTP_STATUS" = "401" ] || [ "$HTTP_STATUS" = "403" ]; then
  echo "⚠️ token_v2が失効しています。ブラウザから再取得してください → Fallbackへ"
  # Fallbackへ
elif [ "$HTTP_STATUS" != "200" ]; then
  echo "⚠️ enqueueTask失敗（HTTP $HTTP_STATUS） → Fallbackへ"
  # Fallbackへ
fi

TASK_ID=$(echo "$RESPONSE_BODY" | jq -r '.taskId')

# Step 2: ポーリング（最大60秒 = 5秒×12回）
PDF_URL=""
for i in $(seq 1 12); do
  RESULT=$(curl -s -X POST "https://www.notion.so/api/v3/getTasks" \
    -H "Cookie: token_v2=$NOTION_TOKEN_V2" \
    -H "Content-Type: application/json" \
    -d "{\"taskIds\": [\"$TASK_ID\"]}")

  STATUS=$(echo "$RESULT" | jq -r '.results[0].state')
  if [ "$STATUS" = "success" ]; then
    PDF_URL=$(echo "$RESULT" | jq -r '.results[0].status.exportURL')
    break
  fi
  sleep 5
done

# ポーリングタイムアウト判定
if [ -z "$PDF_URL" ]; then
  echo "⚠️ 60秒経過してもエクスポート完了せず → Fallbackに切り替えます"
  # Fallbackへ
fi

# Step 3: PDFダウンロード
curl -s -o "/tmp/claude/output.pdf" "$PDF_URL"
```

### Fallback: Notion MCP → Markdown → pandoc

`NOTION_TOKEN_V2` が未設定 or Primary失敗時に自動切替。

**前提**: `pandoc` がインストール済み（`brew install pandoc`）

```bash
# pandocインストールチェック
if ! command -v pandoc &>/dev/null; then
  echo "❌ pandoc が見つかりません。brew install pandoc を実行してください"
  exit 1
fi

# PDFエンジン優先順: typst > wkhtmltopdf > lualatex
if command -v typst &>/dev/null; then
  PDF_ENGINE="typst"
elif command -v wkhtmltopdf &>/dev/null; then
  PDF_ENGINE="wkhtmltopdf"
elif command -v lualatex &>/dev/null; then
  PDF_ENGINE="lualatex"
else
  echo "❌ PDFエンジンが見つかりません。brew install typst を推奨"
  exit 1
fi

echo "📄 PDFエンジン: $PDF_ENGINE"

# Step 1: Notion MCP でページ内容をMarkdownで取得
# → notion_get_page_content ツール使用

# Step 2: Markdownファイルに保存
# /tmp/claude/notion-export.md

# Step 3: pandoc でPDF変換（検出されたエンジンを使用）
pandoc /tmp/claude/notion-export.md \
  -o /tmp/claude/output.pdf \
  --pdf-engine="$PDF_ENGINE" \
  -V mainfont="Hiragino Sans" \
  -V fontsize=11pt \
  -V geometry:margin=2cm \
  -V lang=ja
```

## 使い方

```
/notion-pdf

→ ページIDまたはURLを指定
→ 自動でPrimary方式を試行
→ 失敗時はFallbackに切り替え
→ /tmp/claude/<title>.pdf に出力
```

### 入力

| パラメータ | 必須 | 説明 |
|-----------|------|------|
| page_id or URL | ✅ | NotionページID or URL |
| output_path | - | 出力先（default: `/tmp/claude/<title>.pdf`） |
| format | - | A4（default）/ Letter / A3 |

### 出力

```
pdf_path: /tmp/claude/2025-01-20-プロジェクトAlpha-定例MTG-議事録.pdf
method: enqueueTask | pandoc
page_title: "2025-01-20 プロジェクトAlpha 定例MTG 議事録"
```

**ファイル名フォーマット**: `YYYY-MM-DD-slugified-title.pdf`

- slugifyルール: スペース→ハイフン、`/` `\` `:` `*` `?` を除去、30文字以内に切り詰め
- 例: `2025-01-20-プロジェクトAlpha-定例MTG-議事録.pdf`

```bash
# slugify処理
SLUG=$(echo "$PAGE_TITLE" | sed 's/ /-/g; s/[\/\\:*?]//g' | cut -c1-30)
FILENAME="$(date +%Y-%m-%d)-${SLUG}.pdf"
```

## 方式の自動選択ロジック

```
NOTION_TOKEN_V2 が設定済み?
  → No: Fallback へ
  → Yes: enqueueTask を試行
    → HTTP 401/403: 「token_v2失効」表示 → Fallback へ
    → HTTP 200 + ポーリング成功: PDF完成 ✅
    → ポーリングタイムアウト(60秒): Fallback へ

Fallback:
  pandoc インストール済み?
    → No: 「brew install pandoc」表示して停止 ❌
    → Yes: PDFエンジン検出（typst > wkhtmltopdf > lualatex）
      → エンジン見つからない: 「brew install typst」表示して停止 ❌
      → エンジン見つかった: Notion MCP → Markdown → pandoc → PDF完成 ✅
```

## パイプライン連携

| 呼び出し元 | 用途 |
|-----------|------|
| `share-minutes` | 議事録をPDF化してメール添付 |
| 単体使用 | 任意のNotionページをPDF化 |

## PDFフォーマットオプション

### enqueueTask方式

| オプション | 値 |
|-----------|-----|
| `exportType` | `pdf` |
| `pdfFormat` | `A4` / `Letter` / `A3` |
| `locale` | `ja` / `en` |
| `timeZone` | `Asia/Tokyo` |

### pandoc方式

| オプション | 値 |
|-----------|-----|
| `--pdf-engine` | `typst` / `wkhtmltopdf` / `lualatex` |
| `mainfont` | `Hiragino Sans`（macOS日本語） |
| `fontsize` | `11pt` |
| `geometry:margin` | `2cm` |

## 注意事項

- `NOTION_TOKEN_V2` はセッショントークンなので定期的に更新が必要
- enqueueTask方式はNotionの非公式API（将来変更の可能性あり）
- 大きなページ（100ブロック超）はエクスポートに時間がかかる
- PDFは `/tmp/claude/` に出力（一時ファイル）
- pandoc方式は画像が含まれないことがある（Markdown変換の制約）

## Cross-references

- **share-minutes**: 議事録PDF変換の実行元
- **create-minutes**: 議事録テンプレートのPDF出力
- **gog-drive**: PDF の Google Drive アップロード
