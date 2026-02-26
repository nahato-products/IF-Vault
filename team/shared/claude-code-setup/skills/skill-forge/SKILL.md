---
name: skill-forge
description: "Create, evaluate, and optimize Claude Code Skills. Quality scoring, token optimization, description engineering"
user-invocable: true
---

# Skill Forge

`/skill-forge` で起動。モードを選択:

1. **Create** - 新しいSkillをゼロから作成（8フェーズ）
2. **Search** - 既存Skillを検索・評価・取得→最適化（Acquire & Optimize）
3. **Review** - 既存Skillを10項目100点で評価・最適化

## Decision Tree

```
新規Skill → 既存80%+カバー? Yes→Search(Acquire&Optimize) / No→Create(Phase1〜)
既存改善 → スコア既知? Yes→8点以下あれば最適化 / No→Review(10項目採点)
検索・発見 → Search Mode: find-skillsで検索
```

---

## 公式仕様 [必須]

違反したらリリース不可。全項目チェック。

| 項目 | 制約 |
|------|------|
| name | 小文字+ハイフンのみ、64文字以内 |
| description | 1024文字以内。英語。"何をするか + Use when [トリガー]" |
| SKILL.md | 500行以内 |
| ファイル参照 | 1階層のみ（サブディレクトリ不可） |
| フロントマター | name, description, user-invocable が基本。allowed-tools, license も使用可 |
| allowed-tools | スキルが使用できるツールを制限。例: `allowed-tools: ["Bash", "Read", "Glob"]` |
| 時間依存情報 | 日付・バージョン番号は入れない |
| ロードタイミング | descriptionはセッション開始時にシステムプロンプトに注入される。本文（SKILL.md body）はdescriptionのトリガー条件に一致した時のみ読み込まれる。 |

---

## Create Mode [CRITICAL]

### Phase 1: 要件定義

最初に全て確認してから作業開始:

- **何を解決するか**: このSkillがないと何が困るか
- **誰が使うか**: 自分だけ / チーム / コミュニティ公開
- **発火方式**: 自動（`user-invocable: false`）or 手動（`true` + `/command`）
- **スコープ**: 1つのSkillで何をカバーするか（広すぎると焦点がぼける、狭すぎると価値が薄い）

**判断基準**:
- 特定の作業で毎回同じ知識を参照する → 自動発火
- 必要な時だけ使うワークフロー → 手動起動
- 両方の性質がある → 原則は自動、ワークフロー部分はreference.mdに

### Phase 2: 競合調査

既存Skillとの重複を避ける。作る前に必ずチェック:

```bash
ls ~/.claude/skills/          # インストール済みを確認
# Claude Code内で /find-skills コマンドを実行してコミュニティを検索
```

**見つけた候補の評価**:
- 行数と内容密度は十分か
- トリガーは正確か（descriptionを確認）
- 自分の要件を何%カバーしてるか
- 最終更新はいつか（3ヶ月以上前は注意）

**判断**:
- 既存が80%以上カバー → Search Mode の Acquire & Optimize フローへ
- 既存が50%以下 → 自作
- 類似が複数 → 比較評価して最良を選択

### Phase 3: 設計

**SKILL.md**（毎回コンテキストにロードされる）:
- 核となる原則・ルール・判断基準
- クイックリファレンス（数値、閾値）
- When to Apply / When NOT to Apply

**reference.md**（必要時のみ参照される）:
- 実装の詳細・コード例
- チェックリスト・テンプレート
- アンチパターン集
- 参考文献

**行数目安**: SKILL.md 300-420行 + reference.md 200-350行

**自動発火型**:
```
When to Apply → When NOT to Apply → セクション[優先度タグ] → Reference
```

**手動起動型**:
```
モード選択 → 各モードのワークフロー → Reference
```

**優先度タグ**: `[CRITICAL]` > `[HIGH]` > `[MEDIUM]` でセクションの重要度を明示

### Phase 4: Description Engineering

descriptionはSkillの生命線。発火精度の9割はここで決まる。

**構造**: `[何をするか]. [カバー範囲]. Use when [トリガー条件の列挙].`

**ルール**:
- 英語で書く（トリガーエンジンが英語ベース）
- "Use when" の後にトリガーキーワードを網羅的に列挙
- 動詞を複数入れる: designing, implementing, fixing, improving, reviewing
- 具体的なコンポーネント名・技術名を入れる
- 手動起動型は末尾に `Invoke with /[name].` を追加
- 500-700文字が適正（短すぎるとトリガー漏れ、長すぎると焦点がぼける）

**チェック**:
- [ ] "Use when" が含まれている
- [ ] 動詞が3つ以上
- [ ] 具体的なキーワードが5個以上
- [ ] 1024文字以内

**テンプレート、カテゴリ別キーワード、良/悪の実例集は [reference.md](reference.md) を参照。**

### Phase 5: コンテンツ作成

**構造ルール**:
- 1原則 = 見出し + 説明1行 + 箇条書き3-5個
- 箇条書きは具体的に（数値、コード例、やることを明記）
- 見出しはh3まで（h4以降は使わない）

