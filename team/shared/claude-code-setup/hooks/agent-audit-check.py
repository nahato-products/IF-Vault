#!/usr/bin/env python3
"""
agent-audit-check: SessionStart 時に全エージェントの品質スコアとセキュリティをチェック。
低品質（< 70点）や CRITICAL 問題を additionalContext で通知する。
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

# audit_agent.py の関数を再利用（~/.agents/skills/ 優先、なければ ~/.claude/skills/）
for _p in [
    Path.home() / ".agents/skills/agent-importer/scripts",
    Path.home() / ".claude/skills/agent-importer/scripts",
]:
    if _p.exists():
        sys.path.insert(0, str(_p))
        break

try:
    from audit_agent import quality_score, security_vetting
except ImportError:
    # audit_agent.py が見つからない場合はスキップ
    print("{}")
    sys.exit(0)

AGENTS_DIR = Path.home() / ".claude" / "agents"
THRESHOLD = 70  # この点数未満を警告


def check_all_agents() -> tuple[list[str], list[str]]:
    low_quality: list[str] = []
    security_issues: list[str] = []

    if not AGENTS_DIR.exists():
        return low_quality, security_issues

    for agent_file in sorted(AGENTS_DIR.glob("*.json")):
        try:
            agent = json.loads(agent_file.read_text(encoding="utf-8"))
            name = agent.get("name", agent_file.stem)

            score, _ = quality_score(agent)
            issues = security_vetting(agent)

            # 既存重複チェックは除外（自分自身が存在するのは正常）
            critical = [
                i for i in issues
                if i["level"] == "CRITICAL" and i["check"] != "既存重複"
            ]

            if score < THRESHOLD:
                low_quality.append(f"{name}({score}点)")
            if critical:
                security_issues.append(f"{name}: {critical[0]['check']}")

        except Exception:
            pass

    return low_quality, security_issues


def main() -> None:
    low_quality, security_issues = check_all_agents()

    messages: list[str] = []

    if security_issues:
        messages.append(f"🚨 エージェントに CRITICAL な問題: {', '.join(security_issues)}")

    if low_quality:
        messages.append(f"⚠️ 品質スコア {THRESHOLD}点未満のエージェント: {', '.join(low_quality)}")

    if messages:
        context = "[agent-audit] " + " / ".join(messages) + "\n`/agent-importer` で修正できます。"
        print(json.dumps({"additionalContext": context}, ensure_ascii=False))
    else:
        print("{}")


if __name__ == "__main__":
    main()
