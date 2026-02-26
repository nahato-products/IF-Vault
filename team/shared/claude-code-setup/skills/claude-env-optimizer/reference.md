# claude-env-optimizer Reference

> **注意**: 本リファレンスの具体的なファイル名・数値・スキル構成は参考例。実際の環境に合わせて読み替えること。実際のスキル一覧は `ls ~/.claude/skills/`、hook一覧は `~/.claude/settings.json` の hooks セクションを参照。

## Skills カテゴリマップ
Symlinkは `~/.agents/skills/` からのリンク（外部管理、アップデートで上書きされる可能性あり）。

### Skills カテゴリ（8分類）

| カテゴリ | 内容 | 例 |
|---------|------|-----|
| Next.js/React | フロントエンド基盤 | nextjs-app-router-patterns, react-component-patterns |
| UI/デザイン | デザインシステム・UX | tailwind-design-system, micro-interaction-patterns |
| バックエンド/DB | 認証・データベース | supabase-auth-patterns, ansem-db-patterns |
| 品質/セキュリティ | テスト・エラー処理 | testing-strategy, error-handling-logging |
| DevOps/Git | CI/CD・コンテナ | ci-cd-deployment, docker-expert |
| ドメイン特化 | 特定技術・ツール | line-bot-dev, obsidian-power-user |
| ドキュメント処理 | ファイル変換 | pdf, docx, xlsx |
| メタ/ユーティリティ | スキル管理・環境管理 | skill-forge, context-economy |

### Tier 分類基準

| Tier | 基準 |
|------|------|
| S | 毎日使うコアスキル |
| A | 週数回使う重要スキル |
| B | 月数回の専門スキル |
| C | 必要時のみのツール系 |


---

## コスト分析

### スキルdescriptionのトークンコスト
- 全スキルのdescription → システムリマインダーとして**毎回ロード**
- スキル数が増えるほどコストが増加。定期的に `/context-economy` で確認推奨

### 削除についての方針
スキル削除は慎重に。各スキルは固有の役割を持ち、「重複に見えても実は別物」というケースが多い。
- `baseline-ui` ≠ `web-design-guidelines`（Tailwind特化チェッカー vs フレームワーク非依存リファレンス）
- `fixing-accessibility` ≠ `web-design-guidelines`（即座レビュアー vs 学習資料）
- `find-skills` ≠ `skill-forge`（ユーザー向け検索 vs 開発者向け作成ツール）
- 削除前に必ず「置き換え先が同じ機能を本当にカバーするか」を検証すること

---

## Hook 仕様リファレンス

### Hook の type 種別

| type | 動作 | 用途 |
|------|------|------|
| `"command"` | シェルスクリプトを実行。stdin でJSON受信、stdout でJSON返却 | 外部処理（ファイル操作、ログ等） |
| `"prompt"` | インラインプロンプトとしてClaudeのコンテキストに注入 | 軽量な指示追加・リマインダー |
| `"agent"` | サブエージェントを起動して処理を委譲 | 複雑な自律的タスク |

> 本環境の実装済みhookは全て `"command"` タイプ。

### 実装済み

| イベント | matcher | スクリプト | JSON出力形式 |
|---------|---------|-----------|-------------|
| PreToolUse | Read | token-guardian-warn.sh | hookSpecificOutput + additionalContext |
| PreCompact | (all) | session-compact-restore.sh | hookSpecificOutput (仕様未記載、防御的)。matcher値: `"manual"`(ユーザー起動) / `"auto"`(システム起動) |
| PostToolUse | Edit\|Write | security-post-edit.sh | hookSpecificOutput + additionalContext |
| Stop | (all) | session-stop-summary.sh | **JSON出力なし** (stderr + ファイル + 4機能: Git通知/debug/ローテ/session-env掃除/settings自動クリーン) |
| PostToolUseFailure | (all) | tool-failure-logger.sh | hookSpecificOutput + additionalContext |
| Notification | (all) | notification.sh | hookSpecificOutput + additionalContext |

### Stop hook の仕様制約
- `additionalContext` **非サポート**
- `decision: "block"` → Claudeが**続行してしまう**（停止をブロック）
- 情報提供のみの場合 → stderr + ファイル書き出しが唯一の手段

