#!/bin/bash
# ============================================================
# Claude Code スタンドアロン配布パッケージ ビルドスクリプト
#
# IF-Vault リポ内で実行 → Git非参加者向けのzipを生成
#
# 使い方: bash team/shared/claude-code-setup/build-package.sh [バージョン]
# 例:     bash team/shared/claude-code-setup/build-package.sh 1.0.0
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

# --- バージョン ---
VERSION="${1:-$(date +%Y%m%d)}"
PACKAGE_NAME="claude-code-setup-v${VERSION}"

# --- パス設定 ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SHARED_SKILLS_DIR="${REPO_ROOT}/team/shared/skills"
META_SKILLS_DIR="${SCRIPT_DIR}/skills"
HOOKS_DIR="${SCRIPT_DIR}/hooks"
TEMPLATES_DIR="${SCRIPT_DIR}/templates"
STANDALONE_SCRIPT="${SCRIPT_DIR}/install-standalone.sh"

# 出力先
OUTPUT_DIR="${HOME}/Downloads"
BUILD_DIR="/tmp/claude/${PACKAGE_NAME}"

# --- 事前チェック ---
if [ ! -d "$SHARED_SKILLS_DIR" ]; then
  error "共有スキルが見つかりません: $SHARED_SKILLS_DIR"
  error "IF-Vault リポのルートから実行してください"
  exit 1
fi

if [ ! -f "$STANDALONE_SCRIPT" ]; then
  error "install-standalone.sh が見つかりません: $STANDALONE_SCRIPT"
  exit 1
fi

echo ""
echo "========================================="
echo "  配布パッケージ ビルド"
echo "  バージョン: ${VERSION}"
echo "========================================="
echo ""

# --- Step 1: クリーンビルド ---
info "ビルドディレクトリ準備..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
ok "ビルドディレクトリ作成: ${BUILD_DIR}"

# --- Step 2: install.sh ---
info "install-standalone.sh → install.sh としてコピー..."
cp "$STANDALONE_SCRIPT" "${BUILD_DIR}/install.sh"
chmod +x "${BUILD_DIR}/install.sh"
ok "install.sh"

# --- Step 3: Hooks ---
info "Hooks コピー..."
cp -r "$HOOKS_DIR" "${BUILD_DIR}/hooks"
chmod +x "${BUILD_DIR}"/hooks/*.sh
HOOKS_COUNT=$(ls -1 "${BUILD_DIR}"/hooks/*.sh 2>/dev/null | wc -l | tr -d ' ')
ok "Hooks: ${HOOKS_COUNT}個"

# --- Step 4: Templates ---
info "Templates コピー..."
cp -r "$TEMPLATES_DIR" "${BUILD_DIR}/templates"
ok "Templates"

# --- Step 5: Skills (共有 + メタを統合) ---
info "Skills 統合コピー..."
mkdir -p "${BUILD_DIR}/skills"

# 共有スキル (team/shared/skills/)
shared_count=0
for skill_dir in "$SHARED_SKILLS_DIR"/*/; do
  [ -d "$skill_dir" ] || continue
  name=$(basename "$skill_dir")
  cp -r "$skill_dir" "${BUILD_DIR}/skills/${name}"
  shared_count=$((shared_count + 1))
done
ok "共有スキル: ${shared_count}個"

# メタスキル (claude-code-setup/skills/)
meta_count=0
for skill_dir in "$META_SKILLS_DIR"/*/; do
  [ -d "$skill_dir" ] || continue
  name=$(basename "$skill_dir")
  # 共有側に同名があればスキップ（共有優先）
  if [ -d "${BUILD_DIR}/skills/${name}" ]; then
    warn "${name}: 共有スキルと重複（共有側を維持）"
    continue
  fi
  cp -r "$skill_dir" "${BUILD_DIR}/skills/${name}"
  meta_count=$((meta_count + 1))
done
ok "メタスキル: ${meta_count}個 追加"

TOTAL_SKILLS=$((shared_count + meta_count))
ok "Skills 合計: ${TOTAL_SKILLS}個"

# --- Step 6: バージョンファイル ---
cat > "${BUILD_DIR}/VERSION" <<EOF
version: ${VERSION}
built: $(date '+%Y-%m-%d %H:%M:%S')
built_by: $(whoami)
skills: ${TOTAL_SKILLS}
hooks: ${HOOKS_COUNT}
EOF
ok "VERSION ファイル作成"

# --- Step 7: zip ---
info "zip 作成中..."
mkdir -p "$OUTPUT_DIR"
ZIP_PATH="${OUTPUT_DIR}/${PACKAGE_NAME}.zip"

# 既存のzipがあれば削除
[ -f "$ZIP_PATH" ] && rm "$ZIP_PATH"

(cd /tmp/claude && zip -rq "${PACKAGE_NAME}.zip" "${PACKAGE_NAME}/")
mv "/tmp/claude/${PACKAGE_NAME}.zip" "$ZIP_PATH"
ok "zip 作成完了"

# --- Step 8: クリーンアップ ---
rm -rf "$BUILD_DIR"

# --- 完了 ---
ZIP_SIZE=$(du -h "$ZIP_PATH" | cut -f1)

echo ""
echo "========================================="
echo "  ビルド完了!"
echo "========================================="
echo ""
echo "  出力: ${ZIP_PATH}"
echo "  サイズ: ${ZIP_SIZE}"
echo "  Skills: ${TOTAL_SKILLS}個"
echo "  Hooks: ${HOOKS_COUNT}個"
echo ""
echo "配布方法:"
echo "  1. Slack / Google Drive / AirDrop 等でzipを渡す"
echo "  2. 受取側: unzip → bash install.sh を実行"
echo ""
