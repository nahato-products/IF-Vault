# gog-drive Reference

## gog CLI Drive コマンド詳細

### ls
```bash
gog drive ls [flags]
```
- `--parent=STRING`: 親フォルダID
- `--json` / `--plain`: 出力形式

### search
```bash
gog drive search <query> ... [flags]
```
- 全文検索。複数キーワード対応。

### get
```bash
gog drive get <fileId>
```
ファイルメタデータ取得。

### download
```bash
gog drive download <fileId> [flags]
```
- `--out=STRING`: 出力先パス
- `--format=STRING`: エクスポート形式（pdf/csv/xlsx/pptx/txt/png/docx）

### upload
```bash
gog drive upload <localPath> [flags]
```
- `--name=STRING`: ファイル名上書き
- `--parent=STRING`: アップロード先フォルダID

### copy
```bash
gog drive copy <fileId> <name> [flags]
```
- `--parent=STRING`: コピー先フォルダID

### mkdir
```bash
gog drive mkdir <name> [flags]
```
- `--parent=STRING`: 親フォルダID

### delete
```bash
gog drive delete <fileId>
```
ゴミ箱へ移動。

### move
```bash
gog drive move <fileId> [flags]
```
- `--parent=STRING`: 移動先フォルダID

### rename
```bash
gog drive rename <fileId> <newName>
```

### share
```bash
gog drive share <fileId> [flags]
```
- `--email=STRING`: 共有先メール
- `--role=STRING`: reader/writer/commenter/owner
- `--type=STRING`: user/group/domain/anyone

### unshare
```bash
gog drive unshare <fileId> <permissionId>
```

### permissions
```bash
gog drive permissions <fileId> [flags]
```

### url
```bash
gog drive url <fileId> ...
```

### comments
```bash
gog drive comments list <fileId> [flags]
gog drive comments create <fileId> [flags]
```
- `--content=STRING`: コメント内容

### drives
```bash
gog drive drives [flags]
```
共有ドライブ一覧。

## グローバルフラグ
- `--account=STRING`: 対象アカウント
- `--json` / `--plain`: 出力形式
- `--force`: 確認スキップ
- `--no-input`: プロンプトなし
- `--verbose`: 詳細ログ
