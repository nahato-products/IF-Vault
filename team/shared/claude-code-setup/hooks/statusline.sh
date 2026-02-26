#!/bin/bash
# StatusLine: git branch + changes + cwd
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
  if [ "$changes" -gt 0 ]; then
    status_parts+=("⎇ ${branch} +${changes}")
  else
    status_parts+=("⎇ ${branch}")
  fi
fi
status_parts+=("📁 ${display_dir}")

printf '%s' "$(IFS=' | '; printf '%s' "${status_parts[*]}")"
exit 0
