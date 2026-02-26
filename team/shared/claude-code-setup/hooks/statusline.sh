#!/bin/bash
# StatusLine: git branch + changes + cwd + context window
set -euo pipefail
input=$(cat)
cwd=$(printf '%s\n' "$input" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    ws = data.get('workspace', {})
    print(ws.get('current_dir', '') or data.get('cwd', ''))
except (json.JSONDecodeError, ValueError):
    pass
" 2>/dev/null)

if [ -z "$cwd" ]; then cwd=$(pwd); fi
display_dir="${cwd/#$HOME/~}"

status_parts=()
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null || printf "detached")
  changes=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  staged=$(git -C "$cwd" --no-optional-locks diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
  untracked=$(git -C "$cwd" --no-optional-locks ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
  last_msg=$(git -C "$cwd" --no-optional-locks log --oneline -1 --format='%s' 2>/dev/null)
  commit_count=$(git -C "$cwd" --no-optional-locks rev-list --count HEAD 2>/dev/null || echo "0")

  # Phase estimation
  phase=""
  if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
    phase="🏠"
  elif [ "$untracked" -gt 0 ] && [ "$commit_count" -le 1 ]; then
    phase="🔰"
  elif [ "$staged" -gt 0 ]; then
    phase="📦"
  elif printf '%s' "$last_msg" | grep -qiE '^(fix|WIP|wip|bugfix)'; then
    phase="🔧"
  elif printf '%s' "$branch" | grep -qE '^feature/'; then
    phase="🚀"
  else
    phase="🏠"
  fi

  if [ "$changes" -gt 0 ]; then
    status_parts+=("${phase} ⎇ ${branch} +${changes}")
  else
    status_parts+=("${phase} ⎇ ${branch}")
  fi
fi
status_parts+=("📁 ${display_dir}")

# コンテキストウィンドウの残量を表示
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty' 2>/dev/null)
if [ -n "$remaining" ]; then
  # 整数に丸める
  remaining_int=$(printf "%.0f" "$remaining" 2>/dev/null)
  if [ -n "$remaining_int" ]; then
    status_parts+=("🧠 ${remaining_int}%")
  fi
fi

# 最後に使ったスキル名を表示
last_skill_file="${HOME}/.claude/session-env/last-skill.txt"
if [ -f "$last_skill_file" ]; then
  last_skill=$(cat "$last_skill_file" 2>/dev/null)
  if [ -n "$last_skill" ]; then
    status_parts+=("🎯 ${last_skill}")
  fi
fi

printf '%s' "$(IFS=' | '; printf '%s' "${status_parts[*]}")"
exit 0
