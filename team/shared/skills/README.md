# チーム共有 Skills ガイド

guchiが作成・最適化した Claude Code Skills のセットアップと使い方。Claude Codeを使うメンバー全員が対象。

全スキルは skill-forge の10項目100点レビューで品質担保済み（全24スキル 100/100 達成）。

## 共有スキル一覧

### Tier 1: 全員必須（日常で自動発火）

| Skill | 何をしてくれるか | 発火タイミング | スコア |
|-------|----------------|--------------|--------|
| ux-psychology | UIの品質を心理学ベースでチェック・提案 | UI作業で自動 | 100/100 |
| natural-japanese-writing | 日本語ドキュメントからAI臭を排除 | Markdown執筆で自動 | 100/100 |
| ansem-db-patterns | PostgreSQL DB設計パターンをガイド | DB設計で自動 | 100/100 |

### Tier 2: 開発者向け推奨

| Skill | 何をしてくれるか | 発火タイミング | スコア |
|-------|----------------|--------------|--------|
| typescript-best-practices | TypeScript設計パターンをガイド | TS/JSファイル操作時 | 100/100 |
| testing-strategy | TDD・テスト品質・Playwrightをガイド | テスト作業時 | 100/100 |
| systematic-debugging | 4フェーズのデバッグ手順を強制 | バグ発生時 | 100/100 |
| error-handling-logging | Next.jsのエラーハンドリングをガイド | エラー処理実装時 | 100/100 |
| security-review | セキュリティ脆弱性を体系的にレビュー | `/security-review` で手動起動 | 100/100 |
| supabase-auth-patterns | Supabase Auth・RLS設計をガイド | 認証実装時 | 100/100 |

全て手動操作なしで自動発火する（security-reviewのみ手動起動）。

---

## Tier 1 詳細

### ux-psychology — UIを触るとき自動で効く

29の認知心理学原則とニールセンの10ヒューリスティクスをベースに、UIの設計と実装をガイドする。「なぜそうすべきか」を教えてくれる（実装のHOWは web-design-guidelines が担当）。

**発火する場面**: フォーム作成、ボタン配置（フィッツの法則）、ローディング状態、モーダル、通知/トースト、ダッシュボード、AI機能のUI、ニューロダイバーシティ対応

**発火しない場面**: バックエンドロジック、DB設計、CI/CD設定、テストコード

| ファイル | 行数 | 中身 |
|---------|------|------|
| SKILL.md | 399行 | 29原則+10ヒューリスティクス（8パート構成） |
| reference.md | 534行 | UIパーツ設計、AI UX、アンチパターン集、チェックリスト |

---

### natural-japanese-writing — 日本語を書くとき自動で効く

AI生成テキストに共通する28の不自然パターンを検出・排除する。全ルールにR1-R28の通し番号が付いていて、reference.mdと完全対応。

**排除するパターン（抜粋）**

| パターン | 例 | 対処 |
|---------|-----|------|
| 括弧依存 | Aを（Bの場合は）Cする | 括弧の中身を本文に溶かす |
| 語尾連続 | 〜する。〜する。〜する。 | 体言止めや疑問形を混ぜる |
| 安全クッション | 一般的には〜と言われています | 削除して断定する |
| 両論逃げ | AもBも一長一短です | スタンスを取って推奨案を書く |
| 前置き宣言 | 以下の3つの観点から説明します | 見出しで伝わるから削除 |
| カタカナ業務用語 | インサイト、レバレッジ | 日本語で言える場合は日本語 |

**発火しない場面**: チャット応答、コードコメント、英語ドキュメント、コミットメッセージ、YAML/JSON

| ファイル | 行数 | 中身 |
|---------|------|------|
| SKILL.md | 186行 | 28ルール(R1-R28)＋セルフチェック |
| reference.md | 463行 | Before/After実例集、ジャンル別注意点 |

---

### ansem-db-patterns — DB設計するとき自動で効く

ANSEM 32テーブルの実践から抽出した23のPostgreSQL設計パターンをガイドする。

**発火する場面**: テーブル設計（命名規則・データ型）、FK削除ポリシー判断、監査カラム設計、楽観ロック、パーティション、集計テーブル（スナップショット方式）

| ファイル | 行数 | 中身 |
|---------|------|------|
| SKILL.md | 334行 | 23パターン（6パート構成） |
| reference.md | 394行 | テンプレート6種、チェックリスト3種、アンチパターン集 |

---

## Tier 2 詳細

### typescript-best-practices — TypeScriptを書くとき自動で効く

型ファースト開発、判別共用体、ブランド型、網羅的ハンドリング、Zodバリデーション、ジェネリクス活用をガイド。Reactコンポーネントやエラーハンドリングは別スキルに委譲。

| ファイル | 行数 | 中身 |
|---------|------|------|
| SKILL.md | 306行 | 19パターン（6パート構成） |
| reference.md | 191行 | tsconfig設定、判別共用体判断表、Zodクックブック、Utility型早見表 |

### systematic-debugging — バグに遭遇したら自動で効く

4フェーズ（調査→パターン分析→仮説検証→実装）の体系的デバッグを強制。3回修正失敗でアーキテクチャ再考を促すエスカレーションルール付き。

| ファイル | 行数 | 中身 |
|---------|------|------|
| SKILL.md | 187行 | 4フェーズ+3-Fix Escalation Rule |
| reference.md | 167行 | Root Cause Tracing、waitFor実装、決定フローチャート |

### testing-strategy — テストを書くとき自動で効く

TDD（Red-Green-Refactor）、テスト品質分析（オーバーモック・フレーキーテスト検出）、Playwright E2Eテストをガイド。

