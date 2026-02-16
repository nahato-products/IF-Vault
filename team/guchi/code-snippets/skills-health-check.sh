#!/bin/bash
# Skills ヘルスチェックスクリプト
# 55個のインストール済みSkillsを一括診断する
#
# 使い方: bash skills-health-check.sh
# 推奨: 週1で実行してSkillsの状態を確認

SKILLS_DIR="$HOME/.claude/skills"
MAX_LINES=500
MIN_DESC_LEN=100
WARN_COUNT=0
ERROR_COUNT=0

echo "=============================="
echo " Skills Health Check"
echo " $(date '+%Y-%m-%d %H:%M')"
echo "=============================="
echo ""

# スキル数カウント
TOTAL=$(ls -d "$SKILLS_DIR"/*/ 2>/dev/null | wc -l | tr -d ' ')
echo "インストール済み: ${TOTAL}個"
echo ""

# --- 1. SKILL.md 行数チェック ---
echo "--- 1. 行数チェック（上限: ${MAX_LINES}行）---"
OVER_COUNT=0
for dir in "$SKILLS_DIR"/*/; do
  skill_name=$(basename "$dir")
  skill_file="$dir/SKILL.md"
  if [ -f "$skill_file" ]; then
    lines=$(wc -l < "$skill_file" | tr -d ' ')
    if [ "$lines" -gt "$MAX_LINES" ]; then
      echo "  ⚠️  ${skill_name}: ${lines}行（+$((lines - MAX_LINES))超過）"
      OVER_COUNT=$((OVER_COUNT + 1))
      WARN_COUNT=$((WARN_COUNT + 1))
    fi
  else
    echo "  ❌ ${skill_name}: SKILL.mdが見つからない"
    ERROR_COUNT=$((ERROR_COUNT + 1))
  fi
done
if [ "$OVER_COUNT" -eq 0 ]; then
  echo "  ✅ 全スキル500行以内"
fi
echo ""

# --- 2. description文字数チェック ---
echo "--- 2. description文字数チェック（推奨: ${MIN_DESC_LEN}文字以上）---"
SHORT_COUNT=0
for dir in "$SKILLS_DIR"/*/; do
  skill_name=$(basename "$dir")
  skill_file="$dir/SKILL.md"
  if [ -f "$skill_file" ]; then
    desc=$(grep -m1 '^description:' "$skill_file" | sed 's/^description: //')
    desc_len=${#desc}
    if [ "$desc_len" -lt "$MIN_DESC_LEN" ] && [ "$desc_len" -gt 0 ]; then
      echo "  ⚠️  ${skill_name}: ${desc_len}文字"
      SHORT_COUNT=$((SHORT_COUNT + 1))
      WARN_COUNT=$((WARN_COUNT + 1))
    elif [ "$desc_len" -eq 0 ]; then
      echo "  ❌ ${skill_name}: descriptionが空"
      ERROR_COUNT=$((ERROR_COUNT + 1))
    fi
  fi
done
if [ "$SHORT_COUNT" -eq 0 ]; then
  echo "  ✅ 全スキル${MIN_DESC_LEN}文字以上"
fi
echo ""

# --- 3. reference.md 有無チェック ---
echo "--- 3. reference.md 有無チェック ---"
NO_REF_COUNT=0
for dir in "$SKILLS_DIR"/*/; do
  skill_name=$(basename "$dir")
  if [ ! -f "$dir/reference.md" ] && [ ! -d "$dir/references" ]; then
    NO_REF_COUNT=$((NO_REF_COUNT + 1))
  fi
done
echo "  reference.mdあり: $((TOTAL - NO_REF_COUNT))個"
echo "  reference.mdなし: ${NO_REF_COUNT}個"
echo ""

# --- 4. "Use when" パターンチェック ---
echo "--- 4. 'Use when' パターンチェック ---"
NO_USEWHEN=0
for dir in "$SKILLS_DIR"/*/; do
  skill_name=$(basename "$dir")
  skill_file="$dir/SKILL.md"
  if [ -f "$skill_file" ]; then
    if ! grep -q 'Use when' "$skill_file" 2>/dev/null; then
      echo "  ⚠️  ${skill_name}: 'Use when'パターンなし"
      NO_USEWHEN=$((NO_USEWHEN + 1))
      WARN_COUNT=$((WARN_COUNT + 1))
    fi
  fi
done
if [ "$NO_USEWHEN" -eq 0 ]; then
  echo "  ✅ 全スキルに'Use when'あり"
fi
echo ""

# --- 5. 行数ランキング（Top 10）---
echo "--- 5. 行数ランキング（Top 10）---"
for dir in "$SKILLS_DIR"/*/; do
  skill_name=$(basename "$dir")
  skill_file="$dir/SKILL.md"
  if [ -f "$skill_file" ]; then
    lines=$(wc -l < "$skill_file" | tr -d ' ')
    echo "$lines $skill_name"
  fi
done | sort -rn | head -10 | while read lines name; do
  if [ "$lines" -gt "$MAX_LINES" ]; then
    echo "  ${lines}行 ${name} ⚠️"
  else
    echo "  ${lines}行 ${name}"
  fi
done
echo ""

# --- サマリー ---
echo "=============================="
echo " サマリー"
echo "=============================="
echo "  総数: ${TOTAL}個"
echo "  エラー: ${ERROR_COUNT}件"
echo "  警告: ${WARN_COUNT}件"
if [ "$ERROR_COUNT" -eq 0 ] && [ "$WARN_COUNT" -eq 0 ]; then
  echo "  🎉 全スキル健全！"
elif [ "$ERROR_COUNT" -eq 0 ]; then
  echo "  ⚠️  軽微な問題あり（運用に支障なし）"
else
  echo "  ❌ 要対応の問題あり"
fi
echo ""
echo "実行完了: $(date '+%Y-%m-%d %H:%M:%S')"
