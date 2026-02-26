---
date: 2026-02-26
tags: [Claude Code, オンボーディング, setup, Skills]
status: active
---

# Claude Code セットアップガイド

nahato チーム向けの Claude Code 導入・環境構築ガイド。

## Claude Code とは

ターミナルで動く AI コーディングアシスタント。ファイル読み書き・Git 操作・コード生成を AI が代行する。Skills を入れると特定分野の知識が自動で適用され、エージェントに委譲すれば複雑なタスクを並列実行できる。

## 初期セットアップ

### 1. Claude Code インストール

```bash
npm install -g @anthropic-ai/claude-code
```

### 2. チーム環境を一括セットアップ（推奨）

```bash
git clone https://github.com/zenntouyou-yabai/team-claude-skills
cd team-claude-skills
./setup.sh
```

カテゴリごとに Y/n で選択しながら進む。インストールされるもの:

| 種別 | 数 | 内容 |
|---|---|---|
| **Skills** | 164個 | 開発・セキュリティ・UI・マーケ・議事録 等 |
| **エージェント** | 10体 | タスク専門 AI（code-reviewer / frontend-builder 等）|
| **フック** | 35本 | 安全ガード・自動化・品質監視 |
| **settings.json** | — | 全フック（27本・11イベント）を自動登録 |

### 3. CLAUDE.md をカスタマイズ

`~/.claude/CLAUDE.md` を開いて自分の口調・スタイル・よく使う技術を追加する。

```markdown
# 基本方針
- 日本語で応対
- コードのコメントは英語

# よく使う技術
- TypeScript / Next.js
- PostgreSQL / Supabase
- Tailwind CSS v4
```

### 4. プロジェクト CLAUDE.md

リポジトリのルートに `.claude/CLAUDE.md` を置くとプロジェクト固有の指示ができる。IF-Vault には既に設定済み。

## Skills の使い方

### Skills とは

特定分野の知識パック。関連する作業をすると自動で適用（自動発火型）か、`/スキル名` で明示的に呼び出す（手動起動型）。

### ロール別おすすめ Skills

#### 全員必須

| スキル | 効果 |
|--------|------|
| `ux-psychology` | UI/UX の認知心理学ベース設計 |
| `natural-japanese-writing` | AI 臭を排除した自然な日本語 |
| `systematic-debugging` | 根本原因調査の4段階プロセス |
| `typescript-best-practices` | 型安全パターンと実装ルール |
| `ansem-db-patterns` | PostgreSQL 本番スキーマ設計 |
| `error-handling-logging` | エラー分類とログ構造化設計 |

#### フロントエンド担当

| スキル | 効果 |
|--------|------|
| `react-component-patterns` | React 合成・CVA・SC/CC 設計 |
| `tailwind-design-system` | Tailwind v4 CSS-first 設定 |
| `nextjs-app-router-patterns` | App Router ルーティング・キャッシュ |
| `vercel-react-best-practices` | ランタイムパフォーマンス最適化 |
| `design-token-system` | トークン階層・OKLCH 色・ダークモード |
| `mobile-first-responsive` | LIFF/PWA・モバイルファースト |

#### DB・バックエンド担当

| スキル | 効果 |
|--------|------|
| `supabase-postgres-best-practices` | クエリ最適化・接続プール |
| `supabase-auth-patterns` | Auth・RLS・セッション管理 |
| `security-review` | 脆弱性検出・セキュリティ監査 |
| `backend-builder`（エージェント） | Server Actions / Supabase CRUD の実装委譲 |

### 主なスラッシュコマンド

| コマンド | 動作 |
|---------|------|
| `/skill-forge` | Skills 作成・評価ツール |
| `/agent-importer` | コミュニティエージェントの取り込み |
| `/code-review` | コードレビュー |
| `/context-economy` | トークン最適化 |
| `/claude-env-optimizer` | 環境ヘルスチェック |

### スキルの無効化

```bash
# 一時的に無効化
mv ~/.claude/skills/スキル名 ~/.claude/skills/_スキル名

# 完全削除
rm ~/.claude/skills/スキル名
```

## エージェントの使い方

複雑なタスクは専門エージェントに委譲できる。指示するだけで worktree 分離された環境で自動実行される。

| エージェント | モデル | 担当 |
|---|---|---|
| `code-reviewer` | Opus | 4パスコードレビュー |
| `frontend-builder` | Sonnet | Next.js UI 実装 |
| `backend-builder` | Sonnet | Server Actions / Supabase |
| `test-engineer` | Sonnet | Vitest / Playwright |
| `db-analyzer` | Opus | ER図・SQL 最適化 |
| `team-collaborator` | Sonnet | Notion 議事録・進捗レポート |

## 自動で動くフック（主なもの）

普通に使っているだけで裏側が動く。

| フック | タイミング | 効果 |
|---|---|---|
| `command-shield` | コマンド実行前 | `rm -rf` 等を 🔴 表示で警告 |
| `security-post-edit` | ファイル保存後 | 機密情報・脆弱性を自動スキャン |
| `lint-on-edit` | ファイル保存後 | ESLint 自動実行 |
| `session-start-context` | セッション開始時 | 前回の状態・Git 差分を自動注入 |
| `agent-audit-check` | セッション開始時 | 全エージェントの品質スコアを監視 |
| `lessons-recorder` | 修正指摘時 | パターンを記録して同じミスを防ぐ |

## 環境を最新に保つ

```bash
cd team-claude-skills
git pull && ./setup.sh
```

## 困ったら

- 環境全体レポート: `team/sekiguchi/notes/Claude Code環境最適化レポート 2026-02-26.md`
- Skills カタログ: `team/sekiguchi/notes/Claude-Code-Skills-カタログ.md`
- リポジトリ: https://github.com/zenntouyou-yabai/team-claude-skills

---

_最終更新: 2026-02-26_