| ファイル | 行数 | 中身 |
|---------|------|------|
| SKILL.md | 280行 | TDD + テスト品質 + Playwright（3パート構成） |
| reference.md | 220行 | テストスメル詳細、Playwrightパターン集 |

### error-handling-logging — エラー処理を実装するとき自動で効く

Next.js の error.tsx / global-error.tsx 階層、カスタムエラークラス、構造化ログ、Sentry統合、APIエラー設計をガイド。

| ファイル | 行数 | 中身 |
|---------|------|------|
| SKILL.md | 319行 | Decision Tree + エラー分類 + Boundary + Sentry + API |
| reference.md | 508行 | Sentry設定3種、エラーテーブル、コード例 |

### security-review — セキュリティレビュー（手動起動）

`/security-review` で起動。OWASP Top 10ベースのコードレビュー。信頼度ベースのレポート出力。

| ファイル | 行数 | 中身 |
|---------|------|------|
| SKILL.md | 287行 | レビュープロセス + 脆弱性パターン + レポート形式 |
| reference.md | 158行 | OWASP Top 10マッピング、Severity判断フロー、チェックリスト |

### supabase-auth-patterns — 認証・RLSを実装するとき自動で効く

Supabase Authの認証フロー（Email/OAuth/Magic Link）、セッション管理、RLSポリシー設計、Next.js Middleware連携をガイド。

| ファイル | 行数 | 中身 |
|---------|------|------|
| SKILL.md | 310行 | 認証フロー + セッション + RLS + API保護 |
| reference.md | 183行 | LINE Login統合、JWT管理、エラーテーブル |

---

## セットアップ

### 初回セットアップ（1回だけ）

IF-Vaultのルートディレクトリで実行する。

```bash
# === Tier 1: 全員必須 ===
ln -s "$(pwd)/team/shared/skills/ux-psychology" ~/.claude/skills/ux-psychology
ln -s "$(pwd)/team/shared/skills/natural-japanese-writing" ~/.claude/skills/natural-japanese-writing
ln -s "$(pwd)/team/shared/skills/ansem-db-patterns" ~/.claude/skills/ansem-db-patterns

# === Tier 2: 開発者向け（必要なものだけ選んでOK）===
# 以下はguchiの ~/.claude/skills/ からコピーしてもらう
# TypeScript開発
# ln -s "$(pwd)/team/shared/skills/typescript-best-practices" ~/.claude/skills/typescript-best-practices
# テスト・デバッグ
# ln -s "$(pwd)/team/shared/skills/testing-strategy" ~/.claude/skills/testing-strategy
# ln -s "$(pwd)/team/shared/skills/systematic-debugging" ~/.claude/skills/systematic-debugging
# エラーハンドリング
# ln -s "$(pwd)/team/shared/skills/error-handling-logging" ~/.claude/skills/error-handling-logging
# セキュリティ
# ln -s "$(pwd)/team/shared/skills/security-review" ~/.claude/skills/security-review
# Supabase認証
# ln -s "$(pwd)/team/shared/skills/supabase-auth-patterns" ~/.claude/skills/supabase-auth-patterns
```

作成後、Claude Codeを再起動すれば使える。

### 更新

`git pull` するだけで全メンバーに反映される。シンボリックリンクの再作成は不要。

### 無効化

使いたくない場合はリンクを削除する。

```bash
rm ~/.claude/skills/ux-psychology
```

---

## guchiが管理している全Skills

全38個。自作24個＋コミュニティ14個。自作はすべて skill-forge の10項目レビューで100点満点に最適化済み。

### 自作Skills全一覧（スコア順）

| Skill | スコア | カテゴリ |
|-------|--------|---------|
| ansem-db-patterns | 100 | DB |
| chrome-extension-dev | 100 | 開発 |
| ci-cd-deployment | 100 | インフラ |
| dashboard-data-viz | 100 | UI |
| design-token-system | 100 | UI |
| docker-expert | 100 | インフラ |
| error-handling-logging | 100 | 品質 |
| line-bot-dev | 100 | 開発 |
| micro-interaction-patterns | 100 | UI |
| mobile-first-responsive | 100 | UI |
| natural-japanese-writing | 100 | ライティング |
| nextjs-app-router-patterns | 100 | フレームワーク |
| obsidian-power-user | 100 | ツール |
| react-component-patterns | 100 | UI |
| security-review | 100 | セキュリティ |
| supabase-auth-patterns | 100 | 認証 |
| supabase-postgres-best-practices | 100 | DB |
| systematic-debugging | 100 | 品質 |
| tailwind-design-system | 100 | UI |
| testing-strategy | 100 | 品質 |
| typescript-best-practices | 100 | 開発 |
| ux-psychology | 100 | UX |
| vercel-react-best-practices | 100 | パフォーマンス |
| web-design-guidelines | 100 | UI |

### Skillsの作り方

`/skill-forge` コマンドで起動するメタスキルを使う。8フェーズのCreate Modeで要件定義から品質レビューまで一気通貫で作成できる。10項目100点満点の品質スコアリングで品質を担保する。

新しいSkillを作りたくなったらguchiに相談。

---

## ファイル構成

```
team/shared/skills/
├── README.md                          <- このファイル
├── ux-psychology/
│   ├── SKILL.md                       <- 399行
│   └── reference.md                   <- 534行
├── natural-japanese-writing/
│   ├── SKILL.md                       <- 186行
│   └── reference.md                   <- 463行
└── ansem-db-patterns/
    ├── SKILL.md                       <- 334行
    └── reference.md                   <- 394行
```

> [!TIP]
> Tier 2 のスキルを共有フォルダに追加したい場合は、guchiの `~/.claude/skills/` から該当ディレクトリをコピーしてこのフォルダに配置し、上のセットアップコマンドのコメントを外す。
