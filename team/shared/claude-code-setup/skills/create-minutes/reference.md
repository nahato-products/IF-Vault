# create-minutes Reference

## Notion MCP ツール一覧（議事録関連）

### ページ検索
```
notion_search
  query: "議事録"
  filter: { property: "object", value: "page" }
```

### ページ作成
```
notion_create_page
  parent_id: "<親ページID>"  # or データベースID
  title: "ページタイトル"
  content: "Markdown形式の本文"
```

### ページ取得
```
notion_get_page
  page_id: "<ページID>"
```

### ページ更新
```
notion_update_page
  page_id: "<ページID>"
  content: "更新後のMarkdown"
```

### データベース検索
```
notion_query_database
  database_id: "<データベースID>"
  filter: { ... }
  sorts: [{ property: "Date", direction: "descending" }]
```

## Notionブロック対応

Notion MCP経由で使えるMarkdown記法:

| Markdown | Notionブロック |
|----------|--------------|
| `# 見出し` | Heading 1 |
| `## 見出し` | Heading 2 |
| `### 見出し` | Heading 3 |
| `- リスト` | Bulleted list |
| `1. 番号` | Numbered list |
| `- [ ] タスク` | To-do |
| `> 引用` | Quote |
| `` `コード` `` | Code (inline) |
| `---` | Divider |
| `**太字**` | Bold |
| `*斜体*` | Italic |
| `@名前` | Mention (Notion内) |

## テンプレート変数

スキル内で置換する変数:

| 変数 | 説明 | 例 |
|------|------|-----|
| `{date}` | 日付 | 2025-01-20 |
| `{time_start}` | 開始時刻 | 14:00 |
| `{time_end}` | 終了時刻 | 15:00 |
| `{title}` | MTG名 | プロジェクトAlpha 定例 |
| `{attendees}` | 参加者リスト | 田中, 佐藤, 鈴木 |
| `{agenda}` | 議題リスト | Q1ロードマップ, 予算確認 |
| `{location}` | 場所 | Google Meet / 会議室A |
| `{recorder}` | 記録者 | 関口 |

## ワークフロー図

```
[ユーザー入力] or [gog-calendar]
        ↓
  create-minutes（テンプレ作成）
        ↓
    [Notion ページ]
        ↓
  transcribe-to-minutes（文字起こし流し込み）
  fill-external-minutes（外部向け整形）
        ↓
    [完成した議事録]
        ↓
  share-minutes（PDF化 + メール送信）
```
