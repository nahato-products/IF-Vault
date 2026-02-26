#!/bin/bash
# PreToolUse: Block Read of sensitive files (.env, keys, credentials)
# Exit 2 = hard block (deny pattern bypass workaround)
input=$(cat)
file_path=$(printf '%s\n' "$input" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('file_path', ''))
except (json.JSONDecodeError, ValueError):
    pass
" 2>/dev/null)

if [ -z "$file_path" ]; then exit 0; fi

basename=$(basename -- "$file_path" 2>/dev/null)
case "$basename" in
  .env|.env.*|*.pem|*.key|id_rsa*|credentials.json|secrets.json|secrets.yaml|secrets.yml)
    printf '%s\n' "機密ファイル ${basename} の読み取りをブロック" >&2
    exit 2
    ;;
esac
exit 0
