# Skill Forge — Reference

SKILL.md の補足資料。テンプレート、カテゴリ別キーワード、スコアリング詳細、アンチパターン。

---

## Description テンプレート集

### UI/UX系
```
Guides [specific area] design and implementation using [methodology]. Covers [scope]. Use when designing, implementing, fixing, or improving [component list], or conducting [review type].
```

### 開発ワークフロー系
```
[Action]s [workflow area] following [methodology]. Use when [specific triggers], managing [specific items], or setting up [specific configs].
```

### セキュリティ系
```
Reviews code for [vulnerability types] following [standard]. Use when reviewing [code types], auditing [specific areas], or checking [security concerns].
```

### テスト系
```
Guides [test type] using [framework]. Use when writing, reviewing, or debugging [test types], setting up [test infrastructure], or analyzing [test quality].
```

### DB/インフラ系
```
Best practices for [technology] including [specific areas]. Use when designing, optimizing, or troubleshooting [specific components].
```

### ドキュメント処理系
```
[Action]s [document type] files. Use when creating, reading, editing, or converting [file types], extracting [data types], or generating [output types].
```

---

## Description 実例集

### 良い例

**UI/UX系（525文字）**:
```
Guides UI/UX design and implementation using cognitive psychology principles, Nielsen's heuristics, and anti-patterns. Covers AI UX and neurodiversity. Use when designing, implementing, fixing, or improving UI components, forms, buttons, navigation, modals, dialogs, notifications, toasts, user flows, onboarding, error handling, validation, loading states, skeleton UI, empty states, responsive layouts, dashboards, data tables, search UI, design systems, dark mode, animations, accessibility, usability, AI features, or conducting UX reviews and audits.
```
→ 動詞5個、具体的コンポーネント20+、"Use when"あり、手動起動ではないので"Invoke with"なし

**セキュリティ系（引用符パターン）**:
```
Security code review for vulnerabilities. Use when asked to "security review", "find vulnerabilities", "check for security issues", "audit security", "OWASP review", or review code for injection, XSS, authentication, authorization, cryptography issues.
```
→ 引用符でユーザーの実際の入力パターンをカバー

### 悪い例

| 例 | 問題 |
|-----|------|
| `Helps with UI best practices.` | 動詞なし、"Use when"なし、具体性ゼロ |
| `Webアプリのセキュリティを確認します。` | 日本語のみ、トリガーエンジンが認識しない |
| `A comprehensive guide to everything about testing.` | "Use when"なし、キーワード不足 |

---

## カテゴリ別トリガーキーワード

### UI/UX
designing, implementing, fixing, improving, reviewing, forms, buttons, navigation, modals, dialogs, notifications, toasts, tables, dashboards, search, filters, layouts, responsive, accessibility, animations, design system, dark mode, user flows, onboarding, error handling, validation, loading states, skeleton UI, empty states, usability

### 開発ワークフロー
git, branch, merge, rebase, commit, pull request, code review, debugging, refactoring, deployment, CI/CD, workflow, worktree, bisect, cherry-pick

### セキュリティ
security, vulnerability, injection, XSS, CSRF, authentication, authorization, encryption, OWASP, audit, review, secrets, credentials

### DB
database, query, index, migration, schema, performance, PostgreSQL, SQL, optimization, replication, partitioning, VACUUM

### テスト
test, testing, unit test, integration test, e2e, playwright, coverage, mock, assertion, TDD, flaky, test quality

### デザイン
design, color, typography, animation, motion, layout, visual, brand, marketing, asset, image

### モバイル/プラットフォーム
iOS, Android, mobile, responsive, HIG, Material Design, SwiftUI, accessibility, touch, gesture

---

## SKILL.md 構造テンプレート

### 自動発火型

```markdown
---
name: [skill-name]
description: [説明]. Use when [トリガー列挙].
user-invocable: false
---

# [タイトル]

## When to Apply
- [条件1]
- [条件2]

## When NOT to Apply
- [除外条件1]

---

## Part 1: [カテゴリ] [CRITICAL]

### 1. [原則名]
[説明1行]
- [アクション]
- [アクション]

---

## Reference
詳細は [reference.md](reference.md) を参照。
```

### 手動起動型

```markdown
---
name: [skill-name]
description: [説明]. Use when [トリガー]. Invoke with /[name].
user-invocable: true
---

# [タイトル]

`/[name]` で起動。モード選択:
1. **Mode A** - [説明]
2. **Mode B** - [説明]

---

## Mode A
[ワークフロー]

---

## Reference
詳細は [reference.md](reference.md) を参照。
```

---

