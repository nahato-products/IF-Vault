#!/bin/bash
# Claude Code config.json Restore Script

CONFIG_FILE="$HOME/.claude/config.json"
BACKUP_DIR="$HOME/.claude/backups/config"

# List available backups
echo "📋 Available config.json backups:"
echo ""
ls -lt "$BACKUP_DIR"/config.json.* 2>/dev/null | head -10 | awk '{print NR". "$9" ("$6" "$7" "$8")"}'

if [ ! -f "$BACKUP_DIR/config.json."* ]; then
  echo "❌ No backups found in $BACKUP_DIR"
  exit 1
fi

echo ""
echo "Which backup do you want to restore? (Enter number, or 'q' to quit)"
read -r choice

if [ "$choice" = "q" ] || [ "$choice" = "Q" ]; then
  echo "Cancelled."
  exit 0
fi

# Get the selected backup file
SELECTED_BACKUP=$(ls -1t "$BACKUP_DIR"/config.json.* | sed -n "${choice}p")

if [ -z "$SELECTED_BACKUP" ]; then
  echo "❌ Invalid selection"
  exit 1
fi

echo ""
echo "📄 Selected backup:"
echo "  $SELECTED_BACKUP"
echo ""
echo "This will replace your current config.json. Continue? (y/N)"
read -r confirm

if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
  echo "Cancelled."
  exit 0
fi

# Backup current config before restoring
if [ -f "$CONFIG_FILE" ]; then
  TIMESTAMP=$(date +%Y%m%d_%H%M%S)
  cp "$CONFIG_FILE" "$CONFIG_FILE.before-restore.$TIMESTAMP"
  echo "✅ Backed up current config to $CONFIG_FILE.before-restore.$TIMESTAMP"
fi

# Restore
cp "$SELECTED_BACKUP" "$CONFIG_FILE"
echo "✅ Restored config.json from backup"
echo ""
echo "🔄 Please restart Claude Code to apply changes."
