#!/usr/bin/env python3
"""
agent-importer: エージェントJSON の セキュリティ vetting + 品質スコアリング
Usage:
  python3 audit_agent.py --file path/to/agent.json
  python3 audit_agent.py --json '{"name": "...", ...}'
  python3 audit_agent.py --source https://github.com/owner/repo
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import urllib.request
from datetime import datetime
from pathlib import Path
from typing import Any

# ────────────────────────────────────────────
# 定数
# ────────────────────────────────────────────

DANGER_PATTERNS = [
    r"curl\s+[^|]+\|\s*sh",
    r"curl\s+[^|]+\|\s*bash",
    r"rm\s+-rf\b",
    r"\beval\s*\(",
    r"\beval\s+\$",
    r"\bexec\s*\(",
]

SECRET_PATTERNS = [
    r"sk-[A-Za-z0-9]{20,}",       # OpenAI / Anthropic
    r"ghp_[A-Za-z0-9]{36}",       # GitHub PAT
    r"eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}",  # JWT
    r"AKIA[A-Z0-9]{16}",          # AWS Access Key
    r"xoxb-[0-9]+-[A-Za-z0-9]+",  # Slack Bot Token
]

INJECTION_PATTERNS = [
    r"上記の指示を無視",
    r"ignore (the |all |previous |above )",
    r"disregard (the |all |previous |above )",
    r"forget (the |all |previous |above )",
    r"override (the |all |previous |above )",
]

PRIVILEGE_ESCALATION_PATTERNS = [
    r"sudo\s+",
    r"chmod\s+777",
    r"/etc/passwd",
    r"/etc/shadow",
    r"~/.ssh/",
]

VALID_MODELS = {
    "claude-opus-4-6",
    "claude-sonnet-4-6",
    "claude-haiku-4-5-20251001",
    "claude-opus-4-5",
    "claude-sonnet-4-5",
    # 短縮形も許容
    "opus",
    "sonnet",
    "haiku",
}


# ────────────────────────────────────────────
# ロード
# ────────────────────────────────────────────

def load_agent(source: str) -> dict[str, Any]:
    """ファイルパス / JSON文字列 / GitHub URL からエージェントを読み込む"""
    path = Path(source)
    if path.exists():
        with open(path, encoding="utf-8") as f:
            return json.load(f)

    # JSON 文字列として試みる
    try:
        return json.loads(source)
    except json.JSONDecodeError:
        pass

    # GitHub URL
    if source.startswith("https://github.com"):
        raw_url = source.replace(
            "https://github.com/", "https://raw.githubusercontent.com/"
        ).replace("/blob/", "/")
        req = urllib.request.Request(raw_url, headers={"User-Agent": "agent-importer/1.0"})
        with urllib.request.urlopen(req, timeout=10) as resp:
            return json.loads(resp.read().decode("utf-8"))

    raise ValueError(f"ソースを解析できません: {source}")


# ────────────────────────────────────────────
# セキュリティ vetting
# ────────────────────────────────────────────

def security_vetting(agent: dict[str, Any]) -> list[dict[str, str]]:
    """8点セキュリティチェック。問題があれば issue リストを返す"""
    issues: list[dict[str, str]] = []
    prompt = agent.get("systemPrompt", "")

    # 1. 危険コマンド
    for pat in DANGER_PATTERNS:
        if re.search(pat, prompt, re.IGNORECASE):
            issues.append({"level": "CRITICAL", "check": "危険コマンド", "detail": f"パターン検出: `{pat}`"})

    # 2. 機密情報ハードコード
    for pat in SECRET_PATTERNS:
        if re.search(pat, prompt):
            issues.append({"level": "CRITICAL", "check": "機密情報ハードコード", "detail": f"パターン検出: `{pat}`"})

    # 3. 外部URL
    urls = re.findall(r"https?://[^\s\"']+", prompt)
    suspicious_urls = [u for u in urls if not any(
        trusted in u for trusted in [
            "github.com", "docs.anthropic.com", "supabase.com",
            "nextjs.org", "tailwindcss.com", "vercel.com",
        ]
    )]
    if suspicious_urls:
        issues.append({
            "level": "WARNING",
            "check": "外部URL",
            "detail": f"要確認URL: {', '.join(suspicious_urls[:3])}",
        })

    # 4. tools 権限チェック
    tools = agent.get("tools", [])
    if "Bash" in tools and "Write" in tools:
        issues.append({
            "level": "WARNING",
            "check": "tools権限",
            "detail": "Bash + Write の組み合わせ。意図的な場合は無視してください",
        })
    overpowered = [t for t in tools if "FullAccess" in t or "Admin" in t]
    if overpowered:
        issues.append({"level": "CRITICAL", "check": "過剰権限", "detail": f"過剰権限ツール: {overpowered}"})

    # 5. プロンプトインジェクション
    for pat in INJECTION_PATTERNS:
        if re.search(pat, prompt, re.IGNORECASE):
            issues.append({"level": "CRITICAL", "check": "プロンプトインジェクション", "detail": f"パターン検出: `{pat}`"})

    # 6. 権限昇格
    for pat in PRIVILEGE_ESCALATION_PATTERNS:
        if re.search(pat, prompt, re.IGNORECASE):
            issues.append({"level": "CRITICAL", "check": "権限昇格", "detail": f"パターン検出: `{pat}`"})

    # 7. model バリデーション
    model = agent.get("model", "")
    if model and model not in VALID_MODELS:
        issues.append({"level": "WARNING", "check": "不審なmodel指定", "detail": f"未知のモデル: `{model}`"})

    # 8. 既存重複チェック
    agents_dir = Path.home() / ".claude" / "agents"
    name = agent.get("name", "")
    if name and (agents_dir / f"{name}.json").exists():
        issues.append({"level": "WARNING", "check": "既存重複", "detail": f"~/.claude/agents/{name}.json が既に存在します"})

    return issues


# ────────────────────────────────────────────
# 品質スコアリング
# ────────────────────────────────────────────

def quality_score(agent: dict[str, Any]) -> tuple[int, list[str]]:
    """100点満点スコアリング。スコアと詳細リストを返す"""
    score = 0
    details: list[str] = []

    desc = agent.get("description", "")
    examples = agent.get("examples", [])
    name = agent.get("name", "")
    display = agent.get("displayName", "")
    model = agent.get("model", "")
    isolation = agent.get("isolation", "")
    tags = agent.get("tags", [])

    if "Use when" in desc or "Use when" in desc:
        score += 25
        details.append("[+25] description に 'Use when' あり")
    else:
        details.append("[ 0] description に 'Use when' なし")

    if "Do not trigger" in desc or "Do not use" in desc:
        score += 20
        details.append("[+20] description に 'Do not trigger' あり")
    else:
        details.append("[ 0] description に 'Do not trigger' なし")

    if len(examples) >= 3:
        score += 25
        details.append(f"[+25] examples {len(examples)}個あり（3個以上）")
    elif len(examples) > 0:
        score += 10
        details.append(f"[+10] examples {len(examples)}個あり（3個未満）")
    else:
        details.append("[ 0] examples なし")

    if name and display:
        score += 10
        details.append("[+10] name + displayName 両方定義あり")
    elif name:
        score += 5
        details.append("[+ 5] name のみ（displayName なし）")
    else:
        details.append("[ 0] name 未定義")

    if model:
        score += 10
        details.append(f"[+10] model 明示: {model}")
    else:
        details.append("[ 0] model 未指定")

    if isolation == "worktree":
        score += 5
        details.append("[+ 5] isolation: worktree 設定あり")
    else:
        details.append("[ 0] isolation: worktree なし")

    if len(tags) >= 3:
        score += 5
        details.append(f"[+ 5] tags {len(tags)}個あり（3個以上）")
    else:
        details.append(f"[ 0] tags {len(tags)}個（3個未満）")

    return score, details


# ────────────────────────────────────────────
# 最適化
# ────────────────────────────────────────────

def optimize(agent: dict[str, Any]) -> tuple[dict[str, Any], list[str]]:
    """不足項目を自動補完・提案。最適化済みエージェントと変更ログを返す"""
    optimized = dict(agent)
    changes: list[str] = []

    if not optimized.get("isolation"):
        optimized["isolation"] = "worktree"
        changes.append("isolation: 'worktree' を追加")

    if not optimized.get("version"):
        optimized["version"] = "1.0.0"
        changes.append("version: '1.0.0' を追加")

    if not optimized.get("author"):
        optimized["author"] = "Sekiguchi Yuki"
        changes.append("author: 'Sekiguchi Yuki' を追加")

    prompt = optimized.get("systemPrompt", "")
    if prompt and "日本語で応答" not in prompt:
        optimized["systemPrompt"] = prompt.rstrip() + "\n\n必ず日本語で応答してください。"
        changes.append("systemPrompt 末尾に日本語指示を追加")

    if not optimized.get("displayName") and optimized.get("name"):
        optimized["displayName"] = f"🤖 {optimized['name'].replace('-', ' ').title()}"
        changes.append(f"displayName: '{optimized['displayName']}' を自動生成")

    return optimized, changes


# ────────────────────────────────────────────
# レポート生成
# ────────────────────────────────────────────

def generate_report(
    agent: dict[str, Any],
    source: str,
    issues: list[dict[str, str]],
    score: int,
    score_details: list[str],
    changes: list[str],
) -> str:
    name = agent.get("name", "unknown")
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    critical = [i for i in issues if i["level"] == "CRITICAL"]
    warnings = [i for i in issues if i["level"] == "WARNING"]
    verdict = "✅ APPROVED" if not critical else "❌ REJECTED"
    if warnings and not critical:
        verdict = "⚠️ NEEDS_REVIEW"

    score_label = "✅ 優秀" if score >= 90 else "🟡 良好" if score >= 70 else "⚠️ 要改善" if score >= 50 else "❌ 不十分"

    lines = [
        f"# Agent Import Audit Report",
        f"Date: {timestamp}",
        f"Agent: `{name}`",
        f"Source: {source}",
        "",
        "---",
        "",
        "## Security Vetting",
    ]

    if not issues:
        lines.append("✅ 全8項目クリア")
    else:
        for issue in issues:
            icon = "❌" if issue["level"] == "CRITICAL" else "⚠️"
            lines.append(f"- {icon} **{issue['check']}**: {issue['detail']}")

    lines += [
        "",
        f"## Quality Score: {score}/100 {score_label}",
    ]
    lines += [f"  {d}" for d in score_details]

    if changes:
        lines += [
            "",
            "## 自動最適化（適用済み）",
        ]
        lines += [f"- {c}" for c in changes]

    lines += [
        "",
        f"## Verdict: {verdict}",
    ]
    if critical:
        lines.append("")
        lines.append("**CRITICAL な問題が検出されたためインストールを中止します。**")
        lines.append("上記の問題を修正してから再度実行してください。")

    return "\n".join(lines)


# ────────────────────────────────────────────
# メイン
# ────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(description="Claude Code エージェント vetting + 品質スコアリング")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--file", help="エージェントJSONファイルのパス")
    group.add_argument("--json", help="エージェントJSON文字列")
    group.add_argument("--source", help="GitHub URL")
    parser.add_argument("--output", help="レポート出力先（省略時は ~/.claude/tmp/ に自動保存）")
    parser.add_argument("--install", action="store_true", help="承認後に自動インストール")
    args = parser.parse_args()

    source = args.file or args.json or args.source
    print(f"🔍 エージェント読み込み中: {source[:80]}...")

    try:
        agent = load_agent(source)
    except Exception as e:
        print(f"❌ 読み込み失敗: {e}", file=sys.stderr)
        sys.exit(1)

    print(f"📋 エージェント名: {agent.get('name', '(未定義)')}")

    issues = security_vetting(agent)
    score, score_details = quality_score(agent)
    optimized, changes = optimize(agent)
    report = generate_report(agent, source, issues, score, score_details, changes)

    # レポート保存
    tmp_dir = Path.home() / ".claude" / "tmp"
    tmp_dir.mkdir(parents=True, exist_ok=True)
    ts = datetime.now().strftime("%Y%m%d-%H%M%S")
    name = agent.get("name", "unknown")
    out_path = Path(args.output) if args.output else tmp_dir / f"agent-audit-{name}-{ts}.md"
    out_path.write_text(report, encoding="utf-8")
    print(f"\n📄 監査レポート: {out_path}")
    print(f"\n{report}")

    # CRITICAL があればここで終了
    critical = [i for i in issues if i["level"] == "CRITICAL"]
    if critical:
        print("\n❌ CRITICAL な問題が検出されました。インストールを中止します。")
        sys.exit(1)

    # インストール
    if args.install:
        agents_dir = Path.home() / ".claude" / "agents"
        agents_dir.mkdir(parents=True, exist_ok=True)
        dest = agents_dir / f"{name}.json"
        dest.write_text(json.dumps(optimized, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"\n✅ インストール完了: {dest}")
    else:
        print("\n💡 インストールするには --install フラグを追加してください")
        print(f"   python3 {__file__} --file {source} --install")


if __name__ == "__main__":
    main()