**トークン効率のバランス**:
- 削る: 自明な相互参照、重複アドバイス、常識的な内容、不要な空行
- 残す: 具体的数値・コード例、価値ある関連性、文脈を伝える説明文
- 圧縮しすぎない: 1-2行に削ると文脈が失われ、実装精度が落ちる

### Phase 6: 品質レビュー

10項目100点満点。全項目9点以上でリリース可。

| # | 項目 | 観点 |
|---|------|------|
| 1 | Trigger Accuracy | descriptionで正しく発火するか |
| 2 | Content Accuracy | 事実・数値・引用は正確か |
| 3 | Content Completeness | 主要トピックに抜けはないか |
| 4 | Token Efficiency | 無駄な行・冗長な表現はないか |
| 5 | Actionability | 読んですぐ実装/判断できるか |
| 6 | Structure | 論理的で素早くナビゲートできるか |
| 7 | Cross-reference | 相互参照は正確で価値があるか |
| 8 | Spec Compliance | 公式仕様に完全準拠しているか |
| 9 | reference.md Quality | 補足資料は十分で整理されているか |
| 10 | Differentiation | 既存Skillと比べて独自の価値があるか |

**5並列レビュー手法**（大規模Skillの場合）:

同時に5つの観点からレビューを実行し、結果を統合:
1. 事実の正確性チェック（一次ソースとの照合）
2. コミュニティSkillとの比較（差別化と重複）
3. トークン効率分析（冗長性・移動候補の特定）
4. シナリオテスト（実際のタスクで適用してみる）
5. トリガー品質チェック（descriptionのキーワード網羅性）

### Phase 7: 最適化

Phase 6で8点以下の項目を修正。問題→対策の対応表は Review Mode の最適化プレイブックを参照。

**優先順**: reference.mdへ移動（テンプレ・チェックリスト）→ 冗長表現の圧縮（自明な相互参照・説明文・箇条書き統合）→ 構造再編（When to Apply圧縮・Reference簡略化）

### Phase 8: リリース前チェック

- [ ] name: 小文字+ハイフン、64文字以内
- [ ] description: 英語、"Use when"あり、1024文字以内
- [ ] SKILL.md: 500行以内
- [ ] reference.md: リンク先が正しい
- [ ] フロントマター: 非標準フィールドなし
- [ ] 時間依存情報: なし
- [ ] 相互参照: 全て有効（番号ミスなし）
- [ ] 10項目レビュー: 全項目9点以上
- [ ] 重複チェック: 既存Skillと被っていない

---

## Search Mode [HIGH]

既存Skillの検索・取得は **find-skills** スキルを使用。このモードでは取得後の最適化に特化する。

### Acquire & Optimize（取得→最適化フロー）

既存Skillが要件の80%以上をカバーする場合、自作より取得→最適化が効率的:

1. **取得**: find-skills で検索・インストール
2. **現状把握**: SKILL.md + reference.md を読み構造・内容を把握
3. **ギャップ分析**: 自分の要件との差分を洗い出す
4. **10項目レビュー**: Review Mode で採点（→ 弱点を特定）
5. **最適化**: 8点以下の項目を改善
6. **検証**: 再採点で全項目9点以上を確認

**判断基準**: 初回スコア60点以上なら最適化する価値あり。60点未満は自作の方が早い。

検索コマンド・即座判定フィルター・比較フレームワークは [reference.md](reference.md) を参照。

---

## Review Mode [HIGH]

既存Skillに10項目100点レビューを実施する。

### 実行手順

1. 対象SkillのSKILL.md + reference.md を読む
2. 10項目それぞれ1-10点で採点
3. 8点以下の項目に具体的な改善案を出す
4. 改善を実施
5. 再採点で全項目9点以上を確認

### 最適化プレイブック

| 問題 | 対策 |
|------|------|
| トリガーが弱い | descriptionにキーワード追加、動詞を増やす |
| 行数オーバー | reference.mdに実装詳細・チェックリストを移動 |
| 冗長 | 自明な相互参照削除、説明文圧縮、箇条書き統合 |
| 構造が悪い | 優先度タグ追加、セクション再編、When NOT to Apply追加 |
| 事実誤認 | 一次ソースで検証して修正 |
| 網羅性不足 | 不足トピックを特定→SKILL.mdまたはreference.mdに追加 |
| 相互参照ミス | 全参照を機械的に検証、番号の連続性確認 |
| reference.md不足 | テンプレート、チェックリスト、アンチパターンを追加 |

---

## Cross-references [MEDIUM]

- **typescript-best-practices**: スキル内のコード例における型安全性確保
- **natural-japanese-writing**: 日本語スキルの散文品質向上（description・SKILL.md本文）
- **testing-strategy**: スキルのテスト可能性設計・品質検証パターン

## Reference

テンプレート集、カテゴリ別キーワード、スコアリング詳細、アンチパターン集は [reference.md](reference.md) を参照。
