#!/usr/bin/env python3
"""
スキルコンボ提案システム
CLAUDE.md のワークフロー定義と Cross-references を解析して、
各スキルの SKILL.md frontmatter に combos: フィールドを追加する。

コンボの3ソース:
  1. ワークフロー隣接: CLAUDE.md のワークフローテーブルで前後に来るスキル
  2. Cross-references 双方向: A→B かつ B→A ならコンボ
  3. 同一ワークフロー内: 同じフローに登場するスキル（最大3件）
"""

from __future__ import annotations

import re
import sys
import os
sys.path.insert(0, os.path.expanduser("~/.claude/hooks"))
from _skill_utils import SkillCache
from pathlib import Path
from collections import defaultdict

_cache = SkillCache()

CLAUDE_MD_PATH = Path.home() / ".claude/CLAUDE.md"
SKILLS_DIR = next(
    (p for p in [Path.home() / ".agents/skills", Path.home() / ".claude/skills"] if p.exists()),
    Path.home() / ".claude/skills",
)
MAX_COMBOS = 5


# ─────────────────────────────────────────────
# 1. スキル名正規化
# ─────────────────────────────────────────────

def normalize_skill_name(raw: str) -> str:
    """
    ワークフロー記述から実際のスキル名を取り出す。
    例: "skill-forge(Create)" → "skill-forge"
        "_mcp-builder"        → "mcp-builder"
        "pptx/docx"           → "pptx"  (スラッシュ区切りは最初だけ)
    """
    name = raw.strip()
    # カッコ付き引数を除去
    name = re.sub(r'\(.*?\)', '', name)
    # 先頭の _ を除去（ファイル名上は _ なしが正）
    name = name.lstrip('_')
    # スラッシュ区切りは最初のトークンだけ採用
    name = name.split('/')[0]
    return name.strip()


def skill_exists(name: str) -> bool:
    return (SKILLS_DIR / name / "SKILL.md").exists()


# ─────────────────────────────────────────────
# 2. CLAUDE.md からワークフローを抽出
# ─────────────────────────────────────────────

def parse_workflows(claude_md: Path) -> dict[str, list[str]]:
    """
    ワークフローテーブルを解析して {フロー名: [スキル名, ...]} を返す。
    テーブル行例: | **UI構築** | design-brief → style-reference-db → ... | 説明 |
    """
    workflows: dict[str, list[str]] = {}
    text = claude_md.read_text(encoding="utf-8")

    # スキルワークフロー（マルチスキル連携）セクション内のテーブル行を対象
    section_match = re.search(
        r'### スキルワークフロー.*?(?=\n##|\Z)',
        text,
        re.DOTALL
    )
    if not section_match:
        print("[WARN] スキルワークフローセクションが見つかりませんでした", file=sys.stderr)
        return workflows

    section = section_match.group(0)

    # テーブルの各データ行を処理
    for line in section.splitlines():
        # | **フロー名** | スキルチェーン | 説明 | のパターン
        m = re.match(r'\|\s*\*\*(.+?)\*\*\s*\|\s*(.+?)\s*\|\s*(.+?)\s*\|', line)
        if not m:
            continue
        flow_name = m.group(1).strip()
        chain_str = m.group(2).strip()

        # → で区切られたスキル名を抽出
        raw_skills = [s.strip() for s in chain_str.split('→')]
        skills = []
        for raw in raw_skills:
            norm = normalize_skill_name(raw)
            if norm:
                skills.append(norm)

        if skills:
            workflows[flow_name] = skills

    return workflows


# ─────────────────────────────────────────────
# 3. 各スキルの Cross-references を抽出
# ─────────────────────────────────────────────

def parse_cross_references(skills_dir: Path) -> dict[str, list[str]]:
    """
    {スキル名: [参照先スキル名, ...]} を返す。
    ## Cross-references セクション内の - **スキル名**: ... を解析。
    """
    refs: dict[str, list[str]] = {}

    for skill_dir in sorted(skills_dir.iterdir()):
        if not skill_dir.is_dir():
            continue
        skill_md = skill_dir / "SKILL.md"
        if not skill_md.exists():
            continue

        skill_name = skill_dir.name
        text = skill_md.read_text(encoding="utf-8")

        # Cross-references セクションを抽出
        cr_match = re.search(
            r'## Cross-references\s*\n(.*?)(?=\n## |\Z)',
            text,
            re.DOTALL
        )
        if not cr_match:
            refs[skill_name] = []
            continue

        cr_section = cr_match.group(1)
        # - **スキル名**: 説明 のパターン（_prefix あり/なしどちらも）
        found = re.findall(r'-\s+\*\*_?([\w\-]+)\*\*', cr_section)
        # 自分自身は除外
        found = [f for f in found if f != skill_name]
        refs[skill_name] = found

    return refs


# ─────────────────────────────────────────────
# 4. コンボスコアリング
# ─────────────────────────────────────────────

