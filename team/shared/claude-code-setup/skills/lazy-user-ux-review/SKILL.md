---
name: lazy-user-ux-review
description: "Score UI/UX from the laziest user's perspective through 10-category 100-point system covering First Impression, CTA Clarity, Form Friction, Loading Tolerance, Error Recovery, Navigation, Mobile Thumb Zone, Visual Feedback, Progressive Disclosure, and Zero-Config Experience. Use when reviewing UI, auditing UX, evaluating forms, assessing landing pages, improving conversion, or reducing user friction. Invoke with /lazy-user-ux-review."
user-invocable: true
---

# Lazy User UX Review

`/lazy-user-ux-review` で起動。「究極の怠惰ユーザー」の視点でUI/UXを100点満点でスコアリングする。

## How to Use

- `/lazy-user-ux-review` — プロジェクト全体のUI/UXレビュー
- `/lazy-user-ux-review <path>` — 特定の画面・コンポーネントをレビュー

## Lazy User Persona [CRITICAL]

レビューは全てこのペルソナで行う。「普通のユーザー」ではなく**最も怠惰なユーザー**:

| 特性 | 行動 |
|------|------|
| 3秒で諦める | ファーストビューで目的が分からなければ離脱 |
| 3フィールド以上入力しない | 4つ目のフォームフィールドで「あとでやろう」→永遠にやらない |
| スクロールしない | ファーストビュー以下は存在しないのと同じ |
| 説明文を読まない | ラベルとボタンテキストだけで判断する |
| エラーで即離脱 | 「何が間違ってるか」を自分で探す気はゼロ |
| 設定画面を開かない | デフォルトのまま使う。カスタマイズは存在しない |
| 片手で操作する | もう片方の手はコーヒーかスマホ |
| 待てない | 2秒以上のローディングで「壊れた？」と思う |
| 戻るボタンを連打する | 迷ったら考えずに戻る。履歴が壊れたら離脱 |
| 通知は全部オフ | プッシュ通知の許可ダイアログ→即「許可しない」 |

**判断基準**: このペルソナが「何も考えずに目的を達成できるか」

---

## Review Process [HIGH]

4ステップで各画面を評価する:

### Step 1: 発見（3秒テスト）

- ページを開いた瞬間、何のページか分かるか
- メインのCTAが1つだけ明確に見えるか
- 視覚的ノイズ（バナー、ポップアップ、過剰な色使い）はないか

### Step 2: 理解（10秒テスト）

- スクロールなしで「次に何をすべきか」分かるか
- ラベル・ボタンテキストだけで操作が理解できるか
- 情報の優先順位が視覚的に明確か

### Step 3: 操作（タスク完了テスト）

- 目的達成まで何クリック/何タップか（3以下が理想）
- フォーム入力は最小限か（3フィールド以下が理想）
- エラー時に何をすべきか即座に分かるか

### Step 4: 完了（満足テスト）

- 操作完了のフィードバックがあるか
- 次のアクションが示されるか
- 「戻る」「やり直す」がいつでも可能か

---

## Scoring [CRITICAL]

10カテゴリ x 10点 = 100点満点。各カテゴリの詳細採点基準は [reference.md](reference.md) 参照。

| # | カテゴリ | 観点 | 重み |
|---|---------|------|------|
| 1 | First Impression | 3秒で何のページか分かるか | CRITICAL |
| 2 | CTA Clarity | メインアクションが1つだけ明確に見えるか | CRITICAL |
| 3 | Form Friction | 入力フィールド数・ステップ数は最小限か | HIGH |
| 4 | Loading Tolerance | 待機時間中の体験は適切か | HIGH |
| 5 | Error Recovery | エラーからの復帰が即座にできるか | HIGH |
| 6 | Navigation Simplicity | 迷わずに目的地に辿り着けるか | HIGH |
| 7 | Mobile Thumb Zone | 片手操作でメイン機能が使えるか | MEDIUM |
| 8 | Visual Feedback | 操作結果が即座に視覚的に返るか | HIGH |
| 9 | Progressive Disclosure | 情報が段階的に提示されているか | MEDIUM |
| 10 | Zero-Config Experience | 設定なしでデフォルトのまま使えるか | MEDIUM |

