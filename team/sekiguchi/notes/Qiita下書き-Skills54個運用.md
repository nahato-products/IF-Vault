---
date: 2026-02-14
tags: [Qiita, Claude Code, Skills, 下書き]
status: draft
---

# Claude Code Skillsを55個運用してわかったこと

Claude Codeに55個のSkillsをインストールして2週間。検索、選別、自作、品質管理まで一通りやった結果を共有する。

## Skillsとは何か

Claude CodeのSkillsは、特定分野の知識パックだ。SKILL.mdというMarkdownファイルに原則やルールを書いておくと、関連する作業時に自動でコンテキストにロードされる。プロンプトに毎回「UXの原則に従って」と書く必要がなくなる。

自動発火の仕組みはdescriptionフィールドの解析で決まる。ここの書き方次第で「いつ発火するか」が変わる。この挙動を理解しているかどうかが、Skills運用の質を分ける。

## 55個の内訳

| カテゴリ | 数 | 例 |
|---------|-----|-----|
| UI/UXデザイン | 13 | ux-psychology, web-design-guidelines, Apple HIG系6つ |
| フロントエンド・API | 4 | vercel-react-best-practices, nextjs-app-router-patterns |
| 開発ワークフロー | 8 | git-advanced-workflows, systematic-debugging |
| DB | 3 | supabase-postgres, neon-postgres, ansem-db-patterns |
| セキュリティ | 2 | security-review, vibe-security-skill |
| 動画・アニメーション | 4 | remotion-best-practices, ffmpeg |
| ドキュメント処理 | 4 | docx, pdf, xlsx, pptx |
| テスト | 3 | webapp-testing, test-driven-development |
| その他 | 14 | skill-forge, natural-japanese-writing, docker-expert等 |

ソース別では、外部リポジトリ製が51個、自作が4個（ux-psychology, natural-japanese-writing, skill-forge, ansem-db-patterns）。

## Description Engineering

Skillsの発火精度はdescriptionで9割決まる。英語で書き、"Use when"パターンを含め、動詞を5個以上入れる。これだけで発火率が劇的に変わる。

悪い例:
```
description: Helps with UI best practices.
```

良い例:
```
description: Guides UI/UX design and implementation using cognitive psychology principles, Nielsen's heuristics, and anti-patterns. Covers AI UX and neurodiversity. Use when designing, implementing, fixing, or improving UI components, forms, buttons, navigation, modals, dialogs...
```

後者はUIコンポーネントの作業で確実に発火する。前者はたぶん発火しない。

descriptionの適正長は500-700文字。短すぎるとトリガー漏れ、長すぎると焦点がぼける。手動起動型は末尾に `Invoke with /[name].` を追加する。

## 10項目100点レビュー

Skillの品質を定量評価する仕組みを自作した。

| # | 項目 | 見ること |
|---|------|---------|
| 1 | Trigger Accuracy | descriptionで正しく発火するか |
| 2 | Content Accuracy | 事実や数値は正確か |
| 3 | Content Completeness | 主要トピックに抜けはないか |
| 4 | Token Efficiency | 無駄な行や冗長な表現はないか |
| 5 | Actionability | 読んですぐ実装できるか |
| 6 | Structure | 論理的でナビゲートしやすいか |
| 7 | Cross-reference Quality | 相互参照は正確で価値があるか |
| 8 | Spec Compliance | 公式仕様に準拠しているか |
| 9 | reference.md Quality | 補足資料は十分か |
| 10 | Differentiation | 既存Skillにない独自の価値があるか |

全項目9点以上でリリース。8点以下があれば改善ポイントが明確になる。自作Skillの品質はこのフレームワークで担保している。

## 同時発火の管理

複数のSkillsが同時にロードされるとコンテキストを圧迫する。

React/Next.js作業時の同時発火:
- vercel-react-best-practices: 136行
- nextjs-app-router-patterns: 543行
- tailwind-design-system: 874行
- 合計: 1,553行

UI設計作業時の同時発火:
- ux-psychology: 410行
- web-design-guidelines: 1,288行
- 合計: 1,698行

合計が2,000行を超えると体感で応答速度に影響が出始める。同時発火の組み合わせを事前に洗い出して、問題がないか確認しておくのが大事。

手動起動型（`/baseline-ui`等）はコマンドで呼ばない限りロードされないから、重いスキルは手動起動型にするのも手。

## 自作Skillの作り方

skill-forgeというメタスキルを作った。8フェーズでゼロからSkillを作れる。

1. **要件定義** — スコープと発火方式を決める
2. **競合調査** — 既存Skillを検索して重複を避ける
3. **設計** — SKILL.mdとreference.mdの分離を決める
4. **Description Engineering** — descriptionを書く（ここが最重要）
5. **コンテンツ作成** — 構造ルールとトークン効率を意識して書く
6. **品質レビュー** — 10項目100点で採点
7. **最適化** — 8点以下の項目を改善
8. **リリース前チェック** — 公式仕様への準拠を確認

自作4つのスコア:
| スキル | スコア | 特徴 |
|--------|--------|------|
| ux-psychology | 88/100 | 29原則+10H+AI UX+ニューロダイバーシティ |
| natural-japanese-writing | 93/100 | AI生成テキストのパターン排除20ルール |
| skill-forge | 91/100 | Skills作成・検索・評価のメタスキル |
| ansem-db-patterns | 84/100 | 32テーブルのDB設計パターン集 |

## 500行の壁

公式仕様でSKILL.mdは500行以内。55個中12個がこの制限を超えている。全て外部リポジトリ製で、最大はweb-design-guidelinesの1,288行。

超過していても内容の網羅性が勝っていれば維持する方針をとった。削って実用性が下がるくらいなら、超過を許容した方が合理的。

自作Skillsは全て500行以内に収めている。核心はSKILL.mdに書き、詳細やテンプレートはreference.mdに分離する。reference.mdは必要なときだけ参照されるから、トークン効率に影響しない。

## ヘルスチェックの自動化

55個もあるとアップデート漏れや仕様違反が見えなくなる。シェルスクリプトで一括チェックする仕組みを作った。

チェック項目:
- SKILL.md行数（500行超え検出）
- description文字数（100文字未満を検出）
- reference.md有無
- "Use when"パターンの有無

週1で走らせて状態を確認している。

## やってみてわかったこと

Skillsは「入れる」より「選ぶ」が難しい。npmパッケージと同じで、入れるのは一瞬だが、品質の見極めには時間がかかる。descriptionが短い、内容が薄い、最終更新が古い。この3条件のどれかに当てはまるスキルは入れても効果が薄い。

自作Skillsの価値は独自性にある。コミュニティのスキルは汎用的な知識をまとめたものが多く、差別化が難しい。ansem-db-patternsはANSEMという特定プロジェクトの設計パターンを凝縮した。次のDB設計で同じ判断を繰り返さなくて済む。こういう「自分にしか書けないスキル」が一番効く。

descriptionは英語で書く。トリガーエンジンが英語ベースで動いているため、日本語だと発火しない。内容が日本語でもdescriptionだけは英語にする。

reference.mdの使い方で差がつく。SKILL.mdは毎回ロードされるが、reference.mdは必要なときだけ参照される。テンプレートやチェックリスト、アンチパターン集はreference.mdに入れる。トークン効率が上がり、応答速度も改善する。

---

_最終更新: 2026-02-15_