### Stop hook の4機能
1. **Git未コミットチェック** — staged/unstaged/untrackedを検出、session-env/uncommitted-changes.mdに記録、stderrで通知
2. **debug/ ログローテーション** — 3日超の.txtファイルを自動削除
3. **session-env/ 空ディレクトリ掃除** — 空サブディレクトリを削除
4. **settings.local.json 自動クリーンアップ** — 拡充badリストに該当 or 100文字超のエントリを除去
   - badプレフィックス:
     - `bash:` — セッション固有の許可が蓄積して肥大化の原因になるため
     - `dd:`, `echo:`, `python3:`, `python:` — 一時的なワンライナー実行の許可が残留するため
     - `npx:` — パッケージ実行の許可がバージョン違いで無意味になるため
     - `chmod:`, `open:`, `ln:` — ファイル操作の許可がパス固有で再利用されないため
     - `for `, `do `, `done`, `if `, `then`, `fi)` — シェルスクリプト断片が許可リストに混入したゴミ

### JSON出力テンプレート

**PreToolUse（ブロックしない情報提供）:**
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "メッセージ"
  }
}
```

**PreToolUse（ツール使用を拒否）:**
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "理由"
  }
}
```

**PostToolUse / PostToolUseFailure:**
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "メッセージ"
  }
}
```

### stdin JSON スキーマ（主要フィールド）

**全イベント共通:**
```json
{
  "session_id": "abc123",
  "cwd": "/current/working/directory",
  "hook_event_name": "PreToolUse"
}
```

**ツール系イベント追加フィールド:**
- `tool_name`: ツール名
- `tool_input`: ツールへの入力
- `tool_use_id`: ツール使用ID

**PostToolUseFailure 固有:**
- `error`: エラーメッセージ（※ `tool_error` ではない）
- `is_interrupt`: 中断フラグ

---

### Hook スクリプトのテスト

イベント別にstdinをシミュレートして動作確認:

```bash
# PreToolUse (Read)
echo '{"tool_name":"Read","tool_input":{"file_path":"/tmp/test.txt"}}' | bash ~/.claude/hooks/block-sensitive-read.sh

# PostToolUse (Edit)
echo '{"tool_name":"Edit","tool_input":{"file_path":"src/app.tsx"},"tool_output":"success"}' | bash ~/.claude/hooks/security-post-edit.sh

# PostToolUseFailure
echo '{"tool_name":"Bash","error":"command not found","is_interrupt":false}' | bash ~/.claude/hooks/tool-failure-logger.sh

# Stop
bash ~/.claude/hooks/session-stop-summary.sh
```

期待出力の検証: hookが正常なら空出力（何も出さない）。問題検出時はJSON出力（`{"hookSpecificOutput":...}`）。`echo $?` で終了コードも確認。

## 不採用 Hook と理由

| イベント | 不採用理由 |
|---------|-----------|
| SessionStart | PreCompactの保存で代替可能 |
| SessionEnd | Stopで十分カバー |
| PermissionRequest | settings.local.jsonの許可リストで運用済み |
| UserPromptSubmit | 過剰介入のリスク |
| SubagentStart | ユースケースが薄い |
| SubagentStop | ユースケースが薄い |
| TeammateIdle | ユースケースが薄い |
| TaskCompleted | ユースケースが薄い |
| Setup | CLI初期化時のみ発火（--init, --maintenance）。日常運用では不要 |

---

## ディスク容量チェック（health モード）

health モードでは `du -sh ~/.claude/` でディレクトリ全体のサイズを確認。肥大化の主な原因: `debug/` ログ蓄積、`session-env/` 残留ファイル、`settings.local.json` の許可リスト膨張。

## ファイル配置マップ

```
~/.claude/
├── CLAUDE.md                  # グローバル指示
├── config.json                # Claude Code 内部設定
├── settings.json              # permissions + hooks
├── settings.local.json        # 自動蓄積許可（Stop hookで定期クリーンアップ）
├── history.jsonl              # セッション履歴（自動生成）
├── hooks/                     # 実際の内容は settings.json の hooks セクションを参照
│   └── (登録済みhookスクリプト)
├── session-env/
│   ├── compact-state.md           # Compaction時の状態保存
│   └── uncommitted-changes.md     # Stop時の未コミット変更
├── debug/
│   └── tool-failures.jsonl        # ツール失敗ログ
├── scripts/                   # ユーザー定義スクリプト
├── skills/                    # 全スキル（ls で確認）
│   └── claude-env-optimizer/      # 本スキル
└── [system dirs]              # cache/, plans/, tasks/, telemetry/ 等（Claude Code自動生成）
```
