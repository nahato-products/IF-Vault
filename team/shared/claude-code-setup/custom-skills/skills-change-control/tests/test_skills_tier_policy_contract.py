"""
tests/test_skills_tier_policy_contract.py
Skills Tier Policy 契約テスト

実行:
  cd ~/.claude/skills/skills-change-control
  python3 -m unittest tests.test_skills_tier_policy_contract

テスト設計方針:
  - P1 違反は必ず FAIL
  - P2 違反は FAIL
  - P3 は警告のみ（FAIL しない）
  - 出力契約（findings/risks/verdict）の形式を保証
"""
import json
import os
import re
import unittest
from pathlib import Path

SKILL_ROOT = Path(__file__).parent.parent
POLICY_FILE = SKILL_ROOT / "policy" / "skills_tier_policy.json"
SKILLS_DIR = Path.home() / ".claude" / "skills"


def load_policy() -> dict:
    with open(POLICY_FILE) as f:
        return json.load(f)


def get_installed_skills() -> tuple[list[str], list[str]]:
    """インストール済みスキルを always_on / conditional に分類して返す"""
    always_on, conditional = [], []
    if not SKILLS_DIR.exists():
        return always_on, conditional
    for item in SKILLS_DIR.iterdir():
        if item.is_dir() or item.is_symlink():
            name = item.name
            if name.startswith("_"):
                always_on.append(name)
            else:
                conditional.append(name)
    return sorted(always_on), sorted(conditional)


class TestPolicyFileIntegrity(unittest.TestCase):
    """Policy ファイル自体の整合性チェック"""

    def test_policy_file_exists(self):
        self.assertTrue(POLICY_FILE.exists(), f"policy file not found: {POLICY_FILE}")

    def test_policy_schema(self):
        policy = load_policy()
        self.assertIn("version", policy)
        self.assertIn("tiers", policy)
        self.assertIn("rules", policy)
        tiers = policy["tiers"]
        self.assertIn("always_on", tiers)
        self.assertIn("conditional", tiers)
        self.assertIn("parking", tiers)

    def test_no_duplicate_across_tiers(self):
        """同じスキルが複数 tier に登録されていないこと"""
        policy = load_policy()
        tiers = policy["tiers"]
        all_skills = (
            tiers["always_on"] + tiers["conditional"] + tiers["parking"]
        )
        duplicates = [s for s in all_skills if all_skills.count(s) > 1]
        self.assertEqual(
            [], list(set(duplicates)),
            f"重複登録スキル: {list(set(duplicates))}"
        )

    def test_always_on_naming_convention(self):
        """always_on スキルはアンダースコアプレフィックスを持つこと"""
        policy = load_policy()
        violations = [s for s in policy["tiers"]["always_on"] if not s.startswith("_")]
        self.assertEqual(
            [], violations,
            f"always_on なのにアンダースコアなし: {violations}"
        )

    def test_conditional_no_underscore(self):
        """conditional スキルはアンダースコアプレフィックスを持たないこと"""
        policy = load_policy()
        violations = [s for s in policy["tiers"]["conditional"] if s.startswith("_")]
        self.assertEqual(
            [], violations,
            f"conditional なのにアンダースコアあり: {violations}"
        )


class TestOneInOneOut(unittest.TestCase):
    """one-in-one-out ルールの検証"""

    def test_always_on_count_within_limit(self):
        """always_on スキル数が上限以下であること"""
        policy = load_policy()
        limit = policy["rules"]["always_on_max"]
        always_on, _ = get_installed_skills()
        self.assertLessEqual(
            len(always_on), limit,
            f"always_on が上限超過: {len(always_on)} > {limit}。"
            f"one-in-one-out: 追加するなら既存を降格/削除してください"
        )

    def test_always_on_policy_matches_installed(self):
        """インストール済み always_on がポリシーと一致すること（P1）"""
        policy = load_policy()
        policy_set = set(policy["tiers"]["always_on"])
        installed, _ = get_installed_skills()
        installed_set = set(installed)

        unregistered = installed_set - policy_set
        self.assertEqual(
            set(), unregistered,
            f"[P1] always_on 未登録スキル: {unregistered}。"
            f"policy.json に追加するか、アンダースコアを外してください"
        )

    def test_always_on_policy_installed(self):
        """ポリシー登録済み always_on が実際にインストールされていること（P1）"""
        policy = load_policy()
        policy_set = set(policy["tiers"]["always_on"])
        installed, _ = get_installed_skills()
        installed_set = set(installed)

        missing = policy_set - installed_set
        self.assertEqual(
            set(), missing,
            f"[P1] always_on 未インストール: {missing}。install.sh を実行してください"
        )


