#!/usr/bin/env python3
"""
env-orchestrator.py — 環境自動判定エンジン

「何を自動実行するか」の判定ロジック自体を自動化する。
classify_actions() の RISK_RULES がポリシーの核心。

  LOW   → 即時自動実行（サイレント）
  MEDIUM → pending-decisions.md にコマンド付きで追記
  HIGH  → pending-decisions.md に警告付きで追記

Usage:
  python3 env-orchestrator.py         # SessionStart モード
  python3 env-orchestrator.py --full  # 詳細出力（/ops:health 用）
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Literal, NamedTuple

# 共有キャッシュモジュールをフックディレクトリから読み込む
_HOOKS_DIR = Path.home() / ".claude/hooks"
if str(_HOOKS_DIR) not in sys.path:
    sys.path.insert(0, str(_HOOKS_DIR))
from _skill_utils import SkillCache  # noqa: E402

HOME        = Path.home()
CLAUDE_JSON = HOME / ".claude.json"
AGENTS_DIR  = HOME / ".agents/skills"
SKILLS_DIR  = HOME / ".claude/skills"
HOOKS_DIR   = _HOOKS_DIR
SESSION_ENV = HOME / ".claude/session-env"
PENDING_FILE = SESSION_ENV / "pending-decisions.md"
STATE_FILE  = SESSION_ENV / "orchestrator-state.json"

THIRTY_DAYS_MS = 30 * 24 * 60 * 60 * 1000

RiskLevel = Literal["LOW", "MEDIUM", "HIGH"]


class Action(NamedTuple):
    title: str
    risk: RiskLevel
    detail: str
    command: str | None = None


# ──────────────────────────────────────────────
# シグナル収集
# ──────────────────────────────────────────────

def get_active_skills() -> set[str]:
    # キャッシュから取得（~/.agents/skills/ の全走査をスキップ）
    return _cache.active_skills()


def get_undefined_combos(active: set[str]) -> list[str]:
    """combos: が未定義のアクティブスキル（~/.agents/skills/ に SKILL.md があるもののみ対象）

    generate-skill-combos.py は ~/.agents/skills/ のファイルを更新するため、
    ~/.claude/skills/ 直置きスキルは対象外（自動修正不可）。
    """
    meta = _cache.skill_meta()
    return [
        name for name in active
        if meta.get(name.lstrip("_"), {}).get("has_combos") is False
    ]


def get_skill_usage() -> dict:
    try:
        return json.loads(CLAUDE_JSON.read_text()).get("skillUsage", {})
    except Exception:
        return {}


def get_skill_rank(skill_key: str) -> str:
    return _cache.skill_meta().get(skill_key, {}).get("rank", "N-C")


def get_stale_skills(active: set[str], usage: dict) -> list[tuple[str, str, str]]:
    """(name, rank, last_used) — 30日超未使用のアクティブスキル"""
    now_ms = datetime.now(timezone.utc).timestamp() * 1000
    result = []
    seen: set[str] = set()
    for name in sorted(active):
        key = name.lstrip("_")
        if key in seen:
            continue
        seen.add(key)
        u = usage.get(key, {})
        last_ms = u.get("lastUsedAt", 0) if isinstance(u, dict) else 0
        if last_ms == 0 or (now_ms - last_ms) > THIRTY_DAYS_MS:
            last_str = (
                datetime.fromtimestamp(last_ms / 1000, tz=timezone.utc).strftime("%Y-%m-%d")
                if last_ms > 0 else "未使用"
            )
            result.append((name, get_skill_rank(key), last_str))
    return result


# キャッシュインスタンス（モジュールレベルで 1 回だけ構築）
_cache = SkillCache()

# ──────────────────────────────────────────────
# 判定エンジン（ここがポリシー as コードの核心）
#
# RISK_RULES = [
#   (シグナル, リスクレベル, 判定根拠)
# ]
# LOW   = 安全: 副作用なし or 完全可逆
# MEDIUM = 注意: ファイル削除等、人が確認すべき
# HIGH  = 重要: ランク変更等、設計判断を伴う
# ──────────────────────────────────────────────

def classify_actions(
    undefined_combos: list[str],
    stale_skills: list[tuple[str, str, str]],
    full_mode: bool = False,
) -> tuple[list[str], list[Action]]:
    """
    シグナルを受け取り、リスクルールに従って振り分ける。
    Returns:
        auto_items : 自動実行した内容の説明リスト
        review_items: レビューキューに積む Action リスト
    """
    auto_items: list[str] = []
    review_items: list[Action] = []

    # ── LOW: combos 未定義 → 自動生成 ──────────────────
    # 根拠: 既存 SKILL.md への追記のみ、完全可逆（combos は suggestion に過ぎない）
    if undefined_combos:
        combos_script = HOOKS_DIR / "generate-skill-combos.py"
        if combos_script.exists():
            result = subprocess.run(
                ["python3", str(combos_script)],
                capture_output=True, text=True, timeout=30,
            )
            if result.returncode == 0:
                auto_items.append(f"combos 自動生成 ({len(undefined_combos)}件)")

    # ── MEDIUM: N ランク + 30日超未使用 → パーキング候補 ──
    # 根拠: N ランクはデフォルト / 低優先度。30日未使用は明確な不活性サイン。
    # ただし削除は人が確認すべきなのでキューへ。
    parking_candidates = [
        (name, rank, last)
        for name, rank, last in stale_skills
        if rank.split("-")[0] == "N"
    ]
    for name, rank, last in parking_candidates[:8]:
        review_items.append(Action(
            title=f"パーキング候補: `{name}` [{rank}]",
            risk="MEDIUM",
            detail=f"最終使用: {last} (30日超未使用 / Nランク)",
            command=f"rm ~/.claude/skills/{name}",
        ))

    # ── HIGH: SR/UR + 30日超未使用 → 降格候補 ──────────
    # 根拠: 高ランクスキルをパーキングするのは設計判断。人が確認すべき。
    downgrade_candidates = [
        (name, rank, last)
        for name, rank, last in stale_skills
        if rank.split("-")[0] in ("SR", "UR")
    ]
    for name, rank, last in downgrade_candidates[:5]:
        parts = rank.split("-")
        rarity, strength = (parts[0], parts[1]) if len(parts) == 2 else (rank, "C")
        next_rarity = {"UR": "SR", "SR": "R"}.get(rarity, rarity)
        next_rank = f"{next_rarity}-{strength}"
        review_items.append(Action(
            title=f"降格候補: `{name}` [{rank} → {next_rank}]",
            risk="HIGH",
            detail=f"最終使用: {last} (高ランクスキルが30日超未使用)",
            command=(
                f"# SKILL.md の rank を変更:\n"
                f"# {rank} → {next_rank}\n"
                f"vi ~/.agents/skills/{name}/SKILL.md"
            ),
        ))

    return auto_items, review_items


# ──────────────────────────────────────────────
# 状態管理（連続実行での重複通知を抑制）
# ──────────────────────────────────────────────

def load_state() -> dict:
    try:
        return json.loads(STATE_FILE.read_text())
    except Exception:
        return {}


def save_state(review_items: list[Action]) -> None:
    SESSION_ENV.mkdir(parents=True, exist_ok=True)
    STATE_FILE.write_text(json.dumps({
        "last_run": datetime.now(timezone.utc).isoformat(),
        "pending_count": len(review_items),
        "titles": [a.title for a in review_items],
    }, ensure_ascii=False, indent=2))


def is_same_as_last_run(review_items: list[Action]) -> bool:
    """前回と同じ項目セットなら True（重複通知を抑制）"""
    state = load_state()
    prev_titles = set(state.get("titles", []))
    curr_titles = {a.title for a in review_items}
    return prev_titles == curr_titles and bool(curr_titles)


# ──────────────────────────────────────────────
# 出力
# ──────────────────────────────────────────────

def write_pending_decisions(auto_items: list[str], review_items: list[Action]) -> None:
    if not auto_items and not review_items:
        PENDING_FILE.unlink(missing_ok=True)
        return

    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    lines = [f"## 🤖 自動判定結果（{now}）\n"]

    if auto_items:
        lines.append("### ✅ 自動実行済み")
        for item in auto_items:
            lines.append(f"- {item}")
        lines.append("")

    if review_items:
        lines.append("### 📋 要確認（コマンド付き）")
        lines.append("`/ops:health` で詳細確認 or 下記コマンドを実行:\n")
        medium = [a for a in review_items if a.risk == "MEDIUM"]
        high   = [a for a in review_items if a.risk == "HIGH"]
        if medium:
            lines.append("#### 🟡 MEDIUM — 推奨: 実行")
            for a in medium:
                lines.append(f"**{a.title}** — {a.detail}")
                if a.command:
                    lines.append(f"```bash\n{a.command}\n```")
                lines.append("")
        if high:
            lines.append("#### 🔴 HIGH — 確認後に実行")
            for a in high:
                lines.append(f"**{a.title}** — {a.detail}")
                if a.command:
                    lines.append(f"```bash\n{a.command}\n```")
                lines.append("")

    SESSION_ENV.mkdir(parents=True, exist_ok=True)
    PENDING_FILE.write_text("\n".join(lines))


def print_full_report(
    auto_items: list[str],
    review_items: list[Action],
    undefined_combos: list[str],
    stale_skills: list[tuple[str, str, str]],
) -> None:
    W = 52
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    print(f"\n{'═' * W}")
    print(f"  🤖  環境自動判定レポート")
    print(f"  生成: {now}")
    print(f"{'═' * W}")

    print(f"\n【自動実行済み（LOW リスク）】")
    if auto_items:
        for item in auto_items:
            print(f"  ✅ {item}")
    else:
        print("  (なし)")

    medium = [a for a in review_items if a.risk == "MEDIUM"]
    high   = [a for a in review_items if a.risk == "HIGH"]

    print(f"\n【要確認: 🟡 MEDIUM ({len(medium)}件)】")
    if medium:
        for a in medium:
            print(f"  {a.title}")
            print(f"    {a.detail}")
            if a.command:
                print(f"    → {a.command.splitlines()[0]}")
    else:
        print("  (なし)")

    print(f"\n【要確認: 🔴 HIGH ({len(high)}件)】")
    if high:
        for a in high:
            print(f"  {a.title}")
            print(f"    {a.detail}")
    else:
        print("  (なし)")

    print(f"\n【シグナルサマリー】")
    print(f"  combos 未定義: {len(undefined_combos)}件")
    print(f"  30日超未使用:  {len(stale_skills)}件")
    print(f"\n{'═' * W}\n")


# ──────────────────────────────────────────────
# メイン
# ──────────────────────────────────────────────

def main() -> None:
    full_mode = "--full" in sys.argv
    active = get_active_skills()
    usage  = get_skill_usage()

    undefined_combos = get_undefined_combos(active)
    stale_skills     = get_stale_skills(active, usage)

    auto_items, review_items = classify_actions(
        undefined_combos, stale_skills, full_mode
    )

    # 自動実行は毎回行う（combos 生成等は冪等）
    # レビューキューは差分がある場合のみ更新（重複通知抑制）
    same_as_last = not full_mode and is_same_as_last_run(review_items)
    if not same_as_last:
        write_pending_decisions(auto_items, review_items)
        save_state(review_items)

    if full_mode:
        print_full_report(auto_items, review_items, undefined_combos, stale_skills)
    else:
        if auto_items:
            print(f"✅ 自動実行: {', '.join(auto_items)}")
        if review_items and not same_as_last:
            medium_n = sum(1 for a in review_items if a.risk == "MEDIUM")
            high_n   = sum(1 for a in review_items if a.risk == "HIGH")
            parts = []
            if medium_n:
                parts.append(f"🟡{medium_n}件")
            if high_n:
                parts.append(f"🔴{high_n}件")
            if parts:
                print(f"📋 要確認: {' '.join(parts)} (/ops:health で詳細)")


if __name__ == "__main__":
    main()
