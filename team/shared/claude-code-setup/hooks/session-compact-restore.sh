#!/bin/bash
# Hook A: PreCompact — セッション状態をCompaction前に保存（強化版）
# 方針: ファイルベースの状態保存 + 作業コンテキストの完全記録
set -euo pipefail

# stdin を消費（hook runner がパイプ破壊しないよう）
cat >/dev/null 2>&1

STATE_DIR="${HOME:?}/.claude/session-env"
mkdir -p "$STATE_DIR"
STATE_FILE="$STATE_DIR/compact-state.md"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
CWD=$(pwd)

GIT_BRANCH=""
GIT_STATUS=""
GIT_DIFF_STAT=""
GIT_RECENT_COMMITS=""
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  GIT_BRANCH=$(git branch --show-current 2>/dev/null)
  GIT_STATUS=$(git status --short 2>/dev/null | head -20)
  GIT_DIFF_STAT=$(git diff --stat 2>/dev/null | tail -5)
  GIT_RECENT_COMMITS=$(git log --oneline -5 2>/dev/null)
fi

# 最後に使ったスキルを記録
LAST_SKILL=""
SKILL_LOG="${HOME:?}/.claude/session-env/skill-usage.jsonl"
if [ -f "$SKILL_LOG" ]; then
  LAST_SKILL=$(tail -1 "$SKILL_LOG" 2>/dev/null | jq -r '.skill // empty' 2>/dev/null)
fi
echo "$LAST_SKILL" > "$STATE_DIR/last-skill.txt"

# 直近で編集したファイル（Git tracked のみ）
RECENT_FILES=""
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  RECENT_FILES=$(git diff --name-only 2>/dev/null | head -10)
  STAGED_FILES=$(git diff --cached --name-only 2>/dev/null | head -10)
  if [ -n "$STAGED_FILES" ]; then
    RECENT_FILES="${RECENT_FILES}
${STAGED_FILES}"
  fi
fi

cat > "$STATE_FILE" <<EOF
# Compact State (自動保存)

- **保存日時**: ${TIMESTAMP}
- **作業ディレクトリ**: ${CWD}
- **Git Branch**: ${GIT_BRANCH:-N/A}
- **最後のスキル**: ${LAST_SKILL:-不明}

## 未コミット変更
\`\`\`
${GIT_STATUS:-変更なし}
\`\`\`

## diff stat
\`\`\`
${GIT_DIFF_STAT:-なし}
\`\`\`

## 直近コミット
\`\`\`
${GIT_RECENT_COMMITS:-なし}
\`\`\`

## 作業中のファイル
\`\`\`
${RECENT_FILES:-なし}
\`\`\`

---
_PreCompact hookにより自動保存。SessionStart hookが次セッションで自動復元_
EOF

exit 0
