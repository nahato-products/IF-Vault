---
date: 2026-02-14
tags: [Claude Code, オンボーディング, setup, Skills]
status: active
---

# Claude Code セットアップガイド

nahato チーム向けのClaude Code導入・Skills活用ガイド。

## Claude Codeとは

ターミナルで動くAIコーディングアシスタント。ファイル読み書き、Git操作、コード生成をAIが代行してくれる。Skillsを入れると特定分野の知識が自動で適用される。

## 初期セットアップ

### 1. インストール

```bash
npm install -g @anthropic-ai/claude-code
```

### 2. CLAUDE.mdを作る

自分のホームディレクトリに設定ファイルを作る。Claude Codeはこのファイルを読んで応答をカスタマイズする。

```bash
mkdir -p ~/.claude
touch ~/.claude/CLAUDE.md
```

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

### 3. プロジェクトCLAUDE.md

リポジトリのルートに `.claude/CLAUDE.md` を置くと、そのプロジェクト固有の指示ができる。IF-Vaultには既に設定済み。

## Skillsの使い方

### Skillsとは

特定分野の知識パック。インストールすると、関連する作業をしたときに自動で知識が適用される。UXの原則、セキュリティチェック、DBの設計パターンなどがある。

### インストール方法

```bash
# 検索
npx skills find [キーワード]

# インストール（グローバル）
npx skills add <owner/repo@skill> -g -y

# アップデート確認
npx skills check

# 全スキルアップデート
npx skills update
```

### おすすめSkillsセット

チームで使うと効果が高いもの。

#### 全員向け

| スキル | 効果 | インストール |
|--------|------|------------|
| security-review | コードの脆弱性チェック | `npx skills add getsentry/sentry-agent-skills@security-review -g -y` |
| typescript-best-practices | TypeScriptの型安全パターン | `npx skills add 0xbigboss/claude-code@typescript-best-practices -g -y` |
| git-advanced-workflows | Git操作のベストプラクティス | `npx skills add wshobson/agents@git-advanced-workflows -g -y` |

#### フロントエンド担当

| スキル | 効果 |
|--------|------|
| vercel-react-best-practices | React/Next.jsパフォーマンス最適化 |
| tailwind-design-system | Tailwind CSSデザインシステム |
| web-design-guidelines | WCAG 2.2アクセシビリティ準拠 |

#### DB・バックエンド担当

| スキル | 効果 |
|--------|------|
| supabase-postgres-best-practices | PostgreSQLの最適化34ルール |
| ansem-db-patterns | ANSEM設計パターン（チーム独自） |
| api-design-principles | REST/GraphQL API設計原則 |

### チーム共有Skills

`team/shared/skills/` にチーム共有スキルが置いてある。シンボリックリンクで自分の環境に反映する。

```bash
# UX心理学スキル（UI作業で自動発火）
ln -s /path/to/IF-Vault/team/shared/skills/ux-psychology ~/.claude/skills/ux-psychology

# 日本語文書品質スキル（日本語ドキュメント執筆で自動発火）
ln -s /path/to/IF-Vault/team/shared/skills/natural-japanese-writing ~/.claude/skills/natural-japanese-writing
```

`/path/to/IF-Vault` は自分の環境のパスに置き換えること。

### 自動発火 vs 手動起動

スキルには2種類ある。

- **自動発火型**: 関連する作業をすると勝手に適用される（例: ux-psychology はUI作業時に自動発火）
- **手動起動型**: コマンドで明示的に呼ぶ（例: `/skill-forge` でSkill管理ツールを起動）

### 無効化したいとき

```bash
# 一時的に無効化（フォルダ名を変える）
mv ~/.claude/skills/ux-psychology ~/.claude/skills/_ux-psychology

# 完全削除
npx skills remove ux-psychology -g
```

## 便利な使い方

### Slashコマンド

手動起動型のスキルはスラッシュコマンドで呼べる。

| コマンド | 動作 |
|---------|------|
| `/skill-forge` | Skills作成・検索・評価ツール |
| `/baseline-ui` | UIの基本チェック |
| `/fixing-accessibility` | アクセシビリティ修正 |

### ヘルスチェック

インストール済みSkillsの状態を一括チェックするスクリプトがある。

```bash
bash team/guchi/code-snippets/skills-health-check.sh
```

## 注意点

- Skillsは毎回コンテキストにロードされるため、入れすぎるとトークン消費が増える
- 重いスキルが同時発火すると応答が遅くなることがある
- 外部リポジトリ製のスキルは `npx skills update` で最新に保つ
- 機密情報（APIキーなど）はCLAUDE.mdに書かない

## 困ったら

- guchiのSkills一覧: `team/guchi/notes/Claude-Code-Skills一覧.md`
- Skills品質レポート: `team/guchi/notes/Skills-49個スキャンレポート.md`
- 自作Skills詳細: `team/guchi/notes/自作Skills一覧.md`

---

_最終更新: 2026-02-14_
