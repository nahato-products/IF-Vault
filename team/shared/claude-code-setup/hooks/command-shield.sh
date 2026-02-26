#!/bin/bash
# command-shield.sh — PreToolUse hook for Bash commands
# Classifies commands into risk levels and injects additionalContext labels
# 🟢 safe: read-only, no side effects
# 🟡 review: modifiable but reversible
# 🔴 destructive: irreversible or high-impact

set -euo pipefail

input=$(cat)

# Extract tool_name and command
tool_name=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)
if [ "$tool_name" != "Bash" ]; then
  exit 0
fi

command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
if [ -z "$command" ]; then
  exit 0
fi

# Get the first token (base command) — handle pipes/chains by checking full string
base_cmd=$(printf '%s' "$command" | awk '{print $1}')

# --- Risk classification (priority order: destructive > review > safe) ---

risk=""
label=""
reason=""

# 🔴 Destructive patterns (shared module)
source "$(dirname "$0")/_destructive-patterns.sh"
classify_destructive "$command"

if [ -n "$DESTRUCTIVE_LABEL" ]; then
  risk="🔴 destructive"
  label="$DESTRUCTIVE_LABEL"
  reason="$DESTRUCTIVE_REASON"

# 🟡 Review patterns (modifiable but generally reversible)
elif printf '%s' "$command" | grep -qE 'git\s+add'; then
  risk="🟡 review"
  label="git add"
  reason="ステージング変更 — git reset で戻せる"
elif printf '%s' "$command" | grep -qE 'git\s+commit'; then
  risk="🟡 review"
  label="git commit"
  reason="コミット作成 — git reset HEAD~ で戻せる"
elif printf '%s' "$command" | grep -qE 'git\s+push(\s|$)' && ! printf '%s' "$command" | grep -qE '(-f|--force)'; then
  risk="🟡 review"
  label="git push"
  reason="リモートへプッシュ — 共有状態に影響"
elif printf '%s' "$command" | grep -qE 'git\s+merge'; then
  risk="🟡 review"
  label="git merge"
  reason="ブランチマージ — git merge --abort で中断可"
elif printf '%s' "$command" | grep -qE 'git\s+rebase'; then
  risk="🟡 review"
  label="git rebase"
  reason="履歴書き換え — git rebase --abort で中断可"
elif printf '%s' "$command" | grep -qE 'git\s+stash\s+drop'; then
  risk="🟡 review"
  label="git stash drop"
  reason="stash 削除 — 復元困難"
elif printf '%s' "$command" | grep -qE '(npm|pnpm|yarn)\s+install' || printf '%s' "$command" | grep -qE '(pnpm|npm)\s+add'; then
  risk="🟡 review"
  label="package install"
  reason="パッケージインストール — node_modules 変更"
elif printf '%s' "$command" | grep -qE 'brew\s+install'; then
  risk="🟡 review"
  label="brew install"
  reason="システムパッケージインストール"
elif printf '%s' "$command" | grep -qE '(npm|pnpm|yarn)\s+(uninstall|remove)'; then
  risk="🟡 review"
  label="package remove"
  reason="パッケージ削除"
elif [ "$base_cmd" = "mkdir" ]; then
  risk="🟡 review"
  label="mkdir"
  reason="ディレクトリ作成"
elif [ "$base_cmd" = "chmod" ] || [ "$base_cmd" = "chown" ]; then
  risk="🟡 review"
  label="$base_cmd"
  reason="ファイル権限変更"
elif [ "$base_cmd" = "mv" ]; then
  risk="🟡 review"
  label="mv"
  reason="ファイル移動/リネーム"
elif [ "$base_cmd" = "cp" ]; then
  risk="🟡 review"
  label="cp"
  reason="ファイルコピー"
elif printf '%s' "$command" | grep -qE 'docker\s+(run|build|compose)'; then
  risk="🟡 review"
  label="docker"
  reason="コンテナ操作"

# 🟢 Safe (read-only / no side effects) — explicit patterns
elif [ "$base_cmd" = "ls" ] || [ "$base_cmd" = "cat" ] || [ "$base_cmd" = "head" ] || [ "$base_cmd" = "tail" ]; then
  risk="🟢 safe"
  label="$base_cmd"
  reason="読み取り専用コマンド"
elif [ "$base_cmd" = "echo" ] || [ "$base_cmd" = "printf" ] || [ "$base_cmd" = "which" ] || [ "$base_cmd" = "type" ]; then
  risk="🟢 safe"
  label="$base_cmd"
  reason="出力専用・副作用なし"
elif [ "$base_cmd" = "pwd" ] || [ "$base_cmd" = "whoami" ] || [ "$base_cmd" = "date" ] || [ "$base_cmd" = "uname" ]; then
  risk="🟢 safe"
  label="$base_cmd"
  reason="システム情報取得"
elif [ "$base_cmd" = "wc" ] || [ "$base_cmd" = "sort" ] || [ "$base_cmd" = "uniq" ] || [ "$base_cmd" = "diff" ]; then
  risk="🟢 safe"
  label="$base_cmd"
  reason="読み取り専用コマンド"
elif [ "$base_cmd" = "find" ] || [ "$base_cmd" = "grep" ] || [ "$base_cmd" = "rg" ] || [ "$base_cmd" = "fd" ]; then
  risk="🟢 safe"
  label="$base_cmd"
  reason="検索コマンド — 読み取り専用"
elif [ "$base_cmd" = "tree" ] || [ "$base_cmd" = "file" ] || [ "$base_cmd" = "stat" ] || [ "$base_cmd" = "du" ]; then
  risk="🟢 safe"
  label="$base_cmd"
  reason="ファイル情報取得"
elif printf '%s' "$command" | grep -qE '^git\s+(status|log|diff|show|branch|remote|tag|stash\s+list|blame|shortlog)'; then
  risk="🟢 safe"
  label="git (read)"
  reason="Git 読み取りコマンド"
elif [ "$base_cmd" = "node" ] || [ "$base_cmd" = "python3" ] || [ "$base_cmd" = "python" ]; then
  risk="🟢 safe"
  label="$base_cmd"
  reason="スクリプト実行"
elif printf '%s' "$command" | grep -qE '(vitest|jest|pytest|cargo\s+test|go\s+test)'; then
  risk="🟢 safe"
  label="test runner"
  reason="テスト実行 — 読み取り系"
elif printf '%s' "$command" | grep -qE '(eslint|prettier|biome|tsc)\s'; then
  risk="🟢 safe"
  label="lint/format"
  reason="静的解析・フォーマット"
elif [ "$base_cmd" = "sed" ] && printf '%s' "$command" | grep -qE 'sed\s+(-[a-zA-Z]*i|-i)'; then
  risk="🟡 review"
  label="sed -i"
  reason="インプレース書き換え — ファイルを直接変更"
elif [ "$base_cmd" = "jq" ] || [ "$base_cmd" = "sed" ] || [ "$base_cmd" = "awk" ]; then
  risk="🟢 safe"
  label="$base_cmd"
  reason="テキスト処理"
elif [ "$base_cmd" = "curl" ] || [ "$base_cmd" = "wget" ]; then
  risk="🟢 safe"
  label="$base_cmd"
  reason="HTTP リクエスト（GET想定）"
fi

# Default: 🟢 safe for unrecognized commands
if [ -z "$risk" ]; then
  risk="🟢 safe"
  label="$base_cmd"
  reason="既知の危険パターンに該当なし"
fi

# Output additionalContext
printf '{"hookSpecificOutput":{"additionalContext":"%s | %s — %s"}}' "$risk" "$label" "$reason"

exit 0
