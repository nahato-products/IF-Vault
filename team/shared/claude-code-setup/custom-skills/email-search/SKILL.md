---
name: email-search
description: "Search Gmail using natural language queries that convert ambiguous Japanese search intent into precise Gmail search queries and executes them. Handles fuzzy date references, sender name matching, attachment filters, and contextual queries. Use when searching emails with natural language phrases, finding past correspondence by context, locating emails from specific senders, filtering by date range or attachments, or retrieving email threads using conversational queries. Do not trigger for sending or drafting emails (use gog-gmail) or Gmail query syntax operations (use gog-gmail). Invoke with /email-search."
user-invocable: true
triggers:
  - メールを検索したい
  - Gmailを検索
  - 過去のメールを探したい
  - 添付ファイルのメールを検索
  - /email-search
---

# email-search

自然言語でメールを検索するスキル。ユーザーの曖昧な検索意図を Gmail 検索クエリに変換し、gog-gmail で実行する。

## 動作フロー

```
ユーザーの自然言語 → クエリ変換 → gog gmail search → 結果整形
```

### Step 1: 意図の解析

ユーザーの発話から以下を抽出する:

| 要素 | 例 | Gmail演算子 |
|------|-----|------------|
| 送信者 | 「田中さんから」 | `from:tanaka` |
| 宛先 | 「営業部宛て」 | `to:sales` |
| 件名 | 「議事録について」 | `subject:議事録` |
| 期間 | 「先週」「今月」「3日以内」 | `after:` / `newer_than:` |
| 添付 | 「添付付き」「PDFが付いてる」 | `has:attachment` / `filename:pdf` |
| 状態 | 「未読の」「スター付き」 | `is:unread` / `is:starred` |
| ラベル | 「プロジェクトAの」 | `label:project-a` |
| 除外 | 「通知メール以外」 | `-from:noreply` |
| キーワード | 「見積もり」 | そのまま検索語 |

### Step 2: 日付の変換ルール

| 自然言語 | 変換先 |
|---------|--------|
| 今日 | `newer_than:1d` |
| 昨日 | `after:YYYY/MM/DD before:YYYY/MM/DD` （実日付計算） |
| 今週 | `newer_than:7d` |
| 先週 | `after:YYYY/MM/DD before:YYYY/MM/DD` |
| 今月 | `after:YYYY/MM/01` |
| 先月 | `after:YYYY/MM/01 before:YYYY/MM/01` |
| X日以内 | `newer_than:Xd` |
| X日前 | `after:YYYY/MM/DD before:YYYY/MM/DD` |

日付は実行時の `date` コマンドで算出する。

### Step 3: クエリ組み立て → 実行

```bash
# 変換結果をユーザーに提示
echo "検索クエリ: from:tanaka newer_than:7d has:attachment"

# 実行
gog gmail search "from:tanaka newer_than:7d has:attachment" --max 20 --json
```

### Step 4: 結果の整形

JSON結果から以下を抽出して見やすく表示:
- 日時
- 送信者
- 件名
- スニペット（本文プレビュー）
- スレッドID（後続操作用）

## 使用例

### 「田中さんから先週来た添付付きメール」
```bash
gog gmail search "from:tanaka after:2025/01/13 before:2025/01/20 has:attachment" --max 20 --json
```

### 「今月の未読メールで見積もりに関するもの」
```bash
gog gmail search "is:unread after:2025/01/01 見積もり" --max 20 --json
```

### 「プロジェクトAlphaのラベルが付いた重要メール」
```bash
gog gmail search "label:project-alpha is:important" --max 20 --json
```

### 「3日以内にチームから来たPDF添付メール」
```bash
gog gmail search "to:me newer_than:3d filename:pdf" --max 20 --json
```

### 「noreply以外の未読メール」
```bash
gog gmail search "is:unread -from:noreply -from:no-reply" --max 20 --json
```

## 複合検索のコツ

- OR検索: `{from:tanaka from:sato}` — 田中さんか佐藤さんから
- AND: スペース区切りで自動AND
- 除外: `-` プレフィックス
- 完全一致: `"exact phrase"` でフレーズ検索
- サイズ: `larger:5M` で5MB以上

## 後続操作

検索結果から次のアクションへ:
- **メール全文読む**: `gog gmail get <messageId> --json`
- **返信する**: `gog gmail drafts create --reply-to-message-id <messageId>`
- **添付DL**: `gog gmail attachment <messageId> <attachmentId>`
- **Web表示**: `gog gmail url <threadId>`

## 依存

- `gog-gmail` スキル（内部で gog gmail search を呼ぶ）

## Cross-references

- **gog-gmail**: Gmail 検索クエリの実行先
- **natural-japanese-writing**: 日本語検索意図の解釈精度
