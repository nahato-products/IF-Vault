#!/bin/bash
# PreToolUse: Block Read of sensitive files (.env, keys, credentials)
# Exit 2 = hard block (deny pattern bypass workaround)
set -euo pipefail
source "$(dirname "$0")/_common.sh"
input=$(cat)
file_path=$(extract_file_path "$input")

if [ -z "$file_path" ]; then exit 0; fi

# Block sensitive paths (full path match) — チルダ展開のみ（eval禁止）
resolved="${file_path/#\~/$HOME}"
case "$resolved" in
  "$HOME/.ssh/config"|"$HOME/.ssh/config."*)
    printf '%s\n' "機密ファイル ~/.ssh/config の読み取りをブロック" >&2
    exit 2
    ;;
esac

basename=$(basename -- "$file_path" 2>/dev/null)
case "$basename" in
  .env|.env.*|*.pem|*.key|*.p12|*.pfx|*.keystore|id_rsa*|credentials.json|secrets.json|secrets.yaml|secrets.yml)
    printf '%s\n' "機密ファイル ${basename} の読み取りをブロック" >&2
    exit 2
    ;;
esac
exit 0