### スコア帯の目安

| スコア | 評価 | Lazy Userの反応 |
|--------|------|----------------|
| 90-100 | Excellent | 「お、なんか知らんけどできた」 |
| 70-89 | Good | 「まあ使えるけど、ちょっとダルい」 |
| 50-69 | Needs Work | 「は？意味わかんない」→ 離脱率高 |
| 0-49 | Critical | 「壊れてる？」→ 即離脱 |

---

## 出力フォーマット [CRITICAL]

### 1. スコア表

```
## Lazy User UX Score: XX/100

| # | カテゴリ | スコア | 判定 |
|---|---------|--------|------|
| 1 | First Impression | X/10 | [状態] |
| 2 | CTA Clarity | X/10 | [状態] |
| 3 | Form Friction | X/10 | [状態] |
| 4 | Loading Tolerance | X/10 | [状態] |
| 5 | Error Recovery | X/10 | [状態] |
| 6 | Navigation Simplicity | X/10 | [状態] |
| 7 | Mobile Thumb Zone | X/10 | [状態] |
| 8 | Visual Feedback | X/10 | [状態] |
| 9 | Progressive Disclosure | X/10 | [状態] |
| 10 | Zero-Config Experience | X/10 | [状態] |
```

判定: 9-10 = PASS / 7-8 = OK / 4-6 = WARN / 1-3 = FAIL

### 2. TOP 3 修正提案

スコアが低い上位3つのカテゴリに対し、具体的な修正案をコード付きで提示:

```
### Fix #1: [カテゴリ名] (現在: X/10 → 目標: Y/10)

**問題**: [Lazy Userが感じる具体的な不満]
**修正**: [具体的な変更内容]

// Before
[現状のコード]

// After
[改善後のコード]
```

### 3. Quick Wins

5分以内で修正できる改善を最大5つリストアップ:

```
### Quick Wins (5分以内で改善)

- [ ] [修正内容] → [期待効果] (対象ファイル)
```

---

## Review実行手順

1. **対象の特定**: 引数なし→主要画面を自動検出 / パス指定→該当画面のみ
2. **コード読み込み**: レイアウト、ページ、コンポーネントを読んで構造を把握
3. **ペルソナ適用**: 各画面をLazy Userとして4ステップで評価
4. **スコアリング**: 10カテゴリそれぞれを採点（reference.mdの基準に従う）
5. **修正提案**: TOP 3 + Quick Winsを具体的なコード付きで提示

### 対象画面の自動検出（引数なし時）

```
app/page.tsx              → LP/トップ
app/dashboard/page.tsx    → ダッシュボード
app/login/page.tsx        → 認証
app/**/form*.tsx           → フォーム画面
app/settings/page.tsx     → 設定画面
```

---

## 他スキルとの棲み分け

| スキル | このスキル | そのスキル |
|--------|----------|----------|
| ux-psychology | Lazy Userペルソナでの実践スコアリング | 認知心理学の原則・理論的根拠 |
| web-design-guidelines | 「怠惰ユーザーに使えるか」の判定 | WCAG・aria・HTMLの技術仕様 |
| micro-interaction-patterns | FBの有無・質のスコアリング | Framer Motion実装コード |
| baseline-ui | スコアに基づく改善提案 | UIコンポーネントの基本テンプレート |

---

## Cross-references

- **ux-psychology**: UX原則の理論的根拠（本スキルは実践スコアリング）
- **web-design-guidelines**: WCAG・アクセシビリティ技術仕様
- **micro-interaction-patterns**: Visual Feedback改善のFramer Motion実装
- **baseline-ui**: 改善提案時のコンポーネントテンプレート

## Reference

各カテゴリの詳細採点基準（1-3/4-6/7-8/9-10）、Before/Afterコード例、修正テンプレート5種、画面別チェックリスト、Lazy User Flow Analysisテンプレートは [reference.md](reference.md) 参照。