def build_combos(
    workflows: dict[str, list[str]],
    cross_refs: dict[str, list[str]],
    all_skills: set[str],
) -> dict[str, list[str]]:
    """
    各スキルのコンボ候補をスコアリングして上位 MAX_COMBOS 件を返す。
    スコア:
      - ワークフロー隣接（前後1つ）: +3
      - Cross-references 双方向:    +3
      - 同一ワークフロー内:          +1 (隣接を除く)
    """
    # スキルペアのスコアテーブル {skill: {other_skill: score}}
    scores: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))

    # ── Source 1 & 3: ワークフロー ──
    for flow_name, chain in workflows.items():
        # 存在するスキルのみに絞る
        valid_chain = [s for s in chain if s in all_skills]

        for i, skill in enumerate(valid_chain):
            for j, other in enumerate(valid_chain):
                if skill == other:
                    continue
                diff = abs(i - j)
                if diff == 1:
                    # 隣接
                    scores[skill][other] += 3
                else:
                    # 同一フロー内（隣接以外）最大3件まで
                    scores[skill][other] += 1

    # ── Source 2: Cross-references 双方向 ──
    for skill, refs in cross_refs.items():
        if skill not in all_skills:
            continue
        for ref in refs:
            if ref not in all_skills:
                continue
            # A→B
            scores[skill][ref] += 2
            # B→A が存在すれば追加ボーナス
            if skill in cross_refs.get(ref, []):
                scores[skill][ref] += 1
                scores[ref][skill] += 1

    # スコア降順で上位 MAX_COMBOS を選択
    result: dict[str, list[str]] = {}
    for skill in all_skills:
        if skill not in scores or not scores[skill]:
            result[skill] = []
            continue
        ranked = sorted(scores[skill].items(), key=lambda x: (-x[1], x[0]))
        result[skill] = [s for s, _ in ranked[:MAX_COMBOS]]

    return result


# ─────────────────────────────────────────────
# 5. SKILL.md の frontmatter を更新
# ─────────────────────────────────────────────

def update_skill_frontmatter(skill_name: str, combos: list[str]) -> bool:
    """
    SKILL.md の frontmatter に combos: を追加 or 更新する。
    rank: の直後に挿入。既存の combos: があれば置換。
    戻り値: 変更があれば True
    """
    skill_md = SKILLS_DIR / skill_name / "SKILL.md"
    original = skill_md.read_text(encoding="utf-8")

    # combos: の YAML 文字列を生成
    combos_yaml = "combos:\n" + "".join(f"  - {c}\n" for c in combos)

    # frontmatter ブロックを取り出す
    fm_match = re.match(r'^(---\n)(.*?)(---\n)', original, re.DOTALL)
    if not fm_match:
        print(f"  [SKIP] {skill_name}: frontmatter が見つかりません", file=sys.stderr)
        return False

    prefix = fm_match.group(1)   # "---\n"
    fm_body = fm_match.group(2)  # frontmatter 内容
    suffix = fm_match.group(3)   # "---\n"
    rest = original[fm_match.end():]

    # 既存の combos: ブロックを除去
    fm_body = re.sub(
        r'^combos:\n(?:  - .+\n)*',
        '',
        fm_body,
        flags=re.MULTILINE
    )

    # rank: 行の直後に combos: を挿入
    if re.search(r'^rank:', fm_body, re.MULTILINE):
        fm_body = re.sub(
            r'^(rank:.*\n)',
            r'\1' + combos_yaml,
            fm_body,
            count=1,
            flags=re.MULTILINE
        )
    else:
        # rank: がなければ先頭に追加
        fm_body = combos_yaml + fm_body

    new_content = prefix + fm_body + suffix + rest

    if new_content == original:
        return False

    skill_md.write_text(new_content, encoding="utf-8")
    return True


# ─────────────────────────────────────────────
# 6. メイン
# ─────────────────────────────────────────────

def main():
    print("=" * 60)
    print("スキルコンボ提案システム")
    print("=" * 60)

    # スキル一覧を収集
    all_skills: set[str] = set(_cache.skill_meta().keys())
    print(f"\n対象スキル数: {len(all_skills)}")

    # ワークフロー解析
    print("\n[1/4] CLAUDE.md のワークフローを解析中...")
    workflows = parse_workflows(CLAUDE_MD_PATH)
    print(f"  → {len(workflows)} フローを検出")
    for flow, chain in list(workflows.items())[:3]:
        print(f"     {flow}: {' → '.join(chain[:4])}{'...' if len(chain) > 4 else ''}")

    # Cross-references 解析
    print("\n[2/4] Cross-references を解析中...")
    cross_refs = parse_cross_references(SKILLS_DIR)
    skills_with_refs = sum(1 for v in cross_refs.values() if v)
    print(f"  → {skills_with_refs} スキルが Cross-references を持つ")

    # コンボ生成
    print("\n[3/4] コンボをスコアリング中...")
    combos_map = build_combos(workflows, cross_refs, all_skills)
    skills_with_combos = sum(1 for v in combos_map.values() if v)
    print(f"  → {skills_with_combos} スキルにコンボ候補あり")

    # SKILL.md に書き込み
    print("\n[4/4] SKILL.md を更新中...")
    updated_count = 0
    skipped_count = 0
    for skill_name in sorted(all_skills):
        combos = combos_map.get(skill_name, [])
        if not combos:
            skipped_count += 1
            continue
        changed = update_skill_frontmatter(skill_name, combos)
        if changed:
            updated_count += 1

    print(f"\n  更新: {updated_count} スキル")
    print(f"  スキップ（コンボなし）: {skipped_count} スキル")

    # ─── 結果サマリー ───
    print("\n" + "=" * 60)
    print("結果サマリー")
    print("=" * 60)
    print(f"\ncombos が追加されたスキル数: {updated_count} 件\n")

    # コンボ数トップ5
    top5 = sorted(
        [(s, len(c)) for s, c in combos_map.items() if c],
        key=lambda x: -x[1]
    )[:5]
    print("コンボ数が多いトップ5スキル:")
    for rank, (skill, count) in enumerate(top5, 1):
        combos_list = ", ".join(combos_map[skill])
        print(f"  {rank}. {skill} ({count}件): {combos_list}")

    print("\n完了!")


if __name__ == "__main__":
    main()
