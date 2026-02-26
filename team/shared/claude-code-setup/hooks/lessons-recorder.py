#!/usr/bin/env python3
"""
lessons-recorder: ユーザーの修正・指摘パターンを検知し、
tasks/lessons.md への記録を Claude に自動指示する。
UserPromptSubmit フックとして動作。
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

# 修正・指摘を示すキーワードパターン
CORRECTION_PATTERNS = [
    r'違(う|い|います|いました)',
    r'(そう|それ)じゃ(ない|なく)',
    r'(間違|まちが)(い|え|えて)',
    r'修正して',
    r'直して',
    r'(ちょっと|少し)?待って',
    r'ダメ(だよ|です|じゃん)?',
    r'NGで',
    r'(やり直|やりなお)し',
    r'そうじゃ(なくて|なく)',
    r'(意図|ねらい|目的)が違',
    r'誤解して',
]

LESSONS_PATH = Path.home() / ".claude" / "session-env" / "lessons.md"


def is_correction(message: str) -> bool:
    for pat in CORRECTION_PATTERNS:
        if re.search(pat, message):
            return True
    return False


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except Exception:
        print("{}")
        return

    message = data.get("message", "")

    if not is_correction(message):
        print("{}")
        return

    # lessons.md が存在しない場合は初期化
    LESSONS_PATH.parent.mkdir(parents=True, exist_ok=True)
    if not LESSONS_PATH.exists():
        LESSONS_PATH.write_text(
            "# Lessons Learned\n\nセッション中の修正・指摘パターンを記録する。\n次のセッション開始時に参照し、同じミスを繰り返さない。\n\n",
            encoding="utf-8",
        )

    # Claude への指示を additionalContext として注入
    context = (
        f"[lessons-recorder] ユーザーから修正・指摘が検出されました。\n"
        f"このやりとりで何を間違えたか・なぜ指摘されたかを1行で {LESSONS_PATH} に追記してください。\n"
        f"形式: `- [YYYY-MM-DD] <間違えたパターン> → <正しいアプローチ>`\n"
        f"記録後は通常の応答を続けてください。"
    )

    print(json.dumps({"additionalContext": context}, ensure_ascii=False))


if __name__ == "__main__":
    main()
