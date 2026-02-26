#!/bin/bash
# command-shield-gui.sh — PreToolUse hook for Bash commands (GUI版)
# 🔴 destructive コマンドのみ macOS ネイティブダイアログで最終確認
# 🟡 review / 🟢 safe はスルー（command-shield.sh の additionalContext で対応済み）
# 依存: osascript（macOS 標準）
#
# Phase 1: osascript ダイアログ（ゼロ依存）
# Phase 2: menubar 常駐アプリ化（予定）

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

# --- 🔴 Destructive pattern detection (shared module) ---

source "$(dirname "$0")/_destructive-patterns.sh"
classify_destructive "$command"
label="$DESTRUCTIVE_LABEL"
reason="$DESTRUCTIVE_REASON"

# Not destructive → pass through silently
if [ -z "$label" ]; then
  exit 0
fi

# --- GUI Dialog (🔴 destructive only) ---

# Truncate command for display (max 200 chars)
display_cmd=$(printf '%s' "$command" | head -c 200)
if [ ${#command} -gt 200 ]; then
  display_cmd="${display_cmd}..."
fi

# Escape for AppleScript
escaped_cmd=$(printf '%s' "$display_cmd" | python3 -c "
import sys
s = sys.stdin.read()[:200]
s = s.replace('\\\\', '').replace('\"', '').replace(\"'\", '').replace('\\n', ' ').replace('\\r', '')
print(s, end='')
")

# Show native macOS dialog — default button is "拒否"（安全側）
result=$(osascript -e "
  display dialog \"🔴 危険なコマンドを検知

【コマンド】
${escaped_cmd}

【分類】${label}
【理由】${reason}

本当に実行しますか？\" \
  buttons {\"拒否\", \"実行する\"} \
  default button \"拒否\" \
  with icon stop \
  with title \"Claude Code — Command Shield\" \
  giving up after 30
" 2>&1) || true

# Denied or timeout → block (exit 2 = hard block, consistent with block-sensitive-read.sh)
if printf '%s' "$result" | grep -q "拒否"; then
  printf '%s\n' "GUI拒否: ${label} — ${reason}" >&2
  exit 2
fi

if printf '%s' "$result" | grep -q "gave up"; then
  printf '%s\n' "タイムアウト（30秒）— 危険コマンドはデフォルト拒否: ${label}" >&2
  exit 2
fi

# Approved → log and allow
log_dir="${HOME}/.claude/logs"
mkdir -p "$log_dir"
printf '%s | GUI-APPROVED | label=%s | cmd=%s\n' \
  "$(date '+%Y-%m-%d %H:%M:%S')" "$label" "$display_cmd" \
  >> "${log_dir}/command-approvals.log"

exit 0
