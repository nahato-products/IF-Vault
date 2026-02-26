---
name: skills-change-control
description: Manage and audit Claude Code skill tier changes (always_on/conditional/parking) with policy enforcement, one-in-one-out cost control, contract tests (18 tests), and audit trail. Use when promoting skills to always_on, demoting to conditional, moving to parking, deleting skills, or auditing current tier health. Do not trigger for creating new skills (use skill-forge) or discovering community skills (use find-skills).
version: 1.0.0
triggers:
  - スキルのtierを変えたい
  - always_onに昇格させたい
  - スキルを降格したい
  - スキルを削除したい
  - スキル監査を実行したい
  - skills-change-control
  - /skills-change-control
cost: medium
---

# Skills Change Control

Skills tier の変更を安全に行うためのガバナンス スキル。
P1/P2 違反ゼロ・コストゲート通過・監査証跡の保持を保証する。

## 前提知識

| Tier | 命名規則 | ロード | 備考 |
|------|----------|--------|------|
| always_on | `_` プレフィックス必須 | 毎回自動 | コストに直結 → 上限 {{ policy.rules.always_on_max }} 個 |
| conditional | プレフィックスなし | 明示呼び出し時のみ | 無制限だが定期棚卸し推奨 |
| parking | プレフィックスなし | 無効（インストール禁止） | 一時退避・削除待ち |

## 必須フロー

変更の種類に応じて以下のフェーズを順に実施する。

### Phase 0: 影響スコープの確認

```
変更対象: <スキル名>
変更種別: always_on昇格 / conditional降格 / parking移行 / 削除 / 新規追加
影響: always_on数 +N → <変更後の数> / <上限数>
コスト増加: あり / なし（降格・削除は減少）
```

### Phase 1: ポリシー更新

`policy/skills_tier_policy.json` を編集する。

**always_on 昇格** の場合：
- one-in-one-out: 既存 always_on から1つを conditional に降格してから昇格
- `_` プレフィックスをディレクトリに追加（リネーム or シンボリックリンク）
- `tiers.always_on` に追加、`tiers.conditional` から削除

**conditional 降格** の場合：
- `_` プレフィックスを外す
- `tiers.always_on` から削除、`tiers.conditional` に追加

**parking 移行** の場合：
- 実ディレクトリは `~/.claude/skills/` から削除（または `_parking_` プレフィックス）
- `tiers.parking` に追加

**新規追加** の場合：
- always_on なら one-in-one-out ルールを先に確認
- SKILL.md が存在することを確認（P2 通過条件）

### Phase 2: 契約テスト（必須）

```bash
cd ~/.claude/skills/skills-change-control
python3 -m unittest tests.test_skills_tier_policy_contract -v
```

**全テスト PASS でなければ Phase 3 に進まない。**

### Phase 3: 監査スクリプト実行

```bash
# 基本監査（always_on 全件 + P1/P2 判定）
~/.claude/skills/skills-change-control/scripts/skills_tier_audit.sh

# strict: conditional 含む全件 SKILL.md チェック
~/.claude/skills/skills-change-control/scripts/skills_tier_audit.sh --strict-installed
```

### Phase 4: 出力レポート

以下の形式でレポートする：

```
## Skills Change Control レポート

### 変更内容
- 対象スキル: <名前>
- 変更種別: <always_on昇格 / conditional降格 / etc.>
- 理由・根拠: <なぜこの変更が必要か>

### ポリシー適合
- always_on 数: <変更前> → <変更後> (上限: {{ policy.rules.always_on_max }})
- one-in-one-out: 遵守 / N/A
- cost_gate_required: PASS / N/A

### テスト結果
- 契約テスト: PASS (全 N テスト)
- 監査スクリプト: PASS / FAIL

### Findings
- [P1] <件数>件 — <内容または「なし」>
- [P2] <件数>件 — <内容または「なし」>
- [P3] <件数>件 — <内容または「なし」>

### Verdict
✅ PASS — 変更を適用しました
❌ FAIL — P1/P2 解消が必要です（<具体的な修正内容>）
```

## コストゲート（常に確認）

always_on への昇格・追加前に必ず確認：

1. **上限チェック**: 現在の always_on 数 + 1 ≤ `always_on_max` か？
2. **one-in-one-out**: 上限に達している場合、降格するスキルを先に決定
3. **SKILL.md 存在**: `_スキル名/SKILL.md` が存在するか？（P2 条件）
4. **価値対コスト**: 毎回ロードされる価値があるか？（conditional で十分では？）

## 禁止事項

- テスト FAIL のまま policy.json を更新しない
- 監査スクリプト FAIL のまま「後で直す」と進めない
- always_on に追加する際、one-in-one-out なしに上限を超えない
- SKILL.md なしのスキルを always_on に昇格しない

## ファイル構成

```
~/.claude/skills/skills-change-control/
├── SKILL.md                               # このファイル
├── policy/
│   └── skills_tier_policy.json           # Source of Truth
├── scripts/
│   └── skills_tier_audit.sh              # 監査スクリプト（実行権限必要）
└── tests/
    ├── __init__.py
    └── test_skills_tier_policy_contract.py  # 契約テスト
```

## Cross-references

- `_claude-env-optimizer`: 環境全体の健全性チェック（skills health 含む）
- `skill-forge`: 新スキル作成時の品質保証フロー
- `context-economy`: スキルロードのコスト最適化
