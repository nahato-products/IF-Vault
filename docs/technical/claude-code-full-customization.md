---
date: 2026-02-20
tags: [Claude Code, カスタマイズ, setup, tmux]
status: active
---

# Claude Code フルカスタマイズ再現ガイド

guchiの環境を再現するための手順書。Boris Cherny氏が提唱した9つのカスタマイズ軸をベースに構築している。

> [!info] 前提
> - macOS + Homebrew 導入済み
> - Claude Code インストール済み（`npm install -g @anthropic-ai/claude-code`）
> - Skills の基本導入は [[claude-code-setup]] を参照

## 9軸カスタマイズ一覧

| # | 軸 | 概要 | 設定場所 |
|---|---|---|---|
| 1 | Effort | 思考深度をHighに固定 | settings.json `env` |
| 2 | Plugins | 公式マーケットプレイス接続 | `/plugin` |
| 3 | LSPs | TypeScript LSP で型解析強化 | settings.json `enabledPlugins` |
| 4 | MCPs | 外部ツール接続（Slack, Notion, Playwright等） | `claude mcp add` |
| 5 | Skills | 25個のスキルパック | `~/.claude/skills/` |
| 6 | Custom Agents | 4体の専門エージェント | `~/.claude/agents/` |
| 7 | Hooks | 7つのライフサイクルhook | settings.json `hooks` |
| 8 | Status Lines | カスタムステータスバー | settings.json `statusLine` |
| 9 | Output Styles | CLAUDE.md でトーン定義 | `~/.claude/CLAUDE.md` |

## 1. Effort — 思考深度の固定

`~/.claude/settings.json` に環境変数を追加。全セッションでHigh思考が有効になる。

```json
{
  "env": {
    "CLAUDE_CODE_EFFORT_LEVEL": "high"
  }
}
```

軽いタスク時は `/model` で一時的に Low に切替可能。

## 2. Plugins — マーケットプレイス

```bash
# Claude Code 内で実行
/plugin
```

公式マーケットプレイスが自動接続される。ここからLSP、MCP、スキル等をインストールできる。

## 3. LSPs — TypeScript 言語サーバー

TypeScript/JavaScript の型解析・定義ジャンプ・参照検索が有効になる。

```bash
# 言語サーバーのインストール
npm install -g typescript-language-server typescript

# 確認
typescript-language-server --version
```

`settings.json` でプラグインを有効化:

```json
{
  "enabledPlugins": {
    "typescript-lsp@claude-plugins-official": true
  }
}
```

対応拡張子: `.ts` `.tsx` `.js` `.jsx` `.mts` `.cts` `.mjs` `.cjs`

## 4. MCPs — 外部ツール接続

現在接続中のMCPサーバー:

| MCP | 用途 |
|-----|------|
| Slack | メッセージ送受信、チャンネル検索 |
| Notion | ページ作成・検索・更新 |
| Playwright | ブラウザ自動操作・E2Eテスト |
| Pencil | .pen ファイルのデザイン編集 |
| token-guardian | トークン消費の最適化 |
| context7 | ライブラリドキュメント参照 |
| eslint | コードリント |
| shadcn | UIコンポーネント |

MCPの追加:

```bash
claude mcp add <server-name> -- <command>
```

## 5. Skills — 知識パック（25個）

### 導入済みスキル一覧

**Web開発コア**
- `nextjs-app-router-patterns` — Next.js 15/16 App Router
- `react-component-patterns` — React コンポーネント設計
- `tailwind-design-system` — Tailwind CSS v4
- `typescript-best-practices`（※ 外部スキル）

**UI/UX**
- `baseline-ui` — UI制約チェック
- `ux-psychology` — UX心理学原則
- `micro-interaction-patterns` — アニメーション
- `design-token-system` — デザイントークン
- `lazy-user-ux-review` — UXスコアリング
- `mobile-first-responsive` — モバイルファースト
- `web-design-guidelines` — WCAG 2.2

**バックエンド/DB**
- `supabase-auth-patterns` — Supabase Auth + RLS
- `supabase-postgres-best-practices`（※ 外部スキル）
- `error-handling-logging` — エラーハンドリング
- `vercel-ai-sdk` — AI SDK統合

**インフラ/CI**
- `ci-cd-deployment` — GitHub Actions + Vercel
- `docker-expert` — Docker最適化
- `testing-strategy` — テスト戦略
- `dashboard-data-viz` — ダッシュボード構築

