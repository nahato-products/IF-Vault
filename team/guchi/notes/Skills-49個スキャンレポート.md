---
date: 2026-02-14
tags: [Claude Code, Skills, レビュー, 品質管理]
status: active
---

# Skills スキャンレポート（v2.7時点・49個）

v2.7時点（49個）のインストール済みSkillsを一括スキャンし、仕様違反・品質問題・改善候補を洗い出した。v3.0で全54個の再レビュー＋最適化を実施済み（2026-02-14）。追加5個（vercel-react-best-practices 136行、nextjs-app-router-patterns 543行、tailwind-design-system 874行、api-design-principles 528行、natural-japanese-writing 176行）は全て500行以内の仕様準拠。tailwind-design-systemは874行で仕様超過だが外部リポジトリ製のため維持。

---

## 仕様違反: 500行超え（12個）

公式仕様でSKILL.mdは500行以内と定められている。以下は全て外部リポジトリ製で、自分では修正しない方がいい。アップデート時に自動で壊れるリスクがある。

| Skill | 行数 | 超過 | 判定 |
|-------|------|------|------|
| web-design-guidelines | 1,288 | +788 | 維持。WCAG準拠の網羅性が価値 |
| macos-design-guidelines | 965 | +465 | 維持。Apple HIG原文の圧縮版 |
| ios-design-guidelines | 959 | +459 | 維持。同上 |
| android-design-guidelines | 950 | +450 | 維持。Material Design 3網羅 |
| tailwind-design-system | 874 | +374 | 維持。Tailwind v4デザインシステム構築ガイド（v2.9追加） |
| vibe-security-skill | 758 | +258 | 維持。XSS/CSRF/SSRF/JWT等を1ファイルで完結 |
| obsidian-bases | 651 | +151 | 維持。Bases機能の公式ガイド |
| obsidian-markdown | 620 | +120 | 維持。Obsidian記法の公式ガイド |
| docker-expert | 614 | +114 | 維持。Dockerfile実例が豊富 |
| nextjs-app-router-patterns | 543 | +43 | 維持。Next.js App Router パターン集（v2.9追加） |
| api-design-principles | 528 | +28 | 維持。REST/GraphQL API設計原則（v2.9追加） |
| ipados-design-guidelines | 528 | +28 | 維持。ギリギリだが許容範囲 |

全て維持する理由は、行数超過よりコンテンツの網羅性が勝っている点。ehmo/platform-design-skillsシリーズは公式HIGの圧縮版で、これ以上削ると実用性が下がる。v2.9追加の3つは微超過〜中超過だが、いずれもコンテンツの価値が上回る。

---

## 短いdescription（5個）

descriptionが100文字未満だとトリガー精度が落ちる。ただしibelick/ui-skills系の3つは手動コマンド起動なので、自動発火の精度は問題にならない。

| Skill | 文字数 | description | 影響 |
|-------|--------|-------------|------|
| fixing-accessibility | 39 | Fix accessibility issues. | 低。`/fixing-accessibility` で手動起動 |
| fixing-metadata | 46 | Ship correct, complete metadata. | 低。`/fixing-metadata` で手動起動 |
| fixing-motion-performance | 47 | Fix animation performance issues. | 低。手動起動の側面が強い |
| remotion-best-practices | 67 | Best practices for Remotion... | 中。自動発火型だがRemotionコード限定なので問題少 |
| baseline-ui | 89 | Enforces an opinionated UI baseline... | 低。`/baseline-ui` で手動起動 |

対応不要。手動起動型はdescriptionの長さが発火精度に影響しない。remotion-best-practicesはプリインストールで、Remotionファイルを触れば確実に発火する。

---

## 薄いコンテンツ（100行未満 / 8個）

行数が少ないこと自体は問題ではない。中身が詰まっていれば薄い方がトークン効率は良い。

| Skill | 行数 | reference有無 | 評価 |
|-------|------|---------------|------|
| remotion-best-practices | 43 | ✅ 26個のruleファイル | 問題なし。SKILL.mdはインデックス、実体はruleファイル群 |
| motion-designer | 53 | ❌ | やや薄い。Disney 12原則だけで具体的なコード例なし |
| supabase-postgres-best-practices | 64 | ✅ 31個のreferenceファイル | 問題なし。remotionと同じインデックス構造 |
| baseline-ui | 85 | ❌ | 問題なし。85行に制約ルールが密集している |
| webapp-testing | 95 | ✅ scripts/ + examples/ | 問題なし。Decision Treeが実用的 |
| brainstorming | 96 | ❌ | 問題なし。ワークフロー定義に特化 |
| youtube-downloader | 98 | ❌ | 問題なし。ツール実行型で内容十分 |
| video-motion-graphics | 99 | ❌ | やや薄い。After Effects中心で汎用性に欠ける |

---

## 仕様違反: フロントマター問題（1個）

| Skill | 問題 | 詳細 |
|-------|------|------|
| supabase-postgres-best-practices | 時間依存情報あり | `date: January 2026`、`version: "1.1.0"` がフロントマターに入っている |

Supabase公式リポジトリ製なので手を出さない。アップデートで修正されることを期待する。

---

## 重複・競合リスク

| ペア | 重複度 | 判定 |
|------|--------|------|
| ux-psychology + web-design-guidelines | 中 | アクセシビリティ部分が一部重複。ux-psychologyは認知心理学寄り、webは WCAG技術仕様寄りで棲み分けできている |
| security-review + vibe-security-skill | 中 | security-reviewはコードレビュー特化（偽陽性低減）、vibe-securityは予防型（実装時のガイドライン）。両方あって価値がある |
| motion-designer + video-motion-graphics | 高 | Disney 12原則 vs After Effects実践。motion-designerの方が汎用的。video-motion-graphicsは動画制作に入らない限り不要 |
| fixing-motion-performance + motion-designer | 低 | パフォーマンス修正 vs デザイン原則。完全に別の役割 |

---

## アクション推奨

### すぐやること

なし。致命的な問題は見つからなかった。

### 次のアップデート時に確認

1. **vibe-security-skill** — 758行は大きい。アップデートでスリム化されたら嬉しい
2. **supabase-postgres-best-practices** — フロントマターの日付問題がアップデートで消えるか確認
3. **ehmo/platform-design-skills** — 6スキル合計5,670行。iOS/macOS/web以外を本当に使うか半年後に棚卸し

### 削除候補（優先度低）

| Skill | 理由 | 判断 |
|-------|------|------|
| video-motion-graphics | motion-designerと重複大。After Effects特化で使用頻度低い | 様子見。動画制作の頻度次第 |
| tvos-design-guidelines | Apple TV開発の予定がない | 様子見。容量は小さいので害は少ない |
| visionos-design-guidelines | Vision Pro開発の予定がない | 同上 |
| watchos-design-guidelines | watchOS開発の予定がない | 同上 |

---

## 全体評価

49個中、致命的な問題を持つスキルはゼロ。500行超えの9個は全て外部リポジトリ製で、内容の網羅性を考えると削る必要はない。自作の2スキル（ux-psychology、skill-forge）は仕様完全準拠・100点通過済み。

トークン効率の観点では、自動発火型の重いスキル（web-design-guidelines 1,288行、ux-psychology 410行）が同時ロードされるケースだけ注意が必要。ただしUI作業時にこの2つが同時発火しても、コンテキストウィンドウの許容範囲内に収まっている。

---

_最終更新: 2026-02-14_
