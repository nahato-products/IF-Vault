#!/usr/bin/env python3
"""
lessons-sync.py — Stop フック
セッション終了時に個人の lessons.md を IF-Vault の team/{name}/ に同期する。
チーム全員の気づきが蓄積されていく。
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

LESSONS_SRC  = Path.home() / ".claude/session-env/lessons.md"
VAULT        = Path.home() / "Documents/Obsidian Vault"
MEMBER_NAME  = "sekiguchi"
LESSONS_DEST = VAULT / f"team/{MEMBER_NAME}/lessons.md"


def main() -> None:
    # lessons.md がなければスキップ
    if not LESSONS_SRC.exists():
        print("{}")
        return

    src_text = LESSONS_SRC.read_text(encoding="utf-8").strip()
    if not src_text:
        print("{}")
        return

    # IF-Vault が存在しなければスキップ
    if not VAULT.exists() or not (VAULT / ".git").exists():
        print("{}")
        return

    # 宛先ディレクトリ作成
    LESSONS_DEST.parent.mkdir(parents=True, exist_ok=True)

    # 既存と差分チェック
    existing = LESSONS_DEST.read_text(encoding="utf-8").strip() if LESSONS_DEST.exists() else ""
    if src_text == existing:
        print("{}")
        return

    # 書き込み
    LESSONS_DEST.write_text(src_text + "\n", encoding="utf-8")

    # git commit（エラーは無視）
    try:
        subprocess.run(["git", "add", str(LESSONS_DEST)], cwd=str(VAULT), capture_output=True, timeout=10)
        result = subprocess.run(["git", "diff", "--cached", "--quiet"], cwd=str(VAULT), capture_output=True, timeout=5)
        if result.returncode != 0:
            subprocess.run(
                ["git", "commit", "-m", f"lessons: {MEMBER_NAME} の学習パターンを更新"],
                cwd=str(VAULT), capture_output=True, timeout=15,
            )
    except Exception:
        pass

    print("{}")


if __name__ == "__main__":
    main()
