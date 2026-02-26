#!/bin/bash
# ============================================================
#  Team Claude Skills セットアップ
#  カスタムスキル + 厳選コミュニティスキルを一括インストール
# ============================================================
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"
CUSTOM_SRC="$SCRIPT_DIR/custom-skills"

# --- カラー ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}  ✓${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# --- 前提チェック ---
echo ""
echo "=========================================="
echo "  Team Claude Skills セットアップ"
echo "=========================================="
echo ""

if ! command -v claude &>/dev/null; then
    error "claude コマンドが見つかりません。先にインストールしてください:\n  npm install -g @anthropic-ai/claude-code"
fi

if ! command -v git &>/dev/null; then
    error "git コマンドが見つかりません。先にインストールしてください。"
fi

mkdir -p "$SKILLS_DIR"

# --- カスタムスキル（このリポジトリ収録） ---
info "カスタムスキル (最大33個) をインストール..."

# --- コアスキル（自動装備）---
CORE_SKILLS=(
    agent-importer
    ansem-db-patterns
    api-design-patterns
    chrome-extension-dev
    code-review
    cognitive-load-optimizer
    context-economy
    dashboard-data-viz
    design-token-system
    design-brief
    style-reference-db
    duckdb-csv
    line-bot-dev
    micro-interaction-patterns
    mobile-first-responsive
    react-component-patterns
    natural-japanese-writing
    obsidian-automation
    skill-forge
    skill-loader
    skills-change-control
    ux-psychology
    observability
)

# --- 選択スキル: Google Workspace ---
GOOGLE_SKILLS=(
    email-search
    gog-calendar
    gog-drive
    gog-gmail
)

# --- 選択スキル: 議事録ワークフロー ---
MINUTES_SKILLS=(
    create-minutes
    fill-external-minutes
    share-minutes
    transcribe-and-update
    transcribe-to-minutes
    notion-pdf
)

# --- 選択スキル: SNS/Twitter ---
SNS_SKILLS=(
    xurl-twitter-ops
)

installed=0
skipped=0

install_custom_skill() {
    local skill="$1"
    if [ ! -d "$CUSTOM_SRC/$skill" ]; then
        warn "$skill: ソースが見つかりません（スキップ）"
        skipped=$((skipped + 1))
        return
    fi
    if [ -d "$SKILLS_DIR/$skill" ] && [ ! -L "$SKILLS_DIR/$skill" ]; then
        local backup="$SKILLS_DIR/${skill}.bak.$(date +%Y%m%d%H%M%S)"
        mv "$SKILLS_DIR/$skill" "$backup"
        warn "$skill: 既存をバックアップ → $(basename "$backup")"
    elif [ -L "$SKILLS_DIR/$skill" ]; then
        rm "$SKILLS_DIR/$skill"
    fi
    cp -r "$CUSTOM_SRC/$skill" "$SKILLS_DIR/$skill"
    ok "$skill"
    installed=$((installed + 1))
}

# コアスキル（自動装備）
info "コアスキル (${#CORE_SKILLS[@]}個) を自動装備..."
for skill in "${CORE_SKILLS[@]}"; do
    install_custom_skill "$skill"
done

# Google Workspace スキル（選択）
echo ""
if [ -t 0 ]; then
    read -r -p "📅 Google Workspace スキルを装備する？ gog-calendar / gog-drive / gog-gmail / email-search (Y/n): " answer
    answer="${answer:-Y}"
else
    answer="Y"
fi
if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "Google Workspace スキル (${#GOOGLE_SKILLS[@]}個) をインストール..."
    for skill in "${GOOGLE_SKILLS[@]}"; do
        install_custom_skill "$skill"
    done
fi

# 議事録ワークフロー（選択）
echo ""
if [ -t 0 ]; then
    read -r -p "📝 議事録ワークフロースキルを装備する？ create-minutes / transcribe / share 等 (Y/n): " answer
    answer="${answer:-Y}"
else
    answer="Y"
fi
if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "議事録スキル (${#MINUTES_SKILLS[@]}個) をインストール..."
    for skill in "${MINUTES_SKILLS[@]}"; do
        install_custom_skill "$skill"
    done
fi

# SNS/Twitter（選択）
echo ""
if [ -t 0 ]; then
    read -r -p "🐦 SNS/Twitter スキルを装備する？ xurl-twitter-ops (y/N): " answer
    answer="${answer:-N}"
else
    answer="N"
fi
if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "SNS スキル (${#SNS_SKILLS[@]}個) をインストール..."
    for skill in "${SNS_SKILLS[@]}"; do
        install_custom_skill "$skill"
    done
fi

echo ""
info "カスタムスキル: ${installed}個インストール / ${skipped}個スキップ"

# --- コミュニティスキル: git clone方式 ---
# コミュニティスキルをインストールするヘルパー関数
install_skill_from_repo() {
    local repo="$1"
    local skill_name="$2"
    local tmp_dir
    tmp_dir="$(mktemp -d)"

    # クローン失敗は警告のみ（スクリプト継続）
    if ! git clone --depth 1 --quiet "https://github.com/${repo}.git" "$tmp_dir" 2>/dev/null; then
        warn "${skill_name}: リポジトリのクローン失敗 (${repo})"
        rm -rf "$tmp_dir"
        return 0
    fi

    # リポジトリ内でスキルディレクトリを探す
    # head -1 で find が SIGPIPE で終了し pipefail が誤発動するのを || true で抑制
    local skill_path
    skill_path=$(find "$tmp_dir" -type d -name "$skill_name" 2>/dev/null | head -1) || true

    if [ -z "$skill_path" ]; then
        warn "${skill_name}: リポジトリ内に見つかりません (${repo})"
        rm -rf "$tmp_dir"
        return 0
    fi

    # インストール
    if [ -L "$SKILLS_DIR/$skill_name" ] || [ -d "$SKILLS_DIR/$skill_name" ]; then
        rm -rf "$SKILLS_DIR/$skill_name"
    fi
    cp -r "$skill_path" "$SKILLS_DIR/$skill_name"
    ok "$skill_name (from ${repo})"

    rm -rf "$tmp_dir"
}

