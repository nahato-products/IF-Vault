---
name: code-review
description: "Review code systematically with multi-pass review strategy, severity-ranked findings, security/performance/maintainability checklists, PR size optimization, review comment quality standards, and automated review patterns for TypeScript/React/Next.js codebases. Use when reviewing pull requests, conducting code reviews, auditing code quality, checking PR readiness, analyzing code changes for issues, writing constructive review comments, establishing review standards for teams, reducing review turnaround time, prioritizing review findings by severity, or assessing technical debt in changed code. Do not trigger for testing strategy (use testing-strategy), security vulnerability scanning (use security-review), or code refactoring execution (use code-refactoring). Invoke with /code-review."
user-invocable: true
triggers:
  - コードレビューする
  - PRをレビュー
  - コードの品質チェック
  - /code-review
  - review:code
---

# Code Review

`/code-review` で起動。モード選択:

1. **Review** - PR/コードの体系的レビュー実行
2. **Audit** - 既存コードベースの品質監査
3. **Standards** - チームレビュー基準の策定・改善

## When NOT to Apply

- テスト戦略・テスト設計（→ testing-strategy）
- セキュリティ脆弱性スキャン（→ security-review）
- リファクタリング実行（→ code-refactoring）
- 型安全性の設計判断（→ typescript-best-practices）

## Decision Tree

```
PR来た → Review Mode
コード品質調査 → Audit Mode
レビュー基準作り → Standards Mode
セキュリティ懸念 → security-review へ
テスト不足 → testing-strategy へ
リファクタ実行 → code-refactoring へ
```

---

## Review Mode [CRITICAL]

### Multi-Pass Strategy

**4パスで網羅的にレビュー。** 1パスで全部見ようとしない。各パスに集中。

| Pass | Focus | 観点 |
|------|-------|------|
| 1 | Architecture & Design | 設計意図、責務分離、変更の妥当性 |
| 2 | Logic & Correctness | バグ、エッジケース、エラー処理、型安全性 |
| 3 | Security & Performance | 認証・認可、XSS、N+1、再レンダリング |
| 4 | Style & Maintainability | 命名、可読性、テスト、ドキュメント |

#### Pass 1: Architecture & Design（大局観）

最初に diff 全体を俯瞰。個別のコード品質より**設計判断**を見る。

- 変更の目的は PR タイトル・説明と一致しているか
- 責務分離は適切か（1ファイルに複数の関心が混在していないか）
- 既存アーキテクチャのパターンに沿っているか
- 影響範囲は妥当か（関係ないファイルの変更がないか）
- API の後方互換性は保たれているか
- 変更が大きすぎないか（400行超 → 分割を提案）

#### Pass 2: Logic & Correctness（ロジック）

関数・メソッド単位で**正しさ**を検証。

- 条件分岐の網羅性（else の考慮漏れ、switch の default）
- 境界値・エッジケース（空配列、null/undefined、0、負数、空文字）
- 非同期処理（await 漏れ、Promise.all vs Promise.allSettled、競合状態）
- エラーハンドリング（try-catch の範囲、エラー握りつぶし、ユーザー向けメッセージ）
- 型安全性（`any` の使用、型ガード、Zod バリデーション）
- 不変性（意図しない副作用、参照の共有）

#### Pass 3: Security & Performance（非機能）

セキュリティとパフォーマンスの観点。**1つでも 🔴 Critical があればマージ不可。**

**Security:**
- 入力バリデーション（サーバーサイド必須、クライアントだけは NG）
- 認証・認可チェック（API Route / Server Action に認可ガードがあるか）
- XSS ベクター（`dangerouslySetInnerHTML`、ユーザー入力の直接レンダリング）
- CSRF 対策（状態変更操作に適切なトークン）
- 機密情報の露出（クライアントに渡すデータ、ログ出力、エラーメッセージ）
- SQL/NoSQL インジェクション（Prepared Statements / ORM 経由か）

**Performance:**
- N+1 クエリ（ループ内の DB/API 呼び出し）
- 不要な再レンダリング（useMemo / useCallback の要否、コンポーネント分割）
- バンドルサイズ影響（重いライブラリの追加、dynamic import の検討）
- 画像最適化（next/image 使用、適切なサイズ・フォーマット）
- キャッシュ戦略（ISR / SWR / React Query の staleTime）

#### Pass 4: Style & Maintainability（可読性）

最後に可読性・保守性。ここは nit が多いが、チーム全体のコード品質に関わる。

- 命名（意図が伝わるか、プロジェクトの規約に沿っているか）
- 関数の長さ（30行超は分割を検討）
- コメント（Why を説明しているか、What を繰り返していないか）
- テスト（新機能にテストがあるか、既存テストが壊れていないか）
- import 整理（未使用 import、import 順序）
- マジックナンバー・ハードコード値

### Finding Severity Levels [CRITICAL]

