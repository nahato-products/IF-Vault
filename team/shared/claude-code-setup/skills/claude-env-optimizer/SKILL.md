---
name: claude-env-optimizer
description: "Claude Code environment maintenance: hooks audit, skills inventory, health check, session management"
user-invocable: true
---

# claude-env-optimizer

Claude Code 環境のメンテナンス統合スキル。
`/claude-env-optimizer` で起動後、モードを選択して実行する。

## Modes

ユーザーが `/claude-env-optimizer` を起動した時、以下の4モードから選択させる:

### Mode 1: `hooks` — Hooks診断

登録済みHookとスクリプトの整合性を診断する。

**手順:**
1. `~/.claude/settings.json` の `hooks` セクションを読み取る
2. `~/.claude/hooks/` ディレクトリのスクリプトを列挙
3. 各スクリプトの `chmod +x` 状態を確認
4. settings.json登録済み vs 実ファイルの整合性チェック
5. 利用可能な全イベントから未実装hookを提案

**チェック項目:**
- [ ] settings.jsonに登録されたパスに実ファイルが存在するか
- [ ] スクリプトに実行権限があるか
- [ ] matcherのパターンは正しいか
- [ ] 不要になったhookスクリプトが残っていないか

**出力フォーマット:**
```
## Hooks診断結果

### 登録済み (N本)
| イベント | matcher | スクリプト | 状態 |
|---------|---------|-----------|------|
| PreToolUse | Read | token-guardian-warn.sh | ✅ |
| ...

### 未登録スクリプト
- (あれば表示)

### 未実装イベント
- SessionStart: (提案/不採用理由)
- ...
```

**Hookのtype種別:**
- `"command"` — シェルスクリプト実行（stdin/stdout JSON）
- `"prompt"` — インラインプロンプト注入
- `"agent"` — サブエージェント起動

**利用可能な全Hookイベント:**
PreToolUse, PostToolUse, PreCompact, Stop, PostToolUseFailure, SessionStart, SessionEnd, Notification, SubagentStart, SubagentStop, UserPromptSubmit, PermissionRequest, TeammateIdle, TaskCompleted, Setup

### Mode 2: `skills` — Skills棚卸し

全スキルをTier/カテゴリで一覧表示し、ヘルスチェックする。

**手順:**
1. `~/.claude/skills/` を再帰的にスキャン
2. 各SKILL.mdのfrontmatter読み取り
3. Tier/カテゴリ分類に基づいて一覧表示
4. ヘルスチェック実行

**Tier分類（reference.mdのマスターデータを参照）:**
- **S** 毎日使うコアスキル
- **A** 週数回使う重要スキル
- **B** 月数回の専門スキル
- **C** 必要時のみのツール系

**ヘルスチェック項目:**
- [ ] SKILL.md が500行を超えていないか（肥大化警告）
- [ ] frontmatter（description, user-invocable）が正しいか
- [ ] symlinkの場合、リンク先が生きているか
- [ ] reference.md が存在するか（任意だが推奨）
- [ ] skillsフォルダ直下に迷子ファイルがないか

**出力フォーマット:**
```
## Skills棚卸し結果

### Tier S — コア (N個)
| スキル | カテゴリ | 行数 | ref | 状態 |
|--------|---------|------|-----|------|
| nextjs-app-router-patterns | Frontend | 320 | ✅ | ✅ |
| ...

### Tier A — 重要 (N個)
...

### ヘルスチェック結果
- ⚠️ XXX: SKILL.md が520行（500行超過）
- ✅ 全スキルのfrontmatter正常
```

### Mode 3: `health` — 環境ヘルスチェック

Claude Code環境全体の健全性を診断する。

**チェック項目:**

1. **MCP Servers**
   - `~/.claude.json` の mcpServers セクションを読み取り、各サーバーの command パスが存在するか、依存パッケージ（npx対象のnpmパッケージ等）がインストール済みかを確認
   - 各サーバーのパス（command/args）が存在するか
   - node_modules等の依存が揃っているか

2. **Settings**
   - `~/.claude/settings.json` のJSON構文チェック
   - `~/.claude/settings.local.json` の存在と構文チェック
   - settings.local.json の許可リスト肥大化チェック（for断片等のゴミ蓄積）
   - permissions/hooksの整合性チェック

3. **CLAUDE.md**
   - `~/.claude/CLAUDE.md` の最終更新日
   - 内容の行数（肥大化チェック）

4. **一時ファイル・ディスク容量**
   - `du -sh ~/.claude/` で全体サイズ確認（100MB超は要整理）
   - `~/.claude/debug/` のファイルサイズ確認
   - `~/.claude/session-env/` の古い状態ファイル
   - `~/.claude/` 直下の不要ファイル

**出力フォーマット:**
```
## 環境ヘルスチェック結果

### MCP Servers
| サーバー | パス | 状態 |
|---------|------|------|
| pencil | ~/.antigravity/.../mcp-server | ✅ |
| ...

### Settings
- settings.json: ✅ 正常 (24行)
- settings.local.json: ✅ 正常

### CLAUDE.md
- 最終更新: 2026-02-10
- 行数: 45行 ✅

### 一時ファイル
- debug/tool-failures.jsonl: 2.3KB ✅
- session-env/compact-state.md: 0.5KB ✅
```

### Mode 4: `session` — セッション管理

現在のセッション状態と過去の障害パターンを表示する。

**手順:**
1. `~/.claude/session-env/compact-state.md` の最新状態を表示
2. `~/.claude/session-env/uncommitted-changes.md` の未コミット変更を表示
3. `~/.claude/debug/tool-failures.jsonl` の失敗パターンを分析
4. 頻出失敗ツールのTop5を表示
5. トークン効率化の詳細は `context-economy` スキルへ誘導

**出力フォーマット:**
```
## セッション状態

### 最新Compact State
- 保存日時: 2026-02-18 15:30:00
- 作業ディレクトリ: /Users/sekiguchiyuki/projects/xxx
- Git Branch: feature/yyy

### ツール失敗分析 (直近100件)
| ツール | 失敗回数 | 最頻エラー |
|--------|---------|-----------|
| Bash | 12 | timeout |
| ...

### 連続失敗パターン
- (検出されたパターンがあれば表示)

💡 トークン効率化の詳細は `/context-economy` を使ってね！
```

## 呼び出し方法

```
/claude-env-optimizer          → モード選択画面を表示
/claude-env-optimizer hooks    → 直接 hooks 診断モードへ
/claude-env-optimizer skills   → 直接 skills 棚卸しモードへ
/claude-env-optimizer health   → 直接 環境ヘルスチェックへ
/claude-env-optimizer session  → 直接 セッション管理モードへ
```

## Cross-references

- **context-economy**: トークン効率化に特化。このスキルとは補完関係
- **skill-forge**: スキル作成・レビュー・最適化に特化
- **find-skills**: コミュニティスキルの検索・インストール

## Decision Matrix

```
環境メンテしたい
├─ Hookが動いてるか確認 → /claude-env-optimizer hooks
├─ スキル一覧を見たい → /claude-env-optimizer skills
├─ 環境全体の健全性チェック → /claude-env-optimizer health
├─ セッション状態を確認 → /claude-env-optimizer session
├─ トークン節約したい → /context-economy
└─ 新しいスキルを作りたい → /skill-forge
```
