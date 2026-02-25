# Claude Code チーム環境セットアップ

nahato-Inc チーム共通の Claude Code 環境設定。

## クイックスタート

```bash
# IF-Vault リポジトリのルートから実行
bash team/shared/claude-code-setup/install.sh
```

確認プロンプトが出るので `y` で続行。既存ファイルは上書きしない（差分がある hooks のみバックアップ＆更新）。

### コマンド一覧

| コマンド | 説明 |
|---------|------|
| `bash install.sh` | フルインストール（全52スキル + hooks + settings） |
| `bash install.sh -y` | 確認プロンプトをスキップ（CI・自動実行向け） |
| `bash install.sh --dry-run` | 実際には変更せず内容をプレビュー |
| `bash install.sh --list` | 利用可能なスキル一覧（インストール済み状態も表示） |
| `bash install.sh --verify` | ヘルスチェック（スキル数・hooks・settings を確認） |
| `bash install.sh --skill=スキル名` | 指定スキルだけ追加（既存はスキップ） |
| `bash install.sh --update=スキル名` | 指定スキルを強制上書き更新 |
| `bash install.sh --community` | コミュニティスキル11個を一括インストール |
| `bash install.sh --help` | ヘルプ表示 |

### 使い方の例

```bash
# 初回セットアップ（推奨）
bash team/shared/claude-code-setup/install.sh

# CI や自動実行（確認スキップ）
bash team/shared/claude-code-setup/install.sh -y

# 何がインストールされるか事前確認
bash team/shared/claude-code-setup/install.sh --dry-run

# インストール済みスキルの一覧確認
bash team/shared/claude-code-setup/install.sh --list

# ヘルスチェック
bash team/shared/claude-code-setup/install.sh --verify

# playwright だけ追加
bash team/shared/claude-code-setup/install.sh --skill=playwright

# deep-research を最新版に更新
bash team/shared/claude-code-setup/install.sh --update=deep-research

# コミュニティスキル追加
bash team/shared/claude-code-setup/install.sh --community
```

### Claude に読ませて使う場合

install.sh を Claude に読ませて「`--skill=playwright` で playwright だけ入れて」と伝えるだけで個別インストールできます。

### ロール別クイックスタート

インストール時にロールを選択すると、推奨スキルが表示される。

| ロール | 説明 | 重点スキル |
|--------|------|-----------|
| 全員共通 | 全スキルをインストール | Tier 1〜4 全部 |
| フロントエンド | UI/UX・React・デザイン系を優先表示 | react-component-patterns, tailwind-design-system, design-token-system 等 |
| バックエンド | DB・API・インフラ系を優先表示 | supabase-postgres-best-practices, docker-expert 等 |

※ どのロールでも全スキルがインストールされる。推奨表示は参考情報。

---

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

### Skills（52個）

**フロントエンド / UI（13個）**

| スキル | 用途 |
|--------|------|
| baseline-ui | Tailwind/Radix UI アンチパターン防止 |
| design-brief | UI実装前のデザインブリーフ強制 |
| design-token-system | Tailwind v4 デザイントークン設計 |
| micro-interaction-patterns | Framer Motion マイクロインタラクション |
| mobile-first-responsive | LIFF/PWA モバイルファースト実装 |
| nextjs-app-router-patterns | Next.js 15/16 App Router パターン |
| react-component-patterns | React コンポーネント設計パターン |
| style-reference-db | デザインスタイル参照プリセット |
| tailwind-design-system | Tailwind CSS v4 設定・移行 |
| ux-psychology | UX心理学原則（Nielsen/Gestalt等） |
| vercel-ai-sdk | Vercel AI SDK AI機能実装 |
| vercel-react-best-practices | Core Web Vitals / バンドル最適化 |
| web-design-guidelines | WCAG 2.2 / セマンティックHTML |

**バックエンド / DB（8個）**

| スキル | 用途 |
|--------|------|
| api-design-patterns | RESTful API 設計・OpenAPI |
| ansem-db-patterns | ANSEM プロジェクト DB 設計パターン |
| docker-expert | Dockerfile / docker-compose 最適化 |
| error-handling-logging | エラー境界・構造化ログ・Sentry |
| observability | OpenTelemetry / SLI/SLO 計装 |
| supabase-auth-patterns | Supabase Auth + RLS 認証設計 |
| supabase-postgres-best-practices | Postgres パフォーマンス最適化 |
| typescript-best-practices | 高度な TypeScript パターン |

**品質 / テスト / セキュリティ（9個）**

| スキル | 用途 |
|--------|------|
| code-refactoring | リファクタリング・SOLID原則適用 |
| code-review | 多段階コードレビュー |
| playwright | ブラウザ自動化・UI テスト ※1 |
| security-arsenal | Red/Blue セキュリティ操作 |
| security-best-practices | OWASP Top 10 防御実装 |
| security-review | 脆弱性検出・トリアージ |
| security-threat-model | 脅威モデル作成 |
| systematic-debugging | 根本原因デバッグ |
| testing-strategy | Vitest / Playwright テスト戦略 |

**開発効率 / CI（8個）**

| スキル | 用途 |
|--------|------|
| brainstorming | 機能設計・要件整理の壁打ち |
| ci-cd-deployment | GitHub Actions / Vercel CI/CD |
| claude-env-optimizer | Claude Code 環境診断・最適化 |
| cognitive-load-optimizer | 認知負荷低減・フロー維持 |
| context-economy | トークン消費最適化 |
| duckdb-csv | CSV を SQL で分析 |
| skill-forge | スキル作成・評価・最適化 |
| skill-loader | 非アクティブスキルのオンデマンド復元 |

