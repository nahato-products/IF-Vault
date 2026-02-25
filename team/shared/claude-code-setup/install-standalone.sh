#!/bin/bash
# ============================================================
# Claude Code チーム環境セットアップ（スタンドアロン版）
#
# Git リポジトリ不要。配布zipに同梱された全ファイルを
# cp でコピーしてインストールする。
#
# 使い方: bash install.sh
# オプション:
#   --verify          インストール後ヘルスチェック
#   --community       コミュニティスキル一括インストール
#   --skill=スキル名  指定スキルだけインストール
# ============================================================

set -euo pipefail

# --- カラー出力 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { printf "${BLUE}[INFO]${NC}  %s\n" "$1"; }
ok()    { printf "${GREEN}[OK]${NC}    %s\n" "$1"; }
warn()  { printf "${YELLOW}[WARN]${NC}  %s\n" "$1"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$1"; }
header(){ printf "\n${CYAN}--- %s ---${NC}\n" "$1"; }

# --- 引数パース ---
FLAG_VERIFY=false
FLAG_COMMUNITY=false
FLAG_SKILL=""

for arg in "$@"; do
  case "$arg" in
    --verify)    FLAG_VERIFY=true ;;
    --community) FLAG_COMMUNITY=true ;;
    --skill=*)   FLAG_SKILL="${arg#--skill=}" ;;
    --help|-h)
      echo "使い方: bash install.sh [--verify] [--community] [--skill=スキル名]"
      echo ""
      echo "オプション:"
      echo "  (なし)             チーム環境フルインストール"
      echo "  --verify           ヘルスチェックのみ実行"
      echo "  --community        コミュニティスキル(11個)を一括インストール"
      echo "  --skill=スキル名   指定スキルだけインストール"
      echo "  --help             このヘルプを表示"
      echo ""
      echo "例:"
      echo "  bash install.sh --skill=playwright      # playwright だけ追加"
      echo "  bash install.sh --skill=deep-research   # deep-research だけ追加"
      exit 0
      ;;
    *) error "不明なオプション: $arg (--help でヘルプ表示)"; exit 1 ;;
  esac
done

# --- パス設定 ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"
HOOKS_DIR="${CLAUDE_DIR}/hooks"
SKILLS_DIR="${CLAUDE_DIR}/skills"
SESSION_DIR="${CLAUDE_DIR}/session-env"
DEBUG_DIR="${CLAUDE_DIR}/debug"

# 全スキルが同梱されている（共有 + メタ統合済み）
BUNDLED_SKILLS_DIR="${SCRIPT_DIR}/skills"
BUNDLED_HOOKS_DIR="${SCRIPT_DIR}/hooks"
BUNDLED_TEMPLATES_DIR="${SCRIPT_DIR}/templates"

# --- 事前チェック ---
if ! command -v claude &>/dev/null; then
  error "Claude Code がインストールされていません"
  echo "  インストール: https://docs.anthropic.com/en/docs/claude-code"
  exit 1
fi

# 配布パッケージの整合性チェック
if [ ! -d "$BUNDLED_SKILLS_DIR" ]; then
  error "skills/ フォルダが見つかりません。配布zipが壊れている可能性があります"
  exit 1
fi

if [ ! -d "$BUNDLED_HOOKS_DIR" ]; then
  error "hooks/ フォルダが見つかりません。配布zipが壊れている可能性があります"
  exit 1
fi

