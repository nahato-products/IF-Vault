#\!/usr/bin/env python3
"""
workflow-audit.py — CLAUDE.md ワークフロー整合性チェック

スキルワークフローテーブルを解析し、存在しないスキル参照を検出する。
CLAUDE.md が更新されたときのみ詳細チェックを実行（SessionStart での負荷最小化）。

使用方法:
  python3 workflow-audit.py            # SessionStart モード（差分チェック）
  python3 workflow-audit.py --full     # フルレポート（ops:health 用）
"""
from __future__ import annotations

import hashlib
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Tuple

CLAUDE_MD    = Path.home() / ".claude/CLAUDE.md"
AGENTS_DIR   = Path.home() / ".agents/skills"
SKILLS_DIR   = Path.home() / ".claude/skills"
STATE_FILE   = Path.home() / ".claude/session-env/workflow-audit-state.json"
ISSUES_FILE  = Path.home() / ".claude/session-env/workflow-issues.md"

# ──────────────────────────────────────
# スキル名正規化
# ──────────────────────────────────────

def normalize_skill_name(raw: str) -> str:
    """
    ワークフロー記述から ~/.agents/skills/ のディレクトリ名を取り出す。
    例: "skill-forge(Create)" -> "skill-forge"
        "_mcp-builder"        -> "mcp-builder"
        "pptx/docx"           -> "pptx"
    """
    name = re.sub(r"\(.*?\)", "", raw).strip()
    name = name.lstrip("_")
    name = name.split("/")[0].strip()
    return name

# MCP や非スキル参照はスキップ
_NON_SKILL_REFS = {"token-guardian", "style-reference-db", "design-brief", "duckdb-csv"}

# ──────────────────────────────────────
# CLAUDE.md 解析
# ──────────────────────────────────────

def parse_workflows(claude_md: Path) -> Dict[str, List[str]]:
    """ワークフローテーブルから {フロー名: [スキル名, ...]} を返す"""
    text = claude_md.read_text()
    section = re.search(r"### スキルワークフロー.*?(?=\n##|\Z)", text, re.DOTALL)
    if not section:
        return {}

    workflows: Dict[str, List[str]] = {}
    for line in section.group(0).splitlines():
        m = re.match(r"\|\s*\*\*(.+?)\*\*\s*\|\s*(.+?)\s*\|\s*.+\|", line)
        if not m:
            continue
        flow_name = m.group(1).strip()
        chain = [
            normalize_skill_name(s)
            for s in m.group(2).split("\u2192")  # →
        ]
        skills = [s for s in chain if s and s not in _NON_SKILL_REFS]
        if skills:
            workflows[flow_name] = skills
    return workflows

# ──────────────────────────────────────
# スキル一覧
# ──────────────────────────────────────

def get_all_skill_names() -> set:
    """~/.agents/skills/ + ~/.claude/skills/ の両方を走査（直接配置スキルも拾う）"""
    import sys as _sys, os as _os
    _sys.path.insert(0, _os.path.expanduser("~/.claude/hooks"))
    from _skill_utils import SkillCache
    return set(SkillCache().skill_meta().keys()) | SkillCache().active_skills()

def get_active_skill_names() -> set:
    import sys as _sys, os as _os
    _sys.path.insert(0, _os.path.expanduser("~/.claude/hooks"))
    from _skill_utils import SkillCache
    return SkillCache().active_skills()

# ──────────────────────────────────────
# 状態管理
# ──────────────────────────────────────

def md5_hash(path: Path) -> str:
    return hashlib.md5(path.read_bytes()).hexdigest()

def load_state() -> dict:
    try:
        return json.loads(STATE_FILE.read_text())
    except Exception:
        return {}

def save_state(state: dict) -> None:
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    STATE_FILE.write_text(json.dumps(state, ensure_ascii=False, indent=2))

# ──────────────────────────────────────
# 監査ロジック
# ──────────────────────────────────────

