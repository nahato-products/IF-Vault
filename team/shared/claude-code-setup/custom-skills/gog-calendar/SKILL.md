---
name: gog-calendar
description: "Manage Google Calendar via gog CLI for listing, creating, updating, and deleting events with availability checks. Covers event creation with Google Meet URLs, recurring event configuration, and free/busy time queries. Use when creating calendar events, checking schedules, finding available time slots, generating Meet URLs, setting up recurring meetings, or managing calendar entries programmatically. Do not trigger for email operations (use gog-gmail) or Drive file management (use gog-drive). Invoke with /gog-calendar."
user-invocable: true
triggers:
  - カレンダーを操作する
  - Google Calendarに予定を作る
  - MTGを設定
  - 空き時間を確認したい
  - /gog-calendar
---

# gog-calendar

gog CLI を使った Google Calendar 操作スキル。予定の一覧・作成・更新・削除・空き時間確認をカバー。

## コマンド一覧

### カレンダー一覧

```bash
gog calendar calendars --json
```

### 予定の一覧・検索

```bash
# 今日の予定
gog calendar events --json

# 特定カレンダーの予定
gog calendar events <calendarId> --json

# 期間指定
gog calendar events --from "2025-01-15T00:00:00+09:00" --to "2025-01-16T00:00:00+09:00" --json

# キーワード検索
gog calendar search "定例" --json
```

### 予定の作成

```bash
# 基本的な予定
gog calendar create <calendarId> \
  --summary "プロジェクトAlpha 定例MTG" \
  --from "2025-01-20T14:00:00+09:00" \
  --to "2025-01-20T15:00:00+09:00" \
  --description "議題: Q1ロードマップ確認" \
  --location "会議室A"

# 参加者 + Meet付き
gog calendar create <calendarId> \
  --summary "1on1 田中さん" \
  --from "2025-01-20T10:00:00+09:00" \
  --to "2025-01-20T10:30:00+09:00" \
  --attendees "tanaka@example.com,sato@example.com" \
  --with-meet \
  --send-updates all

# 終日予定
gog calendar create <calendarId> \
  --summary "有給休暇" \
  --from "2025-01-20" \
  --to "2025-01-21" \
  --all-day

# 繰り返し予定（毎週月曜）
gog calendar create <calendarId> \
  --summary "週次定例" \
  --from "2025-01-20T10:00:00+09:00" \
  --to "2025-01-20T11:00:00+09:00" \
  --rrule "RRULE:FREQ=WEEKLY;BYDAY=MO"

# リマインダー付き
gog calendar create <calendarId> \
  --summary "締切: 提案書提出" \
  --from "2025-01-25T17:00:00+09:00" \
  --to "2025-01-25T17:30:00+09:00" \
  --reminder "popup:30m" --reminder "email:1d"
```

### 予定の更新

```bash
gog calendar update <calendarId> <eventId> \
  --summary "【変更】定例MTG" \
  --from "2025-01-20T15:00:00+09:00" \
  --to "2025-01-20T16:00:00+09:00" \
  --send-updates all
```

### 予定の削除

```bash
gog calendar delete <calendarId> <eventId>
```

### 出欠確認

```bash
# 承諾
gog calendar respond <calendarId> <eventId> --status accepted

# 辞退
gog calendar respond <calendarId> <eventId> --status declined

# 仮承諾
gog calendar respond <calendarId> <eventId> --status tentative
```

### 空き時間確認

```bash
# 自分の空き時間
gog calendar freebusy "<calendarId>" \
  --from "2025-01-20T09:00:00+09:00" \
  --to "2025-01-20T18:00:00+09:00" --json

# 複数人の空き時間（カンマ区切り）
gog calendar freebusy "user1@example.com,user2@example.com" \
  --from "2025-01-20T09:00:00+09:00" \
  --to "2025-01-24T18:00:00+09:00" --json

# 予定の競合チェック
gog calendar conflicts --json
```

### 特殊な予定

```bash
# フォーカスタイム
gog calendar focus-time \
  --from "2025-01-20T14:00:00+09:00" \
  --to "2025-01-20T16:00:00+09:00" <calendarId>

# 不在（OOO）
gog calendar out-of-office \
  --from "2025-01-20" \
  --to "2025-01-21" <calendarId>

# 勤務場所
gog calendar working-location \
  --from "2025-01-20" \
  --to "2025-01-21" \
  --type home <calendarId>
```

## RFC3339 日時フォーマット

```
YYYY-MM-DDThh:mm:ss+09:00   # JST
YYYY-MM-DDThh:mm:ssZ         # UTC
YYYY-MM-DD                    # 終日予定用
```

## ワークフロー例

### 1. 今週の予定確認→空き時間でMTG設定

```bash
# Step 1: 今週の予定一覧
gog calendar events --from "2025-01-20T00:00:00+09:00" --to "2025-01-24T23:59:59+09:00" --json

# Step 2: 参加者の空き時間確認
gog calendar freebusy "tanaka@example.com,sato@example.com" \
  --from "2025-01-20T09:00:00+09:00" \
  --to "2025-01-24T18:00:00+09:00" --json

# Step 3: 空き枠にMTG作成
gog calendar create primary \
  --summary "プロジェクト相談" \
  --from "2025-01-22T14:00:00+09:00" \
  --to "2025-01-22T14:30:00+09:00" \
  --attendees "tanaka@example.com,sato@example.com" \
  --with-meet --send-updates all
```

## 注意事項

- `<calendarId>` は `primary`（デフォルト）またはメールアドレス形式
- `--account` で対象Googleアカウントを切り替え可能
- 予定作成・更新・削除は実行前にユーザーに内容を確認する
- `--send-updates all` は参加者に通知が飛ぶので注意

## Cross-references

- **gog-gmail**: カレンダー招待のメール通知・関連メール操作
- **gog-drive**: MTG 関連資料の検索・共有
- **create-minutes**: MTG 予定情報から議事録テンプレートの事前作成
