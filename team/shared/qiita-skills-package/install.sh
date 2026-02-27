#!/bin/bash

# Qiita Skills Package インストーラー
# Claude Code用のQiita記事執筆Skillsをインストールします

set -e

# カラー出力
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Qiita Skills Package インストーラー${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 必要な環境チェック
echo -e "${YELLOW}[1/5] 環境チェック中...${NC}"

if ! command -v claude &> /dev/null; then
    echo -e "${RED}✗ Claude Codeがインストールされていません${NC}"
    echo "  https://github.com/anthropics/claude-code からインストールしてください"
    exit 1
fi

echo -e "${GREEN}✓ Claude Codeが見つかりました${NC}"

# Claude Codeのディレクトリ確認
CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"

if [ ! -d "$SKILLS_DIR" ]; then
    echo -e "${YELLOW}  Skillsディレクトリを作成します: $SKILLS_DIR${NC}"
    mkdir -p "$SKILLS_DIR"
fi

echo -e "${GREEN}✓ Claude Codeディレクトリが見つかりました${NC}"
echo ""

# Obsidian Vaultパスの確認
echo -e "${YELLOW}[2/5] Obsidian Vaultパスを入力してください${NC}"
echo -e "  ${BLUE}例: $HOME/Documents/Obsidian\ Vault${NC}"
read -p "Obsidian Vaultのパス: " VAULT_PATH

# パスの検証
VAULT_PATH="${VAULT_PATH/#\~/$HOME}"  # ~を$HOMEに展開

if [ ! -d "$VAULT_PATH" ]; then
    echo -e "${RED}✗ 指定されたパスが見つかりません: $VAULT_PATH${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Obsidian Vaultが見つかりました${NC}"
echo ""

# Skillsのインストール
echo -e "${YELLOW}[3/5] Skillsをインストール中...${NC}"

SKILLS=(
    "qiita-draft"
    "qiita-publish"
    "qiita-review"
    "qiita-workflow"
)

for skill in "${SKILLS[@]}"; do
    TARGET_DIR="$SKILLS_DIR/$skill"

    if [ -d "$TARGET_DIR" ]; then
        echo -e "${YELLOW}  ⚠ $skill は既にインストールされています。上書きしますか? (y/N)${NC}"
        read -p "  > " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "  ${BLUE}→ $skill をスキップしました${NC}"
            continue
        fi
        rm -rf "$TARGET_DIR"
    fi

    mkdir -p "$TARGET_DIR"
    cp "skills/$skill/skill.md" "$TARGET_DIR/"
    echo -e "${GREEN}  ✓ $skill をインストールしました${NC}"
done

echo ""

# オプション: Slack連携Skillのインストール
echo -e "${YELLOW}[4/5] オプション機能のインストール${NC}"
echo -e "${BLUE}Slack連携Skill (qiita-topics-from-slack) をインストールしますか?${NC}"
echo -e "  ※ Claude Code に Slack MCP サーバーが設定されている必要があります"
read -p "インストールする? (y/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    TARGET_DIR="$SKILLS_DIR/qiita-topics-from-slack"
    mkdir -p "$TARGET_DIR"
    cp "skills/qiita-topics-from-slack/skill.md" "$TARGET_DIR/"
    echo -e "${GREEN}  ✓ qiita-topics-from-slack をインストールしました${NC}"
else
    echo -e "${BLUE}  → Slack連携Skillをスキップしました${NC}"
fi

echo ""

# Qiitaディレクトリ構造の作成
echo -e "${YELLOW}[5/5] Qiitaディレクトリ構造を作成中...${NC}"

QIITA_DIR="$VAULT_PATH/11_Qiita"

if [ -d "$QIITA_DIR" ]; then
    echo -e "${YELLOW}  ⚠ 11_Qiita ディレクトリは既に存在します。上書きしますか? (y/N)${NC}"
    read -p "  > " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}  → ディレクトリ作成をスキップしました${NC}"
    else
        # 既存の記事を保護
        if [ -d "$QIITA_DIR/drafts" ] || [ -d "$QIITA_DIR/published" ]; then
            BACKUP_DIR="$QIITA_DIR.backup.$(date +%Y%m%d_%H%M%S)"
            echo -e "${YELLOW}  既存の記事をバックアップします: $BACKUP_DIR${NC}"
            mv "$QIITA_DIR" "$BACKUP_DIR"
        fi

        mkdir -p "$QIITA_DIR"/{drafts,published,templates}
        cp config/.qiita-config.yaml "$QIITA_DIR/"
        cp config/templates/article-template.md "$QIITA_DIR/templates/"
        cp docs/*.md "$QIITA_DIR/"
        echo -e "${GREEN}  ✓ Qiitaディレクトリ構造を作成しました${NC}"
    fi
else
    mkdir -p "$QIITA_DIR"/{drafts,published,templates}
    cp config/.qiita-config.yaml "$QIITA_DIR/"
    cp config/templates/article-template.md "$QIITA_DIR/templates/"
    cp docs/*.md "$QIITA_DIR/"
    echo -e "${GREEN}  ✓ Qiitaディレクトリ構造を作成しました${NC}"
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  インストールが完了しました！ 🎉${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}インストールされたSkills:${NC}"
for skill in "${SKILLS[@]}"; do
    echo -e "  ${GREEN}✓${NC} /$skill"
done

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "  ${GREEN}✓${NC} /qiita-topics-from-slack"
fi

echo ""
echo -e "${BLUE}次のステップ:${NC}"
echo -e "  1. Claude Code を再起動してください"
echo -e "  2. ${GREEN}/qiita-workflow start${NC} で記事執筆を開始"
echo -e "  3. 詳しい使い方は ${YELLOW}$QIITA_DIR/QUICKSTART.md${NC} を参照"
echo ""
echo -e "${YELLOW}📚 ドキュメント:${NC}"
echo -e "  - QUICKSTART.md - クイックスタートガイド"
echo -e "  - WORKFLOW_GUIDE.md - ワークフローガイド"
echo -e "  - SYSTEM_ARCHITECTURE.md - システム構成"
echo ""
echo -e "${GREEN}Happy Writing! 🚀${NC}"
