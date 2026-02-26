"""
_skill_utils.py — スキルメタデータ共有キャッシュ

SessionStart で複数の Python フックが ~/.agents/skills/ を個別に
全走査するのを防ぐ。1 時間 TTL の JSON キャッシュに集約。

使い方:
    from _skill_utils import SkillCache
    cache = SkillCache()
    active = cache.active_skills()    # set[str]
    meta   = cache.skill_meta()       # dict[name -> {rank, has_combos}]
    refs   = cache.cross_refs()       # dict[name -> list[str]]
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

HOME        = Path.home()
AGENTS_DIR  = next(
    (p for p in [HOME / ".agents/skills", HOME / ".claude/skills"] if p.exists()),
    HOME / ".claude/skills",
)
SKILLS_DIR  = HOME / ".claude/skills"
SESSION_ENV = HOME / ".claude/session-env"
CACHE_FILE  = SESSION_ENV / "skills-meta-cache.json"
CACHE_TTL   = 3600  # 秒（1 時間）


class SkillCache:
    """スキルメタデータのファイルキャッシュ（TTL 付き）"""

    def __init__(self) -> None:
        self._data: dict | None = self._load()

    # ── public API ──────────────────────────────

    def active_skills(self) -> set[str]:
        """~/.claude/skills/ のアクティブスキル名セット"""
        return set(self._get()["active"])

    def skill_meta(self) -> dict[str, dict]:
        """~/.agents/skills/ 全スキルのメタ情報 {name: {rank, has_combos}}"""
        return self._get()["meta"]

    def cross_refs(self) -> dict[str, list[str]]:
        """~/.agents/skills/ 全スキルの Cross-references {name: [参照先スキル名, ...]}"""
        return self._get()["cross_refs"]

    def invalidate(self) -> None:
        """キャッシュを強制無効化（スキル追加後などに呼ぶ）"""
        CACHE_FILE.unlink(missing_ok=True)
        self._data = None

    # ── internal ────────────────────────────────

    def _get(self) -> dict:
        if self._data is None:
            self._data = self._build()
            self._save(self._data)
        return self._data

    def _load(self) -> dict | None:
        try:
            raw = json.loads(CACHE_FILE.read_text())
            age = datetime.now(timezone.utc).timestamp() - raw.get("ts", 0)
            if age < CACHE_TTL:
                return raw
        except Exception:
            pass
        return None

    def _save(self, data: dict) -> None:
        SESSION_ENV.mkdir(parents=True, exist_ok=True)
        data["ts"] = datetime.now(timezone.utc).timestamp()
        CACHE_FILE.write_text(json.dumps(data, ensure_ascii=False))

    def _build(self) -> dict:
        """SKILL.md を全走査してメタデータを構築（1 時間に 1 回だけ実行）"""
        active: list[str] = []
        if SKILLS_DIR.exists():
            active = [
                p.name for p in SKILLS_DIR.iterdir()
                if p.is_dir() or p.is_symlink()
            ]

        meta: dict[str, dict] = {}
        cross_refs: dict[str, list[str]] = {}
        if AGENTS_DIR.exists():
            for d in AGENTS_DIR.iterdir():
                if not d.is_dir():
                    continue
                sm = d / "SKILL.md"
                if not sm.exists():
                    continue
                text = sm.read_text()
                m = re.search(r"^rank:\s*(\S+)", text, re.M)
                meta[d.name] = {
                    "rank": m.group(1) if m else "N-C",
                    "has_combos": "combos:" in text,
                }
                # Cross-references セクションを解析
                cr_match = re.search(
                    r"## Cross-references\s*\n(.*?)(?=\n## |\Z)",
                    text,
                    re.DOTALL,
                )
                if cr_match:
                    found = re.findall(r"-\s+\*\*_?([\w\-]+)\*\*", cr_match.group(1))
                    cross_refs[d.name] = [f for f in found if f != d.name]
                else:
                    cross_refs[d.name] = []

        return {"active": active, "meta": meta, "cross_refs": cross_refs, "ts": 0}
