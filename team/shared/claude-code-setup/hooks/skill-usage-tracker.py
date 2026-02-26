#!/usr/bin/env python3
"""
skill-usage-tracker.py — PostToolUse hook (matcher: Skill)
Skill ツールの使用を ~/.claude/debug/skill-usage.jsonl に記録する
skill-usage-logger.sh (UserPromptSubmit) より正確: 実際のツール呼び出しを記録
"""
import sys, json
from pathlib import Path
from datetime import datetime, timezone

LOG_FILE = Path.home() / ".claude/debug/skill-usage.jsonl"
MAX_LINES = 2000
KEEP_LINES = 1000


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    if data.get("tool_name") != "Skill":
        sys.exit(0)

    tool_input = data.get("tool_input", {})
    skill_name = tool_input.get("skill", "").strip()
    if not skill_name:
        sys.exit(0)

    entry = {
        "ts": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "skill": skill_name,
        "args": (tool_input.get("args") or "")[:100],
        "source": "tool",  # UserPromptSubmit 経由の "prompt" と区別
    }

    LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
    with LOG_FILE.open("a") as f:
        f.write(json.dumps(entry, ensure_ascii=False) + "\n")

    # last-skill.txt も更新（session-start-context.sh で "最後に使ったスキル" として表示）
    try:
        state_dir = Path.home() / ".claude/session-env"
        state_dir.mkdir(parents=True, exist_ok=True)
        (state_dir / "last-skill.txt").write_text(skill_name)
    except Exception:
        pass

    # ローテーション: MAX_LINES 超えたら最新 KEEP_LINES 行に切り詰め
    try:
        lines = LOG_FILE.read_text().splitlines()
        if len(lines) > MAX_LINES:
            LOG_FILE.write_text("\n".join(lines[-KEEP_LINES:]) + "\n")
    except Exception:
        pass


if __name__ == "__main__":
    main()
