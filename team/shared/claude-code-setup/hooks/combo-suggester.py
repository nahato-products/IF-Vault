#!/usr/bin/env python3
"""
combo-suggester.py — PostToolUse hook (matcher: Skill)
スキルが使用された直後に、combos: フィールドから関連スキルを提案する

セッション内で同じスキルのコンボは1回のみ表示（session dedup）
"""
import sys, json, re, os
from pathlib import Path
from typing import Optional, List, Set

sys.path.insert(0, os.path.expanduser("~/.claude/hooks"))
from _skill_utils import SkillCache
_cache = SkillCache()

AGENTS_DIR = Path.home() / ".agents" / "skills"
SKILLS_DIR = Path.home() / ".claude" / "skills"
SESSION_STATE = Path.home() / ".claude/session-env/combo-shown.json"

MAX_COMBOS = 4  # 表示する最大コンボ数


def load_shown() -> Set[str]:
    """このセッションで既に表示済みのスキル名セットを読み込む"""
    try:
        return set(json.loads(SESSION_STATE.read_text()))
    except Exception:
        return set()


def save_shown(shown: Set[str]) -> None:
    """表示済みセットをファイルに保存"""
    try:
        SESSION_STATE.parent.mkdir(parents=True, exist_ok=True)
        SESSION_STATE.write_text(json.dumps(sorted(shown), ensure_ascii=False))
    except Exception:
        pass


def find_skill_md(skill_name: str) -> Optional[Path]:
    """スキル名から SKILL.md のパスを解決。コロン記法にも対応。"""
    normalized = skill_name.replace(":", "-")
    candidates = [skill_name, normalized]
    for name in list(candidates):
        if name.startswith("_"):
            candidates.append(name[1:])
        else:
            candidates.append(f"_{name}")

    for base_dir in [AGENTS_DIR, SKILLS_DIR]:
        for candidate in candidates:
            p = base_dir / candidate / "SKILL.md"
            if p.exists():
                return p
    return None


def parse_combos(skill_md: Path) -> List[str]:
    """YAML frontmatter の combos: フィールドをパース"""
    try:
        content = skill_md.read_text()
    except Exception:
        return []

    m = re.search(r'^combos:\s*\n((?:[ \t]+-[ \t]+\S.*\n?)+)', content, re.M)
    if not m:
        return []

    combos = []
    for line in m.group(1).strip().split('\n'):
        item = re.sub(r'^[ \t]*-[ \t]+', '', line).strip()
        if item:
            combos.append(item)
    return combos


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    if data.get("tool_name") != "Skill":
        sys.exit(0)

    skill_name = (data.get("tool_input") or {}).get("skill", "").strip()
    if not skill_name:
        sys.exit(0)

    # セッション内 dedup: 既に表示済みならスキップ
    shown = load_shown()
    if skill_name in shown:
        sys.exit(0)

    skill_md = find_skill_md(skill_name)
    if not skill_md:
        sys.exit(0)

    combos = parse_combos(skill_md)
    if not combos:
        sys.exit(0)

    # アクティブスキルセット（共有キャッシュから取得）
    active: Set[str] = _cache.active_skills()

    lines = []
    for combo in combos[:MAX_COMBOS]:
        is_active = combo in active or combo.lstrip("_") in active
        status = "" if is_active else "  ⏸️"
        lines.append(f"    {combo}{status}")

    if lines:
        print(f"\n💡 {skill_name} のコンボ候補:")
        print('\n'.join(lines))

    # 表示済みとして記録
    shown.add(skill_name)
    save_shown(shown)


if __name__ == "__main__":
    main()
