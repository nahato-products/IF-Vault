#!/usr/bin/env python3
"""
agent-discovery.py — SessionStart フック
既知のコミュニティリポジトリを 24h に1回チェックし、
新着エージェントを ~/.claude/session-env/agent-queue.md に追記する。
"""
from __future__ import annotations

import json
import sys
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

STATE_DIR = Path.home() / ".claude" / "session-env"
STATE_FILE = STATE_DIR / "agent-discovery-state.json"
QUEUE_FILE = STATE_DIR / "agent-queue.md"
CHECK_INTERVAL_HOURS = 24

# チェック対象リポジトリ（信頼度順）
SOURCES = [
    {
        "repo": "iannuttall/claude-agents",
        "path": "",         # ルート直下
        "trust": "medium",
    },
    {
        "repo": "rshah515/claude-code-subagents",
        "path": "agents",
        "trust": "medium",
    },
]


def load_state() -> dict:
    try:
        return json.loads(STATE_FILE.read_text(encoding="utf-8"))
    except Exception:
        return {}


def save_state(state: dict) -> None:
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    STATE_FILE.write_text(json.dumps(state, ensure_ascii=False, indent=2), encoding="utf-8")


def should_check(state: dict, repo: str) -> bool:
    last = state.get(repo, {}).get("last_checked")
    if not last:
        return True
    last_dt = datetime.fromisoformat(last)
    now = datetime.now(timezone.utc)
    elapsed = (now - last_dt).total_seconds() / 3600
    return elapsed >= CHECK_INTERVAL_HOURS


def fetch_latest_commit(repo: str, path: str) -> dict | None:
    url = f"https://api.github.com/repos/{repo}/commits?path={path}&per_page=3"
    req = urllib.request.Request(
        url,
        headers={"User-Agent": "agent-discovery/1.0", "Accept": "application/vnd.github.v3+json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=8) as resp:
            commits = json.loads(resp.read().decode("utf-8"))
            if commits:
                return commits[0]
    except Exception:
        pass
    return None


def fetch_file_list(repo: str, path: str) -> list[str]:
    url = f"https://api.github.com/repos/{repo}/contents/{path}"
    req = urllib.request.Request(
        url,
        headers={"User-Agent": "agent-discovery/1.0", "Accept": "application/vnd.github.v3+json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=8) as resp:
            items = json.loads(resp.read().decode("utf-8"))
            return [
                item["name"]
                for item in items
                if item["type"] == "file" and item["name"].endswith((".json", ".md"))
            ]
    except Exception:
        return []


def get_installed_names() -> set[str]:
    agents_dir = Path.home() / ".claude" / "agents"
    return {f.stem for f in agents_dir.glob("*.json")} if agents_dir.exists() else set()


def append_queue(entries: list[dict]) -> None:
    QUEUE_FILE.parent.mkdir(parents=True, exist_ok=True)
    now = datetime.now().strftime("%Y-%m-%d")
    lines = [f"\n## {now} 新着エージェント候補\n"]
    for e in entries:
        lines.append(
            f"- [ ] **{e['name']}** — {e['repo']} ({e['trust']})\n"
            f"  `python3 ~/.agents/skills/agent-importer/scripts/audit_agent.py "
            f"--source https://github.com/{e['repo']}/blob/main/{e['path']} --install`\n"
        )
    with QUEUE_FILE.open("a", encoding="utf-8") as f:
        f.writelines(lines)


def main() -> None:
    state = load_state()
    installed = get_installed_names()
    new_entries: list[dict] = []
    now_iso = datetime.now(timezone.utc).isoformat()

    for source in SOURCES:
        repo = source["repo"]
        path = source["path"]

        if not should_check(state, repo):
            continue

        commit = fetch_latest_commit(repo, path)
        last_sha = state.get(repo, {}).get("last_sha")
        current_sha = commit["sha"] if commit else None

        if current_sha and current_sha != last_sha:
            # 新しいコミットがある → ファイル一覧を取得
            files = fetch_file_list(repo, path)
            for fname in files:
                stem = Path(fname).stem
                # ドキュメント・設定ファイルを除外
                if stem.upper() in {"README", "CHANGELOG", "LICENSE", "CONTRIBUTING", "SETUP"}:
                    continue
                # エージェント名として妥当か（kebab-case, 小文字）
                if not stem.replace("-", "").replace("_", "").isalnum():
                    continue
                if stem not in installed:
                    new_entries.append({
                        "name": stem,
                        "repo": repo,
                        "path": f"{path}/{fname}".lstrip("/"),
                        "trust": source["trust"],
                    })

        # 状態を更新
        state[repo] = {"last_checked": now_iso, "last_sha": current_sha}

    save_state(state)

    if new_entries:
        append_queue(new_entries)
        context = (
            f"[agent-discovery] 🆕 未インストールのコミュニティエージェントが {len(new_entries)}件 見つかりました。"
            f" `~/.claude/session-env/agent-queue.md` を確認して `/agent-importer` で取り込めます。"
        )
        print(json.dumps({"additionalContext": context}, ensure_ascii=False))
    else:
        print("{}")


if __name__ == "__main__":
    main()
