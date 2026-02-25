---
name: create-minutes
description: "Generate meeting minutes templates via Notion MCP with auto-created internal and external meeting pages, attendee lists, date/time, and agenda items pre-filled. Use when preparing meeting minutes before a meeting, creating new minutes pages in Notion, setting up meeting agendas, initializing meeting templates, or starting a new internal or external meeting workflow. Do not trigger for transcribing audio recordings (use transcribe-to-minutes), converting minutes to PDF (use notion-pdf), or sharing minutes via email (use share-minutes). Invoke with /create-minutes."
user-invocable: true
---

# create-minutes

Notion MCP を使って議事録テンプレートページを作成するスキル。議事録パイプラインの起点。

## 前提

- Notion MCP が接続済み（`claude mcp list` で確認）
- 議事録を作成するNotionワークスペースへのアクセス権限

## テンプレート種別

### 1. 内部MTG議事録

社内ミーティング用。発言ログを含む詳細な記録。

```
📝 [日付] [MTG名] 議事録

基本情報:
- 日時: YYYY-MM-DD HH:MM〜HH:MM
- 場所: オンライン / 会議室名
- 参加者: @名前, @名前, ...
- 記録者: @名前

議題:
1. [議題1]
2. [議題2]
3. [議題3]

議事内容:
## 1. [議題1]
- 発言者: 内容
- 決定事項:
- TODO:

## 2. [議題2]
...

決定事項まとめ:
- [ ]

次回アクション:
- [ ] [担当] [内容] [期限]
```

### 2. 外部MTG議事録

クライアント・パートナー向け。共有を前提とした整理されたフォーマット。

```
📋 [日付] [MTG名] 議事録

基本情報:
- 日時: YYYY-MM-DD HH:MM〜HH:MM
- 場所:
- 出席者:
  - [自社] @名前, @名前
  - [先方] 名前様, 名前様

議題と決定事項:
## 1. [議題1]
概要:
決定事項:
備考:

## 2. [議題2]
...

Next Steps:
| # | アクション | 担当 | 期限 |
|---|-----------|------|------|
| 1 | | | |

次回MTG:
- 日時:
- 議題候補:
```

## 使い方

### Step 1: ユーザーから情報を収集

以下を確認する（AskUserQuestion使用）:

1. **種別**: 内部MTG or 外部MTG
2. **MTG名**: 例「プロジェクトAlpha 定例」
3. **日時**: 例「2025-01-20 14:00-15:00」
4. **参加者**: 例「田中、佐藤、鈴木」
5. **議題**: 例「Q1ロードマップ、予算確認」
6. **Notion配置先**: 親ページIDまたはデータベースID

### Step 2: Notion MCPでページ作成

Notion MCP の `notion_create_page` ツールを使ってページを作成する。

```
ツール: notion_create_page
パラメータ:
  - parent_id: <親ページID or データベースID>
  - title: "📝 2025-01-20 プロジェクトAlpha 定例 議事録"
  - content: <テンプレート内容（Markdown）>
```

### Step 3: 作成結果を返す

- ページURL
- ページID（後続スキルで使用）
- 作成したテンプレートの概要

## パイプライン連携

このスキルは以下の複合スキルから呼ばれる:

| 呼び出し元 | 用途 |
|-----------|------|
| `transcribe-to-minutes` | 文字起こし結果を流し込む先として作成 |
| `fill-external-minutes` | 外部向け議事録のテンプレとして作成 |

### 戻り値（他スキルへの引き渡し）

```
page_id: <NotionページID>
page_url: <NotionページURL>
template_type: internal | external
```

## カスタマイズ

### カレンダー連携

gog-calendar から予定情報を取得して自動入力:

```bash
# 予定の詳細を取得
gog calendar event <calendarId> <eventId> --json
```

→ 取得した summary, start, end, attendees をテンプレートに自動マッピング

### 定期MTGの場合

前回の議事録からフォーマットを引き継ぐ:

1. Notion MCP で前回ページを検索
2. 構造をコピー
3. 日付・参加者を更新
4. 前回の「次回アクション」を今回の議題に転記

## 注意事項

- Notion MCP の認証が切れている場合は再認証を案内
- 親ページ/データベースIDが不明な場合は `notion_search` で検索
- ページ作成後、必ずURLをユーザーに返す
- 議事録テンプレートはプロジェクトごとにカスタマイズ可能

## Cross-references

- **transcribe-to-minutes**: 録音音声からの文字起こし → 議事録生成
- **fill-external-minutes**: 内部議事録から外部共有版を作成
- **share-minutes**: 議事録の PDF 化とメール配信
- **notion-pdf**: 議事録ページの PDF エクスポート
