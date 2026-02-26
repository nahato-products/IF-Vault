#!/bin/bash
# Hook D: PostToolUseFailure — ツール失敗ログ蓄積 + 連続失敗検出

input=$(cat)

LOG_FILE="${HOME:?}/.claude/debug/tool-failures.jsonl"
mkdir -p "$(dirname "$LOG_FILE")"

export TG_LOG_FILE="$LOG_FILE"

printf '%s\n' "$input" | python3 -c "
import sys, json, datetime, os

log_file = os.environ.get('TG_LOG_FILE', '')
if not log_file:
    sys.exit(0)

try:
    data = json.loads(sys.stdin.read())
except (json.JSONDecodeError, ValueError):
    sys.exit(0)

tool = data.get('tool_name', 'unknown')
error = str(data.get('error', ''))[:200]
ts = datetime.datetime.now().strftime('%Y-%m-%dT%H:%M:%S')

# 1回のファイル読み込みで全処理
try:
    with open(log_file, 'r') as f:
        lines = f.readlines()
except FileNotFoundError:
    lines = []
except OSError:
    lines = []

# 新エントリ追加
new_entry = json.dumps({'ts': ts, 'tool': tool, 'error': error}, ensure_ascii=False) + '\n'
lines.append(new_entry)

# ローテーション（1000行超 → 500行に切り詰め）
if len(lines) > 1000:
    lines = lines[-500:]

# 書き戻し（1回の書き込み）
try:
    with open(log_file, 'w') as f:
        f.writelines(lines)
except OSError:
    sys.exit(0)

# 同一ツール3回連続失敗チェック
if len(lines) >= 3:
    recent_tools = []
    for line in lines[-3:]:
        try:
            recent_tools.append(json.loads(line).get('tool', ''))
        except (json.JSONDecodeError, ValueError):
            pass
    if len(recent_tools) >= 3 and len(set(recent_tools)) == 1 and recent_tools[0]:
        msg = f'{recent_tools[0]} が3回連続失敗。アプローチを変えて。ログ: ~/.claude/debug/tool-failures.jsonl'
        print(json.dumps({
            'hookSpecificOutput': {
                'hookEventName': 'PostToolUseFailure',
                'additionalContext': msg
            }
        }, ensure_ascii=False))
" 2>/dev/null

exit 0
