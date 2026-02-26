---
name: gog-gmail
description: "Manage Gmail via gog CLI for searching, sending, drafting, and replying to emails. Covers Gmail search query syntax, thread operations, label management, and attachment handling. Use when sending emails, creating email drafts, searching emails with query syntax, attaching files to messages, managing Gmail labels, replying to threads, or building email automation workflows. Do not trigger for natural language email search (use email-search) or calendar operations (use gog-calendar). Invoke with /gog-gmail."
user-invocable: true
triggers:
  - メールを送りたい
  - Gmailを操作する
  - メール下書きを作る
  - メールに返信する
  - /gog-gmail
---

# gog-gmail

gog CLI を使った Gmail 操作スキル。検索・送信・下書き・返信・ラベル管理をカバー。

## 安全設計

- **メール送信はデフォルト「下書き作成」**。直接送信は `--force` 付きのみ
- 宛先・件名は必ずユーザーに確認してから実行
- `--account` で対象アカウントを明示（複数アカウント対応）

## コマンド一覧

### 検索

```bash
# 基本検索（最大10件）
gog gmail search "from:tanaka subject:議事録" --max 10 --json

# 期間指定
gog gmail search "after:2025/01/01 before:2025/02/01 has:attachment" --json

# 未読のみ
gog gmail search "is:unread label:inbox" --max 20
```

### メッセージ取得

```bash
# メッセージ詳細
gog gmail get <messageId> --json

# 添付ファイルDL
gog gmail attachment <messageId> <attachmentId>
```

### 下書き作成（推奨）

```bash
# 新規下書き
gog gmail drafts create \
  --to "tanaka@example.com" \
  --subject "MTG議事録の共有" \
  --body "お疲れ様です。添付にて議事録を共有いたします。"

# 返信下書き
gog gmail drafts create \
  --to "tanaka@example.com" \
  --subject "Re: プロジェクト進捗" \
  --body "ご確認ありがとうございます。" \
  --reply-to-message-id "<messageId>"

# 添付付き
gog gmail drafts create \
  --to "team@example.com" \
  --subject "資料共有" \
  --body "添付ご確認ください。" \
  --attach "/path/to/file.pdf"
```

### 送信（要確認）

```bash
# 直接送信（--force で確認スキップ）
gog gmail send \
  --to "tanaka@example.com" \
  --subject "件名" \
  --body "本文" \
  --force

# 返信（reply-all）
gog gmail send \
  --reply-to-message-id "<messageId>" \
  --reply-all \
  --body "返信本文" \
  --force

# ファイルから本文読み込み
gog gmail send \
  --to "team@example.com" \
  --subject "週報" \
  --body-file "/tmp/claude/weekly-report.txt" \
  --force
```

### 下書き管理

```bash
gog gmail drafts list --json          # 一覧
gog gmail drafts get <draftId> --json  # 詳細
gog gmail drafts send <draftId>        # 下書きを送信
gog gmail drafts delete <draftId>      # 削除
```

### スレッド・ラベル

```bash
# スレッド操作
gog gmail thread get <threadId> --json
gog gmail thread modify <threadId> --add-labels "IMPORTANT" --remove-labels "UNREAD"

# ラベル一覧
gog gmail labels list --json

# バッチ操作
gog gmail batch archive "is:read older_than:30d"
```

## Gmail検索クエリ構文

| 演算子 | 例 | 意味 |
|--------|-----|------|
| `from:` | `from:tanaka` | 送信者 |
| `to:` | `to:team@example.com` | 宛先 |
| `subject:` | `subject:議事録` | 件名 |
| `has:attachment` | - | 添付あり |
| `filename:` | `filename:pdf` | 添付ファイル名 |
| `after:` / `before:` | `after:2025/01/01` | 日付範囲 |
| `older_than:` / `newer_than:` | `newer_than:7d` | 相対日付 |
| `is:unread` | - | 未読 |
| `is:starred` | - | スター付き |
| `label:` | `label:project-alpha` | ラベル |
| `in:` | `in:sent` | フォルダ |
| `{ }` | `{from:a from:b}` | OR検索 |
| `-` | `-from:noreply` | 除外 |

## ワークフロー例

### 1. 今日の重要メール確認
```bash
gog gmail search "is:unread is:important newer_than:1d" --max 20 --json
```

### 2. 特定プロジェクトのメール一括確認
```bash
gog gmail search "label:project-alpha newer_than:7d" --json
```

### 3. 議事録を添付して関係者に送信
```bash
# Step 1: 下書き作成
gog gmail drafts create \
  --to "team@example.com" \
  --cc "manager@example.com" \
  --subject "【共有】2025/01/15 定例MTG議事録" \
  --body-file "/tmp/claude/minutes-body.txt" \
  --attach "/tmp/claude/minutes.pdf"

# Step 2: ユーザー確認後に送信
gog gmail drafts send <draftId>
```

## 出力形式

- `--json`: スクリプト連携用（パイプラインで使う場合は必須）
- `--plain`: TSV形式（タブ区切り、grepしやすい）
- デフォルト: 人間向けカラー表示

## エラー時の対応

| エラー | 対処 |
|--------|------|
| `401 Unauthorized` | `gog auth login` で再認証 |
| `429 Rate Limit` | 少し待ってリトライ |
| `404 Not Found` | messageId/threadId を再確認 |

## Cross-references

- **gog-calendar**: カレンダー招待・予定関連のメール連携
- **gog-drive**: メール添付ファイルの Drive 保存・共有リンク
- **email-search**: 自然言語からの Gmail 検索クエリ変換
- **share-minutes**: 議事録 PDF のメール配信
- **fill-external-minutes**: 社外議事録生成時のメールスレッド取得元
