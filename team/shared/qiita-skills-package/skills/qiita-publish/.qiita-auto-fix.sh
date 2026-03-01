#!/bin/bash

# Qiita MCP自動修復スクリプト
# このスクリプトは、config.jsonのQiita MCP設定を自動的にチェック・修復します

CONFIG_FILE="$HOME/.claude/config.json"
BACKUP_DIR="$HOME/.claude/backups/config"
ENV_FILE="$HOME/Documents/Obsidian Vault/11_Qiita/qiita-mcp-server/.env"

echo "🔍 Qiita MCP設定をチェック中..."

# バックアップディレクトリの作成
mkdir -p "$BACKUP_DIR"

# .envからトークンを取得
if [ -f "$ENV_FILE" ]; then
  TOKEN=$(grep QIITA_ACCESS_TOKEN "$ENV_FILE" | cut -d'=' -f2)
  echo "✅ .envファイルからトークンを取得"
else
  echo "❌ .envファイルが見つかりません: $ENV_FILE"
  exit 1
fi

# config.jsonの存在確認
if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ config.jsonが見つかりません"
  exit 1
fi

# config.jsonにenv設定があるかチェック
if ! grep -q '"env"' "$CONFIG_FILE"; then
  echo "⚠️  config.jsonにenv設定がありません。自動修復を実行します..."
  
  # バックアップ
  cp "$CONFIG_FILE" "$BACKUP_DIR/config.json.auto_backup_$(date +%Y%m%d_%H%M%S)"
  
  # 新しい設定を作成
  cat > "$CONFIG_FILE" << EOF
{
  "mcpServers": {
    "qiita": {
      "command": "node",
      "args": [
        "$HOME/Documents/Obsidian Vault/11_Qiita/qiita-mcp-server/index.js"
      ],
      "env": {
        "QIITA_ACCESS_TOKEN": "$TOKEN"
      }
    }
  }
}
EOF
  
  echo "✅ config.jsonを修復しました"
  echo "🔄 Claude Codeを再起動してください"
else
  echo "✅ config.jsonの設定は正常です"
fi
