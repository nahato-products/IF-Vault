# gog-gmail Reference

## gog CLI Gmail コマンド詳細

### search
```bash
gog gmail search <query> [flags]
```
- `--max=10`: 最大件数
- `--page=STRING`: ページトークン
- `--oldest`: 最古のメッセージ日付表示
- `--timezone=STRING`: タイムゾーン（IANA形式）
- `--json`: JSON出力
- `--plain`: TSV出力

### get
```bash
gog gmail get <messageId> [flags]
```
- メッセージ全文取得（full|metadata|raw）

### send
```bash
gog gmail send [flags]
```
- `--to=STRING`: 宛先（カンマ区切り、必須）
- `--cc=STRING`: CC
- `--bcc=STRING`: BCC
- `--subject=STRING`: 件名（必須）
- `--body=STRING`: 本文（プレーンテキスト）
- `--body-file=STRING`: 本文ファイルパス（'-'でstdin）
- `--body-html=STRING`: HTML本文
- `--reply-to-message-id=STRING`: 返信先メッセージID
- `--thread-id=STRING`: スレッドID
- `--reply-all`: 全員に返信
- `--attach=PATH`: 添付ファイル（複数指定可）
- `--from=STRING`: 送信元（verified alias）
- `--force`: 確認スキップ

### drafts
```bash
gog gmail drafts <command> [flags]
```
- `list`: 一覧
- `get <draftId>`: 詳細
- `create`: 作成（sendと同じフラグ、ただし--forceは不要）
- `update <draftId>`: 更新
- `delete <draftId>`: 削除
- `send <draftId>`: 下書き送信

### thread
```bash
gog gmail thread <command>
```
- `get <threadId>`: スレッド取得
- `modify <threadId>`: ラベル変更（`--add-labels`, `--remove-labels`）

### labels
```bash
gog gmail labels <command>
```
- `list`: ラベル一覧

### batch
```bash
gog gmail batch <command>
```
- `archive <query>`: 一括アーカイブ

### attachment
```bash
gog gmail attachment <messageId> <attachmentId>
```

### url
```bash
gog gmail url <threadId> ...
```
- Gmail Web URLを出力

## グローバルフラグ
- `--account=STRING`: 対象アカウント
- `--json`: JSON出力
- `--plain`: TSV出力
- `--force`: 確認スキップ
- `--no-input`: プロンプトなし（CI用）
- `--verbose`: 詳細ログ
