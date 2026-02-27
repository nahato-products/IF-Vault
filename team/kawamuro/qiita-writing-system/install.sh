#!/bin/bash

# Qiita記事執筆システム - インストールスクリプト

set -e

echo "========================================="
echo "Qiita記事執筆システム - インストール"
echo "========================================="
echo ""

# 色の定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Obsidian Vaultのパスを確認
echo "Obsidian Vaultのパスを入力してください:"
read -p "パス: " VAULT_PATH

if [ ! -d "$VAULT_PATH" ]; then
    echo -e "${RED}エラー: ディレクトリが存在しません: $VAULT_PATH${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✓${NC} Obsidian Vault: $VAULT_PATH"
echo ""

# ステップ1: Skillsのインストール
echo "========================================="
echo "ステップ1: Skillsのインストール"
echo "========================================="

if [ ! -d ~/.claude/skills ]; then
    mkdir -p ~/.claude/skills
    echo -e "${GREEN}✓${NC} ~/.claude/skills ディレクトリを作成しました"
fi

cp -r skills/* ~/.claude/skills/
echo -e "${GREEN}✓${NC} Skillsをインストールしました"
echo ""

# ステップ2: Obsidian Vaultのセットアップ
echo "========================================="
echo "ステップ2: Obsidian Vaultのセットアップ"
echo "========================================="

mkdir -p "$VAULT_PATH/11_Qiita/drafts"
mkdir -p "$VAULT_PATH/11_Qiita/published"
mkdir -p "$VAULT_PATH/11_Qiita/templates"

echo -e "${GREEN}✓${NC} ディレクトリを作成しました"

cp config/.qiita-config.yaml "$VAULT_PATH/11_Qiita/"
echo -e "${GREEN}✓${NC} 設定ファイルをコピーしました"
echo ""

# ステップ3: Qiita MCPサーバーのセットアップ
echo "========================================="
echo "ステップ3: Qiita MCPサーバーのセットアップ"
echo "========================================="

cp -r mcp-server/qiita-mcp-server "$VAULT_PATH/11_Qiita/"
echo -e "${GREEN}✓${NC} MCPサーバーをコピーしました"

cd "$VAULT_PATH/11_Qiita/qiita-mcp-server"
echo "npm install を実行中..."
npm install > /dev/null 2>&1
echo -e "${GREEN}✓${NC} 依存関係をインストールしました"
echo ""

# ステップ4: Qiitaアクセストークンの設定
echo "========================================="
echo "ステップ4: Qiitaアクセストークンの設定"
echo "========================================="
echo ""
echo -e "${YELLOW}Qiitaアクセストークンを取得してください:${NC}"
echo "1. https://qiita.com/settings/tokens/new を開く"
echo "2. 「個人用アクセストークン」を作成"
echo "3. スコープを選択: read_qiita, write_qiita"
echo ""
read -p "Qiitaアクセストークンを入力: " QIITA_TOKEN

echo "QIITA_ACCESS_TOKEN=$QIITA_TOKEN" > "$VAULT_PATH/11_Qiita/qiita-mcp-server/.env"
echo -e "${GREEN}✓${NC} トークンを設定しました"
echo ""

# ステップ5: MCP設定ファイルの配置
echo "========================================="
echo "ステップ5: MCP設定ファイルの配置"
echo "========================================="

# .mcp.jsonを生成（パスを置換）
cat config/.mcp.json.example | sed "s|/Users/kawamurohirokazu/Documents/Obsidian Vault|$VAULT_PATH|g" > "$VAULT_PATH/.mcp.json"
echo -e "${GREEN}✓${NC} .mcp.jsonを配置しました"
echo ""

# 完了
echo "========================================="
echo -e "${GREEN}✓ インストール完了！${NC}"
echo "========================================="
echo ""
echo "次のステップ:"
echo "1. Claude Codeを完全に終了してから再起動"
echo "2. Obsidian Vaultに移動: cd $VAULT_PATH"
echo "3. ワークフローを開始: /qiita-workflow start"
echo ""
echo "詳しい使い方は README.md を参照してください。"
echo ""
