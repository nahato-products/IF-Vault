#!/bin/bash
# config-change-audit.sh — ConfigChange hook
# 設定ファイル変更を検知して監査ログに記録する
# ブロックはしない（個人利用のため）

set -euo pipefail

input=$(cat)

source=$(printf '%s' "$input" | jq -r '.source // "unknown"' 2>/dev/null)
file_path=$(printf '%s' "$input" | jq -r '.file_path // "N/A"' 2>/dev/null)
session_id=$(printf '%s' "$input" | jq -r '.session_id // "unknown"' 2>/dev/null)

# ログディレクトリ確保
log_dir="${HOME}/.claude/logs"
mkdir -p "$log_dir"

# 監査ログに追記
timestamp=$(date '+%Y-%m-%d %H:%M:%S')
printf '%s | ConfigChange | source=%s | file=%s | session=%s\n' \
  "$timestamp" "$source" "$file_path" "$session_id" \
  >> "${log_dir}/config-changes.log"

# additionalContext で変更を通知（python3で安全にJSON生成）
printf '%s\n%s' "$source" "$file_path" | python3 -c "
import sys, json
lines = sys.stdin.read().split('\n', 1)
src = lines[0] if len(lines) > 0 else 'unknown'
fp = lines[1] if len(lines) > 1 else 'N/A'
print(json.dumps({
    'hookSpecificOutput': {
        'additionalContext': f'⚙️ 設定変更検知: {src} ({fp})'
    }
}, ensure_ascii=False))
" 2>/dev/null

exit 0
