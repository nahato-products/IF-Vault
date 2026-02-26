#!/usr/bin/env python3
"""
patch-settings.py — ~/.claude/settings.json に全フック設定を安全に追加する。
重複チェック付き。既存設定は上書きしない。
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

SETTINGS_FILE = Path.home() / ".claude" / "settings.json"

# 追加するフック設定（全フック対応）
PATCHES = {
    "PreToolUse": [
        {
            "matcher": "Read",
            "hooks": [
                {"type": "command", "command": "~/.claude/hooks/block-sensitive-read.sh", "timeout": 5},
                {"type": "command", "command": "~/.claude/hooks/token-guardian-warn.sh", "timeout": 5},
            ],
        },
        {
            "matcher": "Bash",
            "hooks": [
                {"type": "command", "command": "~/.claude/hooks/command-shield.sh", "timeout": 5},
                {"type": "command", "command": "~/.claude/hooks/command-shield-gui.sh", "timeout": 5},
            ],
        },
    ],
    "PreCompact": [
        {
            "hooks": [
                {"type": "command", "command": "~/.claude/hooks/session-compact-restore.sh", "timeout": 10},
            ]
        }
    ],
    "UserPromptSubmit": [
        {
            "hooks": [
                {"type": "command", "command": "~/.claude/hooks/skill-autofire-tracker.sh", "timeout": 5},
                {"type": "command", "command": "python3 ~/.claude/hooks/lessons-recorder.py 2>/dev/null", "timeout": 5},
            ]
        }
    ],
    "PostToolUse": [
        {
            "matcher": "Edit|Write",
            "hooks": [
                {"type": "command", "command": "~/.claude/hooks/security-post-edit.sh", "timeout": 10},
                {"type": "command", "command": "~/.claude/hooks/lint-on-edit.sh", "timeout": 10},
                {"type": "command", "command": "python3 ~/.claude/hooks/agent-sync.py 2>/dev/null", "timeout": 15},
            ],
        },
        {
            "matcher": "Skill",
            "hooks": [
                {"type": "command", "command": "python3 ~/.claude/hooks/skill-usage-tracker.py 2>/dev/null", "timeout": 5},
                {"type": "command", "command": "python3 ~/.claude/hooks/combo-suggester.py 2>/dev/null", "timeout": 5},
            ],
        },
        {
            "matcher": "Task",
            "hooks": [
                {"type": "command", "command": "python3 ~/.claude/hooks/agent-usage-tracker.py 2>/dev/null", "timeout": 5},
            ],
        },
    ],
    "PostToolUseFailure": [
        {
            "hooks": [
                {"type": "command", "command": "~/.claude/hooks/tool-failure-logger.sh", "timeout": 5},
            ]
        }
    ],
    "Notification": [
        {
            "hooks": [
                {"type": "command", "command": "~/.claude/hooks/notification.sh", "timeout": 5},
            ]
        }
    ],
    "Stop": [
        {
            "hooks": [
                {"type": "command", "command": "~/.claude/hooks/session-stop-summary.sh", "timeout": 15},
            ]
        }
    ],
    "SessionStart": [
        {
            "hooks": [
                {"type": "command", "command": "python3 ~/.claude/hooks/project-skill-preset.py 2>/dev/null", "timeout": 10},
                {"type": "command", "command": "python3 ~/.claude/hooks/update-skill-ranks.py 2>/dev/null", "timeout": 10},
                {"type": "command", "command": "python3 ~/.claude/hooks/workflow-audit.py 2>/dev/null", "timeout": 10},
                {"type": "command", "command": "python3 ~/.claude/hooks/env-orchestrator.py 2>/dev/null", "timeout": 15},
                {"type": "command", "command": "python3 ~/.claude/hooks/agent-audit-check.py 2>/dev/null", "timeout": 10},
                {"type": "command", "command": "python3 ~/.claude/hooks/update-agent-ranks.py 2>/dev/null", "timeout": 10},
                {"type": "command", "command": "python3 ~/.claude/hooks/agent-discovery.py 2>/dev/null", "timeout": 15},
                {"type": "command", "command": "~/.claude/hooks/session-start-context.sh", "timeout": 10},
            ]
        }
    ],
    "ConfigChange": [
        {
            "hooks": [
                {"type": "command", "command": "~/.claude/hooks/config-change-audit.sh", "timeout": 5},
            ]
        }
    ],
    "WorktreeCreate": [
        {
            "hooks": [
                {"type": "command", "command": "~/.claude/hooks/worktree-setup.sh", "timeout": 10},
            ]
        }
    ],
    "WorktreeRemove": [
        {
            "hooks": [
                {"type": "command", "command": "~/.claude/hooks/worktree-cleanup.sh", "timeout": 10},
            ]
        }
    ],
}


def get_existing_commands(entries: list[dict]) -> set[str]:
    """既存フック設定からコマンド一覧を取得（重複チェック用）"""
    cmds: set[str] = set()
    for entry in entries:
        for hook in entry.get("hooks", []):
            cmd = hook.get("command", "")
            if cmd:
                cmds.add(cmd)
    return cmds


def merge_event(existing: list[dict], patches: list[dict], event: str) -> tuple[list[dict], int]:
    """既存エントリにパッチを重複なくマージ。追加件数を返す"""
    existing_cmds = get_existing_commands(existing)
    added = 0

    for patch_entry in patches:
        matcher = patch_entry.get("matcher")
        new_hooks = [
            h for h in patch_entry.get("hooks", [])
            if h.get("command", "") not in existing_cmds
        ]
        if not new_hooks:
            continue

        # 同じ matcher を持つ既存エントリを探してマージ
        if matcher:
            target = next(
                (e for e in existing if e.get("matcher") == matcher), None
            )
            if target:
                target.setdefault("hooks", []).extend(new_hooks)
            else:
                existing.append({"matcher": matcher, "hooks": new_hooks})
        else:
            # matcher なし: 最初の matcher なしエントリにマージ
            target = next((e for e in existing if "matcher" not in e), None)
            if target:
                target.setdefault("hooks", []).extend(new_hooks)
            else:
                existing.append({"hooks": new_hooks})

        added += len(new_hooks)

    return existing, added


def main() -> None:
    # settings.json 読み込み（なければ空オブジェクト）
    if SETTINGS_FILE.exists():
        try:
            settings = json.loads(SETTINGS_FILE.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            print("❌ settings.json のパースに失敗しました。手動で確認してください。", file=sys.stderr)
            sys.exit(1)
    else:
        settings = {}

    hooks = settings.setdefault("hooks", {})
    total_added = 0

    for event, patches in PATCHES.items():
        existing = hooks.setdefault(event, [])
        merged, added = merge_event(existing, patches, event)
        hooks[event] = merged
        total_added += added
        if added:
            print(f"  ✓ {event}: {added}件追加")
        else:
            print(f"  - {event}: スキップ（既に設定済み）")

    # 書き込み
    SETTINGS_FILE.parent.mkdir(parents=True, exist_ok=True)
    SETTINGS_FILE.write_text(
        json.dumps(settings, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    print(f"\n✅ settings.json 更新完了（{total_added}件追加）")


if __name__ == "__main__":
    main()
