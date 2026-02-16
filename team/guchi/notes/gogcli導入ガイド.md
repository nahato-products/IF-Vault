---
date: 2026-02-12
tags: [tool, google-workspace, claude-code, setup, gogcli]
status: todo
---

# gogcli 導入ガイド

> [!NOTE]
> gogcli（`gog`）は、ターミナルからGoogle Workspace（Gmail・カレンダー・ドライブ・スプレッドシート等）を操作するCLIツール。
> Claude Codeと組み合わせることで、自然言語でGoogle Workspaceを操作できるようになる。

---

## 現状

- [x] `gog` CLIインストール済み（v0.9.0 / Homebrew）
- [ ] Google Cloud APIの有効化
- [ ] OAuth認証設定
- [ ] `gog auth login` で認証
- [ ] Claude Code用スキル定義

---

## Step 1: Google Cloud APIの有効化

### 使用プロジェクト

候補:

| PROJECT_ID | NAME | 備考 |
|-----------|------|------|
| `nahato-if-div` | NAHATO-IF-Div | ANSEM関連。これが自然？ |
| `eighth-road-481010-h9` | My First Project | |
| `gen-lang-client-0674325955` | Default Gemini Project | |
| `tm-databeat` | tm-databeat | |

### 有効化するAPI（6つ）

```bash
# プロジェクトを設定（使うプロジェクトIDに変更）
gcloud config set project nahato-if-div

# APIを有効化
gcloud services enable gmail.googleapis.com
gcloud services enable calendar-json.googleapis.com
gcloud services enable drive.googleapis.com
gcloud services enable sheets.googleapis.com
gcloud services enable docs.googleapis.com
gcloud services enable people.googleapis.com
```

### 確認コマンド

```bash
gcloud services list --enabled --filter="name:(gmail OR calendar OR drive OR sheets OR docs OR people)"
```

---

## Step 2: OAuthクライアントIDの作成

### 方法A: Google Cloud Console（GUI）