# ============================================================
# ヘルスチェック関数（--verify で使用）
# ============================================================
run_verify() {
  echo ""
  echo "========================================="
  echo "  ヘルスチェック"
  echo "========================================="
  echo ""

  local issues=0

  # 1. Skills 数チェック
  header "Skills"
  local skill_count=0
  if [ -d "$SKILLS_DIR" ]; then
    skill_count=$(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d -o -type l | wc -l | tr -d ' ')
  fi
  if [ "$skill_count" -ge 50 ]; then
    ok "Skills: ${skill_count}個 インストール済み"
  else
    warn "Skills: ${skill_count}個 (期待: 50個以上)"
    issues=$((issues + 1))
  fi

  # 2. SKILL.md 存在チェック
  header "SKILL.md"
  local missing_skillmd=0
  for dest in "$SKILLS_DIR"/*/; do
    [ -d "$dest" ] || continue
    local name
    name=$(basename "$dest")
    if [ ! -f "${dest}SKILL.md" ]; then
      warn "SKILL.md 未検出: ${name}"
      missing_skillmd=$((missing_skillmd + 1))
    fi
  done
  if [ "$missing_skillmd" -eq 0 ]; then
    ok "全スキルに SKILL.md あり"
  else
    issues=$((issues + missing_skillmd))
  fi

  # 3. Hooks 実行権限チェック
  header "Hooks"
  local hooks_ok=0
  local hooks_ng=0
  if [ -d "$HOOKS_DIR" ]; then
    for hook_file in "$HOOKS_DIR"/*.sh; do
      [ -f "$hook_file" ] || continue
      if [ -x "$hook_file" ]; then
        hooks_ok=$((hooks_ok + 1))
      else
        warn "実行権限なし: $(basename "$hook_file")"
        hooks_ng=$((hooks_ng + 1))
      fi
    done
  fi
  if [ "$hooks_ng" -eq 0 ] && [ "$hooks_ok" -gt 0 ]; then
    ok "Hooks: ${hooks_ok}個 全て実行権限あり"
  elif [ "$hooks_ok" -eq 0 ]; then
    warn "Hooks が見つかりません"
    issues=$((issues + 1))
  else
    issues=$((issues + hooks_ng))
  fi

  # 4. settings.json deny 数チェック
  header "settings.json"
  if [ -f "${CLAUDE_DIR}/settings.json" ]; then
    local deny_count
    deny_count=$(python3 -c "
import json
with open('${CLAUDE_DIR}/settings.json') as f:
    data = json.load(f)
print(len(data.get('permissions', {}).get('deny', [])))
" 2>/dev/null || echo "0")
    if [ "$deny_count" -ge 7 ]; then
      ok "deny list: ${deny_count}エントリ (7以上)"
    else
      warn "deny list: ${deny_count}エントリ (期待: 7以上)"
      issues=$((issues + 1))
    fi
  else
    warn "settings.json が見つかりません"
    issues=$((issues + 1))
  fi

  # 5. CLAUDE.md チェック
  header "CLAUDE.md"
  if [ -f "${CLAUDE_DIR}/CLAUDE.md" ]; then
    ok "グローバル CLAUDE.md あり"
  else
    warn "グローバル CLAUDE.md なし"
    issues=$((issues + 1))
  fi

  # 6. コピー済みスキルの確認（スタンドアロン版はシンボリックリンクではなくコピー）
  header "スキル配置方式"
  local symlink_count=0
  local copy_count=0
  for dest in "$SKILLS_DIR"/*/; do
    [ -d "$dest" ] || [ -L "$dest" ] || continue
    local name
    name=$(basename "$dest")
    local target="${SKILLS_DIR}/${name}"
    if [ -L "$target" ]; then
      symlink_count=$((symlink_count + 1))
    elif [ -d "$target" ]; then
      copy_count=$((copy_count + 1))
    fi
  done
  ok "コピー: ${copy_count}個, シンボリックリンク: ${symlink_count}個"

  # 結果サマリ
  echo ""
  echo "========================================="
  if [ "$issues" -eq 0 ]; then
    printf "  ${GREEN}全項目 OK!${NC}\n"
  else
    printf "  ${YELLOW}${issues}件 の注意事項あり${NC}\n"
  fi
  echo "========================================="
  echo ""
}

