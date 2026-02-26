#!/bin/bash
# SessionStart Hook — セッション開始時に環境コンテキストを自動注入
# 認知負荷ゼロでの文脈復帰を実現する
#
# 対応source: startup / resume / compact / clear
# additionalContext でプロンプトに注入
set -euo pipefail

INPUT=$(cat)
SOURCE=$(echo "$INPUT" | jq -r '.source // "startup"' 2>/dev/null)

STATE_DIR="${HOME:?}/.claude/session-env"
COMPACT_STATE="$STATE_DIR/compact-state.md"
UNCOMMITTED="$STATE_DIR/uncommitted-changes.md"
LAST_SKILL="$STATE_DIR/last-skill.txt"

# clear の場合はコンテキスト注入しないが、セッション状態はリセットする
if [ "$SOURCE" = "clear" ]; then
  echo '[]' > "$STATE_DIR/combo-shown.json" 2>/dev/null || true
  echo '{}'
  exit 0
fi

# --- 情報収集 ---
CONTEXT_PARTS=""

# 1. compact/resume: 前回の状態を復元
if [ "$SOURCE" = "compact" ] || [ "$SOURCE" = "resume" ]; then
  if [ -f "$COMPACT_STATE" ]; then
    COMPACT_INFO=$(head -15 "$COMPACT_STATE" 2>/dev/null)
    CONTEXT_PARTS="${CONTEXT_PARTS}
📍 前回のセッション状態:
${COMPACT_INFO}"
  fi

  if [ -f "$UNCOMMITTED" ]; then
    UNCOMMITTED_SUMMARY=$(head -5 "$UNCOMMITTED" 2>/dev/null)
    CONTEXT_PARTS="${CONTEXT_PARTS}
${UNCOMMITTED_SUMMARY}"
  fi

  if [ -f "$LAST_SKILL" ]; then
    SKILL_NAME=$(cat "$LAST_SKILL" 2>/dev/null)
    if [ -n "$SKILL_NAME" ]; then
      CONTEXT_PARTS="${CONTEXT_PARTS}
最後に使ったスキル: ${SKILL_NAME}"
    fi
  fi
fi

# 2. Git 状態（全source共通、Git リポジトリ内のみ）
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  BRANCH=$(git branch --show-current 2>/dev/null)
  CHANGED=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
  RECENT_COMMITS=$(git log --oneline -3 2>/dev/null)

  CONTEXT_PARTS="${CONTEXT_PARTS}
🔀 Git: ${BRANCH:-detached} | 変更${CHANGED}件"

  if [ -n "$RECENT_COMMITS" ]; then
    CONTEXT_PARTS="${CONTEXT_PARTS}
直近コミット:
${RECENT_COMMITS}"
  fi
fi

# 3. 直近のツール失敗（あれば上位3件）
FAILURES="$STATE_DIR/../debug/tool-failures.jsonl"
if [ -f "$FAILURES" ]; then
  RECENT_FAILS=$(tail -10 "$FAILURES" 2>/dev/null | jq -r '.tool // empty' 2>/dev/null | sort | uniq -c | sort -rn | head -3)
  if [ -n "$RECENT_FAILS" ]; then
    CONTEXT_PARTS="${CONTEXT_PARTS}
⚠️ 直近のツール失敗傾向: ${RECENT_FAILS}"
  fi
fi

# 4. プロジェクトコンテキスト（project-skill-preset.py が書き込んだもの）
# このスクリプトより先に project-skill-preset.py が実行される前提
PROJECT_CONTEXT="$STATE_DIR/project-context.md"
if [ -f "$PROJECT_CONTEXT" ]; then
  PROJECT_INFO=$(cat "$PROJECT_CONTEXT" 2>/dev/null)
  if [ -n "$PROJECT_INFO" ]; then
    CONTEXT_PARTS="${CONTEXT_PARTS}

${PROJECT_INFO}"
  fi
fi

# 5. ワークフロー整合性の問題（workflow-audit.py が書き込んだもの）
WORKFLOW_ISSUES="$STATE_DIR/workflow-issues.md"
if [ -f "$WORKFLOW_ISSUES" ]; then
  ISSUES_INFO=$(cat "$WORKFLOW_ISSUES" 2>/dev/null)
  if [ -n "$ISSUES_INFO" ]; then
    CONTEXT_PARTS="${CONTEXT_PARTS}

${ISSUES_INFO}"
  fi
fi

# 6. 自動判定結果（env-orchestrator.py が書き込んだもの、上位10行のみ注入）
PENDING_DECISIONS="$STATE_DIR/pending-decisions.md"
if [ -f "$PENDING_DECISIONS" ]; then
  PENDING_INFO=$(head -10 "$PENDING_DECISIONS" 2>/dev/null)
  if [ -n "$PENDING_INFO" ]; then
    CONTEXT_PARTS="${CONTEXT_PARTS}

${PENDING_INFO}"
  fi
fi

# 7. セッション開始時に combo-shown をリセット（dedup状態のクリア）
echo '[]' > "$STATE_DIR/combo-shown.json" 2>/dev/null || true

# 8. lessons.md（過去の修正・指摘パターン）
LESSONS_FILE="$STATE_DIR/lessons.md"
if [ -f "$LESSONS_FILE" ]; then
  LESSONS_COUNT=$(grep -c "^-" "$LESSONS_FILE" 2>/dev/null || echo 0)
  if [ "$LESSONS_COUNT" -gt "0" ]; then
    RECENT_LESSONS=$(tail -5 "$LESSONS_FILE" 2>/dev/null)
    CONTEXT_PARTS="${CONTEXT_PARTS}
📚 過去の修正パターン（lessons.md 最新5件）:
${RECENT_LESSONS}"
  fi
fi

# 9. agent-queue.md（未取り込みコミュニティエージェント）
QUEUE_FILE="$STATE_DIR/agent-queue.md"
if [ -f "$QUEUE_FILE" ]; then
  PENDING=$(grep -c "^\- \[ \]" "$QUEUE_FILE" 2>/dev/null || echo 0)
  if [ "$PENDING" -gt "0" ]; then
    CONTEXT_PARTS="${CONTEXT_PARTS}
📥 未取り込みエージェント候補: ${PENDING}件（~/.claude/session-env/agent-queue.md）"
  fi
fi

# --- 出力 ---
if [ -n "$CONTEXT_PARTS" ]; then
  # JSON エスケープ
  ESCAPED=$(echo "$CONTEXT_PARTS" | jq -Rs '.')
  echo "{\"additionalContext\":${ESCAPED}}"
else
  echo '{}'
fi

exit 0
