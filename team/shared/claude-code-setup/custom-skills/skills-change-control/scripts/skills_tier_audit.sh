#!/bin/bash
# skills_tier_audit.sh — Skills Tier Policy 監査スクリプト
#
# 使い方:
#   skills_tier_audit.sh                    # 基本監査
#   skills_tier_audit.sh --strict-installed  # インストール済み全件 strict チェック
#   skills_tier_audit.sh --strict-all-installed  # 月次: always_on 含め全件
#
# 出力契約: findings（severity順）→ risks → pass/fail verdict
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
POLICY_FILE="${SKILL_ROOT}/policy/skills_tier_policy.json"
SKILLS_DIR="${HOME}/.claude/skills"

RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

MODE="basic"
[[ "${1:-}" == "--strict-installed" ]]     && MODE="strict"
[[ "${1:-}" == "--strict-all-installed" ]] && MODE="strict-all"

echo ""
echo "=========================================="
printf "  ${BOLD}Skills Tier Audit${NC}  [mode: ${MODE}]\n"
echo "  $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="
echo ""

# ─── ポリシー読み込み ───
if [ ! -f "$POLICY_FILE" ]; then
  printf "${RED}[FATAL]${NC} policy file not found: $POLICY_FILE\n"
  exit 2
fi

always_on_policy=$(python3 -c "
import json
d = json.load(open('$POLICY_FILE'))
print(' '.join(d['tiers']['always_on']))
")
conditional_policy=$(python3 -c "
import json
d = json.load(open('$POLICY_FILE'))
print(' '.join(d['tiers']['conditional']))
")
parking_policy=$(python3 -c "
import json
d = json.load(open('$POLICY_FILE'))
print(' '.join(d['tiers']['parking']))
")
always_on_max=$(python3 -c "
import json
print(json.load(open('$POLICY_FILE'))['rules']['always_on_max'])
")

# ─── 実際のインストール状況 ───
installed_always_on=()
installed_conditional=()
for d in "$SKILLS_DIR"/*/; do
  [ -d "$d" ] || [ -L "$d" ] || continue
  name=$(basename "${d%/}")
  if [[ "$name" == _* ]]; then
    installed_always_on+=("$name")
  else
    installed_conditional+=("$name")
  fi
done

# ─── Findings 収集 ───
declare -a P1=() P2=() P3=()

# [P1] always_on ポリシー未登録スキルの検出
for skill in "${installed_always_on[@]}"; do
  if ! echo "$always_on_policy" | grep -qw "$skill"; then
    P1+=("always_on 未登録: ${skill} (policy に追加 or 削除が必要)")
  fi
done

# [P1] ポリシーに登録済みだがインストールされていない always_on
for skill in $always_on_policy; do
  found=false
  for installed in "${installed_always_on[@]}"; do
    [[ "$installed" == "$skill" ]] && found=true && break
  done
  if ! $found; then
    P1+=("always_on 未インストール: ${skill} (install.sh を実行してください)")
  fi
done

# [P1] always_on 上限超過（one-in-one-out 違反）
actual_always_on_count=${#installed_always_on[@]}
if [ "$actual_always_on_count" -gt "$always_on_max" ]; then
  P1+=("one-in-one-out 違反: always_on が ${actual_always_on_count}個 (上限 ${always_on_max}個). 降格または削除が必要")
fi

# [P2] SKILL.md 欠損チェック（always_on 全件、conditional は strict 以上）
check_skillmd() {
  local skill_path="$1"
  local name="$2"
  if [ ! -f "${skill_path}/SKILL.md" ]; then
    P2+=("SKILL.md 欠損: ${name}")
  fi
}

for skill in "${installed_always_on[@]}"; do
  skill_path="${SKILLS_DIR}/${skill}"
  [ -L "$skill_path" ] && skill_path=$(readlink -f "$skill_path" 2>/dev/null || echo "$skill_path")
  check_skillmd "$skill_path" "$skill"
done

if [[ "$MODE" == "strict" || "$MODE" == "strict-all" ]]; then
  for skill in "${installed_conditional[@]}"; do
    skill_path="${SKILLS_DIR}/${skill}"
    [ -L "$skill_path" ] && skill_path=$(readlink -f "$skill_path" 2>/dev/null || echo "$skill_path")
    check_skillmd "$skill_path" "$skill"
  done
fi

# [P2] parking 残留チェック（parking 内スキルが実際にインストールされていないか確認）
for skill in $parking_policy; do
  if [ -d "${SKILLS_DIR}/${skill}" ] || [ -L "${SKILLS_DIR}/${skill}" ]; then
    P2+=("parking スキルがインストール済み: ${skill} (意図的か確認が必要)")
  fi
done

# [P3] conditional ポリシー未登録スキル
for skill in "${installed_conditional[@]}"; do
  if ! echo "$conditional_policy $parking_policy" | grep -qw "$skill"; then
    P3+=("conditional 未登録: ${skill} (policy.json に追加してください)")
  fi
done

# [P3] broken symlink チェック
for target in "$SKILLS_DIR"/*; do
  [ -L "$target" ] || continue
  if [ ! -e "$target" ]; then
    P3+=("リンク切れ: $(basename "$target") (git pull で解消できる可能性あり)")
  fi
done

# ─── 出力: Findings ───
printf "${CYAN}${BOLD}--- Findings (severity 順) ---${NC}\n"
echo ""

total_p1=${#P1[@]}
total_p2=${#P2[@]}
total_p3=${#P3[@]}

if [ $total_p1 -gt 0 ]; then
  for f in "${P1[@]}"; do
    printf "  ${RED}[P1]${NC} $f\n"
  done
else
  printf "  ${GREEN}[P1]${NC} なし\n"
fi

if [ $total_p2 -gt 0 ]; then
  for f in "${P2[@]}"; do
    printf "  ${YELLOW}[P2]${NC} $f\n"
  done
else
  printf "  ${GREEN}[P2]${NC} なし\n"
fi

if [ $total_p3 -gt 0 ]; then
  for f in "${P3[@]}"; do
    printf "  [P3] $f\n"
  done
else
  printf "  [P3] なし\n"
fi

echo ""

# ─── 出力: Risks ───
printf "${CYAN}${BOLD}--- Risks ---${NC}\n"
echo ""
[ $total_p1 -gt 0 ] && printf "  ・Policy 逸脱スキルがあると監査証跡が失われる\n"
[ $total_p2 -gt 0 ] && printf "  ・SKILL.md 欠損はスキルが意図通り発火しないリスク\n"
[ $total_p3 -gt 0 ] && printf "  ・未登録スキルはコスト増加の盲点になりうる\n"
[ $total_p1 -eq 0 ] && [ $total_p2 -eq 0 ] && [ $total_p3 -eq 0 ] \
  && printf "  ・特記リスクなし\n"
echo ""

# ─── 出力: Stats ───
printf "${CYAN}${BOLD}--- Stats ---${NC}\n"
echo ""
printf "  always_on  : ${actual_always_on_count}個 (上限 ${always_on_max}個)\n"
printf "  conditional: ${#installed_conditional[@]}個\n"
printf "  parking    : $(echo $parking_policy | wc -w | tr -d ' ')個\n"
printf "  total      : $((actual_always_on_count + ${#installed_conditional[@]}))個\n"
echo ""

# ─── 出力: Verdict ───
printf "${CYAN}${BOLD}--- Verdict ---${NC}\n"
echo ""
if [ $total_p1 -gt 0 ] || [ $total_p2 -gt 0 ]; then
  printf "  ${RED}${BOLD}FAIL${NC}  P1=${total_p1} P2=${total_p2} P3=${total_p3}\n"
  echo ""
  echo "=========================================="
  printf "  ${RED}${BOLD}FAIL — P1/P2 解消後に再実行してください${NC}\n"
  echo "=========================================="
  echo ""
  exit 1
else
  printf "  ${GREEN}${BOLD}PASS${NC}  P1=0 P2=0 P3=${total_p3}\n"
  echo ""
  echo "=========================================="
  printf "  ${GREEN}${BOLD}PASS${NC}\n"
  echo "=========================================="
  echo ""
  exit 0
fi