**SEO / マーケ（2個）**

| スキル | 用途 |
|--------|------|
| lazy-user-ux-review | 最も怠惰なユーザー視点 UI/UX スコアリング |
| seo | 技術的 SEO・構造化データ |

**議事録 / ドキュメント（6個）**

| スキル | 用途 |
|--------|------|
| create-minutes | Notion 議事録テンプレ自動生成 |
| fill-external-minutes | 社外向け議事録生成 |
| notion-pdf | Notion ページ PDF 変換 |
| share-minutes | 議事録 PDF → メール添付 |
| transcribe-and-update | 録音 → 既存議事録更新 |
| transcribe-to-minutes | 録音 → 新規議事録作成 |

**コンテンツ / 特化（6個）**

| スキル | 用途 |
|--------|------|
| chrome-extension-dev | Chrome 拡張機能開発 |
| dashboard-data-viz | KPI ダッシュボード・TanStack Table |
| deep-research | Gemini 使用の深掘りリサーチ ※2 |
| line-bot-dev | LINE Bot / LIFF 開発 |
| natural-japanese-writing | AI 文体を排除した自然な日本語 |
| obsidian-power-user | Obsidian Vault 構築・自動化 |

> ※1 **playwright**: Playwright のインストールが必要（`npx playwright install`）
> ※2 **deep-research**: `skills/deep-research/.env` に `GEMINI_API_KEY` の設定が必要

### コミュニティスキル（11個・`--community` でインストール）

`--community` フラグで npx 経由で一括インストール:

baseline-ui, deep-research, docx, ffmpeg, find-skills, finishing-a-development-branch, mermaid-visualizer, pdf, pptx, xlsx, using-git-worktrees

### CLAUDE.md テンプレート

`~/.claude/CLAUDE.md` が存在しない場合のみインストール。チーム共通のベースルール（日本語応対、セキュリティ、Git運用）を含む。**インストール後に自分の好みにカスタマイズすること。**

---

## 安全性・既存環境への影響

### install.sh の上書き防止設計

| 対象 | 既存がある場合の動作 |
|------|---------------------|
| Skills（ディレクトリ or シンボリックリンク） | **スキップ**（上書きしない） |
| Hooks | 差分チェック → 差分あれば `.bak` バックアップ後に上書き |
| settings.json | Python マージで deny 追加のみ。既存 allow は保持 |
| CLAUDE.md | **スキップ**（上書きしない） |

### v1.0.0 リリース時の新規スキル（31個）が既存環境に与える影響

v1.0.0 では既存の 19 スキルに**一切変更を加えていない**（git diff で確認済み）。新スキルは全て追加のみ。

- **名前の競合なし**: 31 個の新スキル名は全て既存スキルと異なる
- **既存スキルへの変更なし**: v0 からの既存 19 スキルのファイルは無変更
- **install.sh はスキップ設計**: すでにスキルをインストール済みのメンバーが再実行しても、既存スキルは上書きされず新スキルのみ追加される
- **settings.json の deny list**: 新スキルに関連する deny 追加はなし。既存設定に変化なし

### 実行ファイルを含むスキル

以下のスキルはスクリプトを含むが、Claude が明示的に呼び出した場合にのみ実行される。自動起動や副作用はない。

| スキル | ファイル | 備考 |
|--------|---------|------|
| playwright | `scripts/playwright_cli.sh` | Playwright インストール済み環境が必要 |
| systematic-debugging | `find-polluter.sh` | git bisect ヘルパー。git 環境のみで動作 |
| deep-research | `scripts/research.py` | Gemini API キーが必要（`.env` に設定） |

---

## セットアップ後にやること

1. `~/.claude/CLAUDE.md` を開いて、自分の口調・スタイルを追加
2. Claude Code を再起動（`claude` コマンドを再実行）
3. `bash install.sh --verify` でヘルスチェック
4. `bash install.sh --community` でコミュニティスキルをインストール
5. deep-research を使う場合は `~/.claude/skills/deep-research/.env` に Gemini API キーを設定（`.env.example` を参照）

---

## ディレクトリ構成

```
~/.claude/
├── CLAUDE.md                  # 個人設定（テンプレートから作成）
├── settings.json              # hooks + deny list
├── hooks/                     # 8スクリプト
├── skills/                    # 50+ スキル
├── session-env/               # セッション状態保存
└── debug/                     # デバッグログ
```

---

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

---

## 更新方法

### Git参加者

```bash
git pull
```

シンボリックリンク経由なので `git pull` だけで全メンバーの共有スキルが更新される。再リンク不要。

hooks に更新がある場合は再度 `install.sh` を実行すれば差分のみ更新。既存の skills や CLAUDE.md は上書きされない。

### スタンドアロン版利用者

Git参加者に新しいzipをもらい、再度 `bash install.sh` を実行。既存の skills・CLAUDE.md は上書きされないため、hooks と settings.json の差分のみ反映される。

---

## リリース履歴

| バージョン | 日付 | スキル数 | 主な変更 |
|-----------|------|---------|---------|
| v1.0.0 | 2026-02-25 | 52個 | 31スキル追加（セキュリティ・議事録・品質系を大幅拡充）。ansem-db-patterns・chrome-extension-dev 追加。スタンドアロン配布対応 |
| v0 | 2026-02 | 19個 | 初期リリース |
