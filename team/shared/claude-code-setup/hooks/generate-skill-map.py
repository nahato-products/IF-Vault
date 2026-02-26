#!/usr/bin/env python3
"""
generate-skill-map.py
~/.agents/skills/ 以下の全スキルのCross-referencesを解析し、
スキル間の関係図をMermaid形式で生成するスクリプト。
"""

import os
import re
import sys
from datetime import date
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple


# ===== 設定 =====
AGENTS_SKILLS_DIR = Path.home() / ".agents" / "skills"
CLAUDE_SKILLS_DIR = Path.home() / ".claude" / "skills"
OUTPUT_DIR = Path.home() / ".claude" / "tmp"


# ===== ランク設定 =====
RANK_ORDER = {"UR": 0, "SR": 1, "R": 2, "N": 3}

RANK_STYLES = {
    "UR": "fill:#FFD700,color:#000",
    "SR": "fill:#C0C0C0,color:#000",
    "R":  "fill:#CD7F32,color:#fff",
    "N":  None,  # デフォルト
}


# ===== ユーティリティ =====

def parse_rank(rank_str: str) -> str:
    """'UR-A' -> 'UR', 'SR-B' -> 'SR' などティアを取得"""
    if not rank_str:
        return "N"
    tier = rank_str.split("-")[0].upper()
    return tier if tier in RANK_ORDER else "N"


def get_active_skill_names() -> Set[str]:
    """
    ~/.claude/skills/ にあるスキル名のセットを返す。
    SkillCache 経由でキャッシュを活用する。
    """
    import sys as _sys, os as _os
    _sys.path.insert(0, _os.path.expanduser("~/.claude/hooks"))
    from _skill_utils import SkillCache
    return SkillCache().active_skills()


def parse_skill(skill_dir: Path) -> Optional[Dict]:
    """
    SKILL.md を解析してスキル情報を返す。
    返り値: {
        'id': str,       # ディレクトリ名（ノードID用）
        'name': str,     # frontmatter の name
        'rank': str,     # 'UR' | 'SR' | 'R' | 'N'
        'rank_raw': str, # 元のrankフィールド値
        'refs': List[str],  # Cross-referencesで参照されるスキル名
    }
    """
    skill_md = skill_dir / "SKILL.md"
    if not skill_md.exists():
        return None

    content = skill_md.read_text(encoding="utf-8", errors="ignore")
    lines = content.splitlines()

    # === frontmatter 解析 ===
    name = skill_dir.name
    rank_raw = ""

    in_frontmatter = False
    frontmatter_end = 0
    for i, line in enumerate(lines):
        if i == 0 and line.strip() == "---":
            in_frontmatter = True
            continue
        if in_frontmatter:
            if line.strip() == "---":
                frontmatter_end = i
                break
            m = re.match(r"^name:\s+(.+)$", line.strip())
            if m:
                name = m.group(1).strip().strip('"\'')
            m = re.match(r"^rank:\s+(.+)$", line.strip())
            if m:
                rank_raw = m.group(1).strip()

    rank = parse_rank(rank_raw)

    # === Cross-references セクション解析 ===
    # セクションヘッダーパターン（大文字小文字・[タグ]を考慮）
    crossref_header_re = re.compile(
        r"^#{1,3}\s+Cross-[Rr]eferences?(\s+\[.*?\])?$"
    )
    next_section_re = re.compile(r"^#{1,3}\s+")

    refs = []
    in_crossref = False
    for line in lines[frontmatter_end:]:
        if crossref_header_re.match(line.strip()):
            in_crossref = True
            continue
        if in_crossref:
            # 次のセクションに入ったら終了
            if next_section_re.match(line) and not crossref_header_re.match(line.strip()):
                in_crossref = False
                continue
            # - **skill-name**: description 形式
            m = re.match(r"^\s*-\s+\*\*([^*]+)\*\*", line)
            if m:
                ref_raw = m.group(1).strip()
                # _prefix と スペースを除去
                ref_clean = ref_raw.lstrip("_").strip()
                # スキル名らしい文字列のみ（英数字・ハイフン・コロン）
                if re.match(r"^[\w\-:]+$", ref_clean):
                    refs.append(ref_clean)

    return {
        "id": skill_dir.name,
        "name": name,
        "rank": rank,
        "rank_raw": rank_raw,
        "refs": refs,
    }


def sanitize_node_id(skill_id: str) -> str:
    """Mermaid ノードIDとして使える文字列に変換"""
    return re.sub(r"[^a-zA-Z0-9_]", "_", skill_id)


def build_mermaid(
    skills: Dict[str, Dict],
    active_skill_names: Set[str],
    ur_sr_only: bool = False,
) -> str:
    """
    Mermaid graph LR を生成する。
    ur_sr_only=True の場合はUR/SRスキルのみ。
    """
    lines = ["graph LR"]

    # フィルタリング
    if ur_sr_only:
        target_ids = {
            sid for sid, s in skills.items()
            if s["rank"] in ("UR", "SR")
        }
    else:
        target_ids = set(skills.keys())

    if not target_ids:
        lines.append("    %% No skills to display")
        return "\n".join(lines)

    # ノード定義
    for sid in sorted(target_ids):
        skill = skills[sid]
        node_id = sanitize_node_id(sid)
        label = skill["name"]
        rank = skill["rank"]

        is_active = sid in active_skill_names

        if is_active:
            # 太枠: [[label]] 形式
            lines.append(f'    {node_id}[["{label}"]]')
        else:
            lines.append(f'    {node_id}["{label}"]')

    lines.append("")

    # エッジ定義
    edge_count = 0
    for sid in sorted(target_ids):
        skill = skills[sid]
        src_id = sanitize_node_id(sid)

        for ref in skill["refs"]:
            # ターゲットスキルが存在するか確認
            if ref in skills and ref in target_ids:
                dst_id = sanitize_node_id(ref)
                lines.append(f"    {src_id} --> {dst_id}")
                edge_count += 1

    lines.append("")

    # スタイル定義
    for sid in sorted(target_ids):
        skill = skills[sid]
        rank = skill["rank"]
        node_id = sanitize_node_id(sid)

        style_parts = []
        rank_style = RANK_STYLES.get(rank)
        if rank_style:
            style_parts.append(rank_style)

        is_active = sid in active_skill_names
        if is_active:
            style_parts.append("stroke-width:3px")
        else:
            style_parts.append("stroke-width:1px")

        if style_parts:
            lines.append(f"    style {node_id} {','.join(style_parts)}")

    return "\n".join(lines)


