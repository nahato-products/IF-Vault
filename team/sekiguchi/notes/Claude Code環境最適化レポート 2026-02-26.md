---
created: 2026-02-26
tags: [claude-code, 環境設定, エージェント, 自動化]
status: completed
---

# Claude Code 環境最適化レポート 2026-02-26

## 概要

エージェント管理の全面強化と自動化パイプラインの構築。スキル管理と完全対称な仕組みをエージェントにも適用し、Boris Cherny（Claude Code 生みの親）の知見も取り込んだ。

---

## 1. エージェント体制の整備

### 新規追加
- `backend-builder`（sonnet）— Server Actions / API Route / Supabase CRUD 専門
- `test-engineer`（sonnet）— Vitest / Testing Library / Playwright 専門

### 全面改修
- `team-collaborator` → Notion ドキュメント管理・議事録特化に刷新（v2.0）

### 品質統一
全 10 エージェントの `description` に **"Use when" / "Do not trigger"** を追加。
`audit_agent.py` によるスコアリングで **全員 100/100** を達成。

| エージェント | model | 用途 |
|---|---|---|
| code-reviewer | opus | 4パスコードレビュー |
| db-analyzer | opus | ER図・SQL最適化 |
| gas-expert | opus | Google Apps Script |
| frontend-builder | sonnet | Next.js UI実装 |
| backend-builder | sonnet | Server Actions / Supabase |
| test-engineer | sonnet | Vitest / Playwright |
| description-writer | sonnet | 広告説明文CSV生成 |
| headline-writer | sonnet | 広告見出しCSV生成 |
| obsidian-automator | sonnet | Obsidianテンプレート管理 |
| team-collaborator | sonnet | Notion議事録・進捗レポート |

---

## 2. エージェント自動化パイプライン

スキル管理と完全対称な仕組みを構築。

```
発見
  agent-discovery.py（SessionStart・24h毎）
  → GitHub コミュニティリポジトリをスキャン
  → agent-queue.md に候補を自動追記

取り込み
  agent-importer スキル（vetting 付き自動取り込み）
  → セキュリティ vetting（8点チェック）
  → 品質スコアリング（100点満点）
  → 最適化（isolation/model/日本語化）

品質監視
  agent-audit-check.py（SessionStart）
  → 全エージェントを毎回スキャン
  → 70点未満を通知

使用追跡
  agent-usage-tracker.py（PostToolUse/Task）
  → agent-usage.jsonl に記録

ランク管理
  update-agent-ranks.py（SessionStart）
  → N → N-C → N-B → N-A → N-S
  → 30日未使用はパーキング候補通知

チーム同期
  agent-sync.py（PostToolUse/Edit|Write）
  → team-claude-skills/agents/ に自動 git commit
```

### 新規フック一覧（6本追加）

| フック | タイミング | 役割 |
|---|---|---|
| `lessons-recorder.py` | UserPromptSubmit | 修正キーワード検知 → lessons.md 記録指示 |
| `agent-audit-check.py` | SessionStart | 全エージェント品質チェック |
| `agent-usage-tracker.py` | PostToolUse(Task) | 使用頻度を jsonl に記録 |
| `update-agent-ranks.py` | SessionStart | ランク計算・昇格通知 |
| `agent-discovery.py` | SessionStart | GitHub 新着スキャン |
| `agent-sync.py` | PostToolUse(Edit|Write) | team-claude-skills に自動同期 |

---

## 3. Boris Cherny 式自己改善ループ

Claude Code の生みの親 Boris Cherny 氏の CLAUDE.md 知見を導入。

- ユーザーから修正・指摘を受けたら `tasks/lessons.md` にパターンを記録
- SessionStart でその内容をコンテキストに自動注入
- 同じミスを繰り返さないループが完成

**CLAUDE.md 追記箇所:**
```
- **Lessons記録**: ユーザーから修正を受けたら tasks/lessons.md に
  パターンを記録 → 同じミスを繰り返さないルールを自分で書く
```

---

## 4. team-claude-skills 更新

チームメンバーが `git pull && ./setup.sh` するだけで同じ環境を構築できるように更新。

- `agents/` ディレクトリ追加（全 10 エージェント）
- `hooks/` ディレクトリ追加（エージェント自動化 6 本）
- `custom-skills/agent-importer/` 追加
- `scripts/patch-settings.py` 追加（settings.json を安全にマージ）
- `setup.sh` にエージェント・フック・settings 更新セクションを追加

---

## 5. SessionStart の流れ（8段階）

```
preset → skill-ranks → workflow-audit → env-orchestrator
  → agent-audit → agent-ranks → agent-discovery → session-start-context
```

---

## 6. 環境全体レビュー（200点化対応）

### 発見した問題と修正

環境全体の品質診断を実施し、5件の問題を修正した。

| # | ファイル | 問題 | 修正 |
|---|---|---|---|
| 1 | `generate-skill-combos.py` | `/Users/sekiguchiyuki/` 絶対パスがハードコード | `Path.home()` + フォールバックに変更 |
| 2 | `_skill_utils.py` | `AGENTS_DIR` が guchi 専用の `~/.agents/skills/` 固定 | `~/.agents/skills/` → `~/.claude/skills/` フォールバック追加 |
| 3 | `agent-audit-check.py` | 同上（他メンバーで ImportError になりフックがスキップされる） | フォールバック付きパス解決に変更 |
| 4 | `patch-settings.py` | 6フックのみ登録していた | 全27フック・11イベント対応に拡張 |
| 5 | `team-claude-skills/hooks/` | 6本しか配布されていなかった | 全35本を追加 |

### 修正後の team-claude-skills 構成

```
hooks/     35本（全フック）
agents/    10体（全エージェント）
scripts/
  patch-settings.py  → 全27フック・11イベントを settings.json に登録
setup.sh   → git pull && ./setup.sh で完全同環境を再現
```

### 診断チェック結果

| チェック項目 | 結果 |
|---|---|
| エージェント品質スコア（10体） | 全員 100/100 ✅ |
| エージェントセキュリティ vetting | CRITICAL 問題なし ✅ |
| settings.json フック登録（27本） | 全件登録済み ✅ |
| ハードコードパス | 修正済み ✅ |
| team-claude-skills 同期 | 完全同期 ✅ |

---

## 関連リンク

- team-claude-skills: https://github.com/zenntouyou-yabai/team-claude-skills
- 参考: Boris Cherny の CLAUDE.md 解説（Zenn）