| Level | Label | Action | 例 |
|-------|-------|--------|----|
| 🔴 Critical | must-fix | ブロッキング。マージ不可 | セキュリティ脆弱性、データ損失リスク、本番障害 |
| 🟡 Major | should-fix | 強く推奨。理由あればスキップ可 | バグの可能性、パフォーマンス問題、設計改善 |
| 🔵 Minor | nit | 改善提案。修正は任意 | 命名改善、コードスタイル、リファクタ提案 |
| 💭 Question | question | 意図確認。理解のための質問 | 設計意図、代替案の検討有無 |

**判定基準:**
- ユーザーデータに影響 → 🔴
- 本番で問題になりうる → 🟡
- コード品質向上のみ → 🔵
- 判断できない（情報不足） → 💭

### Review Comment Quality [CRITICAL]

**良いレビューコメントの条件:**

1. **問題 + 改善案**をセットで提示（指摘だけで終わらない）
2. **なぜ**を説明（教育的コメント — 相手の成長に繋がる）
3. **Before/After** コード例を含める（具体的に）
4. **良い点にも言及**（ポジティブフィードバック — 最低1つ）
5. **severity を明示**（修正必須か任意かを曖昧にしない）

```
// BAD: 指摘だけ
「ここ any 使ってますよ」

// GOOD: 問題 + 理由 + 改善案
🟡 [should-fix] `any` 型が使われています。
型安全性が失われ、ランタイムエラーの原因になります。

Before:
const data: any = await fetchUser(id)

After:
const data: User = await fetchUser(id)
// or unknown + 型ガード
const data: unknown = await fetchUser(id)
if (isUser(data)) { ... }
```

### Output Format [HIGH]

レビュー結果は `~/.claude/tmp/review-$(date +%Y%m%d-%H%M%S).md` に保存。

```markdown
# Code Review: {PR タイトル or ファイル名}
Date: {YYYY-MM-DD}

## Summary
{全体の評価を1-2文で}

## Positive Feedback
- {良い点1}
- {良い点2}

## Findings

### 🔴 Critical
#### CR-001: {タイトル}
**File:** `path/to/file.ts:42`
**Pass:** Security & Performance
**Description:** {問題の説明}
**Impact:** {影響}
**Suggestion:**
{Before/After コード例}

### 🟡 Major
...

### 🔵 Minor
...

### 💭 Questions
...

## Statistics
| Severity | Count |
|----------|-------|
| 🔴 Critical | 0 |
| 🟡 Major | 0 |
| 🔵 Minor | 0 |
| 💭 Question | 0 |

## Verdict
{APPROVE / REQUEST_CHANGES / COMMENT}
- APPROVE: 🔴 なし、🟡 が0-1個
- REQUEST_CHANGES: 🔴 が1個以上、または 🟡 が3個以上
- COMMENT: 🟡 が2個、または 💭 のみ
```

---

## Audit Mode [HIGH]

### Codebase Quality Metrics

既存コードベースの品質を体系的に評価。PR レビューではなく**全体の健全性**を診断。

#### Complexity Hotspots

- **Cyclomatic Complexity**: 分岐の多い関数を特定（10超は要注意、20超はリファクタ必須）
- **Cognitive Complexity**: 人間が理解しにくいコード（ネスト深度、early return の不足）
- **File Size**: 300行超のファイルは責務分離を検討
- **Function Length**: 30行超の関数は分割候補

```bash
# 大きいファイルの特定
find src -name '*.ts' -o -name '*.tsx' | xargs wc -l | sort -rn | head -20
```

#### Dependency Analysis

- **Coupling**: モジュール間の依存度（import の方向性、循環参照）
- **Fan-out**: 1ファイルからの import 数（10超は依存しすぎ）
- **Abstraction Level**: 具象への依存 vs インターフェースへの依存

#### Test Coverage Gaps

- カバレッジレポートから未テストの critical path を特定
- テストファイルがないモジュールの洗い出し
- テストはあるが assertion が弱いケース（`toBeDefined` のみ等）

#### Technical Debt Inventory

| カテゴリ | 指標 | 閾値 |
|---------|------|------|
| TODO/FIXME | コメント数 | 10個超で棚卸し |
| `any` 型 | 使用箇所数 | 0が理想、5個超で対応計画 |
| 未使用コード | dead code | 即削除候補 |
| 古い依存 | outdated packages | セキュリティパッチは即対応 |
| eslint-disable | 抑制数 | 各理由を確認 |

### Audit Output [HIGH]

監査結果は `~/.claude/tmp/audit-$(date +%Y%m%d-%H%M%S).md` に保存。

