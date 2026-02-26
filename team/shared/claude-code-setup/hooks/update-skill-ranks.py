#!/usr/bin/env python3
"""
動的ランクアップシステム
~/.claude.json の skillUsage を読んで、使用頻度が高いスキルの強さランクを自動更新する

ランクアップ仕様:
  0-4回  → 現状維持
  5-9回  → B以上に昇格
  10-19回 → A以上に昇格
  20回以上 → S昇格
"""

import json
import os
import re
import sys

# 共有キャッシュ（ランク変更後に無効化）
sys.path.insert(0, os.path.expanduser("~/.claude/hooks"))
from _skill_utils import SkillCache  # noqa: E402

CLAUDE_JSON_PATH = os.path.expanduser("~/.claude.json")
SKILLS_DIR = os.path.expanduser("~/.agents/skills")

RANK_ORDER = ["C", "B", "A", "S"]

def get_min_rank_for_count(count):
    """使用回数から最小強さランクを返す"""
    if count >= 20:
        return "S"
    elif count >= 10:
        return "A"
    elif count >= 5:
        return "B"
    else:
        return None  # 現状維持

def upgrade_rank(current_rank, min_rank):
    """
    current_rank: 'N-C' 形式
    min_rank: 'B' 等の強さ部分
    return: 変更後のrank文字列 or None(変更なし)
    """
    parts = current_rank.split("-")
    if len(parts) != 2:
        return None

    rarity = parts[0]
    strength = parts[1]

    if strength not in RANK_ORDER or min_rank not in RANK_ORDER:
        return None

    current_idx = RANK_ORDER.index(strength)
    min_idx = RANK_ORDER.index(min_rank)

    if min_idx > current_idx:
        new_rank = rarity + "-" + min_rank
        return new_rank
    return None

def update_skill_md(skill_name, new_rank):
    """SKILL.md の rank フィールドを更新する"""
    skill_md_path = os.path.join(SKILLS_DIR, skill_name, "SKILL.md")
    if not os.path.exists(skill_md_path):
        return False, "SKILL.md not found"

    try:
        with open(skill_md_path, "r", encoding="utf-8") as f:
            content = f.read()

        # frontmatter内の rank: を更新（行単位で正確に置換）
        pattern = r"^(rank:\s*)(\S+)(.*)$"
        new_content = re.sub(
            pattern,
            lambda m: m.group(1) + new_rank + m.group(3),
            content,
            count=1,
            flags=re.MULTILINE
        )

        if new_content == content:
            return False, "rank field not found or already up-to-date"

        with open(skill_md_path, "w", encoding="utf-8") as f:
            f.write(new_content)

        return True, "updated"
    except PermissionError:
        return False, "permission denied"
    except Exception as e:
        return False, str(e)

def main():
    # 1. ~/.claude.json から skillUsage を読み込む
    if not os.path.exists(CLAUDE_JSON_PATH):
        print("[update-skill-ranks] ERROR: ~/.claude.json not found")
        sys.exit(0)

    try:
        with open(CLAUDE_JSON_PATH, "r", encoding="utf-8") as f:
            claude_data = json.load(f)
    except Exception as e:
        print("[update-skill-ranks] ERROR: failed to read ~/.claude.json:", e)
        sys.exit(0)

    skill_usage = claude_data.get("skillUsage", {})
    if not skill_usage:
        print("[update-skill-ranks] INFO: skillUsage is empty, nothing to do")
        sys.exit(0)

    upgraded = []
    skipped = []
    errors = []

    for skill_name, usage_data in skill_usage.items():
        # usageCount を取得
        if isinstance(usage_data, dict):
            count = usage_data.get("usageCount", 0)
        elif isinstance(usage_data, int):
            count = usage_data
        else:
            errors.append(skill_name + ": unknown usageData format")
            continue

        # 昇格判定
        min_rank = get_min_rank_for_count(count)
        if min_rank is None:
            skipped.append(skill_name + " (count=" + str(count) + ", 条件未達)")
            continue

        # SKILL.md から現在の rank を読む
        skill_md_path = os.path.join(SKILLS_DIR, skill_name, "SKILL.md")
        if not os.path.exists(skill_md_path):
            skipped.append(skill_name + " (SKILL.md not found)")
            continue

        try:
            with open(skill_md_path, "r", encoding="utf-8") as f:
                content = f.read()
        except Exception as e:
            errors.append(skill_name + ": read error: " + str(e))
            continue

        rank_match = re.search(r"^rank:\s*(\S+)", content, re.MULTILINE)
        if not rank_match:
            skipped.append(skill_name + " (rank field missing)")
            continue

        current_rank = rank_match.group(1)
        new_rank = upgrade_rank(current_rank, min_rank)

        if new_rank is None:
            skipped.append(skill_name + " (count=" + str(count) + ", " + current_rank + " → 変更不要)")
            continue

        # 書き込み
        success, msg = update_skill_md(skill_name, new_rank)
        if success:
            upgraded.append(skill_name + ": " + current_rank + " → " + new_rank + " (count=" + str(count) + ")")
        else:
            errors.append(skill_name + ": " + msg + " (count=" + str(count) + ", wanted " + new_rank + ")")

    # 4. 変更サマリー出力
    print("=" * 50)
    print("[update-skill-ranks] ランクアップサマリー")
    print("=" * 50)

    if upgraded:
        print("\n昇格したスキル (" + str(len(upgraded)) + "件):")
        for item in upgraded:
            print("  ✅ " + item)
        # ランク変更があったのでキャッシュを無効化
        SkillCache().invalidate()
    else:
        print("\n昇格なし")

    if skipped:
        print("\nスキップ (" + str(len(skipped)) + "件):")
        for item in skipped:
            print("  - " + item)

    if errors:
        print("\nエラー (" + str(len(errors)) + "件):")
        for item in errors:
            print("  ⚠ " + item)

    print("=" * 50)

if __name__ == "__main__":
    main()