# ============================================================
# コミュニティスキル関数（--community で使用）
# ============================================================
run_community() {
  echo ""
  echo "========================================="
  echo "  コミュニティスキル 一括インストール"
  echo "========================================="
  echo ""

  mkdir -p "$SKILLS_DIR"

  COMMUNITY_SKILLS=(
    "nicholasoxford/agents@baseline-ui"
    "anthropics/claude-code@deep-research"
    "nicholasoxford/agents@docx"
    "nicholasoxford/agents@ffmpeg"
    "nicholasoxford/agents@find-skills"
    "nicholasoxford/agents@finishing-a-development-branch"
    "nicholasoxford/agents@mermaid-visualizer"
    "nicholasoxford/agents@pdf"
    "nicholasoxford/agents@pptx"
    "nicholasoxford/agents@xlsx"
    "nicholasoxford/agents@using-git-worktrees"
  )

  local community_installed=0
  local community_skipped=0

  for skill_ref in "${COMMUNITY_SKILLS[@]}"; do
    local skill_name="${skill_ref##*@}"
    local dest="${SKILLS_DIR}/${skill_name}"

    if [ -d "$dest" ] || [ -L "$dest" ]; then
      ok "${skill_name}: 既存（スキップ）"
      community_skipped=$((community_skipped + 1))
      continue
    fi

    info "${skill_name}: インストール中..."
    if npx -y @anthropic-ai/claude-code-skills add "${skill_ref}" -g -y 2>/dev/null; then
      ok "${skill_name}: インストール完了"
      community_installed=$((community_installed + 1))
    else
      warn "${skill_name}: 自動インストール失敗"
      echo "  → Claude Code 内で以下を実行してください:"
      echo "    /install-skill ${skill_ref}"
    fi
  done

  echo ""
  ok "コミュニティスキル: ${community_installed}個 新規, ${community_skipped}個 既存スキップ"
  echo ""
}

# ============================================================
# 個別スキルインストール関数（--skill で使用）
# ============================================================
run_skill() {
  local skill_name="$1"
  local src="${BUNDLED_SKILLS_DIR}/${skill_name}"
  local dest="${SKILLS_DIR}/${skill_name}"

  echo ""
  echo "========================================="
  echo "  スキル個別インストール: ${skill_name}"
  echo "========================================="
  echo ""

  if [ ! -d "$src" ]; then
    error "スキルが見つかりません: ${skill_name}"
    echo ""
    echo "利用可能なスキル一覧:"
    ls "$BUNDLED_SKILLS_DIR" | sed 's/^/  /'
    exit 1
  fi

  if [ -d "$dest" ] || [ -L "$dest" ]; then
    ok "${skill_name}: 既にインストール済み（スキップ）"
    echo "  → 再インストールしたい場合は手動で ~/.claude/skills/${skill_name} を削除してください"
    exit 0
  fi

  mkdir -p "$SKILLS_DIR"
  cp -r "$src" "$dest"
  ok "${skill_name}: インストール完了 → ~/.claude/skills/${skill_name}"
  echo ""
  echo "Claude Code を再起動して有効化してください"
  echo ""
}

# ============================================================
# フラグのみの場合 → 該当処理だけ実行して終了
# ============================================================
if [[ -n "$FLAG_SKILL" ]]; then
  run_skill "$FLAG_SKILL"
  exit 0
fi

if [[ "$FLAG_VERIFY" == true ]] || [[ "$FLAG_COMMUNITY" == true ]]; then
  [[ "$FLAG_VERIFY" == true ]]    && run_verify
  [[ "$FLAG_COMMUNITY" == true ]] && run_community
  exit 0
fi

# ============================================================
# メインインストールフロー
# ============================================================

# バージョン情報表示
PACKAGE_VERSION="不明"
if [ -f "${SCRIPT_DIR}/VERSION" ]; then
  PACKAGE_VERSION=$(head -1 "${SCRIPT_DIR}/VERSION" | sed 's/version: //')
fi

