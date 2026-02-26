---
date: 2026-02-20
tags: [Claude Code, オンボーディング, setup, Skills]
status: active
---

# Claude Code セットアップガイド

nahato チーム向けのClaude Code導入・Skills活用ガイド。

## Claude Codeとは

ターミナルで動くAIコーディングアシスタント。ファイル読み書き、Git操作、コード生成をAIが代行してくれる。Skillsを入れると特定分野の知識が自動で適用される。

## 初期セットアップ

### 1. Claude Code インストール

```bash
npm install -g @anthropic-ai/claude-code
```

### 2. チーム環境を一括セットアップ（推奨）

IF-Vault リポジトリのルートで以下を実行するだけ。Hooks・Skills・設定ファイルが全て自動でインストールされる。

```bash
bash team/shared/claude-code-setup/install.sh
```

インストールされるもの:
- **Hooks** (8個): セキュリティ・効率化スクリプト
- **Skills** (24共有 + 3メタ = 27個): チーム共有スキル（シンボリックリンク）
- **settings.json**: 破壊的コマンドの deny list + hooks 登録
- **CLAUDE.md**: グローバル設定テンプレート

セットアップ後にヘルスチェック:

```bash
bash team/shared/claude-code-setup/install.sh --verify
```

### 3. CLAUDE.md をカスタマイズ

`~/.claude/CLAUDE.md` を開いて、自分の口調・スタイル・よく使う技術を追加する。

中身の例:

```markdown
# 基本方針
- 日本語で応対
- コードのコメントは英語

# よく使う技術
- TypeScript / Next.js
- PostgreSQL
- Tailwind CSS
```

### 4. プロジェクトCLAUDE.md

リポジトリのルートに `.claude/CLAUDE.md` を置くと、そのプロジェクト固有の指示ができる。IF-Vaultには既に設定済み。

### 5. コミュニティスキルを追加（任意）

```bash
bash team/shared/claude-code-setup/install.sh --community
```

11個のコミュニティスキル（deep-research, pdf, docx 等）が一括でインストールされる。

## Skillsの使い方

### Skillsとは

特定分野の知識パック。インストールすると、関連する作業をしたときに自動で知識が適用される。UXの原則、セキュリティチェック、DBの設計パターンなどがある。

### ロール別おすすめSkills

install.sh で全スキルが入るが、特に注力すべきスキルはロールによって異なる。

#### 全員必須（Tier 1）

| スキル | 効果 |
|--------|------|
| ux-psychology | UI/UXの認知心理学ベース設計 |
| natural-japanese-writing | AI臭を排除した自然な日本語 |
| ansem-db-patterns | PostgreSQL本番スキーマ設計 |
| typescript-best-practices | 型安全パターンと実装ルール |
| systematic-debugging | 根本原因調査の4段階プロセス |
| error-handling-logging | エラー分類とログ構造化設計 |

#### フロントエンド担当

| スキル | 効果 |
|--------|------|
| react-component-patterns | React合成・CVA・SC/CC設計 |
| tailwind-design-system | Tailwind v4 CSS-first設定 |
| nextjs-app-router-patterns | App Router ルーティング・キャッシュ |
| vercel-react-best-practices | ランタイムパフォーマンス最適化 |
| design-token-system | トークン階層・OKLCH色・ダークモード |
| micro-interaction-patterns | ローディング・トースト・フォームUX |
| web-design-guidelines | WCAG・セマンティックHTML・SEO |
| mobile-first-responsive | LIFF/PWA・モバイルファースト |

#### DB・バックエンド担当

| スキル | 効果 |
|--------|------|
| supabase-auth-patterns | Auth・RLS・セッション管理 |
| supabase-postgres-best-practices | クエリ最適化・接続プール |
| security-review | 脆弱性検出・セキュリティ監査 |
| docker-expert | Docker最適化・Compose・セキュア化 |
| ci-cd-deployment | GitHub Actions・Vercel自動化 |
| testing-strategy | TDD・テスト品質分析フロー |

### 個別にスキルを追加/削除したい場合

install.sh を使わず手動で管理したい場合は、シンボリックリンクを使う。

```bash
# 追加（IF-Vault ルートで実行）
ln -s "$(pwd)/team/shared/skills/スキル名" ~/.claude/skills/スキル名

# 削除
rm ~/.claude/skills/スキル名
```

詳細は `team/shared/skills/README.md` を参照。

### コミュニティスキル（手動インストール）

```bash
# 検索
npx skills find [キーワード]

# インストール（グローバル）
npx skills add <owner/repo@skill> -g -y

# アップデート
npx skills update
```

### 自動発火 vs 手動起動

スキルには2種類ある。

- **自動発火型**: 関連する作業をすると勝手に適用される（例: ux-psychology はUI作業時に自動発火）
- **手動起動型**: コマンドで明示的に呼ぶ（例: `/skill-forge` でSkill管理ツールを起動）

### 無効化したいとき

```bash
# 一時的に無効化（フォルダ名を変える）
mv ~/.claude/skills/ux-psychology ~/.claude/skills/_ux-psychology

# 完全削除
rm ~/.claude/skills/スキル名
```

## 便利な使い方

### Slashコマンド

手動起動型のスキルはスラッシュコマンドで呼べる。

| コマンド | 動作 |
|---------|------|
| `/skill-forge` | Skills作成・検索・評価ツール |
| `/claude-env-optimizer` | 環境ヘルスチェック・メンテナンス |
| `/context-economy` | トークン最適化 |
| `/baseline-ui` | UIの基本チェック |

### ヘルスチェック

```bash
bash team/shared/claude-code-setup/install.sh --verify
```

Skills数・SKILL.md有無・Hooks実行権限・settings.json deny数をチェックする。

## 注意点

- Skillsは毎回コンテキストにロードされるため、入れすぎるとトークン消費が増える
- 重いスキルが同時発火すると応答が遅くなることがある
- シンボリックリンク経由なので `git pull` で全メンバーに最新が反映される
- 機密情報（APIキーなど）はCLAUDE.mdに書かない

## 困ったら

- Skills一覧: `team/shared/skills/README.md`
- セットアップ詳細: `team/shared/claude-code-setup/README.md`
- Skills品質レポート: `team/sekiguchi/notes/Skills-49個スキャンレポート.md`
- 自作Skills詳細: `team/sekiguchi/notes/自作Skills一覧.md`

---

_最終更新: 2026-02-20_
