# Claude Code チーム環境セットアップ

nahato-Inc チーム共通の Claude Code 環境設定。

## クイックスタート

```bash
# IF-Vault リポジトリのルートから実行
bash team/shared/claude-code-setup/install.sh
```

確認プロンプトが出るので `y` で続行。既存ファイルは上書きしない（差分がある hooks のみバックアップ＆更新）。

### オプション

```bash
# ヘルスチェック（インストール後の検証）
bash team/shared/claude-code-setup/install.sh --verify

# コミュニティスキル一括インストール
bash team/shared/claude-code-setup/install.sh --community

# 両方同時
bash team/shared/claude-code-setup/install.sh --verify --community
```

### ロール別クイックスタート

インストール時にロールを選択すると、推奨スキルが表示される。

| ロール | 説明 | 重点スキル |
|--------|------|-----------|
| 全員共通 | 全27スキルをインストール | Tier 1〜4 全部 |
| フロントエンド | UI/UX・React・デザイン系を優先表示 | react-component-patterns, tailwind-design-system, design-token-system 等 |
| バックエンド | DB・API・インフラ系を優先表示 | ansem-db-patterns, supabase-postgres-best-practices, docker-expert 等 |

※ どのロールでも全スキルがインストールされる。推奨表示は参考情報。

## 何がインストールされるか

### Hooks（8スクリプト）

| スクリプト | イベント | 機能 |
|-----------|---------|------|
| block-sensitive-read.sh | PreToolUse (Read) | .env/.pem/.key 等の読み取りをブロック |
| token-guardian-warn.sh | PreToolUse (Read) | 6KB超ファイルの読み取りで警告 |
| session-compact-restore.sh | PreCompact | コンテキスト圧縮前に作業状態を保存 |
| security-post-edit.sh | PostToolUse (Edit/Write) | 編集後に機密情報パターンを検出 |
| session-stop-summary.sh | Stop | 未コミット変更の通知 + settings.local.json 自動クリーン |
| tool-failure-logger.sh | PostToolUseFailure | ツール連続失敗を検出・記録 |
| notification.sh | Notification | macOS 通知で確認要求を即座に察知 |
| statusline.sh | StatusLine | git branch + 変更数 + 作業ディレクトリを常時表示 |

### Deny List（7エントリ）

settings.json に登録される破壊的コマンドのブロックリスト:

- `rm -rf` / `git push --force` / `git push -f`
- `git reset --hard` / `git clean -fd`
- `git checkout .` / `git restore .`

### Skills（24個 共有 + 3個 メタ = 27個）

`team/shared/skills/` の 24 スキルを **シンボリックリンク** で `~/.claude/skills/` にインストール。加えてメタスキル 3 個（claude-env-optimizer, context-economy, skill-forge）をリンク。

一覧:

**共有スキル (24個):** ansem-db-patterns, chrome-extension-dev, ci-cd-deployment, dashboard-data-viz, design-token-system, docker-expert, error-handling-logging, line-bot-dev, micro-interaction-patterns, mobile-first-responsive, natural-japanese-writing, nextjs-app-router-patterns, obsidian-power-user, react-component-patterns, security-review, supabase-auth-patterns, supabase-postgres-best-practices, systematic-debugging, tailwind-design-system, testing-strategy, typescript-best-practices, ux-psychology, vercel-react-best-practices, web-design-guidelines

**メタスキル (3個):** claude-env-optimizer, context-economy, skill-forge

### コミュニティスキル（11個・`--community` でインストール）

`--community` フラグで npx 経由で一括インストール:

baseline-ui, deep-research, docx, ffmpeg, find-skills, finishing-a-development-branch, mermaid-visualizer, pdf, pptx, xlsx, using-git-worktrees

### CLAUDE.md テンプレート

`~/.claude/CLAUDE.md` が存在しない場合のみインストール。チーム共通のベースルール（日本語応対、セキュリティ、Git運用）を含む。**インストール後に自分の好みにカスタマイズすること。**

## 安全性

install.sh は既存環境を壊さない設計。

| 対象 | 既存がある場合の動作 |
|------|---------------------|
| Skills（ディレクトリ or シンボリックリンク） | **スキップ**（上書きしない） |
| Hooks | 差分チェック → 差分あれば `.bak` バックアップ後に上書き |
| settings.json | Python マージで deny 追加のみ。既存 allow は保持 |
| CLAUDE.md | **スキップ**（上書きしない） |

`--verify` / `--community` はオプション引数。デフォルト動作は変わらない。

## セットアップ後にやること

1. `~/.claude/CLAUDE.md` を開いて、自分の口調・スタイルを追加
2. Claude Code を再起動（`claude` コマンドを再実行）
3. `bash install.sh --verify` でヘルスチェック
4. `bash install.sh --community` でコミュニティスキルをインストール

## ディレクトリ構成

```
~/.claude/
├── CLAUDE.md                  # 個人設定（テンプレートから作成）
├── settings.json              # hooks + deny list
├── hooks/                     # 8スクリプト
├── skills/                    # 27+ スキル（共有24 + メタ3 + コミュニティ）
├── session-env/               # セッション状態保存
└── debug/                     # デバッグログ
```

## Git非参加者への配布（スタンドアロン版）

Git リポジトリにアクセスできないメンバーにも、同じ環境を配布できる。

### 配布フロー

```
① Git参加者がビルド
  $ bash team/shared/claude-code-setup/build-package.sh 1.0.0
  → dist/claude-code-setup-v1.0.0.zip 生成

② zip を配布（Slack / Google Drive / AirDrop 等）

③ 受取側が実行
  $ unzip claude-code-setup-v1.0.0.zip
  $ cd claude-code-setup-v1.0.0
  $ bash install.sh
```

### Git版との違い

| 項目 | Git版 (install.sh) | スタンドアロン版 |
|------|-------------------|-----------------|
| Skills 配置方式 | シンボリックリンク（リポに追従） | コピー（独立） |
| スキル更新 | `git pull` で自動 | 新しいzipで再インストール |
| 前提条件 | IF-Vault clone 済み | Claude Code のみ |
| 対象 | Git参加メンバー | 外部メンバー・一時利用者 |

### バージョン指定

```bash
# バージョン番号を指定（推奨）
bash build-package.sh 1.0.0

# 省略すると日付が使われる（例: 20260221）
bash build-package.sh
```

生成された zip には `VERSION` ファイルが含まれ、ビルド日時・スキル数が記録される。

### ヘルスチェック・コミュニティスキル

スタンドアロン版でも同じオプションが使える:

```bash
bash install.sh --verify      # ヘルスチェック
bash install.sh --community   # コミュニティスキル追加
```

## 更新方法

### Git参加者

```bash
git pull
```

シンボリックリンク経由なので `git pull` だけで全メンバーの共有スキルが更新される。再リンク不要。

hooks に更新がある場合は再度 `install.sh` を実行すれば差分のみ更新。既存の skills や CLAUDE.md は上書きされない。

### スタンドアロン版利用者

Git参加者に新しいzipをもらい、再度 `bash install.sh` を実行。既存の skills・CLAUDE.md は上書きされないため、hooks と settings.json の差分のみ反映される。
