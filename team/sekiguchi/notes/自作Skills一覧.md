---
date: 2026-02-17
tags: [Claude Code, Skills, 自作, チーム共有]
status: active
---

# 自作Skills 全24スキル

skill-forgeの10項目100点レビューで全スキル品質担保済み。全24スキルをIF-Vault `team/shared/skills/` でチーム共有化。

skill-forgeはメタスキル（Skillsを作るSkills）なので共有対象外。個人環境のみ。

> [!tip] 関連ノート
> - [[Claude-Code-Skills一覧]] — 全Skills統合リスト（インストール済み55個＋HOLD＋未インストールカタログ）
> - [[Skills-49個スキャンレポート]] — v2.7時点の品質スキャン結果

---

## Tier 1: 全員必須（6個）

日常で最も発火する基盤系。全メンバー必須。

### ux-psychology

UIを触る作業で自動発火する認知心理学ベースのUX設計スキル。

| 項目 | 値 |
|------|-----|
| 発火方式 | 自動 |
| SKILL.md | 404行 |
| reference.md | 533行 |

29原則＋ニールセン10ヒューリスティクス＋AI UXパターン＋ニューロダイバーシティを8パートで構成。認知心理学の「なぜそうすべきか」に特化し、「どう実装するか」は他スキルに委譲。

### natural-japanese-writing

Markdown日本語文を書くとき自動発火。AI生成テキスト特有のパターンを排除する。

| 項目 | 値 |
|------|-----|
| 発火方式 | 自動 |
| SKILL.md | 187行 |
| reference.md | 463行 |

R1-R28の28ルールを6パートに分類。全ルールにx(悪い例)→o(良い例)付き。reference.mdに全ルールのBefore/After集、AI臭スコアリング（5段階）、ジャンル別注意点を収録。187行で28ルールを収める驚異のトークン効率。

### ansem-db-patterns

PostgreSQLのテーブル設計やDDL作成で自動発火。ANSEM 32テーブルの実践知を抽出。

| 項目 | 値 |
|------|-----|
| 発火方式 | 自動 |
| SKILL.md | 334行 |
| reference.md | 394行 |

22パターンを6パートに分類。DDLテンプレート6種、FK削除ポリシー判断フロー、チェックリスト3種、アンチパターン集を収録。完全オリジナルの実践知で独自性が高い。

### typescript-best-practices

TypeScript型設計やコードレビューで自動発火。

| 項目 | 値 |
|------|-----|
| 発火方式 | 自動 |
| SKILL.md | 307行 |
| reference.md | 198行 |

discriminated unions、branded types、exhaustive switch、Zod runtime validation等19パターンを6パートで構成。言語レベルの型パターンに特化し、フレームワーク固有の型は各専門スキルに委譲。

### systematic-debugging

バグ診断や原因追跡で自動発火。4段階の根本原因調査プロセス。

| 項目 | 値 |
|------|-----|
| 発火方式 | 自動 |
| SKILL.md | 181行 |
| reference.md | 184行 |

Phase 1(調査)→Phase 2(パターン分析)→Phase 3(仮説検証)→Phase 4(修正検証)の4段階メソッド。git bisect、境界ロギング、単一変数仮説テスト、3回修正ルールを体系化。

### error-handling-logging

エラー境界やロギング設計で自動発火。Next.js App Router特化。

| 項目 | 値 |
|------|-----|
| 発火方式 | 自動 |
| SKILL.md | 319行 |
| reference.md | 548行 |

AppErrorクラス階層、error.tsx/global-error.tsx境界、構造化JSONロギング、Sentry連携、API標準エラーレスポンスを8セクションで構成。Decision Treeが入口にあり、どのパターンを使うべきか即座に判断できる。

---

## Tier 2: 開発者推奨（10個）

プロジェクト開発で頻繁に使う。担当領域に合わせて選択。

### nextjs-app-router-patterns

| SKILL.md | reference.md | 発火タイミング |
|----------|-------------|--------------|
| 486行 | 472行 | ルート設計・キャッシュ戦略決定時 |

App Router 15のルーティング、データフェッチ、キャッシュ(ISR/PPR/use cache)、Suspense streaming、Server Actions、Middleware、error.tsx/not-found.txパターン。

### react-component-patterns

| SKILL.md | reference.md | 発火タイミング |
|----------|-------------|--------------|
| 471行 | 458行 | コンポーネント設計・リファクタリング時 |

Compound components、asChild/Slot、CVAバリアント、React Hook Form + Zod + Server Actions、SC/CC境界設計。コンポーネントの「内部設計」に特化。

### tailwind-design-system

| SKILL.md | reference.md | 発火タイミング |
|----------|-------------|--------------|
| 190行 | 649行 | Tailwindユーティリティ・バリアント構築時 |

Tailwind v4 CSS-first @theme設定、CVAコンポーネント、container queries、@utility、dark mode、cn()。Token Efficiency改善でSKILL.mdを190行に圧縮、コード例をreference.mdに集約。

### testing-strategy

| SKILL.md | reference.md | 発火タイミング |
|----------|-------------|--------------|
| 273行 | 417行 | テスト設計・バグ修正時テスト作成時 |

