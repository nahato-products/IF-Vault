#!/usr/bin/env python3
"""
project-skill-preset.py — SessionStart hook（最初に実行される）
プロジェクトタイプを検出して:
  1. パーキング済みスキルを自動アクティベート (symlink 作成 → 次セッションから有効)
  2. project-context.md を書き込む → session-start-context.sh が additionalContext に注入
     → 現セッションでも Claude がプロジェクト文脈を把握できる
"""
import sys, json, os
from pathlib import Path
from typing import Dict, List

sys.path.insert(0, os.path.expanduser("~/.claude/hooks"))
from _skill_utils import SkillCache

SKILLS_DIR = Path.home() / ".claude" / "skills"
AGENTS_DIR = Path.home() / ".agents" / "skills"
PROJECT_CONTEXT_FILE = Path.home() / ".claude/session-env/project-context.md"

# プロジェクトタイプ → アクティベート対象スキル
PRESETS: Dict[str, List[str]] = {
    "nextjs": [
        "nextjs-app-router-patterns",
        "tailwind-design-system",
        "react-component-patterns",
        "typescript-best-practices",
        "vercel-ai-sdk",
    ],
    "react": [
        "react-component-patterns",
        "typescript-best-practices",
    ],
    "python": [
        "modern-python",
    ],
    "supabase": [
        "_supabase-postgres-best-practices",
        "_supabase-auth-patterns",
    ],
    "line": [
        "line-bot-dev",
    ],
    "remotion": [
        "remotion-best-practices",
    ],
    "docker": [
        "docker-expert",
        "ci-cd-deployment",
    ],
}

# プロジェクトタイプ → Claude に注入するヒント (1行)
HINTS: Dict[str, str] = {
    "nextjs": "App Router: Server Components + Server Actions + Tailwind CSS v4 @theme + pnpm",
    "react": "コンポーネント: CVA variants + compound pattern + React hooks ベストプラクティス",
    "python": "uv + ruff + ty + pyproject.toml。async は anyio 推奨",
    "supabase": "RLS ポリシー必須。Edge Functions / Postgres Functions, Row Security 注意",
    "line": "LIFF + Messaging API。LINE Bot SDK v3, rich menu, flex message",
    "remotion": "useCurrentFrame / interpolate / spring。Composition でシーン管理",
    "docker": "multi-stage build でイメージ最小化。docker-compose でサービス分離",
}


def detect_project_types(cwd: str) -> List[str]:
    p = Path(cwd)
    types = []

    pkg_path = p / "package.json"
    if pkg_path.exists():
        try:
            pkg = json.loads(pkg_path.read_text())
            deps = {
                **pkg.get("dependencies", {}),
                **pkg.get("devDependencies", {}),
            }
            dep_str = " ".join(deps.keys())

            if "next" in deps:
                types.append("nextjs")
            elif "react" in deps or "react-dom" in deps:
                types.append("react")

            if "remotion" in dep_str or "@remotion/core" in dep_str:
                types.append("remotion")
            if "@line/bot-sdk" in dep_str or "linebot" in dep_str:
                types.append("line")
        except Exception:
            pass

    if (p / "pyproject.toml").exists() or (p / "requirements.txt").exists():
        types.append("python")
    if (p / "supabase").is_dir() or (p / "supabase.config.ts").exists():
        types.append("supabase")
    if (p / "Dockerfile").exists() or (p / "docker-compose.yml").exists() or (p / "docker-compose.yaml").exists():
        types.append("docker")

    return types


def activate_skill(skill_name: str) -> bool:
    src = AGENTS_DIR / skill_name
    dst = SKILLS_DIR / skill_name

    # キャッシュでスキル存在確認（AGENTS_DIR の実ファイル確認はフォールバック）
    meta = SkillCache().skill_meta()
    if skill_name not in meta and not src.exists():
        return False
    if dst.exists() or dst.is_symlink():
        return False

    try:
        SKILLS_DIR.mkdir(parents=True, exist_ok=True)
        dst.symlink_to(src)
        return True
    except Exception:
        return False


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except Exception:
        # context ファイルを削除してホームに戻ったことを反映
        PROJECT_CONTEXT_FILE.unlink(missing_ok=True)
        sys.exit(0)

    cwd = data.get("cwd", "")
    if not cwd:
        PROJECT_CONTEXT_FILE.unlink(missing_ok=True)
        sys.exit(0)

    # ホームディレクトリはプロジェクトなし
    if Path(cwd).resolve() == Path.home().resolve():
        PROJECT_CONTEXT_FILE.unlink(missing_ok=True)
        sys.exit(0)

    project_types = detect_project_types(cwd)
    if not project_types:
        PROJECT_CONTEXT_FILE.unlink(missing_ok=True)
        sys.exit(0)

    # スキルアクティベート
    activated: List[str] = []
    already_active: List[str] = []
    for ptype in project_types:
        for skill in PRESETS.get(ptype, []):
            if activate_skill(skill):
                activated.append(skill)
            else:
                # すでにアクティブ or ソースなし
                src = AGENTS_DIR / skill
                dst = SKILLS_DIR / skill
                if src.exists() and (dst.exists() or dst.is_symlink()):
                    already_active.append(skill)

    # project-context.md を書き込む
    # → session-start-context.sh が additionalContext に注入し現セッションでも有効
    context_lines = [
        f"## プロジェクトコンテキスト: {Path(cwd).name}",
        f"タイプ: {', '.join(project_types)}",
    ]
    for ptype in project_types:
        if ptype in HINTS:
            context_lines.append(f"- {HINTS[ptype]}")

    if activated:
        context_lines.append(f"新規アクティベート済み (次回から): {', '.join(activated)}")
    if already_active:
        context_lines.append(f"アクティブスキル: {', '.join(already_active[:5])}{'...' if len(already_active) > 5 else ''}")

    try:
        PROJECT_CONTEXT_FILE.parent.mkdir(parents=True, exist_ok=True)
        PROJECT_CONTEXT_FILE.write_text("\n".join(context_lines) + "\n")
    except Exception:
        pass

    # ターミナルへの通知（新規アクティベートがあった場合のみ）
    if activated:
        print(f"🔌 [{', '.join(project_types)}] {', '.join(activated)} をアクティベート (次回セッションから有効)")


if __name__ == "__main__":
    main()
