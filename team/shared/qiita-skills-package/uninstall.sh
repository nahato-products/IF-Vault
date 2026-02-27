#!/bin/bash

# Qiita Skills Package アンインストーラー
# インストールされたSkillsを削除します

set -e

# カラー出力
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${RED}  Qiita Skills Package アンインストーラー${NC}"
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}⚠ この操作は元に戻せません！${NC}"
echo ""
echo -e "以下のSkillsが削除されます:"
echo -e "  - qiita-draft"
echo -e "  - qiita-publish"
echo -e "  - qiita-review"
echo -e "  - qiita-workflow"
echo -e "  - qiita-topics-from-slack (存在する場合)"
echo ""
echo -e "${BLUE}※ Obsidian Vault内の記事ファイル (11_Qiita/) は削除されません${NC}"
echo ""
read -p "本当にアンインストールしますか? (yes/no): " -r
echo

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo -e "${BLUE}アンインストールをキャンセルしました${NC}"
    exit 0
fi

SKILLS_DIR="$HOME/.claude/skills"
SKILLS=(
    "qiita-draft"
    "qiita-publish"
    "qiita-review"
    "qiita-workflow"
    "qiita-topics-from-slack"
)

echo -e "${YELLOW}Skillsを削除中...${NC}"

for skill in "${SKILLS[@]}"; do
    SKILL_PATH="$SKILLS_DIR/$skill"
    if [ -d "$SKILL_PATH" ]; then
        rm -rf "$SKILL_PATH"
        echo -e "${GREEN}  ✓ $skill を削除しました${NC}"
    else
        echo -e "${BLUE}  → $skill は見つかりませんでした（スキップ）${NC}"
    fi
done

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  アンインストールが完了しました${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}次のステップ:${NC}"
echo -e "  1. Claude Code を再起動してください"
echo -e "  2. Obsidian Vault内の記事ファイルを削除したい場合は、手動で削除してください"
echo -e "     ${YELLOW}rm -rf ~/path/to/vault/11_Qiita/${NC}"
echo ""
