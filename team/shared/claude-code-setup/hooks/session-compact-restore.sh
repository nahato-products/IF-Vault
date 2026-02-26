#!/bin/bash
# Hook A: PreCompact — セッション状態をCompaction前に保存
# 方針: ファイルベースの状態保存のみ。stdout JSON出力は公式未記載のため非依存。

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
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  GIT_BRANCH=$(git branch --show-current 2>/dev/null)
  GIT_STATUS=$(git status --short 2>/dev/null | head -20)
  GIT_DIFF_STAT=$(git diff --stat 2>/dev/null | tail -5)
fi

cat > "$STATE_FILE" <<EOF
# Compact State (自動保存)

- **保存日時**: ${TIMESTAMP}
- **作業ディレクトリ**: ${CWD}
- **Git Branch**: ${GIT_BRANCH:-N/A}

## 未コミット変更
\`\`\`
${GIT_STATUS:-変更なし}
\`\`\`

## diff stat
\`\`\`
${GIT_DIFF_STAT:-なし}
\`\`\`

---
_PreCompact hookにより自動保存。復帰時は ~/.claude/session-env/compact-state.md を読んで復元_
EOF

exit 0
