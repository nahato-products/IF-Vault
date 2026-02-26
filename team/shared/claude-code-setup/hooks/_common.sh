#!/bin/bash
# _common.sh — Shared utility functions for Claude Code hooks
# Sourced by multiple hooks. Caller must set -euo pipefail.
set -euo pipefail

# Extract file_path from hook JSON input via python3
# Usage: file_path=$(extract_file_path "$input")
extract_file_path() {
  local input="$1"
  printf '%s\n' "$input" | python3 -c "
import sys, json
try:
    print(json.load(sys.stdin).get('tool_input', {}).get('file_path', ''))
except (json.JSONDecodeError, ValueError):
    pass
" 2>/dev/null
}

# Rotate log file when it exceeds max lines
# Usage: rotate_log "$LOG_FILE" "$MAX_LINES" "$KEEP_LINES"
rotate_log() {
  local log_file="$1"
  local max_lines="$2"
  local keep_lines="$3"
  if [ -f "$log_file" ]; then
    local line_count
    line_count=$(wc -l < "$log_file" | tr -d ' ')
    if [ "$line_count" -gt "$max_lines" ]; then
      local temp_file
      temp_file=$(mktemp "${log_file}.XXXXXX")
      tail -n "$keep_lines" "$log_file" > "$temp_file"
      mv "$temp_file" "$log_file"
    fi
  fi
}
