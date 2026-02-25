#!/bin/bash
# ============================================================
# Claude Code チーム環境セットアップ（スタンドアロン版）
# nahato-Inc / IF-Vault
#
# Git リポジトリ不要。配布zipに同梱された全ファイルを
# コピーしてインストールする。
#
# 使い方: bash install.sh [オプション]
#
# オプション:
#   (なし)              フルインストール
#   --verify            ヘルスチェック
#   --list              利用可能なスキル一覧を表示
#   --skill=スキル名    指定スキルだけインストール（既存はスキップ）
#   --update=スキル名   指定スキルを強制上書き更新
#   --community         コミュニティスキル一括インストール
#   --yes / -y          確認プロンプトをスキップ（CI向け）
#   --dry-run           実際には変更せず内容をプレビュー
#   --help              ヘルプ表示
# ============================================================

set -euo pipefail

# --- カラー出力 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { printf "${BLUE}[INFO]${NC}  %s\n" "$1"; }
ok()      { printf "${GREEN}[OK]${NC}    %s\n" "$1"; }
warn()    { printf "${YELLOW}[WARN]${NC}  %s\n" "$1"; }
error()   { printf "${RED}[ERROR]${NC} %s\n" "$1" >&2; }
header()  { printf "\n${CYAN}${BOLD}--- %s ---${NC}\n" "$1"; }
dry_run() { printf "${YELLOW}[DRY-RUN]${NC} %s\n" "$1"; }

# --- 引数パース ---
FLAG_VERIFY=false
FLAG_COMMUNITY=false
FLAG_YES=false
FLAG_DRY_RUN=false
FLAG_SKILL=""
FLAG_UPDATE=""
FLAG_LIST=false

for arg in "$@"; do
  case "$arg" in
    --verify)     FLAG_VERIFY=true ;;
    --community)  FLAG_COMMUNITY=true ;;
    --yes|-y)     FLAG_YES=true ;;
    --dry-run)    FLAG_DRY_RUN=true ;;
    --list)       FLAG_LIST=true ;;
    --skill=*)    FLAG_SKILL="${arg#--skill=}" ;;
    --update=*)   FLAG_UPDATE="${arg#--update=}" ;;
    --help|-h)
      echo ""
      printf "${BOLD}使い方:${NC} bash install.sh [オプション]\n"
      echo ""
      printf "${BOLD}オプション:${NC}\n"
      echo "  (なし)              フルインストール（全スキル + hooks + settings）"
      echo "  --verify            ヘルスチェックのみ実行"
      echo "  --list              利用可能なスキル一覧を表示"
      echo "  --skill=スキル名    指定スキルだけインストール（既存はスキップ）"
      echo "  --update=スキル名   指定スキルを強制上書き更新"
      echo "  --community         コミュニティスキル(11個)を一括インストール"
      echo "  --yes / -y          確認プロンプトをスキップ（CI/自動実行向け）"
      echo "  --dry-run           実際には変更せず内容をプレビュー"
      echo "  --help              このヘルプを表示"
      echo ""
      printf "${BOLD}例:${NC}\n"
      echo "  bash install.sh                         # フルインストール"
      echo "  bash install.sh -y                      # 確認スキップでフルインストール"
      echo "  bash install.sh --dry-run               # 何がインストールされるかプレビュー"
      echo "  bash install.sh --list                  # スキル一覧表示"
      echo "  bash install.sh --skill=playwright      # playwright だけ追加"
      echo "  bash install.sh --update=playwright     # playwright を強制更新"
      echo "  bash install.sh --verify                # ヘルスチェック"
      echo "  bash install.sh --community             # コミュニティスキル追加"
      echo ""
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

BUNDLED_SKILLS_DIR="${SCRIPT_DIR}/skills"
BUNDLED_HOOKS_DIR="${SCRIPT_DIR}/hooks"
BUNDLED_TEMPLATES_DIR="${SCRIPT_DIR}/templates"
SETTINGS_TEMPLATE="${BUNDLED_TEMPLATES_DIR}/settings.json"
CLAUDE_MD_TEMPLATE="${BUNDLED_TEMPLATES_DIR}/CLAUDE.md"

