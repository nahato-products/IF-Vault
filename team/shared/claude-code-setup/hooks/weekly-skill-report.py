#!/usr/bin/env python3
"""
weekly-skill-report.py — 手動実行 or SessionStart（週1回）
直近7日間のスキル使用ランキングを集計し、
additionalContext で Claude に Slack 投稿を促す。
"""
from __future__ import annotations

import json
import sys
from collections import Counter
from datetime import datetime, timezone, timedelta
from pathlib import Path

USAGE_LOG   = Path.home() / ".claude/debug/skill-usage.jsonl"
STATE_FILE  = Path.home() / ".claude/session-env/weekly-report-state.json"
REPORT_DAYS = 7


def load_state() -> dict:
    try:
        return json.loads(STATE_FILE.read_text(encoding="utf-8"))
    except Exception:
        return {}


def save_state(state: dict) -> None:
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    STATE_FILE.write_text(json.dumps(state, ensure_ascii=False, indent=2), encoding="utf-8")


def should_report(state: dict) -> bool:
    last = state.get("last_reported")
    if not last:
        return True
    last_dt = datetime.fromisoformat(last)
    return (datetime.now(timezone.utc) - last_dt).days >= REPORT_DAYS


def collect_usage(since: datetime) -> Counter:
    counter: Counter = Counter()
    if not USAGE_LOG.exists():
        return counter
    for line in USAGE_LOG.read_text(encoding="utf-8").splitlines():
        try:
            entry = json.loads(line)
            ts_str = entry.get("timestamp") or entry.get("ts")
            if not ts_str:
                continue
            ts = datetime.fromisoformat(ts_str)
            if ts.tzinfo is None:
                ts = ts.replace(tzinfo=timezone.utc)
            if ts >= since:
                skill = entry.get("skill") or entry.get("name")
                if skill:
                    counter[skill] += 1
        except Exception:
            continue
    return counter


def main() -> None:
    state = load_state()
    if not should_report(state):
        print("{}")
        return

    since = datetime.now(timezone.utc) - timedelta(days=REPORT_DAYS)
    usage = collect_usage(since)

    if not usage:
        print("{}")
        return

    # トップ10
    top10 = usage.most_common(10)
    total = sum(usage.values())
    lines = [f"{i+1}. `{name}` — {count}回" for i, (name, count) in enumerate(top10)]
    ranking = "\n".join(lines)

    period = f"{since.strftime('%m/%d')}〜{datetime.now().strftime('%m/%d')}"
    context = (
        f"[weekly-skill-report] 📊 週次スキル使用ランキング ({period}) が出ました。"
        f" 合計 {total} 回使用。\n{ranking}\n"
        f"この内容を Slack (#claude-code チャンネル等) に投稿してください。"
    )

    state["last_reported"] = datetime.now(timezone.utc).isoformat()
    save_state(state)

    print(json.dumps({"additionalContext": context}, ensure_ascii=False))


if __name__ == "__main__":
    main()
