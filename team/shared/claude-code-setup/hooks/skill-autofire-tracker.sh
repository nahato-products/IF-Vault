#!/usr/bin/env bash
# skill-autofire-tracker.sh — Track which auto-fire skills likely activated
# Matches user prompt keywords against active skill trigger patterns
# Output: ~/.claude/debug/skill-autofire.jsonl

set -euo pipefail
source "$(dirname "$0")/_common.sh"

LOG_DIR="${HOME}/.claude/debug"
LOG_FILE="${LOG_DIR}/skill-autofire.jsonl"
MAX_LINES=2000
KEEP_LINES=1000

INPUT=$(cat)

MATCHES=$(printf '%s' "$INPUT" | python3 -c "
import sys, json, re
from datetime import datetime, timezone

SKILL_TRIGGERS = {
    'nextjs-app-router-patterns': r'(route|page\.(tsx?|jsx?)|layout|server.action|middleware|app.router|next\.js|ISR|PPR|suspense)',
    'react-component-patterns': r'(component|props|useState|useEffect|hook|CVA|variant|compound|error.boundary)',
    'tailwind-design-system': r'(tailwind|@theme|dark.mode|shadcn|@utility|container.quer)',
    'typescript-best-practices': r'(type|interface|generic|discriminated|branded.type|zod|narrowing)',
    'error-handling-logging': r'(error\.tsx|try.catch|sentry|AppError|error.boundar|logging)',
    'testing-strategy': r'(test|vitest|jest|TDD|coverage|spec\.|\.test\.|テスト.*書)',
    'vercel-ai-sdk': r'(generateText|streamText|useChat|tool.call|ai.sdk|vercel.*ai)',
    'ci-cd-deployment': r'(github.actions|CI|CD|デプロイ|vercel|workflow|pipeline)',
    'design-token-system': r'(design.token|OKLCH|fluid.typo|color.palette|デザイントークン)',
    'line-bot-dev': r'(LINE|LIFF|flex.message|rich.menu|messaging.api)',
    'mobile-first-responsive': r'(mobile|responsive|safe.area|svh|dvh|touch.target|PWA|service.worker)',
    'natural-japanese-writing': r'(日本語.*文章|文章.*書|記事.*書|README.*書|自然.*文体)',
    'obsidian-power-user': r'(obsidian|オブ|vault|dataview|templater|wikilink|callout)',
    'context-economy': r'(トークン.*節約|token.*limit|コンテキスト.*節約|read_smart|read_fragment)',
    'skill-forge': r'(スキル.*作成|SKILL\.md|skill-forge|新しいスキル)',
    'brainstorming': r'(アイデア.*整理|ブレスト|設計.*検討|要件.*探索|選択肢.*比較|何作ろう)',
    'security-review': r'(セキュリティ.*レビュー|脆弱性|XSS|CSRF|SQLi|認証.*漏れ|権限.*チェック)',
    'docker-expert': r'(Docker|Dockerfile|docker.compose|コンテナ.*構成|multi.stage)',
    'deep-research': r'(リサーチ.*お願い|市場調査|競合分析|論文.*調査|調査.*まとめ)',
    'finishing-a-development-branch': r'(PRまとめ|ブランチ.*完成|マージ.*準備|PR.*作成|リリース.*準備)',
    'git-advanced-workflows': r'(rebase.*整理|cherry.pick|bisect|stash.*管理|git.*履歴)',
    'mermaid-visualizer': r'(Mermaid|フロー図|シーケンス図|ER図|アーキテクチャ.*図|図.*描)',
    'modern-python': r'(uv.*python|ruff|pyproject\.toml|Python.*モダン|Python.*セットアップ)',
    'systematic-debugging': r'(デバッグ.*手順|バグ.*原因.*調査|再現しない.*バグ|エラー.*追跡)',
    'claude-developer-platform': r'(Claude.*API|Anthropic.*SDK|Messages.*API|claude-sonnet|claude-opus)',
    'supabase-postgres-best-practices': r'(Supabase.*最適化|RLS.*ポリシー|Edge.*Function|postgres.*チューニング)',
    'pdf': r'(PDF.*変換|PDF.*出力|pdf.*作成|ノーション.*PDF)',
    'theme-factory': r'(テーマ.*作成|カラーパレット.*作成|スライド.*デザイン|配色.*提案)',
    'slack-bot-builder': r'(Slack.*Bot|Bolt.*Framework|slash.command|Block.Kit)',
    'security-threat-model': r'(脅威モデル|threat.model|攻撃.*面|アタックサーフェス|信頼境界)',
}

try:
    data = json.load(sys.stdin)
    prompt = data.get('user_prompt', '')
    if not prompt:
        sys.exit(0)

    matched = []
    for skill, pattern in SKILL_TRIGGERS.items():
        if re.search(pattern, prompt, re.IGNORECASE):
            matched.append(skill)

    if matched:
        entry = {
            'ts': datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
            'matched_skills': matched,
            'prompt_preview': prompt[:80]
        }
        print(json.dumps(entry, ensure_ascii=False))
except Exception:
    pass
" 2>/dev/null || true)

if [ -z "$MATCHES" ]; then
    exit 0
fi

mkdir -p "$LOG_DIR"
chmod 700 "$LOG_DIR"
printf '%s\n' "$MATCHES" >> "$LOG_FILE"

# Rotation
rotate_log "$LOG_FILE" "$MAX_LINES" "$KEEP_LINES"

exit 0
