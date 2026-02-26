# gog-calendar Reference

## gog CLI Calendar コマンド詳細

### calendars
```bash
gog calendar calendars [flags]
```
カレンダー一覧を表示。

### events (list)
```bash
gog calendar events [<calendarId>] [flags]
```
- `--from=STRING`: 開始日時（RFC3339）
- `--to=STRING`: 終了日時（RFC3339）
- `--json` / `--plain`: 出力形式

### event (get)
```bash
gog calendar event <calendarId> <eventId>
```

### create
```bash
gog calendar create <calendarId> [flags]
```
- `--summary=STRING`: タイトル
- `--from=STRING`: 開始日時（RFC3339）
- `--to=STRING`: 終了日時（RFC3339）
- `--description=STRING`: 説明
- `--location=STRING`: 場所
- `--attendees=STRING`: 参加者（カンマ区切り）
- `--all-day`: 終日予定
- `--rrule=STRING`: 繰り返しルール（RRULE形式）
- `--reminder=STRING`: リマインダー（method:duration、複数可、最大5）
- `--event-color=STRING`: イベント色（1-11）
- `--visibility=STRING`: default/public/private/confidential
- `--transparency=STRING`: busy(opaque)/free(transparent)
- `--send-updates=STRING`: 通知: all/externalOnly/none
- `--with-meet`: Google Meet自動作成
- `--guests-can-invite`: ゲスト招待許可
- `--guests-can-modify`: ゲスト変更許可
- `--attachment=URL`: 添付URL
- `--event-type=STRING`: default/focus-time/out-of-office/working-location

### update
```bash
gog calendar update <calendarId> <eventId> [flags]
```
createと同じフラグが使える。

### delete
```bash
gog calendar delete <calendarId> <eventId> [flags]
```

### respond
```bash
gog calendar respond <calendarId> <eventId> [flags]
```
- `--status=STRING`: accepted/declined/tentative

### freebusy
```bash
gog calendar freebusy <calendarIds> [flags]
```
- `--from=STRING`: 開始日時
- `--to=STRING`: 終了日時
- カンマ区切りで複数カレンダー指定可

### conflicts
```bash
gog calendar conflicts [flags]
```

### search
```bash
gog calendar search <query> [flags]
```

### focus-time / out-of-office / working-location
```bash
gog calendar focus-time --from=STRING --to=STRING [<calendarId>]
gog calendar out-of-office --from=STRING --to=STRING [<calendarId>]
gog calendar working-location --from=STRING --to=STRING --type=STRING [<calendarId>]
```
- working-location の `--type`: home/office/custom

### team
```bash
gog calendar team <group-email> [flags]
```
Google Groupメンバー全員の予定を表示。

### users
```bash
gog calendar users [flags]
```
Workspaceユーザー一覧。

## グローバルフラグ
- `--account=STRING`: 対象アカウント
- `--json` / `--plain`: 出力形式
- `--force`: 確認スキップ
- `--no-input`: プロンプトなし
