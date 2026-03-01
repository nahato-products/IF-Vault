#!/bin/bash
# Claude Code config.json Automatic Backup Script
# This script should be run periodically (e.g., via cron or before Claude Code starts)

CONFIG_FILE="$HOME/.claude/config.json"
BACKUP_DIR="$HOME/.claude/backups/config"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
MAX_BACKUPS=30  # Keep last 30 backups

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Check if config.json exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo "⚠️  config.json not found. Skipping backup."
  exit 0
fi

# Create backup
BACKUP_FILE="$BACKUP_DIR/config.json.$TIMESTAMP"
cp "$CONFIG_FILE" "$BACKUP_FILE"
echo "✅ Backed up config.json to $BACKUP_FILE"

# Remove old backups (keep only last MAX_BACKUPS)
BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/config.json.* 2>/dev/null | wc -l)
if [ "$BACKUP_COUNT" -gt "$MAX_BACKUPS" ]; then
  REMOVE_COUNT=$((BACKUP_COUNT - MAX_BACKUPS))
  ls -1t "$BACKUP_DIR"/config.json.* | tail -n "$REMOVE_COUNT" | xargs rm -f
  echo "🗑️  Removed $REMOVE_COUNT old backup(s)"
fi

# Check if qiita MCP server is configured
if ! grep -q '"qiita"' "$CONFIG_FILE"; then
  echo "⚠️  WARNING: Qiita MCP server not found in config.json!"
  echo "    Run healthcheck to repair: ~/.claude/skills/qiita-publish/.qiita-mcp-healthcheck.sh"
fi