# --- コミュニティスキル: 必須 ---
echo ""
info "コミュニティスキル [必須] をインストール..."

install_skill_from_repo "0xbigboss/claude-code"      "typescript-best-practices"
install_skill_from_repo "wshobson/agents"             "nextjs-app-router-patterns"
install_skill_from_repo "wshobson/agents"             "tailwind-design-system"
install_skill_from_repo "wshobson/agents"             "git-advanced-workflows"
install_skill_from_repo "supabase/agent-skills"       "supabase-postgres-best-practices"
install_skill_from_repo "getsentry/skills"            "security-review"
install_skill_from_repo "obra/superpowers-marketplace" "systematic-debugging"
install_skill_from_repo "obra/superpowers-marketplace" "finishing-a-development-branch"

# --- コミュニティスキル: 推奨 ---
echo ""
# 非インタラクティブ環境（CI等）ではデフォルトでYes
if [ -t 0 ]; then
    read -r -p "🌟 コミュニティ推奨スキルを装備する？ webapp-testing / vibe-security / vercel 等 (Y/n): " answer
    answer="${answer:-Y}"
else
    answer="Y"
fi

if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "コミュニティスキル [推奨] をインストール..."
    install_skill_from_repo "anthropics/skills"           "webapp-testing"
    install_skill_from_repo "anthropics/skills"           "web-artifacts-builder"
    install_skill_from_repo "anthropics/skills"           "mcp-builder"
    install_skill_from_repo "trailofbits/skills"          "vibe-security-skill"
    install_skill_from_repo "trailofbits/skills"          "second-opinion"
    install_skill_from_repo "vercel-labs/agent-skills"    "vercel-react-best-practices"
fi

# --- コミュニティスキル: 任意 ---
echo ""
if [ -t 0 ]; then
    read -r -p "📦 コミュニティ任意スキルも入れる？ obsidian-bases / obsidian-markdown (y/N): " answer
    answer="${answer:-N}"
else
    answer="N"
fi

if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "コミュニティスキル [任意] をインストール..."
    install_skill_from_repo "kepano/obsidian-skills"      "obsidian-bases"
    install_skill_from_repo "kepano/obsidian-skills"      "obsidian-markdown"
fi

# ============================================================
# --- エージェント ---
# ============================================================
echo ""
if [ -t 0 ]; then
    read -r -p "🤖 チームエージェント（10個）をインストールする？ (Y/n): " answer
    answer="${answer:-Y}"
else
    answer="Y"
fi

if [[ "$answer" =~ ^[Yy]$ ]]; then
    AGENTS_DIR="$HOME/.claude/agents"
    AGENTS_SRC="$SCRIPT_DIR/agents"
    mkdir -p "$AGENTS_DIR"
    agent_installed=0

    if [ -d "$AGENTS_SRC" ]; then
        for agent_file in "$AGENTS_SRC"/*.json; do
            [ -f "$agent_file" ] || continue
            name=$(basename "$agent_file")
            cp "$agent_file" "$AGENTS_DIR/$name"
            ok "エージェント: ${name%.json}"
            agent_installed=$((agent_installed + 1))
        done
        info "エージェント: ${agent_installed}個インストール"
    else
        warn "agents/ ディレクトリが見つかりません（スキップ）"
    fi
fi

# ============================================================
# --- フック（エージェント自動化） ---
# ============================================================
echo ""
if [ -t 0 ]; then
    read -r -p "🔧 全フック（35本）をインストールする？ command-shield / security / agent-sync / session-context 等 (Y/n): " answer
    answer="${answer:-Y}"
else
    answer="Y"
fi

if [[ "$answer" =~ ^[Yy]$ ]]; then
    HOOKS_DIR="$HOME/.claude/hooks"
    HOOKS_SRC="$SCRIPT_DIR/hooks"
    mkdir -p "$HOOKS_DIR"

    if [ -d "$HOOKS_SRC" ]; then
        for hook_file in "$HOOKS_SRC"/*; do
            [ -f "$hook_file" ] || continue
            name=$(basename "$hook_file")
            cp "$hook_file" "$HOOKS_DIR/$name"
            chmod 700 "$HOOKS_DIR/$name"
            ok "フック: $name"
        done
        info "settings.json にフック設定を追加中..."
        if python3 "$SCRIPT_DIR/scripts/patch-settings.py"; then
            ok "settings.json 更新完了"
        else
            warn "settings.json の自動更新に失敗。手動で確認してください。"
        fi
    else
        warn "hooks/ ディレクトリが見つかりません（スキップ）"
    fi
fi

# --- Codex CLI 同期（検出時のみ）---
CODEX_SYNC="$HOME/.codex/scripts/skills_optimize.sh"
if [ -f "$CODEX_SYNC" ]; then
    echo ""
    info "Codex CLI を検出 — スキルを同期中..."
    if bash "$CODEX_SYNC" 2>/dev/null; then
        ok "Codex スキル同期完了"
    else
        warn "Codex 同期スキップ（エラーは無視）"
    fi
fi

# --- 完了 ---
echo ""
echo "=========================================="
echo -e "${GREEN}  セットアップ完了！${NC}"
echo "=========================================="
echo ""
info "確認:   ls ~/.claude/skills/"
info "更新:   git pull && ./setup.sh"
echo ""
