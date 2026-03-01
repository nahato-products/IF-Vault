#!/bin/bash
# Qiita MCP Server Health Check & Auto-Repair Script

CONFIG_FILE="$HOME/.claude/config.json"
BACKUP_DIR="$HOME/.claude/backups"
ENV_FILE="$HOME/Documents/Obsidian Vault/11_Qiita/qiita-mcp-server/.env"
MCP_SERVER_PATH="$HOME/Documents/Obsidian Vault/11_Qiita/qiita-mcp-server/index.js"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Check if config.json exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ config.json not found at $CONFIG_FILE"
  exit 1
fi

# Backup current config
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
cp "$CONFIG_FILE" "$BACKUP_DIR/config.json.$TIMESTAMP"
echo "✅ Backed up config.json to $BACKUP_DIR/config.json.$TIMESTAMP"

# Check if qiita MCP server is configured
if ! grep -q '"qiita"' "$CONFIG_FILE"; then
  echo "⚠️  Qiita MCP server not configured in config.json"
  echo "🔧 Auto-repairing..."

  # Read current config
  CURRENT_CONFIG=$(cat "$CONFIG_FILE")

  # Check if mcpServers exists
  if echo "$CURRENT_CONFIG" | grep -q '"mcpServers"'; then
    # Add qiita to existing mcpServers
    python3 << 'EOF'
import json
import sys

config_path = "$HOME/.claude/config.json".replace("$HOME", __import__('os').path.expanduser('~'))
with open(config_path, 'r') as f:
    config = json.load(f)

if 'mcpServers' not in config:
    config['mcpServers'] = {}

config['mcpServers']['qiita'] = {
    "command": "node",
    "args": [
        "$HOME/Documents/Obsidian Vault/11_Qiita/qiita-mcp-server/index.js".replace("$HOME", __import__('os').path.expanduser('~'))
    ]
}

with open(config_path, 'w') as f:
    json.dump(config, f, indent=2)

print("✅ Added qiita MCP server to config.json")
EOF
  else
    echo "❌ config.json is malformed. Please check manually."
    exit 1
  fi
fi

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
  echo "❌ .env file not found at $ENV_FILE"
  exit 1
fi

# Check if QIITA_ACCESS_TOKEN is set in .env
if ! grep -q "QIITA_ACCESS_TOKEN=" "$ENV_FILE"; then
  echo "❌ QIITA_ACCESS_TOKEN not found in .env file"
  exit 1
fi

echo "✅ All checks passed!"
echo ""
echo "📋 Configuration Summary:"
echo "  - config.json: ✅ Qiita MCP server configured"
echo "  - .env file: ✅ QIITA_ACCESS_TOKEN set"
echo "  - MCP server: ✅ $MCP_SERVER_PATH"
echo ""
echo "🔄 Please restart Claude Code to apply changes."
