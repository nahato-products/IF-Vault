---
name: skill-forge
description: "Create, review, and optimize Claude Code skills with quality scoring, frontmatter validation, trigger coverage analysis, and cross-reference mapping. Use when creating new skills from scratch, improving existing skill quality, scoring skill effectiveness, reviewing skill frontmatter, or auditing the skill library. Do not trigger for environment health checks (use claude-env-optimizer), skill placement decisions (use skills-change-control), or executing a skill's function."
user-invocable: false
triggers:
  - スキルを作成したい
  - スキルの品質を改善
  - スキルをレビューして
  - 新しいスキルを設計
  - /skill-forge
---

# Skill Forge

Claude Code スキルの作成・評価・最適化スキル。

## Quality Scoring (100点満点)

| 項目 | 点数 |
|------|------|
| description に "Use when" を含む | +25 |
| description に "Do not trigger" を含む | +20 |
| triggers: が5個以上 | +25 |
| YAML frontmatter (---) がある | +20 |
| Cross-references セクションがある | +10 |

## Create Flow

1. スキルの目的・スコープを定義
2. "Use when" / "Do not trigger" を明確化
3. 5個以上のトリガーを設定
4. コアコンテンツを執筆
5. Cross-references で関連スキルを紐付け

## Cross-references

- **claude-env-optimizer**: 環境全体の診断
- **skills-quality-guardian**: スキルライブラリの整合性チェック
- **skills-change-control**: スキルのティア昇格・降格管理
