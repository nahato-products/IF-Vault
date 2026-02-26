#!/usr/bin/env python3
"""
skill-stats.py — ops:skill-stats スキルから呼ばれる分析スクリプト
ログファイルからスキル使用統計を集計して表示する
"""
import json, re, sys, os
sys.path.insert(0, os.path.expanduser("~/.claude/hooks"))
from _skill_utils import SkillCache
from pathlib import Path
from collections import Counter, defaultdict
from datetime import datetime, timezone, timedelta
from typing import Dict, List

_cache = SkillCache()

HOME = Path.home()
USAGE_LOG    = HOME / ".claude/debug/skill-usage.jsonl"
AUTOFIRE_LOG = HOME / ".claude/debug/skill-autofire.jsonl"
CLAUDE_JSON  = HOME / ".claude.json"

# ---- データ収集 ----

def load_jsonl(path: Path) -> List[dict]:
    if not path.exists():
        return []
    entries = []
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            entries.append(json.loads(line))
        except Exception:
            pass
    return entries

usage_entries = load_jsonl(USAGE_LOG)
autofire_entries = load_jsonl(AUTOFIRE_LOG)

# 使用カウント（手動呼び出し）
manual_counts: Counter = Counter()
last_used: Dict[str, str] = {}
for e in usage_entries:
    skill = e.get("skill", "").lstrip("/")
    if skill:
        manual_counts[skill] += 1
        last_used[skill] = e.get("ts", "")

# 自動発火カウント
autofire_counts: Counter = Counter()
for e in autofire_entries:
    for skill in e.get("matched_skills", []):
        autofire_counts[skill] += 1

# アクティブスキル一覧
active_skills = _cache.active_skills()

# 全スキル一覧 + ランク読み取り
all_skills: Dict[str, str] = {
    name: meta["rank"]
    for name, meta in _cache.skill_meta().items()
}

# ---- 集計 ----

# 直近7日間のアクティビティ
now = datetime.now(timezone.utc)
week_ago = now - timedelta(days=7)
recent_skills: Counter = Counter()
for e in usage_entries:
    ts_str = e.get("ts", "")
    try:
        ts = datetime.fromisoformat(ts_str.replace("Z", "+00:00"))
        if ts >= week_ago:
            skill = e.get("skill", "").lstrip("/")
            if skill:
                recent_skills[skill] += 1
    except Exception:
        pass

# ランク別集計
rank_groups: Dict[str, List[str]] = defaultdict(list)
for skill, rank in all_skills.items():
    rank_groups[rank].append(skill)

# パーキング候補（アクティブだが使用0）
parking_candidates = [
    s for s in active_skills
    if manual_counts.get(s, 0) == 0 and autofire_counts.get(s, 0) == 0
    and s in all_skills
]

# ---- 長期未使用・降格候補（~/.claude.json の skillUsage.lastUsedAt を使用）----
THIRTY_DAYS_MS = 30 * 24 * 60 * 60 * 1000
now_ms = now.timestamp() * 1000

long_unused: List[str] = []       # 30日超未使用のアクティブスキル
downgrade_candidates: List[str] = []  # SR/UR + 30日超未使用

try:
    skill_usage_native = json.loads(CLAUDE_JSON.read_text()).get("skillUsage", {})
    seen_keys: set = set()
    for skill in sorted(active_skills):
        skill_key = skill.lstrip("_")
        if skill_key in seen_keys:   # _prefix あり・なしの重複を除去
            continue
        seen_keys.add(skill_key)
        usage = skill_usage_native.get(skill_key, {})
        last_ms = usage.get("lastUsedAt", 0) if isinstance(usage, dict) else 0
        is_stale = (last_ms == 0) or ((now_ms - last_ms) > THIRTY_DAYS_MS)
        if is_stale:
            long_unused.append(skill)
            rank = all_skills.get(skill_key, all_skills.get(skill, "N-C"))
            rarity = rank.split("-")[0] if "-" in rank else "N"
            if rarity in ("UR", "SR"):
                downgrade_candidates.append(f"{skill_key} [{rank}]")
except Exception:
    pass

# ---- 表示 ----

print(f"\n{'═' * 50}")
print(f"  📊 スキル使用統計レポート")
print(f"  生成: {now.strftime('%Y-%m-%d %H:%M')} UTC")
print(f"{'═' * 50}")

# TOP10 手動呼び出し
print(f"\n【手動呼び出し TOP10】")
if manual_counts:
    for skill, count in manual_counts.most_common(10):
        active_mark = "★" if skill in active_skills else "☆"
        rank = all_skills.get(skill, "?")
        last = last_used.get(skill, "")[:10]
        print(f"  {active_mark} {count:3d}回  [{rank:6s}]  {skill}  (最終: {last})")
else:
    print("  (ログなし)")

# TOP10 自動発火
print(f"\n【自動発火 TOP10】")
if autofire_counts:
    for skill, count in autofire_counts.most_common(10):
        active_mark = "★" if skill in active_skills else "☆"
        rank = all_skills.get(skill, "?")
        print(f"  {active_mark} {count:3d}回  [{rank:6s}]  {skill}")
else:
    print("  (ログなし)")

# 直近7日間
print(f"\n【直近7日間のアクティビティ】")
if recent_skills:
    for skill, count in recent_skills.most_common(5):
        print(f"  {count:3d}回  {skill}")
else:
    print("  (アクティビティなし)")

# ランク別集計
print(f"\n【ランク分布】")
total = len(all_skills)
for rarity in ["UR", "SR", "R", "N"]:
    for strength in ["S", "A", "B", "C"]:
        tag = f"{rarity}-{strength}"
        group = [s for s in rank_groups.get(tag, []) if s in active_skills]
        parked = [s for s in rank_groups.get(tag, []) if s not in active_skills]
        if group or parked:
            print(f"  [{tag:6s}]  アクティブ {len(group):3d}件  パーキング {len(parked):3d}件")

print(f"\n  合計: アクティブ {len(active_skills)}件 / 全{total}件")

# パーキング候補（使用実績ゼロ）
print(f"\n【パーキング候補】（アクティブだが使用実績ゼロ）")
if parking_candidates:
    for s in sorted(parking_candidates)[:15]:
        rank = all_skills.get(s, "?")
        print(f"  [{rank:6s}]  {s}")
    if len(parking_candidates) > 15:
        print(f"  ... 他 {len(parking_candidates) - 15}件")
else:
    print("  (なし)")

# 長期未使用パーキング候補（30日超）
print(f"\n【長期未使用パーキング候補】（30日超アクティブだが未使用）")
stale_candidates = [s for s in long_unused if s in all_skills or s.lstrip("_") in all_skills]
if stale_candidates:
    for s in stale_candidates[:15]:
        rank = all_skills.get(s.lstrip("_"), all_skills.get(s, "?"))
        print(f"  [{rank:6s}]  {s}")
    if len(stale_candidates) > 15:
        print(f"  ... 他 {len(stale_candidates) - 15}件")
    print(f"  → parking: rm ~/.claude/skills/<スキル名> でパーキング")
else:
    print("  (なし)")

# 高ランク降格候補
print(f"\n【高ランク降格候補】（SR/UR だが30日超未使用）")
if downgrade_candidates:
    for s in downgrade_candidates:
        print(f"  ⬇  {s}")
    print(f"  → 本当に必要か再確認してください")
else:
    print("  (なし)")

print(f"\n{'═' * 50}\n")
