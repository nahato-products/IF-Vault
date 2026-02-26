#!/bin/bash
# _destructive-patterns.sh — Shared destructive command pattern detection
# Sourced by command-shield.sh and command-shield-gui.sh
# Usage: classify_destructive "$command"
# Returns: sets DESTRUCTIVE_LABEL and DESTRUCTIVE_REASON if pattern matches
set -euo pipefail

classify_destructive() {
  local cmd="$1"
  DESTRUCTIVE_LABEL=""
  DESTRUCTIVE_REASON=""

  if printf '%s' "$cmd" | grep -qE '(rm\s+-(r|f|rf|fr)|rm\s+-r\s+-f|rm\s+-f\s+-r)'; then
    DESTRUCTIVE_LABEL="rm -rf"; DESTRUCTIVE_REASON="再帰的ファイル削除 — 不可逆"
  elif printf '%s' "$cmd" | grep -qiE '(DROP\s+(TABLE|DATABASE|INDEX|SCHEMA)|TRUNCATE\s+TABLE)'; then
    DESTRUCTIVE_LABEL="SQL DROP/TRUNCATE"; DESTRUCTIVE_REASON="データベース破壊操作 — 不可逆"
  elif printf '%s' "$cmd" | grep -qE 'git\s+push\s+.*(-f|--force)'; then
    DESTRUCTIVE_LABEL="git push --force"; DESTRUCTIVE_REASON="リモート履歴上書き — 不可逆"
  elif printf '%s' "$cmd" | grep -qE 'git\s+reset\s+--hard'; then
    DESTRUCTIVE_LABEL="git reset --hard"; DESTRUCTIVE_REASON="未コミット変更を全消去 — 不可逆"
  elif printf '%s' "$cmd" | grep -qE 'git\s+clean\s+.*-f'; then
    DESTRUCTIVE_LABEL="git clean -f"; DESTRUCTIVE_REASON="未追跡ファイル削除 — 不可逆"
  elif printf '%s' "$cmd" | grep -qE 'git\s+(checkout|restore)\s+\.\s*$'; then
    DESTRUCTIVE_LABEL="git checkout/restore ."; DESTRUCTIVE_REASON="作業ツリー全復元 — 未保存変更消失"
  elif printf '%s' "$cmd" | grep -qE 'sudo\s+rm'; then
    DESTRUCTIVE_LABEL="sudo rm"; DESTRUCTIVE_REASON="特権でのファイル削除 — 不可逆"
  elif printf '%s' "$cmd" | grep -qE '>\s*/dev/sd|mkfs\.|dd\s+if='; then
    DESTRUCTIVE_LABEL="disk write"; DESTRUCTIVE_REASON="ディスク直接書き込み — 不可逆"
  elif printf '%s' "$cmd" | grep -qE 'chmod\s+777'; then
    DESTRUCTIVE_LABEL="chmod 777"; DESTRUCTIVE_REASON="全権限開放 — セキュリティリスク"
  elif printf '%s' "$cmd" | grep -qE '(curl|wget)\s.*\|\s*(bash|sh|zsh)'; then
    DESTRUCTIVE_LABEL="pipe to shell"; DESTRUCTIVE_REASON="リモートスクリプト実行 — 任意コード実行リスク"
  fi
}