# --- 事前チェック ---
if ! command -v claude &>/dev/null; then
  error "Claude Code がインストールされていません"
  echo "  インストール: https://docs.anthropic.com/en/docs/claude-code"
  exit 1
fi

# 配布パッケージ整合性チェック
for required_dir in "$BUNDLED_SKILLS_DIR" "$BUNDLED_HOOKS_DIR" "$BUNDLED_TEMPLATES_DIR"; do
  if [ ! -d "$required_dir" ]; then
    error "必要なフォルダが見つかりません: $required_dir"
    error "配布 zip が壊れている可能性があります"
    exit 1
  fi
done

if [ ! -f "$SETTINGS_TEMPLATE" ]; then
  error "settings.json テンプレートが見つかりません: $SETTINGS_TEMPLATE"
  exit 1
fi

# バージョン取得
PACKAGE_VERSION="不明"
if [ -f "${SCRIPT_DIR}/VERSION" ]; then
  _ver=$(head -1 "${SCRIPT_DIR}/VERSION" 2>/dev/null | sed 's/^version:[[:space:]]*//')
  [ -n "$_ver" ] && PACKAGE_VERSION="$_ver"
fi

# スキル数を正確に取得
count_skills() {
  local dir="$1"
  find "$dir" -mindepth 1 -maxdepth 1 \( -type d -o -type l \) | wc -l | tr -d ' '
}

AVAILABLE_SKILLS=$(count_skills "$BUNDLED_SKILLS_DIR")

# ============================================================
# スキル一覧表示（--list）
# ============================================================
run_list() {
  echo ""
  printf "${BOLD}利用可能なスキル（${AVAILABLE_SKILLS}個）${NC}\n"
  echo ""

  # bash 3.2 互換: declare -A を使わずにヘルパー関数で実現
  _show_category() {
    local cat_name="$1"; shift
    printf "${CYAN}▶ ${cat_name}${NC}\n"
    for skill in "$@"; do
      if [ -d "${SKILLS_DIR}/${skill}" ] || [ -L "${SKILLS_DIR}/${skill}" ]; then
        printf "  ${GREEN}✓${NC} %s\n" "$skill"
      else
        printf "  ${YELLOW}○${NC} %s\n" "$skill"
      fi
    done
    echo ""
  }

  _show_category "フロントエンド/UI" \
    baseline-ui design-brief design-token-system micro-interaction-patterns \
    mobile-first-responsive nextjs-app-router-patterns react-component-patterns \
    style-reference-db tailwind-design-system ux-psychology vercel-ai-sdk \
    vercel-react-best-practices web-design-guidelines

  _show_category "バックエンド/DB" \
    api-design-patterns docker-expert error-handling-logging observability \
    supabase-auth-patterns supabase-postgres-best-practices typescript-best-practices \
    ansem-db-patterns

  _show_category "品質/テスト/セキュリティ" \
    code-refactoring code-review playwright security-arsenal security-best-practices \
    security-review security-threat-model systematic-debugging testing-strategy

  _show_category "開発効率/CI" \
    brainstorming ci-cd-deployment claude-env-optimizer cognitive-load-optimizer \
    context-economy duckdb-csv skill-forge skill-loader

  _show_category "議事録/ドキュメント" \
    create-minutes fill-external-minutes notion-pdf share-minutes \
    transcribe-and-update transcribe-to-minutes

  _show_category "コンテンツ/特化" \
    chrome-extension-dev dashboard-data-viz deep-research line-bot-dev \
    natural-japanese-writing obsidian-power-user seo lazy-user-ux-review

  echo "  ${GREEN}✓${NC} = インストール済み  ${YELLOW}○${NC} = 未インストール"
  echo ""
}

