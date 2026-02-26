#!/bin/bash
# TokenGuardian Hook: Suggest read_smart for large files
# Trigger: PreToolUse (Read)
# Non-blocking — advisory only

input=$(cat)

printf '%s\n' "$input" | python3 -c "
import sys, json, os

try:
    data = json.loads(sys.stdin.read())
except (json.JSONDecodeError, ValueError):
    sys.exit(0)

if data.get('tool_name') != 'Read':
    sys.exit(0)

fp = data.get('tool_input', {}).get('file_path', '')
if not fp or not os.path.isfile(fp):
    sys.exit(0)

# 6144 bytes = 6KB: Read tool default limit is 2000 lines,
# files above this threshold benefit from read_smart/read_fragment
size = os.path.getsize(fp)
if size > 6144:
    kb = round(size / 1024, 1)
    print(json.dumps({
        'hookSpecificOutput': {
            'hookEventName': 'PreToolUse',
            'additionalContext': f'TokenGuardian: {kb}KB — read_smart/read_fragment でトークン節約可'
        }
    }, ensure_ascii=False))
" 2>/dev/null

exit 0
