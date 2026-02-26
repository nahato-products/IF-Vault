#!/bin/bash
# worktree-setup.sh — WorktreeCreate hook
# Worktree 作成時に .env コピー + git hooks セットアップを自動実行
set -euo pipefail

input=$(cat)

# Extract worktree path from hook input
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

# Find the original repo root (parent of worktree)
original_root=$(git -C "$worktree_path" rev-parse --path-format=absolute --git-common-dir 2>/dev/null | sed 's|/\.git$||' || true)
if [ -z "$original_root" ]; then
  exit 0
fi

# 1. Copy .env files (if they exist in original repo)
for env_file in .env .env.local .env.development.local; do
  if [ -f "${original_root}/${env_file}" ]; then
    cp "${original_root}/${env_file}" "${worktree_path}/${env_file}" 2>/dev/null || true
  fi
done

# 2. Copy node_modules symlink (avoid redundant install)
if [ -d "${original_root}/node_modules" ] && [ ! -d "${worktree_path}/node_modules" ]; then
  ln -s "${original_root}/node_modules" "${worktree_path}/node_modules" 2>/dev/null || true
fi

# Log
log_dir="${HOME}/.claude/logs"
mkdir -p "$log_dir"
printf '%s | WorktreeCreate | path=%s | from=%s\n' \
  "$(date '+%Y-%m-%d %H:%M:%S')" "$worktree_path" "$original_root" \
  >> "${log_dir}/worktree-ops.log"

exit 0
