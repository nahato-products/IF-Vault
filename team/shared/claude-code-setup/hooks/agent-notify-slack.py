#!/usr/bin/env python3
"""
agent-notify-slack.py — PostToolUse(Edit|Write) フック
~/.claude/agents/*.json が更新されたとき、
additionalContext で Claude に Slack 通知を促す。
agent-sync.py と連動して動作する（同じ条件で起動）。
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

AGENTS_DIR = Path.home() / ".claude/agents"


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except Exception:
        print("{}")
        return

    tool_input = data.get("tool_input", {})
    file_path  = tool_input.get("file_path", "")

    try:
        target = Path(file_path).resolve()
        if not str(target).startswith(str(AGENTS_DIR.resolve())):
            print("{}")
            return
        if target.suffix != ".json":
            print("{}")
            return
    except Exception:
        print("{}")
        return

    agent_name = target.stem
    try:
        agent = json.loads(target.read_text(encoding="utf-8"))
        display = agent.get("displayName", agent_name)
        model   = agent.get("model", "不明")
    except Exception:
        display = agent_name
        model   = "不明"

    context = (
        f"[agent-notify] 🤖 エージェント **{display}**（{agent_name}）が更新されました（model: {model}）。"
        f" IF-Vault に自動同期済みです。"
        f" Slack でチームにシェアしますか？（任意）"
    )
    print(json.dumps({"additionalContext": context}, ensure_ascii=False))


if __name__ == "__main__":
    main()