**品質/セキュリティ**
- `seo` — SEO最適化
- `web-quality-audit` — パフォーマンス監査

**ツール系**
- `skill-forge` — スキル作成・管理（`/skill-forge`）
- `context-economy` — トークン最適化（`/context-economy`）
- `claude-env-optimizer` — 環境診断（`/claude-env-optimizer`）
- `obsidian-power-user` — Obsidian自動化
- `natural-japanese-writing` — 日本語文章品質
- `line-bot-dev` — LINE Bot開発

### インストール方法

```bash
# 外部スキル（npx経由）
npx skills add <owner/repo@skill-name> -g -y

# チーム共有スキル（シンボリックリンク）
ln -s /path/to/IF-Vault/team/shared/skills/<name> ~/.claude/skills/<name>
```

## 6. Custom Agents — 専門エージェント（4体）

| エージェント | 用途 |
|-------------|------|
| `db-analyzer` | DB分析・クエリ最適化 |
| `gas-expert` | Google Apps Script開発 |
| `obsidian-automator` | Obsidian自動化 |
| `team-collaborator` | チーム協業支援 |

エージェントファイルは `~/.claude/agents/` に `.json` 形式で配置。

```bash
# 起動方法
claude --agent db-analyzer

# セッション内で一覧確認
/agents
```

デフォルトエージェントを固定するなら:

```json
{
  "agent": "db-analyzer"
}
```

## 7. Hooks — ライフサイクル介入（7つ）

| イベント | hook | 動作 |
|----------|------|------|
| PreToolUse (Read) | `block-sensitive-read.sh` | `.env` 等の機密ファイル読み取りをブロック |
| PreToolUse (Read) | `token-guardian-warn.sh` | 大きいファイル読み取り時にトークン警告 |
| PreCompact | `session-compact-restore.sh` | Compact時にセッション状態を保存 |
| PostToolUse (Edit/Write) | `security-post-edit.sh` | 編集後に機密情報混入チェック |
| Stop | `session-stop-summary.sh` | セッション終了時にサマリー保存 |
| PostToolUseFailure | `tool-failure-logger.sh` | ツール失敗をログ記録 |
| Notification | `notification.sh` | macOS通知を送信 |
| UserPromptSubmit | `skill-usage-logger.sh` | スキル使用状況を記録 |

hookスクリプトは `~/.claude/hooks/` に配置。`settings.json` の `hooks` セクションで紐付け。

新しいhookの追加はClaudeに依頼するのが手っ取り早い:
> 「ファイル編集後にprettierを自動実行するhookを追加して」

## 8. Status Lines — ステータスバー

`~/.claude/hooks/statusline.sh` が呼ばれ、コンポーザー下部に情報を表示。

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/hooks/statusline.sh"
  }
}
```

初回セットアップは `/statusline` で自動生成もできる。

## 9. Output Styles — 応答トーン

`~/.claude/CLAUDE.md` でトーンを定義:

```markdown
## Identity
- 日本語で応対。ギャルっぽいカジュアルな口調、絵文字適度に使う
```

`/config` から組み込みスタイル（explanatory, learning等）も選択可能。

## Permissions — 安全設定

### Allow（許可）

```json
"allow": [
  "mcp__pencil__*",
  "mcp__token-guardian__*",
  "Write(~/.claude/skills/**)",
  "Edit(~/.claude/skills/**)"
]
```

### Deny（拒否）

```json
"deny": [
  "Bash(rm -rf:*)",
  "Bash(git push --force:*)",
  "Bash(git reset --hard:*)",
  "Bash(git clean -fd:*)",
  "Bash(git checkout .:*)",
  "Bash(git restore .:*)"
]
```

設定は `settings.json`（User scope）と `settings.local.json`（Local scope）の2層で管理。Localは個人のプロジェクト固有の許可（git操作、brew等）を入れる。

## tmux 並列開発環境

複数のClaude Codeセッションを同時に動かすための環境。

### インストール

```bash
brew install tmux
```

### 設定 — `~/.tmux.conf`

```bash
# prefix を Ctrl+a に変更
# マウス操作有効
# | で縦分割、- で横分割
# vim キーバインド（h/j/k/l）でペイン移動
# 256色サポート
# 新規ペイン/ウィンドウでカレントディレクトリ引き継ぎ
# ヒストリ10000行
```

### 並列ランチャー — `~/.claude/scripts/claude-parallel.sh`

```bash
# 2ペイン（デフォルト）
clp