echo ""
echo "========================================="
echo "  Claude Code チーム環境セットアップ"
echo "  スタンドアロン版 v${PACKAGE_VERSION}"
echo "========================================="
echo ""
echo "以下をインストールします:"
echo "  - Hooks: セキュリティ・効率化スクリプト"
echo "  - settings.json: deny list + hooks 登録"
echo "  - Skills: チーム共有スキル (コピー)"
echo "  - グローバル CLAUDE.md テンプレート"
echo "  - 作業ディレクトリ (session-env, debug)"
echo ""

# --- ロール選択 ---
echo "あなたのロールを選んでください（推奨スキルを表示します）:"
echo "  1) 全員共通（全スキルをインストール）"
echo "  2) フロントエンド（UI/UX・React・デザイン系を優先）"
echo "  3) バックエンド（DB・API・インフラ系を優先）"
echo ""
read -p "ロール [1-3, デフォルト: 1]: " role_choice
role_choice="${role_choice:-1}"

echo ""
case "$role_choice" in
  2)
    info "フロントエンドロール: UI/UX/React/デザイン系を優先"
    info "  推奨: ux-psychology, react-component-patterns, tailwind-design-system,"
    info "        micro-interaction-patterns, design-token-system, web-design-guidelines"
    ;;
  3)
    info "バックエンドロール: DB/API/インフラ系を優先"
    info "  推奨: supabase-auth-patterns, supabase-postgres-best-practices,"
    info "        docker-expert, ci-cd-deployment, security-review"
    ;;
  *)
    info "全員共通: 全スキルをインストール"
    role_choice="1"
    ;;
esac

echo ""
read -p "続行しますか？ (y/N): " confirm
if [[ "$confirm" != [yY] ]]; then
  echo "キャンセルしました"
  exit 0
fi

echo ""

# --- Step 1: ディレクトリ作成 ---
info "ディレクトリ作成..."
mkdir -p "$HOOKS_DIR" "$SKILLS_DIR" "$SESSION_DIR" "$DEBUG_DIR"
ok "ディレクトリ作成完了"

# --- Step 2: Hooks インストール ---
info "Hooks インストール..."
hooks_installed=0

for hook_file in "$BUNDLED_HOOKS_DIR"/*.sh; do
  [ -f "$hook_file" ] || continue
  name=$(basename "$hook_file")
  dest="${HOOKS_DIR}/${name}"

  if [ -f "$dest" ]; then
    if ! diff -q "$hook_file" "$dest" &>/dev/null; then
      warn "${name}: 既存ファイルと差分あり → バックアップして上書き"
      cp "$dest" "${dest}.bak"
    else
      ok "${name}: 最新版（スキップ）"
      continue
    fi
  fi

  cp "$hook_file" "$dest"
  chmod +x "$dest"
  ok "${name}: インストール完了"
  hooks_installed=$((hooks_installed + 1))
done

ok "Hooks: ${hooks_installed}個 新規/更新"

# --- Step 3: settings.json マージ ---
info "settings.json 設定..."
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"
SETTINGS_TEMPLATE="${BUNDLED_TEMPLATES_DIR}/settings.json"

if [ -f "$SETTINGS_FILE" ]; then
  warn "settings.json が既に存在します"

  python3 -c "
import json

with open('$SETTINGS_FILE') as f:
    existing = json.load(f)
with open('$SETTINGS_TEMPLATE') as f:
    template = json.load(f)

# deny list をマージ（重複排除）
existing_deny = set(existing.get('permissions', {}).get('deny', []))
template_deny = set(template.get('permissions', {}).get('deny', []))
merged_deny = sorted(existing_deny | template_deny)

if 'permissions' not in existing:
    existing['permissions'] = {}
existing['permissions']['deny'] = merged_deny

# hooks を上書き
existing['hooks'] = template['hooks']

# statusLine を追加
existing['statusLine'] = template['statusLine']

with open('$SETTINGS_FILE', 'w') as f:
    json.dump(existing, f, indent=2, ensure_ascii=False)
    f.write('\n')

added = template_deny - existing_deny
print(f'deny: {len(added)}個追加, hooks: 設定済み')
" 2>/dev/null

  ok "settings.json: マージ完了（既存の allow は保持）"
else
  cp "$SETTINGS_TEMPLATE" "$SETTINGS_FILE"
  ok "settings.json: 新規作成"
fi

# --- Step 4: Skills インストール (コピー) ---
info "Skills インストール (コピー)..."
skills_installed=0
skills_skipped=0

for skill_dir in "$BUNDLED_SKILLS_DIR"/*/; do
  [ -d "$skill_dir" ] || continue
  name=$(basename "$skill_dir")
  dest="${SKILLS_DIR}/${name}"

  if [ -d "$dest" ] || [ -L "$dest" ]; then
    skills_skipped=$((skills_skipped + 1))
    continue
  fi

  cp -r "$skill_dir" "$dest"
  ok "${name}"
  skills_installed=$((skills_installed + 1))
