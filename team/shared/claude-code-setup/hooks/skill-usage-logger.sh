#!/usr/bin/env bash
# skill-usage-logger.sh — UserPromptSubmit hook
# ユーザーのプロンプトにスキル名 (/skill-name) が含まれる場合にログ記録
# 出力先: ~/.claude/debug/skill-usage.jsonl
# ローテーション: 2000行超 → 最新1000行保持

set -euo pipefail
source "$(dirname "$0")/_common.sh"

LOG_DIR="${HOME}/.claude/debug"
LOG_FILE="${LOG_DIR}/skill-usage.jsonl"
MAX_LINES=2000
KEEP_LINES=1000

# stdin から JSON を読み取り
INPUT=$(cat)

# python3 を1回だけ呼び出し: JSON解析 → スキル名抽出 → ログJSON生成を一括処理
LOG_ENTRY=$(printf '%s' "$INPUT" | python3 -c "
import sys, json, re
from datetime import datetime, timezone
try:
    data = json.load(sys.stdin)
    prompt = data.get('user_prompt', '')
    match = re.search(r'(?:^|\s)(\/[a-zA-Z][a-zA-Z0-9_-]{0,63})', prompt)
    if match:
        entry = {
            'ts': datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
            'skill': match.group(1)
        }
        print(json.dumps(entry, ensure_ascii=False))
except Exception:
    pass
" 2>/dev/null || true)

# ログエントリが空なら何もしない（スキル名なし or エラー）
if [ -z "$LOG_ENTRY" ]; then
    exit 0
fi

# ログディレクトリ確保（パーミッション700で作成）
mkdir -p "$LOG_DIR"
chmod 700 "$LOG_DIR"

# アトミックに書き込み（appendモード）
printf '%s\n' "$LOG_ENTRY" >> "$LOG_FILE"

# statusline用: 最新スキル名を state file に書き込み
SKILL_NAME=$(printf '%s' "$LOG_ENTRY" | python3 -c "import sys,json; print(json.load(sys.stdin).get('skill',''))" 2>/dev/null || true)
if [ -n "$SKILL_NAME" ]; then
    STATE_DIR="${HOME}/.claude/session-env"
    mkdir -p "$STATE_DIR"
    printf '%s' "$SKILL_NAME" > "${STATE_DIR}/last-skill.txt"
fi

# ローテーション: 2000行超えたら最新1000行に切り詰め
rotate_log "$LOG_FILE" "$MAX_LINES" "$KEEP_LINES"

exit 0
