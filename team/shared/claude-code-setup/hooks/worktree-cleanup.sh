#!/bin/bash
# worktree-cleanup.sh — WorktreeRemove hook
# Worktree 削除時のクリーンアップとログ記録
set -euo pipefail

input=$(cat)

worktree_path=$(printf '%s' "$input" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('worktree_path', '') or data.get('path', ''))
except (json.JSONDecodeError, ValueError):
    pass
" 2>/dev/null)

if [ -z "$worktree_path" ]; then
  exit 0
fi

# Log removal
log_dir="${HOME}/.claude/logs"
mkdir -p "$log_dir"
printf '%s | WorktreeRemove | path=%s\n' \
  "$(date '+%Y-%m-%d %H:%M:%S')" "$worktree_path" \
  >> "${log_dir}/worktree-ops.log"

exit 0