def run_audit(
    workflows: Dict[str, List[str]],
    all_skills: set,
) -> Tuple[List[str], set]:
    """
    Returns:
        broken_refs: 存在しないスキル参照 ["{フロー}: {スキル}", ...]
        wf_skills:   ワークフロー内の全スキル名 set
    """
    broken_refs: List[str] = []
    wf_skills: set = set()

    for flow_name, chain in workflows.items():
        for skill in chain:
            wf_skills.add(skill)
            if skill not in all_skills:
                broken_refs.append(f"{flow_name}: {skill}")

    return broken_refs, wf_skills

# ──────────────────────────────────────
# 出力
# ──────────────────────────────────────

def write_issues_file(broken_refs: List[str]) -> None:
    """session-start-context.sh が additionalContext に注入するファイルに書く"""
    if not broken_refs:
        ISSUES_FILE.unlink(missing_ok=True)
        return
    lines = [
        "## ⚠️  ワークフロー整合性の問題",
        f"{len(broken_refs)} 件の壊れたスキル参照を検出しました。`/ops:health` で詳細確認を。",
    ]
    for ref in broken_refs[:5]:
        lines.append(f"- ❌ {ref}")
    if len(broken_refs) > 5:
        lines.append(f"- ... 他 {len(broken_refs) - 5} 件")
    ISSUES_FILE.parent.mkdir(parents=True, exist_ok=True)
    ISSUES_FILE.write_text("\n".join(lines) + "\n")

def print_full_report(
    workflows: Dict[str, List[str]],
    broken_refs: List[str],
    all_skills: set,
    active_skills: set,
) -> None:
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    W = 52
    print(f"\n{'═' * W}")
    print(f"  \U0001f5fa  ワークフロー整合性レポート")
    print(f"  生成: {now}")
    print(f"{'═' * W}")

    # 壊れたチェーン
    total_refs = sum(len(c) for c in workflows.values())
    print(f"\n【壊れたワークフローチェーン】")
    if broken_refs:
        for ref in broken_refs:
            print(f"  \u274c {ref}")
        print(f"\n  \u2192 CLAUDE.md のワークフローを修正してください")
    else:
        print(f"  \u2705 全 {len(workflows)} フロー \u00d7 {total_refs} スキル参照 — 問題なし")

    # ワークフロー未登録のアクティブスキル
    wf_skills = {s for chain in workflows.values() for s in chain}
    unlisted = sorted(active_skills - wf_skills)
    print(f"\n【ワークフロー未掲載のアクティブスキル】")
    if unlisted:
        print(f"  以下 {len(unlisted)} 件はアクティブだがワークフローに未登録:")
        for s in unlisted[:10]:
            print(f"  \U0001f535 {s}")
        if len(unlisted) > 10:
            print(f"  ... 他 {len(unlisted) - 10} 件")
    else:
        print("  (全アクティブスキルがワークフローに登場)")

    print(f"\n{'═' * W}\n")

# ──────────────────────────────────────
# メイン
# ──────────────────────────────────────

def main() -> None:
    full_mode = "--full" in sys.argv

    if not CLAUDE_MD.exists():
        if full_mode:
            print(f"ERROR: {CLAUDE_MD} が見つかりません")
        sys.exit(0)

    current_hash = md5_hash(CLAUDE_MD)
    state = load_state()

    # SessionStart: ハッシュ変化なければスキップ
    if not full_mode and state.get("claude_md_hash") == current_hash:
        ISSUES_FILE.unlink(missing_ok=True)
        sys.exit(0)

    all_skills    = get_all_skill_names()
    active_skills = get_active_skill_names()
    workflows     = parse_workflows(CLAUDE_MD)
    broken_refs, _ = run_audit(workflows, all_skills)

    # 状態を保存
    save_state({
        "claude_md_hash": current_hash,
        "last_run": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "broken_count": len(broken_refs),
    })

    if full_mode:
        print_full_report(workflows, broken_refs, all_skills, active_skills)
    else:
        # SessionStart: issues ファイルに書いて session-start-context.sh に委譲
        write_issues_file(broken_refs)
        if broken_refs:
            print(f"\u26a0\ufe0f  CLAUDE.md ワークフロー: {len(broken_refs)} 件の壊れた参照 (/ops:health で確認)")


if __name__ == "__main__":
    main()