done

ok "Skills: ${skills_installed}個 新規, ${skills_skipped}個 既存スキップ"

# --- Step 5: ロール別推奨表示 ---
echo ""
case "$role_choice" in
  2)
    header "フロントエンド推奨スキル（インストール済み）"
    echo "  重点 : react-component-patterns, tailwind-design-system, design-token-system"
    echo "         micro-interaction-patterns, web-design-guidelines, mobile-first-responsive"
    echo "         nextjs-app-router-patterns, vercel-react-best-practices"
    ;;
  3)
    header "バックエンド推奨スキル（インストール済み）"
    echo "  重点 : supabase-auth-patterns, supabase-postgres-best-practices, security-review"
    echo "         docker-expert, ci-cd-deployment, testing-strategy"
    ;;
esac

# --- Step 6: コミュニティスキル案内 ---
info "コミュニティスキル (11個) は --community フラグで一括インストールできます"
echo ""
echo "  bash install.sh --community"
echo ""

# --- Step 7: グローバル CLAUDE.md ---
CLAUDE_MD="${CLAUDE_DIR}/CLAUDE.md"
if [ -f "$CLAUDE_MD" ]; then
  warn "CLAUDE.md が既に存在します（スキップ）"
  echo "  テンプレートは ${BUNDLED_TEMPLATES_DIR}/CLAUDE.md にあります"
  echo "  必要に応じて手動でカスタマイズしてください"
else
  cp "${BUNDLED_TEMPLATES_DIR}/CLAUDE.md" "$CLAUDE_MD"
  ok "CLAUDE.md: テンプレートをインストール"
  echo "  ${CLAUDE_MD} を自分の好みに合わせてカスタマイズしてください"
fi

# --- Step 8: Context7 MCP ---
info "Context7 MCP (リアルタイムドキュメント参照)..."
if command -v claude &>/dev/null; then
  claude mcp add context7 -- npx -y @upstash/context7-mcp@latest 2>/dev/null && \
    ok "Context7 MCP: 追加完了" || \
    warn "Context7 MCP: 追加に失敗（手動で追加してください）"
fi

# --- 完了 ---
echo ""
echo "========================================="
echo "  セットアップ完了!"
echo "========================================="
echo ""
echo "インストール内容:"
echo "  ~/.claude/hooks/        ... Hooks"
echo "  ~/.claude/settings.json ... deny list + hooks"
echo "  ~/.claude/skills/       ... チーム共有スキル (コピー)"
echo "  ~/.claude/session-env/  ... セッション管理用"
echo "  ~/.claude/debug/        ... デバッグログ用"
echo ""
echo "次のステップ:"
echo "  1. ~/.claude/CLAUDE.md を自分の好みにカスタマイズ"
echo "  2. Claude Code を再起動して設定を反映"
echo "  3. bash install.sh --verify でヘルスチェック"
echo "  4. bash install.sh --community でコミュニティスキルを追加"
echo ""
echo "注意: スキルはコピーでインストールされています。"
echo "      更新版が配布されたら、再度 install.sh を実行してください。"
echo ""