## 10項目スコアリング詳細

| # | 項目 | 10点 | 8-9点 | 6-7点 | 改善アクション |
|---|------|------|-------|-------|---------------|
| 1 | Trigger Accuracy | 確実に発火、誤発火なし | エッジケースで漏れ | 表現違いで漏れる | 動詞・コンポーネント名追加 |
| 2 | Content Accuracy | 全事実が一次ソースと一致 | 軽微な不正確さ1-2箇所 | 重要な数値に誤り | 公式ドキュメントで全数値検証 |
| 3 | Content Completeness | 主要トピック全カバー | 1-2トピック欠落 | 明らかな穴あり | チェックリストで抜けを特定 |
| 4 | Token Efficiency | 全行が価値を持つ | 軽微な冗長性 | 明らかな重複あり | reference.md移動、圧縮 |
| 5 | Actionability | 即実装/判断可能 | 一部抽象的 | 実装指示不足 | 数値・コード例を追加 |
| 6 | Structure | 論理的、優先度タグ完備 | 一部セクション弱い | フラット/深すぎ | 優先度タグ追加、h3制限 |
| 7 | Cross-reference | 有効で意外な関連性 | 正確だが一部自明 | ミス/自明が多い | 連続性チェック、自明を削除 |
| 8 | Spec Compliance | 完全準拠 | 推奨事項レベルの非準拠 | 必須仕様に違反 | Phase 8チェックリスト確認 |
| 9 | reference.md Quality | 全情報が整理済み | 1-2セクション不足 | 薄い/構成悪い | テンプレ・チェックリスト追加 |
| 10 | Differentiation | 独自の価値を提供 | 一部既存と重複 | 差別化が弱い | 独自フレームワーク・データ追加 |

---

## アンチパターン集

### Skill設計

| パターン | 問題 | 対策 |
|----------|------|------|
| メガスキル | 全部詰め込んで500行超え | スコープを絞る、reference.mdに分離 |
| 空気スキル | 抽象的アドバイスだけで具体性ゼロ | 数値・コード例・具体的手順を追加 |
| コピペスキル | ドキュメントをそのまま貼っただけ | 構造化・要約・相互参照を設計 |
| 自己参照地獄 | 参照だらけで本文が薄い | 各セクションが独立して読めるように |
| 時限爆弾 | 日付やバージョン番号が入っている | 時間依存情報を全て削除 |

### Description

| パターン | 問題 | 対策 |
|----------|------|------|
| 曖昧すぎ | "Helps with best practices" | 具体的なキーワード列挙 |
| 短すぎ | 50文字以下 | トリガーキーワードを追加 |
| 日本語のみ | トリガーエンジンが英語ベース | 英語で書く |
| Use when なし | 発火条件が不明確 | "Use when..." パターンを追加 |

### 構造

| パターン | 問題 | 対策 |
|----------|------|------|
| フラット | 見出しなしの箇条書き羅列 | h2/h3で論理的に区分 |
| 深すぎ | h4/h5まで使う | h3までに制限 |
| reference.md不使用 | 500行に収まらず内容を削る | reference.mdに分離 |
| reference.md丸投げ | SKILL.mdがスカスカ | 核心はSKILL.mdに残す |

---

## Acquire & Optimize ギャップ分析

### 分析テンプレート

| 観点 | 既存Skill | 自分の要件 | ギャップ |
|------|-----------|-----------|----------|
| トリガーキーワード | | | |
| カバー範囲 | | | |
| 具体性（数値・コード例） | | | |
| 構造（見出し・優先度タグ） | | | |
| reference.md の充実度 | | | |

### よくある最適化パターン

| 取得したSkillの問題 | 対策 |
|---------------------|------|
| descriptionのキーワード不足 | 自分のユースケースの動詞・名詞を追加 |
| 内容が薄い | 詳細・コード例をreference.mdに追加 |
| 優先度タグなし・h4使用 | セクション再編、[CRITICAL]/[HIGH]/[MEDIUM]追加 |
| 汎用的すぎる | プロジェクト固有の原則・パターンを追加 |
| reference.mdがない | 新規作成してチェックリスト・テンプレートを分離 |

---

## コマンドリファレンス

```bash
# 検索: Claude Code内で /find-skills コマンドを実行
# またはGitHubでスキルリポジトリを直接検索

# インストール: リポジトリをクローンしてskillsディレクトリに配置
git clone <repo-url> ~/.claude/skills/<skill-name>
# またはシンボリックリンクで配置
ln -s ~/.agents/skills/<skill-name> ~/.claude/skills/<skill-name>

# アップデート: スキルディレクトリ内でgit pull
cd ~/.claude/skills/<skill-name> && git pull

# バリデーション: SKILL.mdのフロントマターを手動確認
# name, description, user-invocable 等が正しいかチェック

# アンインストール: ディレクトリまたはシンボリックリンクを削除
rm -rf ~/.claude/skills/<skill-name>

# インストール済み一覧
ls ~/.claude/skills/
```