```markdown
# Code Audit Report
Date: {YYYY-MM-DD}
Scope: {対象ディレクトリ / リポジトリ}

## Executive Summary
{全体スコア: A/B/C/D/F + 1行サマリー}

## Metrics
| Metric | Value | Status |
|--------|-------|--------|
| Total Files | | |
| Avg File Size | | |
| Complexity Hotspots (>10) | | |
| Test Coverage | | |
| `any` Usage | | |
| TODO/FIXME Count | | |

## Hotspots (Top 10)
{複雑度・サイズ・変更頻度の高いファイル}

## Technical Debt
{カテゴリ別の debt リスト + 優先度}

## Recommendations
{優先順位付きの改善アクション}
```

---

## Standards Mode [MEDIUM]

### Team Review Guidelines

チームのレビュー文化を構築・改善するためのテンプレートと指針。

#### Review SLA

| PR サイズ | 初回レビュー目標 | 完了目標 |
|----------|----------------|---------|
| S (< 100行) | 当日 | 1営業日以内 |
| M (100-400行) | 1営業日以内 | 2営業日以内 |
| L (400行超) | 分割を依頼 | — |

#### PR Size Guidelines [HIGH]

- **推奨**: 400行以下（レビュー品質が維持できる上限）
- **理想**: 200行前後（集中力が保てる範囲）
- **巨大PR**: 分割戦略を提案
  - 機能単位で分割
  - レイヤー単位（DB → API → UI）
  - リファクタと機能追加を分離

#### Review Checklist Customization [MEDIUM]

プロジェクト固有のチェック項目を追加可能:

```markdown
## Project-Specific Checks
- [ ] i18n: 新しい文字列はすべて翻訳キーを使用
- [ ] a11y: インタラクティブ要素に適切な aria ラベル
- [ ] Analytics: 主要アクションにイベントトラッキング
- [ ] Feature Flag: 新機能はフラグで制御可能
```

#### Reviewer Assignment [MEDIUM]

- **CODEOWNERS** ファイルで自動アサイン
- ドメイン知識のあるメンバーを1人 + コードオーナー1人
- セルフレビューチェックリスト完了後にレビュー依頼

---

## Quick Checklist [CRITICAL]

**全レビューで必ず確認する項目:**

- [ ] 変更の目的が明確（PRタイトル・説明と一致）
- [ ] 影響範囲が適切（関係ないファイルの変更がない）
- [ ] エラーハンドリング（異常系の考慮）
- [ ] セキュリティ（入力バリデーション、認証・認可）
- [ ] パフォーマンス（N+1、不要な再レンダリング、バンドルサイズ）
- [ ] テスト（新機能にテストがあるか、既存テストが壊れていないか）
- [ ] 型安全性（`any` の使用、型ガードの適切さ）
- [ ] 命名・可読性（意図が伝わる命名か）

---

## PR Analysis Workflow [HIGH]

### Step 1: Context 把握

```bash
# PR の変更概要を確認
gh pr view {number} --json title,body,files,additions,deletions
# diff を取得
gh pr diff {number}
# 変更ファイル一覧
gh pr view {number} --json files --jq '.files[].path'
```

### Step 2: サイズ判定

| 変更行数 | サイズ | レビュー戦略 |
|---------|--------|------------|
| < 50 | XS | Quick review、全パス一括 |
| 50-200 | S | 4パス、各パス軽量 |
| 200-400 | M | 4パス、各パスしっかり |
| 400+ | L | 分割依頼 or ファイルグループ単位 |

### Step 3: 4-Pass Review 実行

Pass 1 → 2 → 3 → 4 の順で実行。各パスの findings を severity 付きで記録。

### Step 4: Output 生成

findings をまとめ、verdict を決定。`~/.claude/tmp/review-$(date +%Y%m%d-%H%M%S).md` に保存。

---

## Automated Review Patterns [MEDIUM]

### Pre-Review Checks（レビュー前の自動チェック）

レビュアーの負荷軽減のため、機械的にチェック可能な項目は自動化:

```bash
# TypeScript コンパイルエラー
pnpm tsc --noEmit
# Lint
pnpm eslint --max-warnings 0
# テスト
pnpm vitest run
# 型チェック
pnpm tsc --noEmit --strict
```

**自動化すべき項目:**
- lint / format（CI で強制）
- 型チェック（CI で強制）
- テスト実行（CI で強制）
- PR サイズ警告（400行超で bot コメント）
- セキュリティスキャン（依存関係の脆弱性）

**人間が見るべき項目:**
- 設計判断の妥当性
- ビジネスロジックの正しさ
- 命名・抽象化の適切さ
- エッジケースの網羅性

---

## Reference

Multi-pass 詳細テンプレート、アンチパターン集、レビューコメント例、Audit レポートテンプレート、Technical Debt スコアリングは [reference.md](reference.md) を参照。

## Cross-references

- **skill-forge**: レビュー方法論・Multi-Pass 戦略の応用元
- **testing-strategy**: テスト品質の評価
- **_code-refactoring**: リファクタリングパターン・レビュー指摘の実装
- **typescript-best-practices**: 型安全性レビューの判断基準
- **_security-review**: セキュリティ監査・脆弱性の深掘り
