#!/bin/bash
# Hook: PostToolUse (Edit|Write) — 編集後に ESLint 自動 fix
#
# Cursor の afterFileEdit hooks にインスパイアされた機能。
# TS/JS/TSX/JSX ファイルの編集後、プロジェクトに ESLint があれば
# 自動で --fix を実行し、残存するエラーを additionalContext で通知する。
#
# オプトイン: プロジェクトルートに .claude/lint-on-edit ファイルを作ることで有効化
# （空ファイルでOK。touch .claude/lint-on-edit で有効化）
set -uo pipefail
source "$(dirname "$0")/_common.sh"

input=$(cat)
file_path=$(extract_file_path "$input")

# ファイルパスが取れなければスキップ
[ -z "$file_path" ] && exit 0
[ -f "$file_path" ] || exit 0

# JS/TS ファイルのみ対象
case "$file_path" in
  *.ts|*.tsx|*.js|*.jsx|*.mts|*.cts|*.mjs|*.cjs) ;;
  *) exit 0 ;;
esac

# プロジェクトルートを探す
project_root=$(cd "$(dirname "$file_path")" && git rev-parse --show-toplevel 2>/dev/null) || exit 0

# オプトインチェック: .claude/lint-on-edit が存在する場合のみ実行
[ -f "${project_root}/.claude/lint-on-edit" ] || exit 0

# package.json が存在するプロジェクトのみ
[ -f "${project_root}/package.json" ] || exit 0

# ESLint config が存在するか確認
has_eslint=false
for cfg in \
  "${project_root}/eslint.config.js" \
  "${project_root}/eslint.config.ts" \
  "${project_root}/eslint.config.mjs" \
  "${project_root}/.eslintrc.js" \
  "${project_root}/.eslintrc.cjs" \
  "${project_root}/.eslintrc.json" \
  "${project_root}/.eslintrc.yaml" \
  "${project_root}/.eslintrc.yml" \
  "${project_root}/.eslintrc"; do
  [ -f "$cfg" ] && has_eslint=true && break
done
$has_eslint || exit 0

# ESLint を実行（タイムアウト: 15秒）
cd "$project_root" || exit 0

lint_output=""
lint_exit=0
lint_output=$(timeout 15 npx eslint --fix "$file_path" --format compact 2>&1) || lint_exit=$?

# 正常終了 (fix 完了) または タイムアウト/eslint未インストール の場合はスキップ
[ $lint_exit -eq 127 ] && exit 0  # npx not found
[ $lint_exit -eq 124 ] && exit 0  # timeout

# 残存エラーがある場合のみ通知
if [ $lint_exit -ne 0 ] && [ -n "$lint_output" ]; then
  # エラー行のみ抽出（先頭5件）
  error_lines=$(echo "$lint_output" | grep -E "error|warning" | head -5)
  if [ -n "$error_lines" ]; then
    cat << JSON
{
  "additionalContext": "⚡ ESLint (lint-on-edit):\n${error_lines}"
}
JSON
  fi
fi

exit 0
