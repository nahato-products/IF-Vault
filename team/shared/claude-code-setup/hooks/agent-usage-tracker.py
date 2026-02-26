#!/usr/bin/env python3
"""
agent-usage-tracker.py — PostToolUse フック (matcher: Task)
Task ツールの呼び出しからエージェント名を推定し、使用頻度を記録する。
~/.claude/debug/agent-usage.jsonl に追記。
"""
from __future__ import annotations

import json
import sys
from datetime import datetime, timezone
from pathlib import Path

LOG_FILE = Path.home() / ".claude" / "debug" / "agent-usage.jsonl"
MAX_LINES = 2000
KEEP_LINES = 1000

# ~/.claude/agents/ に存在するエージェント名を動的に読む
def get_known_agents() -> list[str]:
    agents_dir = Path.home() / ".claude" / "agents"
    if not agents_dir.exists():
        return []
    return [f.stem for f in sorted(agents_dir.glob("*.json"))]


def detect_agent_name(tool_input: dict, known_agents: list[str]) -> str | None:
    # 1. name パラメータが直接指定されている場合
    name = tool_input.get("name", "").strip().lower()
    if name in known_agents:
        return name

    # 2. description / prompt からエージェント名を推定
    haystack = " ".join([
        tool_input.get("description", ""),
        tool_input.get("prompt", "")[:200],
    ]).lower()

    for agent in known_agents:
        # エージェント名（ハイフン区切り）の部分一致
        if agent in haystack or agent.replace("-", " ") in haystack:
            return agent

    return None


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except Exception:
        print("{}")
        return

    if data.get("tool_name") != "Task":
        print("{}")
        return

    tool_input = data.get("tool_input", {})
    known_agents = get_known_agents()
    agent_name = detect_agent_name(tool_input, known_agents)

    if not agent_name:
        print("{}")
        return

    entry = {
        "ts": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "agent": agent_name,
        "source": "task",
    }

    LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
    with LOG_FILE.open("a", encoding="utf-8") as f:
        f.write(json.dumps(entry, ensure_ascii=False) + "\n")

    # ローテーション
    try:
        lines = LOG_FILE.read_text().splitlines()
        if len(lines) > MAX_LINES:
            LOG_FILE.write_text("\n".join(lines[-KEEP_LINES:]) + "\n")
    except Exception:
        pass

    print("{}")


if __name__ == "__main__":
    main()