TDD Red-Green-Refactorサイクル、テスト品質分析、AAA、Mock境界ルール、Playwright E2E。全コード例がTypeScript/Vitest統一。

### supabase-auth-patterns

| SKILL.md | reference.md | 発火タイミング |
|----------|-------------|--------------|
| 356行 | 369行 | 認証フロー・RLSポリシー実装時 |

認証フロー（email/OAuth/Magic Link/LINE Login OIDC）、セッション管理、JWT検証、RLS設計（USING/WITH CHECK）、Middleware auth guard。

### supabase-postgres-best-practices

| SKILL.md | reference.md | 発火タイミング |
|----------|-------------|--------------|
| 329行 | 673行 | SQL最適化・遅いクエリ診断時 |

インデックス戦略(B-tree/GIN/GiST/BRIN)、EXPLAIN ANALYZE、Supavisor接続プール、RLS性能最適化、同時実行制御。ansem-db-patternsとは「設計 vs ランタイム性能」で棲み分け。

### vercel-react-best-practices

| SKILL.md | reference.md | 発火タイミング |
|----------|-------------|--------------|
| 328行 | 358行 | バンドル削減・再レンダリング抑制時 |

async request waterfall排除、JSバンドルサイズ削減、Core Web Vitals(LCP/INP/CLS)、React再レンダリング最適化、next/image・next/font設定。CWV目標値テーブルと診断Decision Tree追加。

### security-review

| SKILL.md | reference.md | 発火タイミング |
|----------|-------------|--------------|
| 234行 | 143行 | `/security-review`で手動起動 |

OWASP Top 10ベースの脆弱性検出。Confidence Levels(HIGH/MEDIUM/LOW)分類、Do Not Flagリスト、Severity Decision Tree。user-invocable:falseに変更済み（自動発火に対応）。

### ci-cd-deployment

| SKILL.md | reference.md | 発火タイミング |
|----------|-------------|--------------|
| 277行 | 379行 | パイプライン構築・デプロイ設定時 |

GitHub Actions workflow、Vercel preview/production deploy、環境変数管理、trunk-basedブランチ戦略、Dependabot、rollback。

### docker-expert

| SKILL.md | reference.md | 発火タイミング |
|----------|-------------|--------------|
| 291行 | 294行 | Dockerfile作成・イメージサイズ削減時 |

Multi-stage build、distroless/alpine最適化、docker-compose、non-rootユーザー、health check。言語別Dockerfileテンプレート付き。

---

## Tier 3: 専門特化（6個）

特定ドメインで発火。担当プロジェクトに応じて導入。

### dashboard-data-viz

| SKILL.md | reference.md | 発火タイミング |
|----------|-------------|--------------|
| 350行 | 663行 | ダッシュボード構築・データ表示設計時 |

サイドバーレイアウト、KPIカード、TanStack Table、Recharts/Tremor、Supabase Realtime、フィルタパターン、エクスポート。

### design-token-system

| SKILL.md | reference.md | 発火タイミング |
|----------|-------------|--------------|
| 377行 | 578行 | カラーパレット設計・トークン定義時 |

3層トークン階層(primitive/semantic/component)、OKLCH色空間、L値差0.40コントラスト、globals.css @theme inline、next-themes統合。

### micro-interaction-patterns

| SKILL.md | reference.md | 発火タイミング |
|----------|-------------|--------------|
| 365行 | 842行 | UI状態フィードバック・アニメーション実装時 |

スケルトン/シマー、トースト(sonner)、フォームバリデーションUX、空状態、error.tsx境界、ページ遷移、ボタン状態、ストリーミングUI。

### mobile-first-responsive

| SKILL.md | reference.md | 発火タイミング |
|----------|-------------|--------------|
| 358行 | 569行 | モバイルレスポンシブ・LIFF実装時 |

LIFF Size Modes、safe-area insets、viewport units(svh/lvh/dvh)、タッチターゲット48dp、PWA Serwist、virtual keyboard、bottom sheet。WCAG準拠のviewport設定に修正済み。

### web-design-guidelines

| SKILL.md | reference.md | 発火タイミング |
|----------|-------------|--------------|
| 293行 | 969行 | アクセシビリティ監査・HTML設計時 |

WCAG 2.2 AA、セマンティックHTML、コントラスト・キーボードナビ、フォーム・バリデーション、SEO(meta/OG/JSON-LD/sitemap)、Core Web Vitals、dark mode、i18n、print styles。Token Efficiency改善でSKILL.mdを293行に圧縮。

### line-bot-dev

| SKILL.md | reference.md | 発火タイミング |
|----------|-------------|--------------|
| 365行 | 341行 | LINE Bot開発・Webhook署名検証時 |

Messaging API、@line/bot-sdk、LIFF mini app、Webhook署名検証、Flex Message、Rich Menu、reply vs push最適化、冪等性テンプレート。画像・スタンプ送信とgetMessageContentのコンテンツ取得パターン追加。

---

## Tier 4: ツール系（2個）

特定ツール操作に特化。使うツールに合わせて導入。

### obsidian-power-user

