#!/bin/bash
# Hook C: Stop — セッション終了時の自動メンテナンス
#
# 【仕様制約】Stop hook は additionalContext をサポートしない。
# 【方針】stderr でターミナル通知 + ファイル書き出し

# stdin を消費
cat >/dev/null 2>&1

# --- 1. Git 未コミット変更チェック（Git リポジトリ内のみ） ---
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  unstaged=$(git diff --stat 2>/dev/null)
  staged=$(git diff --cached --stat 2>/dev/null)
  untracked_count=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

  # untracked_count が数値であることを保証
  case "$untracked_count" in
    ''|*[!0-9]*) untracked_count=0 ;;
  esac

  if [ -n "$unstaged" ] || [ -n "$staged" ] || [ "$untracked_count" -gt 0 ]; then
    summary=""
    [ -n "$staged" ] && summary="${summary}Staged: $(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ') files "
    [ -n "$unstaged" ] && summary="${summary}Unstaged: $(git diff --name-only 2>/dev/null | wc -l | tr -d ' ') files "
    [ "$untracked_count" -gt 0 ] && summary="${summary}Untracked: ${untracked_count} files"

    STATE_DIR="${HOME:?}/.claude/session-env"
    mkdir -p "$STATE_DIR"
    cat > "$STATE_DIR/uncommitted-changes.md" <<EOF
# 未コミット変更 ($(date +"%Y-%m-%d %H:%M:%S"))
${summary}

## Staged
\`\`\`
${staged:-なし}
\`\`\`

## Unstaged
\`\`\`
${unstaged:-なし}
\`\`\`
EOF
    printf '%s\n' "未コミット変更あり: ${summary}" >&2
  fi
fi

# --- 2. debug/ セッションログ自動ローテーション ---
DEBUG_DIR="${HOME:?}/.claude/debug"
if [ -d "$DEBUG_DIR" ]; then
  find "$DEBUG_DIR" -name "*.txt" -type f -mtime +3 -delete 2>/dev/null
fi

# --- 3. session-env/ 空ディレクトリ掃除 ---
SESSION_DIR="${HOME:?}/.claude/session-env"
if [ -d "$SESSION_DIR" ]; then
  find "$SESSION_DIR" -mindepth 1 -maxdepth 1 -type d -empty -delete 2>/dev/null
fi

# --- 4. settings.local.json 自動クリーンアップ ---
SETTINGS_FILE="${HOME:?}/.claude/settings.local.json"
if [ -f "$SETTINGS_FILE" ]; then
  python3 -c "
import json, sys, os, tempfile

path = os.path.expanduser('~/.claude/settings.local.json')
try:
    with open(path, 'r') as f:
        data = json.load(f)
except (json.JSONDecodeError, OSError):
    sys.exit(0)

allow = data.get('permissions', {}).get('allow', [])
if not isinstance(allow, list):
    sys.exit(0)

# 危険なワイルドカードパターン
bad_prefixes = [
    'Bash(bash:', 'Bash(dd:', 'Bash(echo:',
    'Bash(python3:', 'Bash(python:', 'Bash(npx:',
    'Bash(chmod:', 'Bash(open:', 'Bash(ln:',
    'Bash(curl:', 'Bash(wget:',
    'Bash(for ', 'Bash(do ', 'Bash(done', 'Bash(if ',
    'Bash(then', 'Bash(fi)',
]
original = len(allow)
cleaned = [
    e for e in allow
    if isinstance(e, str)
    and not any(e.startswith(p) for p in bad_prefixes)
    and len(e) <= 100
]

if len(cleaned) == original:
    sys.exit(0)

data['permissions']['allow'] = cleaned

# アトミック書き込み（途中クラッシュでファイル破損を防止）
try:
    dir_name = os.path.dirname(path)
    fd, tmp_path = tempfile.mkstemp(dir=dir_name, suffix='.tmp')
    with os.fdopen(fd, 'w') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write('\n')
    os.replace(tmp_path, path)
except OSError:
    # tmp_path が残っていたら掃除
    try:
        os.unlink(tmp_path)
    except (OSError, NameError):
        pass
" 2>/dev/null
fi

exit 0
