#!/bin/bash
# Hook B: PostToolUse (Edit|Write) — ファイル変更後セキュリティチェック
# ブロックせず警告のみ（additionalContext）

input=$(cat)

file_path=$(printf '%s\n' "$input" | python3 -c "
import sys, json
try:
    print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))
except (json.JSONDecodeError, ValueError):
    pass
" 2>/dev/null)

if [ -z "$file_path" ]; then
  exit 0
fi

warnings=""

# 1. 危険なファイル名パターンチェック
file_basename=$(basename -- "$file_path")
case "$file_basename" in
  .env|.env.*|*.env|credentials.json|secrets.json|secrets.yaml|secrets.yml|*.pem|*.key|id_rsa*)
    warnings="機密ファイル(${file_basename})が編集された。Gitにコミットしないで！"
    ;;
esac

# 2. ファイル内容のセキュリティパターン検出（先頭1000行のみ）
if [ -f "$file_path" ]; then
  real_matches=$(head -1000 -- "$file_path" 2>/dev/null \
    | grep -inE '(api_key|api_secret|secret_key|password|access_token|private_key|token)\s*[:=]' \
    | grep -ivE '(process\.env|os\.environ|env\(|getenv|import|require|from|type|interface|//|#|NEXT_PUBLIC_|placeholder|example|TODO)' \
    | wc -l | tr -d ' ')
  if [ -n "$real_matches" ] && [ "$real_matches" -gt 0 ]; then
    if [ -n "$warnings" ]; then
      warnings="${warnings} + ハードコード機密${real_matches}件検出。環境変数に移して！"
    else
      warnings="ハードコード機密${real_matches}件検出。環境変数に移して！"
    fi
  fi
fi

# 警告がある場合のみ出力
if [ -n "$warnings" ]; then
  printf '%s\n' "$warnings" | python3 -c "
import sys, json
msg = sys.stdin.read().strip()
print(json.dumps({
    'hookSpecificOutput': {
        'hookEventName': 'PostToolUse',
        'additionalContext': msg
    }
}, ensure_ascii=False))
" 2>/dev/null
fi

exit 0