---

## 品質チェック用コマンド

```bash
# SKILL.mdの行数
wc -l ~/.claude/skills/[name]/SKILL.md

# descriptionの文字数
grep -o 'description: .*' ~/.claude/skills/[name]/SKILL.md | wc -c

# reference.mdの存在確認
ls ~/.claude/skills/[name]/reference.md

# 全Skillの行数一覧
for d in ~/.claude/skills/*/; do echo "$(wc -l < "$d/SKILL.md" 2>/dev/null || echo 0) $(basename $d)"; done | sort -rn
```

---

## 55個運用の実践知

実際に55個のSkillsを管理して得た知見と失敗パターン。以下の数値は経験則であり、プロジェクトにより異なる。

### 運用で得た10の知見

1. **1スキル1責務**: 多機能スキルは使われなくなる。用途を絞って分割した方が使用頻度が上がる
2. **reference.mdの最適サイズは800-2000行**: 800行未満は情報不足、2000行超はトークン消費が大きく応答が遅い
3. **コミュニティスキルはフォークして使う**: そのまま使うのではなく、自分のコンテキストを追加してカスタマイズ
4. **「読み物」と「辞書」を分ける**: reference.mdの冒頭300行に原則、以降に辞書的な情報を配置。Claudeは冒頭を重視する
5. **スキルの「寿命」を意識する**: プロジェクト固有（1-3ヶ月）、技術スタック固有（3-12ヶ月）、普遍的原則（1年以上）
6. **エラーハンドリングをreference.mdに書く**: よくあるエラーと対処法を明記するとClaudeが自律回復できる
7. **バージョン管理はGitで**: `~/.claude/skills/` をgit initして変更を追跡。失敗したカスタマイズをrevertできる
8. **descriptionは英語で書く**: トリガーエンジンが英語ベース。日本語で書くと発火しない
9. **同時発火の合計行数を2000行以内に**: 超えると体感で応答速度に影響が出始める
10. **週1でヘルスチェック**: 行数超過、description不足、reference.md欠落を自動スキャン

### よくある5つの失敗パターン

#### 失敗1: 万能スキルの作成
「全プログラミング言語に対応する万能コーディングスキル」を作成。reference.mdが5000行超になり起動が遅く、Python案件でRustの話が混入して精度低下。言語ごとに分けるべき。

#### 失敗2: 自動化しすぎ
「コード変更を検知したら自動でコミット」するスキル。WIPの状態で大量のコミットが作られ、メッセージが「Update」の連続でGit履歴が汚染。人間の判断が必要な箇所は残す。

#### 失敗3: 抽象原則だけのスキル
「シニアエンジニアの思考法」を詰め込んだスキル。具体例なしで「スケーラビリティを常に考える」だけでは、Claudeが何をすればいいか分からない。チェックリストやコード例が必須。

#### 失敗4: 年号入りスキルの陳腐化
「2023年のフロントエンド最新技術」が1年後に古くなった。スキル名に年号を入れず、トレンドではなく原則を中心に書く。

#### 失敗5: 空テンプレートスキル
プレースホルダーだけのテンプレートスキル。何を書けばいいか分からず使われない。テンプレートより「充実した実例」を用意してカスタマイズする方が早い。

### コミュニティスキルの品質分布（55個運用からの推定、サンプル偏りあり）

| reference.md行数 | 割合 | 評価 |
|---|---|---|
| 0-300行 | 35% | 情報不足で実用性低い |
| 300-800行 | 25% | 軽量で使いやすい |
| 800-2000行 | 30% | 最適ゾーン |
| 2000行以上 | 10% | 重すぎる可能性 |

| description文字数 | 割合 | 所見 |
|---|---|---|
| 0-50文字 | 40% | 短すぎ。トリガーキーワード不足 |
| 50-300文字 | 30% | 最低限。自動発火型でシンプルなスコープ向き |
| 300-700文字 | 20% | 推奨ゾーン。網羅的なトリガーと差別化の両立 |
| 700文字以上 | 10% | 焦点がぼけるリスク。1024文字制限に注意 |

**結論**: 「浅くて使われる」「深くて使われる」の二極化が正解。中途半端な500行スキルは使われない傾向。