| SKILL.md | reference.md | 発火タイミング |
|----------|-------------|--------------|
| 492行 | 360行 | オブ本格運用・クエリ作成時 |

Flavored Markdown（wikilinks/callouts/embeds）、Bases（.base YAML/filter/formula）、Automation（Dataview DQL/Templater/QuickAdd）の3ドメイン。

### chrome-extension-dev

| SKILL.md | reference.md | 発火タイミング |
|----------|-------------|--------------|
| 401行 | 311行 | 拡張機能開発・manifest設定時 |

Chrome MV3、content scripts、popup UI、chrome.storage、background service worker、chrome.alarms、message passing、SNS DOM scraping。

---

## メタスキル（共有対象外）

### skill-forge

Skillsの作成・検索・評価・最適化を行うメタスキル。`/skill-forge` で起動。個人環境のみ。

| 項目 | 値 |
|------|-----|
| 発火方式 | 手動 `/skill-forge` |
| SKILL.md | 225行 |
| reference.md | 320行 |

3モード（Create/Search/Review）。8フェーズのCreate Mode、10項目100点スコアリング、Description Engineering方法論を搭載。全24スキルはこのskill-forgeの品質基準で作成・レビュー済み。

---

## 最終レビュー結果（2026-02-17）

全24スキルに対して以下のチェックを実施し、全項目PASSを確認。

### Spec Compliance（ハード要件）

| チェック項目 | 結果 |
|-------------|------|
| `user-invocable: false` | 24/24 PASS |
| description "Use when"先頭 | 24/24 PASS |
| description ≤1024文字 | 24/24 PASS |
| description "Does NOT cover" | 24/24 PASS |
| SKILL.md ≤500行 | 24/24 PASS |
| h4(####)見出しゼロ | 24/24 PASS |
| ハードコード日付ゼロ | 24/24 PASS |
| クロスリファレンス整合 | 240参照 ALL PASS |

### 修正した主な問題

**2026-02-17 Spec Compliance修正**

| カテゴリ | 件数 | 詳細 |
|---------|------|------|
| user-invocable追加 | 13件 | frontmatterにフィールド自体がなかった13スキルに `false` を追加 |
| user-invocable修正 | 1件 | security-reviewを `true` → `false` に変更 |
| h4見出し除去 | 20箇所 | testing-strategy(4), security-review(2), vercel-react-best-practices(14)をボールド段落見出しに変換 |
| description超過修正 | 1件 | supabase-postgres-best-practices: 1090→1015文字にトリミング |
| "Does NOT cover"追加 | 19件 | 19スキルにスコープ境界テキストを追加 + nextjsの"Not for"→"Does NOT cover"統一 |
| IF-Vault共有同期 | 24件 | 全24スキルのSKILL.mdをteam/shared/skills/にコピー |

**2026-02-17 Token Efficiency + Content修正**

| カテゴリ | 件数 | 詳細 |
|---------|------|------|
| Token Efficiency改善 | 22件 | SKILL.md内のコード例重複をreference.md参照に置換。特にtailwind(495→190行), web-design-guidelines(497→293行)で大幅圧縮 |
| Content Completeness | 1件 | line-bot-dev: 画像・スタンプ送信 + getMessageContent追加 |
| Completeness + Spec | 1件 | vercel-react-best-practices: CWV目標値テーブル + 診断Decision Tree追加 |
| Accuracy + Completeness | 1件 | nextjs-app-router-patterns: error.tsx/not-found.txパターン追加、Client Navigation Hooksをテーブル化 |
| IF-Vault再同期 | 33ファイル | 全24スキルのSKILL.md + 12個のreference.mdを同期 |

---

## セットアップ

IF-Vaultのルートで `git pull` してからシンボリックリンクを作成。

```bash
# Tier 1: 全員必須
ln -s "$(pwd)/team/shared/skills/ux-psychology" ~/.claude/skills/ux-psychology
ln -s "$(pwd)/team/shared/skills/natural-japanese-writing" ~/.claude/skills/natural-japanese-writing
ln -s "$(pwd)/team/shared/skills/ansem-db-patterns" ~/.claude/skills/ansem-db-patterns
ln -s "$(pwd)/team/shared/skills/typescript-best-practices" ~/.claude/skills/typescript-best-practices
ln -s "$(pwd)/team/shared/skills/systematic-debugging" ~/.claude/skills/systematic-debugging
ln -s "$(pwd)/team/shared/skills/error-handling-logging" ~/.claude/skills/error-handling-logging
```

Tier 2-4は [[team/shared/skills/README|Skills README]] のセットアップセクション参照。

---

## 共通の設計原則

- 見出しはh3まで。h4以降はボールドの段落見出しで代替
- セクションには `[CRITICAL]`/`[HIGH]`/`[MEDIUM]` の優先度タグ
- SKILL.mdには核心だけ。詳細はreference.mdに分離
- descriptionは英語。"Use when"パターン必須、"Does NOT cover"で境界明示
- 日付やバージョン番号は入れない
- SKILL.md 500行以内（公式仕様の絶対制約）

---

_最終更新: 2026-02-17_
