#!/usr/bin/env python3
"""
notion-task-updater.py — Stop フック
セッション終了時に session-stop-summary.sh が書いた完了タスクを読み取り、
additionalContext で Claude に Notion ステータス更新を促す。
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

SUMMARY_FILE = Path.home() / ".claude/session-env/session-summary.md"


def main() -> None:
    if not SUMMARY_FILE.exists():
        print("{}")
        return

    text = SUMMARY_FILE.read_text(encoding="utf-8")

    # 完了タスクを抽出（✅ or [x] マーク）
    completed = re.findall(r'(?:✅|☑️|\[x\])\s+(.+)', text)
    if not completed:
        print("{}")
        return

    items = "\n".join(f"- {t.strip()}" for t in completed[:5])
    context = (
        f"[notion-task-updater] ✅ このセッションで完了したタスク（{len(completed)}件）:\n{items}\n"
        f"Notion のタスクボードでステータスを「完了」に更新しますか？ (Notion MCP を使います)"
    )
    print(json.dumps({"additionalContext": context}, ensure_ascii=False))


if __name__ == "__main__":
    main()