class TestSkillMdContract(unittest.TestCase):
    """SKILL.md 存在・構造チェック"""

    def _resolve(self, skill_path: Path) -> Path:
        if skill_path.is_symlink():
            resolved = skill_path.resolve()
            return resolved if resolved.exists() else skill_path
        return skill_path

    def test_always_on_skills_have_skillmd(self):
        """always_on スキルは全て SKILL.md を持つこと（P2）"""
        installed, _ = get_installed_skills()
        missing = []
        for skill in installed:
            path = self._resolve(SKILLS_DIR / skill)
            if not (path / "SKILL.md").exists():
                missing.append(skill)
        self.assertEqual(
            [], missing,
            f"[P2] SKILL.md 欠損 (always_on): {missing}"
        )

    def test_skillmd_has_name_field(self):
        """SKILL.md の frontmatter に name フィールドがあること"""
        installed_ao, installed_cond = get_installed_skills()
        violations = []
        for skill in installed_ao + installed_cond:
            path = self._resolve(SKILLS_DIR / skill)
            skillmd = path / "SKILL.md"
            if not skillmd.exists():
                continue
            content = skillmd.read_text(encoding="utf-8", errors="ignore")
            if 'name:' not in content:
                violations.append(skill)
        self.assertEqual(
            [], violations,
            f"[P2] SKILL.md に name: フィールドなし: {violations}"
        )

    def test_skillmd_has_description_field(self):
        """SKILL.md の frontmatter に description フィールドがあること"""
        installed_ao, _ = get_installed_skills()
        violations = []
        for skill in installed_ao:
            path = self._resolve(SKILLS_DIR / skill)
            skillmd = path / "SKILL.md"
            if not skillmd.exists():
                continue
            content = skillmd.read_text(encoding="utf-8", errors="ignore")
            if 'description:' not in content:
                violations.append(skill)
        self.assertEqual(
            [], violations,
            f"[P2] SKILL.md に description: フィールドなし (always_on): {violations}"
        )


class TestCostGate(unittest.TestCase):
    """コストゲート: always_on 増加による暗黙コスト増を防ぐ"""

    BASELINE_ALWAYS_ON_COUNT = 19  # v1.0.0 時点の always_on 数

    def test_always_on_count_not_silently_increased(self):
        """always_on が baseline より増えた場合、policy に明示されていること"""
        policy = load_policy()
        policy_count = len(policy["tiers"]["always_on"])
        # policy に登録された数が baseline より多い場合、
        # ルール "one_in_one_out": true であることを確認
        if policy_count > self.BASELINE_ALWAYS_ON_COUNT:
            self.assertTrue(
                policy["rules"].get("one_in_one_out", False),
                f"always_on が baseline({self.BASELINE_ALWAYS_ON_COUNT})より増加({policy_count})しているが "
                f"one_in_one_out ルールが無効になっている。コスト影響を確認してください"
            )

    def test_cost_gate_rule_exists(self):
        """cost_gate_required フラグが policy に存在すること"""
        policy = load_policy()
        self.assertIn(
            "cost_gate_required", policy["rules"],
            "cost_gate_required フラグが policy.json に存在しません"
        )
        self.assertTrue(
            policy["rules"]["cost_gate_required"],
            "cost_gate_required が false になっています。意図的な変更か確認してください"
        )


class TestOutputContract(unittest.TestCase):
    """監査スクリプトの出力フォーマット契約テスト"""

    AUDIT_SCRIPT = SKILL_ROOT / "scripts" / "skills_tier_audit.sh"

    def test_audit_script_exists(self):
        self.assertTrue(
            self.AUDIT_SCRIPT.exists(),
            f"audit script not found: {self.AUDIT_SCRIPT}"
        )

    def test_audit_script_executable(self):
        self.assertTrue(
            os.access(self.AUDIT_SCRIPT, os.X_OK),
            f"audit script not executable: {self.AUDIT_SCRIPT}"
        )

    def test_audit_script_contains_required_sections(self):
        """スクリプトが必須セクション（Findings/Risks/Verdict）を出力すること"""
        content = self.AUDIT_SCRIPT.read_text()
        for section in ["Findings", "Risks", "Verdict", "PASS", "FAIL"]:
            self.assertIn(
                section, content,
                f"audit script に '{section}' セクションがありません"
            )

    def test_audit_script_supports_strict_flag(self):
        """--strict-installed フラグがスクリプトにあること"""
        content = self.AUDIT_SCRIPT.read_text()
        self.assertIn(
            "--strict-installed", content,
            "audit script に --strict-installed フラグがありません"
        )

    def test_audit_script_has_p1_p2_checks(self):
        """P1/P2 チェックがスクリプトにあること"""
        content = self.AUDIT_SCRIPT.read_text()
        self.assertIn("[P1]", content)
        self.assertIn("[P2]", content)


if __name__ == "__main__":
    unittest.main(verbosity=2)
