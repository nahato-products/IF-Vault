#!/usr/bin/env python3
"""
update-agent-ranks.py — SessionStart フック
agent-usage.jsonl を集計してエージェントのランクを計算・更新する。
スキルの update-skill-ranks.py と対称な設計。

ランク仕様（スキルと同じ基準）:
  0回    → N（New・未使用）
  1-4回  → N-C
  5-9回  → N-B
  10-19回 → N-A
  20回以上 → N-S

パーキング候補: Nランクのまま 30日以上経過
"""
from __future__ import annotations

import json
import sys
from collections import defaultdict
from datetime import datetime, timezone, timedelta
from pathlib import Path

LOG_FILE = Path.home() / ".claude" / "debug" / "agent-usage.jsonl"
RANKS_FILE = Path.home() / ".claude" / "session-env" / "agent-ranks.json"
AGENTS_DIR = Path.home() / ".claude" / "agents"

RANK_THRESHOLDS = [
    (20, "N-S"),
    (10, "N-A"),
    (5,  "N-B"),
    (1,  "N-C"),
    (0,  "N"),
]

PARKING_DAYS = 30  # Nランクのまま放置でパーキング候補


def calc_rank(count: int) -> str:
    for threshold, rank in RANK_THRESHOLDS:
        if count >= threshold:
            return rank
    return "N"


def load_usage() -> dict[str, int]:
    counts: dict[str, int] = defaultdict(int)
    if not LOG_FILE.exists():
        return counts
    for line in LOG_FILE.read_text(encoding="utf-8").splitlines():
        try:
            entry = json.loads(line)
            agent = entry.get("agent", "").strip()
            if agent:
                counts[agent] += 1
        except Exception:
            continue
    return counts


def load_ranks() -> dict:
    try:
        return json.loads(RANKS_FILE.read_text(encoding="utf-8"))
    except Exception:
        return {}


def save_ranks(ranks: dict) -> None:
    RANKS_FILE.parent.mkdir(parents=True, exist_ok=True)
    RANKS_FILE.write_text(json.dumps(ranks, ensure_ascii=False, indent=2), encoding="utf-8")


def get_all_agents() -> list[str]:
    if not AGENTS_DIR.exists():
        return []
    return [f.stem for f in sorted(AGENTS_DIR.glob("*.json"))]


def main() -> None:
    usage = load_usage()
    prev_ranks = load_ranks()
    all_agents = get_all_agents()
    now_iso = datetime.now(timezone.utc).isoformat()

    new_ranks: dict = {}
    promoted: list[str] = []
    parking_candidates: list[str] = []
    summary_lines: list[str] = []

    for agent in all_agents:
        count = usage.get(agent, 0)
        new_rank = calc_rank(count)
        prev = prev_ranks.get(agent, {})
        prev_rank = prev.get("rank", "N")
        first_seen = prev.get("first_seen", now_iso)

        # ランクアップ検出
        rank_order = ["N", "N-C", "N-B", "N-A", "N-S"]
        prev_idx = rank_order.index(prev_rank) if prev_rank in rank_order else 0
        new_idx = rank_order.index(new_rank) if new_rank in rank_order else 0
        if new_idx > prev_idx:
            promoted.append(f"{agent}: {prev_rank} → {new_rank}")

        # パーキング候補チェック（Nランク + 30日以上）
        if new_rank == "N":
            try:
                first_dt = datetime.fromisoformat(first_seen)
                if (datetime.now(timezone.utc) - first_dt).days >= PARKING_DAYS:
                    parking_candidates.append(agent)
            except Exception:
                pass

        new_ranks[agent] = {
            "rank": new_rank,
            "count": count,
            "first_seen": first_seen,
            "updated": now_iso,
        }
        summary_lines.append(f"  {new_rank:<5} {agent} ({count}回)")

    save_ranks(new_ranks)

    # stdout に出力（SessionStart の additionalContext）
    messages: list[str] = []

    if promoted:
        messages.append(f"🎉 エージェントランクアップ: {', '.join(promoted)}")

    if parking_candidates:
        messages.append(
            f"📦 パーキング候補（{PARKING_DAYS}日以上未使用）: {', '.join(parking_candidates)}"
        )

    if messages:
        context = "[agent-ranks] " + " / ".join(messages)
        print(json.dumps({"additionalContext": context}, ensure_ascii=False))
    else:
        print("{}")

    # ランクサマリーを stderr に出力（SessionStart hook の success メッセージとして表示）
    print(f"\n[update-agent-ranks] ランクサマリー", file=sys.stderr)
    for line in sorted(summary_lines):
        print(line, file=sys.stderr)


if __name__ == "__main__":
    main()
