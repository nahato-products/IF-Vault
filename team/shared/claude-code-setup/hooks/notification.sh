#!/bin/bash
# Notification: macOS notification when Claude needs attention
input=$(cat)
message=$(printf '%s\n' "$input" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    msg = data.get('message', '') or data.get('title', '') or '確認が必要です'
    # Sanitize for AppleScript: remove backslashes and double quotes
    msg = msg[:100].replace('\\\\', '').replace('\"', '')
    print(msg)
except (json.JSONDecodeError, ValueError):
    print('確認が必要です')
" 2>/dev/null)

osascript -e "display notification \"${message}\" with title \"Claude Code\"" 2>/dev/null
exit 0
