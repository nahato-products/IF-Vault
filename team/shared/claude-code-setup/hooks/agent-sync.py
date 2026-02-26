#!/usr/bin/env python3
"""
agent-sync: ~/.claude/agents/ への変更を team-claude-skills/agents/ に自動同期する。
PostToolUse (Edit|Write) フックとして動作。
対象ファイルが ~/.claude/agents/*.json のときのみ実行。
"""
from __future__ import annotations

import json
import shutil
import subprocess
import sys
from pathlib import Path

AGENTS_SRC = Path.home() / ".claude" / "agents"
TEAM_REPO = Path.home() / "team-claude-skills"
AGENTS_DEST = TEAM_REPO / "agents"


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except Exception:
        print("{}")
        return

    # tool_input の file_path を確認（Edit/Write の場合）
    tool_input = data.get("tool_input", {})
    file_path = tool_input.get("file_path", "")

    # ~/.claude/agents/*.json への変更のみ対象
    try:
        target = Path(file_path).resolve()
        agents_dir = AGENTS_SRC.resolve()
        if not str(target).startswith(str(agents_dir)):
            print("{}")
            return
        if target.suffix != ".json":
            print("{}")
            return
    except Exception:
        print("{}")
        return

    # team-claude-skills リポジトリの存在確認
    if not TEAM_REPO.exists() or not (TEAM_REPO / ".git").exists():
        print("{}")
        return

    # agents/ ディレクトリを作成（初回）
    AGENTS_DEST.mkdir(exist_ok=True)

    # 変更されたファイルを同期
    agent_name = target.stem
    dest_file = AGENTS_DEST / target.name

    try:
        shutil.copy2(target, dest_file)
    except Exception:
        print("{}")
        return

    # git add + commit（エラーは無視）
    try:
        subprocess.run(
            ["git", "add", str(dest_file)],
            cwd=str(TEAM_REPO),
            capture_output=True,
            timeout=10,
        )
        result = subprocess.run(
            ["git", "diff", "--cached", "--quiet"],
            cwd=str(TEAM_REPO),
            capture_output=True,
            timeout=5,
        )
        # 差分があればコミット
        if result.returncode != 0:
            subprocess.run(
                ["git", "commit", "-m", f"エージェント更新: {agent_name}"],
                cwd=str(TEAM_REPO),
                capture_output=True,
                timeout=15,
            )
    except Exception:
        pass

    print("{}")


if __name__ == "__main__":
    main()