# ============================================================
# ヘルスチェック（--verify）
# ============================================================
run_verify() {
  echo ""
  echo "========================================="
  echo "  ヘルスチェック"
  echo "========================================="
  echo ""

  local issues=0

  # 1. スキル数チェック
  header "Skills"
  local installed_count=0
  if [ -d "$SKILLS_DIR" ]; then
    installed_count=$(count_skills "$SKILLS_DIR")
  fi
  if [ "$installed_count" -ge "$AVAILABLE_SKILLS" ]; then
    ok "Skills: ${installed_count}個 インストール済み（利用可能: ${AVAILABLE_SKILLS}個）"
  else
    warn "Skills: ${installed_count}個 インストール済み（利用可能: ${AVAILABLE_SKILLS}個）"
    warn "未インストールのスキルがあります。bash install.sh を実行してください"
    issues=$((issues + 1))
  fi

  # 2. SKILL.md 存在チェック
  header "SKILL.md"
  local missing_skillmd=0
  if [ -d "$SKILLS_DIR" ]; then
    for dest in "$SKILLS_DIR"/*/; do
      [ -d "$dest" ] || continue
      local name
      name=$(basename "$dest")
      if [ ! -f "${dest}/SKILL.md" ]; then
        warn "SKILL.md 未検出: ${name}"
        missing_skillmd=$((missing_skillmd + 1))
      fi
    done
  fi
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

  # 4. settings.json チェック
  header "settings.json"
  local settings_file="${CLAUDE_DIR}/settings.json"
  if [ -f "$settings_file" ]; then
    if ! python3 -c "import json; json.load(open('$settings_file'))" 2>/dev/null; then
      warn "settings.json が壊れています（JSON パースエラー）"
      issues=$((issues + 1))
    else
      local deny_count
      deny_count=$(python3 -c "
import json
with open('$settings_file') as f:
    data = json.load(f)
print(len(data.get('permissions', {}).get('deny', [])))
" 2>/dev/null || echo "0")
      if [ "$deny_count" -ge 7 ]; then
        ok "settings.json: 正常（deny: ${deny_count}エントリ）"
      else
        warn "deny list が少なすぎます: ${deny_count}エントリ（期待: 7以上）"
        issues=$((issues + 1))
      fi
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
    warn "グローバル CLAUDE.md なし（bash install.sh で生成できます）"
    issues=$((issues + 1))
  fi

  # 6. スキル配置方式
  header "スキル配置方式"
  local copy_count=0
  local symlink_count=0
  if [ -d "$SKILLS_DIR" ]; then
    for target in "$SKILLS_DIR"/*; do
      if [ -L "$target" ]; then
        symlink_count=$((symlink_count + 1))
      elif [ -d "$target" ]; then
        copy_count=$((copy_count + 1))
      fi
    done
  fi
  ok "コピー: ${copy_count}個, シンボリックリンク: ${symlink_count}個"

  # 結果サマリ
  echo ""
  echo "========================================="
  if [ "$issues" -eq 0 ]; then
    printf "  ${GREEN}${BOLD}全項目 OK!${NC}\n"
  else
    printf "  ${YELLOW}${issues}件 の注意事項あり${NC}\n"
  fi
  echo "========================================="
  echo ""
}

# ============================================================
# 個別スキルインストール（--skill）
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
    echo "利用可能なスキル一覧 (--list で詳細表示):"
    ls "$BUNDLED_SKILLS_DIR" 2>/dev/null | sed 's/^/  /' || true
    exit 1
  fi

  if [ -d "$dest" ] || [ -L "$dest" ]; then
    ok "${skill_name}: 既にインストール済み（スキップ）"
    echo "  → 強制更新: bash install.sh --update=${skill_name}"
    exit 0
  fi

  if [[ "$FLAG_DRY_RUN" == true ]]; then
    dry_run "コピー: ~/.claude/skills/${skill_name}"
    exit 0
  fi

  mkdir -p "$SKILLS_DIR"
  cp -r "${src%/}" "$dest"
  ok "${skill_name}: インストール完了 → ~/.claude/skills/${skill_name}"
  echo ""
  echo "Claude Code を再起動して有効化してください"
  echo ""
}

# ============================================================
# スキル強制更新（--update）
# ============================================================
run_update() {
  local skill_name="$1"
  local src="${BUNDLED_SKILLS_DIR}/${skill_name}"
  local dest="${SKILLS_DIR}/${skill_name}"

  echo ""
  echo "========================================="
  echo "  スキル強制更新: ${skill_name}"
  echo "========================================="
  echo ""

  if [ ! -d "$src" ]; then
    error "スキルが見つかりません: ${skill_name}"
    exit 1
  fi

  if [[ "$FLAG_DRY_RUN" == true ]]; then
    dry_run "既存をバックアップして再コピー: ~/.claude/skills/${skill_name}"
    exit 0
  fi

  if [ -d "$dest" ] || [ -L "$dest" ]; then
    if [ -L "$dest" ]; then
      unlink "$dest"
    else
      mv "$dest" "${dest}.bak.$(date +%Y%m%d%H%M%S)"
      warn "既存をバックアップしました: ${dest}.bak.*"
    fi
  fi

  mkdir -p "$SKILLS_DIR"
  cp -r "${src%/}" "$dest"
  ok "${skill_name}: 更新完了 → ~/.claude/skills/${skill_name}"
  echo ""
  echo "Claude Code を再起動して有効化してください"
  echo ""
}

# ============================================================
# コミュニティスキル（--community）
# ============================================================
run_community() {
  echo ""
  echo "========================================="
  echo "  コミュニティスキル 一括インストール"
  echo "========================================="
  echo ""

  mkdir -p "$SKILLS_DIR"

  local COMMUNITY_SKILLS=(
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

    if [[ "$FLAG_DRY_RUN" == true ]]; then
      dry_run "${skill_name}: インストール予定"
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
# フラグ別処理（単独実行）
# ============================================================
[[ "$FLAG_LIST" == true ]]       && run_list                && exit 0
[[ -n "$FLAG_SKILL" ]]           && run_skill "$FLAG_SKILL"  && exit 0
[[ -n "$FLAG_UPDATE" ]]          && run_update "$FLAG_UPDATE" && exit 0
[[ "$FLAG_VERIFY" == true ]]     && run_verify              && exit 0
[[ "$FLAG_COMMUNITY" == true ]]  && run_community           && exit 0

# ============================================================
# メインインストールフロー
# ============================================================
echo ""
echo "========================================="
echo "  Claude Code チーム環境セットアップ"
printf "  スタンドアロン版 v${PACKAGE_VERSION} | スキル: ${AVAILABLE_SKILLS}個\n"
echo "========================================="
echo ""
echo "以下をインストールします:"
echo "  - Hooks: セキュリティ・効率化スクリプト"
echo "  - settings.json: deny list + hooks 登録"
echo "  - Skills: ${AVAILABLE_SKILLS}個（コピー）"
echo "  - グローバル CLAUDE.md テンプレート"
echo "  - 作業ディレクトリ (session-env, debug)"
echo ""

if [[ "$FLAG_DRY_RUN" == true ]]; then
  printf "${YELLOW}${BOLD}[DRY-RUN モード] 実際には変更しません${NC}\n"
  echo ""
fi

# ロール選択
echo "あなたのロールを選んでください（推奨スキルを表示します）:"
echo "  1) 全員共通（全スキルをインストール）"
echo "  2) フロントエンド（UI/UX・React・デザイン系を優先表示）"
echo "  3) バックエンド（DB・API・インフラ系を優先表示）"
echo ""

role_choice="1"
if [[ "$FLAG_YES" == false ]]; then
  read -r -t 30 -p "ロール [1-3, デフォルト: 1]: " role_choice || role_choice="1"
fi
role_choice="${role_choice:-1}"

echo ""
case "$role_choice" in
  2) info "フロントエンドロール選択" ;;
  3) info "バックエンドロール選択" ;;
  *) info "全員共通（全スキル）"; role_choice="1" ;;
esac

echo ""
if [[ "$FLAG_YES" == false && "$FLAG_DRY_RUN" == false ]]; then
  read -r -t 30 -p "続行しますか？ (y/N): " confirm || confirm="n"
  if [[ "$confirm" != [yY] ]]; then
    echo "キャンセルしました"
    exit 0
  fi
fi

echo ""

# --- Step 1: ディレクトリ作成 ---
if [[ "$FLAG_DRY_RUN" == true ]]; then
  dry_run "ディレクトリ作成: $HOOKS_DIR $SKILLS_DIR $SESSION_DIR $DEBUG_DIR"
else
  mkdir -p "$HOOKS_DIR" "$SKILLS_DIR" "$SESSION_DIR" "$DEBUG_DIR"
  ok "ディレクトリ作成完了"
fi

# --- Step 2: Hooks インストール ---
info "Hooks インストール..."
hooks_installed=0
hooks_count=0

for hook_file in "$BUNDLED_HOOKS_DIR"/*.sh; do
  [ -f "$hook_file" ] || continue
  hooks_count=$((hooks_count + 1))
  local_name=$(basename "$hook_file")
  dest="${HOOKS_DIR}/${local_name}"

  if [[ "$FLAG_DRY_RUN" == true ]]; then
    dry_run "Hook: ${local_name}"
    continue
  fi

  if [ -f "$dest" ]; then
    if ! diff -q "$hook_file" "$dest" &>/dev/null; then
      warn "${local_name}: 差分あり → バックアップして更新"
      cp "$dest" "${dest}.bak"
    else
      ok "${local_name}: 最新版（スキップ）"
      continue
    fi
  fi

  cp "$hook_file" "$dest"
  chmod +x "$dest"
  ok "${local_name}: インストール完了"
  hooks_installed=$((hooks_installed + 1))
done

[[ "$FLAG_DRY_RUN" == false ]] && ok "Hooks: ${hooks_installed}個 新規/更新（合計 ${hooks_count}個）"

# --- Step 3: settings.json マージ ---
info "settings.json 設定..."
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"

if [[ "$FLAG_DRY_RUN" == true ]]; then
  dry_run "settings.json: deny list マージ + hooks 登録"
else
  if [ -f "$SETTINGS_FILE" ]; then
    warn "settings.json 既存 → deny list をマージします"

    merge_result=""
    if ! merge_result=$(python3 - <<PYEOF 2>&1
import json, sys

try:
    with open('$SETTINGS_FILE') as f:
        existing = json.load(f)
except json.JSONDecodeError as e:
    print(f"ERROR: settings.json parse失敗: {e}", file=sys.stderr)
    sys.exit(1)

try:
    with open('$SETTINGS_TEMPLATE') as f:
        template = json.load(f)
except json.JSONDecodeError as e:
    print(f"ERROR: テンプレート parse失敗: {e}", file=sys.stderr)
    sys.exit(1)

existing_deny = set(existing.get('permissions', {}).get('deny', []))
template_deny = set(template.get('permissions', {}).get('deny', []))
merged_deny   = sorted(existing_deny | template_deny)
added         = template_deny - existing_deny

if 'permissions' not in existing:
    existing['permissions'] = {}
existing['permissions']['deny'] = merged_deny
existing['hooks']      = template['hooks']
existing['statusLine'] = template['statusLine']

with open('$SETTINGS_FILE', 'w') as f:
    json.dump(existing, f, indent=2, ensure_ascii=False)
    f.write('\n')

print(f"deny: {len(added)}個追加, hooks: 設定済み")
PYEOF
); then
      error "settings.json のマージに失敗しました"
      error "$merge_result"
      exit 1
    fi

    ok "settings.json: マージ完了 → $merge_result"
  else
    cp "$SETTINGS_TEMPLATE" "$SETTINGS_FILE"
    ok "settings.json: 新規作成"
  fi
fi

# --- Step 4: Skills インストール（コピー）---
info "Skills インストール（コピー: ${AVAILABLE_SKILLS}個）..."
skills_installed=0
skills_skipped=0

for skill_dir in "$BUNDLED_SKILLS_DIR"/*/; do
  [ -d "$skill_dir" ] || continue
  skill_name=$(basename "${skill_dir%/}")
  dest="${SKILLS_DIR}/${skill_name}"

  if [ -d "$dest" ] || [ -L "$dest" ]; then
    skills_skipped=$((skills_skipped + 1))
    continue
  fi

  if [[ "$FLAG_DRY_RUN" == true ]]; then
    dry_run "コピー: ~/.claude/skills/${skill_name}"
    continue
  fi

  cp -r "${skill_dir%/}" "$dest"
  ok "${skill_name}"
  skills_installed=$((skills_installed + 1))
done

[[ "$FLAG_DRY_RUN" == false ]] && ok "Skills: ${skills_installed}個 新規, ${skills_skipped}個 既存スキップ"

# --- Step 5: ロール別推奨表示 ---
echo ""
case "$role_choice" in
  2)
    header "フロントエンド推奨スキル"
    echo "  baseline-ui, react-component-patterns, tailwind-design-system"
    echo "  design-token-system, micro-interaction-patterns, web-design-guidelines"
    echo "  nextjs-app-router-patterns, vercel-react-best-practices, ux-psychology"
    ;;
  3)
    header "バックエンド推奨スキル"
    echo "  supabase-auth-patterns, supabase-postgres-best-practices, ansem-db-patterns"
    echo "  docker-expert, ci-cd-deployment, security-review, testing-strategy"
    ;;