def compute_stats(
    skills: Dict[str, Dict],
    active_skill_names: Set[str],
) -> Dict:
    """統計情報を計算"""
    rank_counts = {"UR": 0, "SR": 0, "R": 0, "N": 0}
    for s in skills.values():
        rank = s["rank"]
        rank_counts[rank] = rank_counts.get(rank, 0) + 1

    # 参照カウント（被参照数）
    ref_count: Dict[str, int] = {}
    for s in skills.values():
        for ref in s["refs"]:
            ref_count[ref] = ref_count.get(ref, 0) + 1

    top5 = sorted(ref_count.items(), key=lambda x: -x[1])[:5]

    return {
        "total": len(skills),
        "active": len(active_skill_names & set(skills.keys())),
        "rank_counts": rank_counts,
        "top5": top5,
        "total_edges": sum(len(s["refs"]) for s in skills.values()),
    }


def main():
    today = date.today().strftime("%Y%m%d")
    today_display = date.today().strftime("%Y-%m-%d")
    output_path = OUTPUT_DIR / f"skill-map-{today}.md"

    # tmpディレクトリを作成
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    print(f"スキルディレクトリを読み込み中: {AGENTS_SKILLS_DIR}")

    if not AGENTS_SKILLS_DIR.exists():
        print(f"ERROR: {AGENTS_SKILLS_DIR} が存在しません", file=sys.stderr)
        sys.exit(1)

    # 全スキルを解析
    skills: Dict[str, Dict] = {}
    for skill_dir in sorted(AGENTS_SKILLS_DIR.iterdir()):
        if not skill_dir.is_dir():
            continue
        parsed = parse_skill(skill_dir)
        if parsed:
            skills[skill_dir.name] = parsed

    print(f"スキル数: {len(skills)}")

    # アクティブスキル名セット
    active_skill_names = get_active_skill_names()
    print(f"アクティブスキル数: {len(active_skill_names & set(skills.keys()))}")

    # 統計
    stats = compute_stats(skills, active_skill_names)

    # Mermaid生成
    mermaid_summary = build_mermaid(skills, active_skill_names, ur_sr_only=True)
    mermaid_full = build_mermaid(skills, active_skill_names, ur_sr_only=False)

    # 出力構築
    rank_counts = stats["rank_counts"]
    top5_str = "\n".join(
        f"  {i+1}. `{name}`: {count}回参照"
        for i, (name, count) in enumerate(stats["top5"])
    ) or "  (参照なし)"

    output_lines = [
        f"# Skill Map - {today_display}",
        "",
        "## UR/SR 関係図（要約）",
        "",
        "> 凡例: 金枠=UR / 銀枠=SR / 太枠=アクティブ（~/.claude/skills/に登録済み）",
        "",
        "```mermaid",
        mermaid_summary,
        "```",
        "",
        "---",
        "",
        "## 全スキル関係図",
        "",
        "> 金=UR / 銀=SR / 銅=R / 白=N / 太枠=アクティブ",
        "",
        "```mermaid",
        mermaid_full,
        "```",
        "",
        "---",
        "",
        "## 統計",
        "",
        f"- **総スキル数**: {stats['total']}",
        f"- **アクティブスキル数**: {stats['active']}（~/.claude/skills/ 登録済み）",
        f"- **UR**: {rank_counts.get('UR', 0)} / **SR**: {rank_counts.get('SR', 0)} / **R**: {rank_counts.get('R', 0)} / **N**: {rank_counts.get('N', 0)}",
        f"- **総エッジ数（Cross-references）**: {stats['total_edges']}",
        "",
        "### 最も参照されるスキル Top5",
        "",
        top5_str,
        "",
        "---",
        "",
        f"_生成日時: {today_display} | スクリプト: ~/.claude/hooks/generate-skill-map.py_",
    ]

    output_content = "\n".join(output_lines)
    output_path.write_text(output_content, encoding="utf-8")

    print(f"\n出力完了: {output_path}")
    print(f"\n--- 統計サマリ ---")
    print(f"総スキル数: {stats['total']}")
    print(f"アクティブ: {stats['active']}")
    print(f"UR: {rank_counts.get('UR', 0)} / SR: {rank_counts.get('SR', 0)} / R: {rank_counts.get('R', 0)} / N: {rank_counts.get('N', 0)}")
    print(f"総エッジ数: {stats['total_edges']}")
    print(f"\nTop5 被参照スキル:")
    for i, (name, count) in enumerate(stats["top5"]):
        print(f"  {i+1}. {name}: {count}回")

    return str(output_path)


if __name__ == "__main__":
    main()