# 3ペイン
clp 3

# 名前付きウィンドウ
clp backend frontend
```

エイリアスを `~/.zshrc` に追加:

```bash
alias clp='~/.claude/scripts/claude-parallel.sh'
```

### tmux 操作チートシート

| 操作 | キー |
|------|------|
| prefix | `Ctrl+a` |
| 縦分割 | `prefix` → `\|` |
| 横分割 | `prefix` → `-` |
| ペイン移動 | `prefix` → `h/j/k/l` |
| ペインリサイズ | `prefix` → `H/J/K/L` |
| セッション一覧 | `tmux ls` |
| デタッチ | `prefix` → `d` |
| アタッチ | `tmux attach -t <name>` |

## 実践小技集

日常的に使える便利テクニック。

### AskUserQuestion で選択肢入力

CLAUDE.md に以下を記載すると、判断を求める場面でクリック式の選択肢が提示される。テキスト入力の手間が減る。

```markdown
- ユーザーに選択・判断を求める場合はAskUserQuestionツールを使うこと
```

### Prompt suggestions（タブ補完）

入力エディタでプロンプトを提案してくれる。`tab` で採用。

```json
{ "promptSuggestionEnabled": true }
```

### md ファイル出力で回答品質を上げる

レビューや分析の出力先をmdファイルにすると、見出し・構造化が促され情報量が増える。

```markdown
# CLAUDE.md に追記
- レビュー・分析等の長文出力は `~/.claude/tmp/` にmdファイルとして保存
```

`~/.claude/tmp/` はgit管理外にしておく。

### カスタムスラッシュコマンドのサブディレクトリ管理

```
~/.claude/commands/
├── dev/
│   └── scaffold.md      # /dev:scaffold — ページ/コンポーネント生成
├── review/
│   ├── code.md           # /review:code — コードレビュー
│   └── pr.md             # /review:pr — PRレビュー
└── ops/
    └── health.md         # /ops:health — 環境ヘルスチェック
```

`/review:` まで入力すると配下のコマンドがサジェストされる。組み込みコマンドとの命名衝突も避けられる。

### ディレクトリ迷子防止

Bashでcd移動した後に作業ディレクトリがずれる問題を防ぐ。

```json
{
  "env": {
    "CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR": "1"
  }
}
```

### キーボードショートカット

| キー | 動作 |
|------|------|
| `Shift+Tab` | Planモード切替 |
| `Ctrl+G` | Planの結果を外部エディタで編集 |
| `Ctrl+S` | プロンプトの一時保存（Stash） |
| `Ctrl+O` | Verbose output 一時表示 |
| `!command` | エディタ内でシェルコマンド直接実行 |
| `/add-dir path` | プロジェクト外ディレクトリを作業対象に追加 |

### /statusline でコンテキスト監視

コンテキスト使用率が閾値を超えると自動要約（Compact）が走り文脈が失われるため、監視が重要。設定済み（`~/.claude/hooks/statusline.sh`）。

## 再現手順（まとめ）

新しいMacで環境を再現するときの手順:

1. Claude Code インストール（`npm install -g @anthropic-ai/claude-code`）
2. `~/.claude/CLAUDE.md` を作成
3. `~/.claude/settings.json` をコピー（env, permissions, hooks, statusLine, enabledPlugins）
4. `~/.claude/hooks/` 配下のスクリプトをコピー
5. `~/.claude/agents/` 配下のエージェント定義をコピー
6. Skills をインストール（`npx skills add` or シンボリックリンク）
7. MCPサーバーを追加（`claude mcp add`）
8. TypeScript LSP をインストール（`npm install -g typescript-language-server typescript`）
9. tmux 環境構築（`brew install tmux` + `.tmux.conf` + `claude-parallel.sh`）
10. `/terminal-setup` 実行（Shift+Enter改行対応）
11. `~/.claude/commands/` のコマンドテンプレートをコピー
12. `~/.claude/tmp/` ディレクトリを作成

## 関連ノート

- [[claude-code-setup]] — 初期セットアップ + Skills導入ガイド
- [[オンボーディング-Slack共有まとめ]]

---

_最終更新: 2026-02-20_