esac

# --- Step 6: CLAUDE.md ---
CLAUDE_MD="${CLAUDE_DIR}/CLAUDE.md"
if [[ "$FLAG_DRY_RUN" == true ]]; then
  dry_run "CLAUDE.md: 既存なければテンプレートをインストール"
elif [ -f "$CLAUDE_MD" ]; then
  warn "CLAUDE.md 既存（スキップ）→ ${BUNDLED_TEMPLATES_DIR}/CLAUDE.md を参照してカスタマイズ"
elif [ -f "$CLAUDE_MD_TEMPLATE" ]; then
  cp "$CLAUDE_MD_TEMPLATE" "$CLAUDE_MD"
  ok "CLAUDE.md: テンプレートをインストール → カスタマイズしてください"
else
  warn "CLAUDE.md テンプレートが見つかりません（スキップ）"
fi

# --- Step 7: Context7 MCP ---
if [[ "$FLAG_DRY_RUN" == false ]]; then
  info "Context7 MCP 登録..."
  if claude mcp add context7 -- npx -y @upstash/context7-mcp@latest 2>/dev/null; then
    ok "Context7 MCP: 追加完了"
  else
    warn "Context7 MCP: 追加に失敗（手動で追加してください）"
  fi
fi

# --- 完了 ---
echo ""
echo "========================================="
if [[ "$FLAG_DRY_RUN" == true ]]; then
  printf "  ${YELLOW}${BOLD}DRY-RUN 完了（変更なし）${NC}\n"
  echo "  実際に適用する場合: bash install.sh"
else
  printf "  ${GREEN}${BOLD}セットアップ完了!${NC}\n"
  echo ""
  echo "インストール内容:"
  echo "  ~/.claude/hooks/        ... Hooks"
  echo "  ~/.claude/settings.json ... deny list + hooks"
  echo "  ~/.claude/skills/       ... ${AVAILABLE_SKILLS}個（コピー）"
  echo "  ~/.claude/session-env/  ... セッション管理"
  echo "  ~/.claude/debug/        ... デバッグログ"
  echo ""
  echo "次のステップ:"
  echo "  1. ~/.claude/CLAUDE.md を自分の好みにカスタマイズ"
  echo "  2. Claude Code を再起動して設定を反映"
  echo "  3. bash install.sh --verify でヘルスチェック"
  echo "  4. bash install.sh --community でコミュニティスキルを追加"
fi
echo "========================================="
echo ""