1. [Google Cloud Console](https://console.cloud.google.com/) を開く
2. 「APIとサービス」→「認証情報」
3. 「認証情報を作成」→「OAuthクライアントID」
4. アプリケーションの種類: **デスクトップアプリ**
5. 名前: `gogcli`（任意）
6. 作成後、JSONファイルをダウンロード

### 方法B: gcloudコマンド（CLI）

```bash
# OAuth同意画面の設定（初回のみ）
# ※ これはConsoleでやった方が楽。内部利用なら「Internal」を選択

# クライアントID作成
gcloud auth application-default login \
  --scopes=https://www.googleapis.com/auth/gmail.modify,\
https://www.googleapis.com/auth/calendar,\
https://www.googleapis.com/auth/drive,\
https://www.googleapis.com/auth/spreadsheets,\
https://www.googleapis.com/auth/documents
```

### JSONファイルの配置

```bash
# ダウンロードしたJSONを配置
mkdir -p ~/.config/gog
mv ~/Downloads/client_secret_XXXXX.json ~/.config/gog/credentials.json
```

> [!WARNING]
> `credentials.json` は **絶対にGitにコミットしない**こと！

---

## Step 3: gog 認証

```bash
# 初回ログイン（ブラウザが開く）
gog auth login
```

- ブラウザでGoogleアカウントにログイン
- 権限を許可
- 認証トークンがローカルに保存される

### 認証確認

```bash
# 認証状態の確認
gog auth status
```

---

## Step 4: 動作確認

```bash
# Gmail: 最新メール5件
gog gmail list --max 5

# カレンダー: 今日の予定
gog calendar list --today

# ドライブ: ファイル一覧
gog drive list --max 10

# スプレッドシート: データ取得
gog sheets get <SPREADSHEET_ID> 'Sheet1!A1:Z10'
```

---

## Step 5: Claude Code スキル定義

### スキルファイルの作成

```bash
mkdir -p ~/.claude/skills/gogcli
```

`~/.claude/skills/gogcli/SKILL.md` に以下を記述:

````markdown
---
name: gogcli
description: >
  Google Workspace CLIツール(gog)を使ってGoogleサービスにアクセスする。
  スプレッドシートの読み書き、Gmail検索・送信、カレンダー確認、
  Googleドライブ操作、ドキュメント操作など。
  「メール検索して」「今日の予定は？」「スプシ読んで」などで発動。
---

# gogcli スキル

## 概要
`gog` コマンドでGoogle Workspaceを操作する。

## コマンド体系

### Gmail
```bash
gog gmail list [--max N] [--query "検索クエリ"]   # メール一覧
gog gmail read <MESSAGE_ID>                        # メール詳細
gog gmail send --to "xxx@yyy.com" --subject "件名" --body "本文"  # メール送信
```

### Calendar
```bash
gog calendar list [--today] [--days N]    # 予定一覧
gog calendar add --title "件名" --start "2026-02-12T10:00:00" --end "2026-02-12T11:00:00"  # 予定追加
```

### Drive
```bash
gog drive list [--max N] [--query "検索"]  # ファイル一覧
gog drive download <FILE_ID> -o <PATH>     # ダウンロード
gog drive upload <PATH>                    # アップロード
```

### Sheets
```bash
gog sheets get <SPREADSHEET_ID> 'シート名!A1:Z100'          # データ取得
gog sheets get <SPREADSHEET_ID> 'シート名!A1:Z100' --json   # JSON形式で取得
gog sheets update <SPREADSHEET_ID> 'シート名!A1' --values '[["a","b"],["c","d"]]'  # 書き込み
```

## GoogleのURLからIDを抽出するルール
- スプレッドシート: `https://docs.google.com/spreadsheets/d/{SPREADSHEET_ID}/...`
- ドキュメント: `https://docs.google.com/document/d/{DOCUMENT_ID}/...`
- ドライブ: `https://drive.google.com/file/d/{FILE_ID}/...`

URLが渡された場合は、上記パターンからIDを抽出して使用する。

## 出力形式
- デフォルト: テーブル形式（人間向け）
- `--json`: JSON形式（プログラム処理向け）
- `--plain`: TSV形式（パイプ処理向け）
````

### スキルの確認

Claude Codeを再起動後、以下で確認:
- 「今日の予定教えて」→ カレンダー参照
- 「○○で検索してメール探して」→ Gmail検索
- 「このスプシ読んで: https://docs.google.com/...」→ Sheets読み取り

---

## トラブルシューティング

| 症状 | 対処 |
|------|------|
| `gog auth login` でエラー | credentials.json の配置パスを確認 |
| API呼び出しで403 | Google CloudでAPIが有効化されているか確認 |
| スコープ不足エラー | `gog auth login` を再実行して権限を追加 |
| レート制限 | しばらく待ってリトライ（通常は問題にならない） |

---

## 参考リンク

- [gogcli 使い方まとめ（note）](https://note.com/immmmmmmu/n/n32e5bb25fba6)
- [Claude Code開発環境整備ログ（スキル定義の例）](https://log.eurekapu.com/dev-tools-and-workflow-2026-02-01/)
- [Claude Plugin Hub - gogcli-spec](https://www.claudepluginhub.com/plugins/biwakonbu-gogcli-spec-plugins-gogcli-spec)
- [gogcliの導入方法と活用例（note）](https://note.com/dify_base/n/n299a05149747)

---

## 料金

**基本無料**。Google Workspace APIは無料枠が大きく、個人〜チーム利用で課金されることはまずない。

| API | 無料枠 |
|-----|-------|
| Gmail | 1日250リクエスト |
| Calendar | 1日100万リクエスト |
| Drive | 1日10億リクエスト |
| Sheets | 1分あたり60リクエスト |

---

_作成: 2026-02-12_
_ステータス: セットアップ途中（Step 1から再開）_
