---
date: 2026-02-13
tags: [Claude Code, Skills, ツール, カタログ, リソース]
status: active
---

# Claude Code Skills 一覧 & カタログ

インストール済み・保留・未インストールの全Skills統合リスト。
自作スキルの詳細は [[自作Skills一覧]] を、v2.7時点の品質スキャンは [[Skills-49個スキャンレポート]] を参照。

✅ インストール済み、🔒 HOLD（評価済み・保留）、❌ REJECT（不要と判断）、無印は未インストール。

---

## インストール済み（55個）

### オブ関連（2個）
| スキル | 内容 | ソース |
|--------|------|--------|
| obsidian-markdown | Obsidian Markdown記法のベスプラ | kepano（Obsidian公式） |
| obsidian-bases | Bases機能の使い方 | kepano（Obsidian公式） |

### DB関連（3個）
| スキル | 内容 | ソース |
|--------|------|--------|
| ansem-db-patterns | PostgreSQL DB設計パターン 22項目（340行+320行） | 自作 |
| supabase-postgres-best-practices | PostgreSQL 34ルール・8カテゴリ | supabase（公式） |
| neon-postgres | Neon（サーバーレスPostgres）連携 | neondatabase（公式） |

### ドキュメント処理（4個）
| スキル | 内容 | ソース |
|--------|------|--------|
| docx | Word文書の作成・編集・分析 | anthropics（Anthropic公式） |
| pdf | PDFテキスト・テーブル抽出 | anthropics（Anthropic公式） |
| xlsx | スプレッドシート操作・数式・チャート | anthropics（Anthropic公式） |
| pptx | スライド読み取り・生成 | anthropics（Anthropic公式） |

### 動画・アニメーション（4個）
| スキル | 内容 | ソース |
|--------|------|--------|
| remotion-best-practices | Remotionのベスプラ | プリインストール |
| video-motion-graphics | モーショングラフィックス全般 | dylantarre/animation-principles |
| motion-designer | アニメーション原則・モーションデザイン | dylantarre/animation-principles |
| ffmpeg | FFmpegでの動画処理・変換 | digitalsamba/claude-code-video-toolkit |

### デザイン・クリエイティブ（2個）
| スキル | 内容 | ソース |
|--------|------|--------|
| marketing-visual-design | マーケティング用ビジュアルデザイン | vasilyu1983/ai-agents-public |
| mermaid-visualizer | Mermaidダイアグラム作成 | axtonliu/axton-obsidian-visual-skills |

### UI/UXデザイン（13個）
| スキル | 内容 | ソース |
|--------|------|--------|
| ux-psychology | アプリ開発特化UX 29原則+10H+AI UX+ニューロダイバーシティ（410+346行） | 自作 |
| baseline-ui | エージェント向けUI制約ガイド（`/baseline-ui`） | ibelick/ui-skills |
| fixing-accessibility | アクセシビリティ修正（`/fixing-accessibility`） | ibelick/ui-skills |
| fixing-metadata | メタデータ修正（`/fixing-metadata`） | ibelick/ui-skills |
| fixing-motion-performance | モーションパフォーマンス最適化 | ibelick/ui-skills |
| ios-design-guidelines | Apple HIG（iOS） | ehmo/platform-design-skills |
| ipados-design-guidelines | Apple HIG（iPadOS） | ehmo/platform-design-skills |
| macos-design-guidelines | Apple HIG（macOS） | ehmo/platform-design-skills |
| tvos-design-guidelines | Apple HIG（tvOS） | ehmo/platform-design-skills |
| visionos-design-guidelines | Apple HIG（visionOS） | ehmo/platform-design-skills |
| watchos-design-guidelines | Apple HIG（watchOS） | ehmo/platform-design-skills |
| android-design-guidelines | Material Design 3（Android） | ehmo/platform-design-skills |
| web-design-guidelines | WCAG 2.2 + Webデザイン（1,288行） | ehmo/platform-design-skills |

### 開発ワークフロー（8個）
| スキル | 内容 | ソース |
|--------|------|--------|
| git-advanced-workflows | Git高度なワークフロー | wshobson/agents |
| using-git-worktrees | Git worktreeのスマート管理 | obra/superpowers |
| finishing-a-development-branch | 開発ブランチ完了ワークフロー | obra/superpowers |
| brainstorming | 構造化ブレスト→設計変換 | obra/superpowers |
| ship-learn-next | 学習→実行プラン変換 | michalparkola/tapestry |
| systematic-debugging | 系統的デバッグ（修正前に原因特定） | obra/superpowers |
| slack-bot-builder | Slackボット構築 | sickn33/antigravity-awesome-skills |
| find-skills | スキル検索・インストール | プリインストール |

### セキュリティ（2個）
| スキル | 内容 | ソース |
|--------|------|--------|
| security-review | コードの脆弱性チェック（偽陽性低減ロジック付き） | getsentry（Sentry公式） |
| vibe-security-skill | Webアプリのセキュリティ保護（予防型） | BehiSecc |

### フロントエンド・API（4個）
| スキル | 内容 | ソース |
|--------|------|--------|
| vercel-react-best-practices | React/Next.jsパフォーマンス最適化 57ルール・8カテゴリ（136行） | vercel-labs（Vercel公式） |
| nextjs-app-router-patterns | Next.js 14+ App Router・RSC・ストリーミング（543行） | wshobson/agents |
| tailwind-design-system | Tailwind CSS v4デザインシステム・トークン・レスポンシブ（874行） | wshobson/agents |
| api-design-principles | REST/GraphQL API設計原則（528行） | wshobson/agents |

### コード品質（2個）
| スキル | 内容 | ソース |
|--------|------|--------|
| code-refactoring | リファクタリングのベスプラ | supercent-io/skills-template |
| typescript-best-practices | TypeScriptのベスプラ | 0xbigboss/claude-code |

### テスト（3個）
| スキル | 内容 | ソース |
|--------|------|--------|
| webapp-testing | Webアプリテスト（Playwright） | anthropics（Anthropic公式） |
| test-quality-analysis | テスト品質分析 | secondsky/claude-skills |
| test-driven-development | TDDワークフロー | obra/superpowers |

### インフラ（1個）
| スキル | 内容 | ソース |
|--------|------|--------|
| docker-expert | Docker構築・運用 | personamanagmentlayer/pcl |

### プレゼン（1個）
| スキル | 内容 | ソース |
|--------|------|--------|
| revealjs | Reveal.jsプレゼン自動生成 | ryanbbrown/revealjs-skill |

### リサーチ（1個）
| スキル | 内容 | ソース |
|--------|------|--------|
| deep-research | Gemini Deep Researchで自律リサーチ | sanjay3290/ai-skills |

### ユーティリティ（2個）
| スキル | 内容 | ソース |
|--------|------|--------|
| youtube-downloader | 動画ダウンロード | ComposioHQ |
| invoice-organizer | 請求書自動整理 | ComposioHQ |

### ドキュメント品質（1個）
| スキル | 内容 | ソース |
|--------|------|--------|
| natural-japanese-writing | 日本語文書のAI臭排除（20ルール5カテゴリ） | 自作 |

### メタスキル（1個）
| スキル | 内容 | ソース |
|--------|------|--------|
| skill-forge | Skills作成・検索・評価（`/skill-forge`） | 自作 |

### ビルトイン（1個）
| スキル | 内容 | ソース |
|--------|------|--------|
| keybindings-help | キーボードショートカットカスタマイズ | プリインストール |

### 削除済み
| スキル | 理由 |
|--------|------|
| ~~postgres-pro~~ | supabase版に置換（34ルール vs 5トピック） |
| ~~remotion-animation~~ | イージング実装が不正確、存在しないスキルを参照 |
| ~~creative-coder~~ | fixing-motion-performanceが上位互換 |

---

## 同時発火の注意点

UI作業時に複数スキルが同時ロードされる可能性あり。特に重いもの:

| スキル | 行数 | 発火条件 |
|--------|------|---------|
| web-design-guidelines | 1,288行 | HTML/CSS/WCAG関連で自動 |
| ux-psychology | 410行（+reference 346行） | UI/UX設計・実装・AI機能で自動 |
| baseline-ui | ~90行 | `/baseline-ui`コマンドで手動 |
| fixing-accessibility | ~100行 | `/fixing-accessibility`コマンドで手動 |
| fixing-motion-performance | ~100行 | アニメーション関連で自動 |

ibelick系はコマンド呼び出し式なので自動発火は限定的。実質的に同時ロードされるのはux-psychology + web-design-guidelines の2つが中心。日本語ドキュメント執筆時はnatural-japanese-writing（176行）も加わるが軽量。

React/Next.js作業時はvercel-react-best-practices（136行）+ nextjs-app-router-patterns（543行）+ tailwind-design-system（874行）が同時発火する可能性がある。合計1,553行とかなり重い。Tailwind作業を伴わない場合はtailwindが発火しないため実質679行程度に収まる。

---

## HOLD（保留中）

今後必要になったら追加検討:

| スキル | 理由 | ソース | 再評価(2/15) |
|--------|------|--------|-------------|
| 🔒 owasp-security | OWASP 2025-2026対応。security-reviewと相乗効果ありそう | agamm/claude-code-owasp | INSTALL検討 |
| 🔒 claude-code-nextjs-skills | Next.js 16 + AI SDK 6 + pgvector | laguagu | pgvector使う段階で |
| 🔒 shadcn-ui | shadcn/ui専門 | giuseppe-trisciuoglio/developer-kit | shadcn採用決定時に |
| 🔒 nextjs-devtools | ライブ診断・RSC最適化。品質未検証 | mcpmarket | 様子見 |
| 🔒 playwright-skill | webapp-testingと重複大（言語違い） | lackeyjb | 必要になったら |
| 🔒 ui-ux-pro-max-skill | テンプレ化リスク。ux-psychologyのUX部分と被る | nextlevelbuilder | 様子見 |

### ❌ REJECT（不要と判断）

| スキル | 理由 | ソース |
|--------|------|--------|
| sanjay3290/postgres | ansem-db-patterns + supabase版で十分。3つ目のDB系は過剰 | sanjay3290/ai-skills |
| ui-ux-pro-max-skill | ux-psychology強化済み（10アンチパターン追加）。重複大 | nextlevelbuilder |

---

## 未インストール・カタログ

以下は3つのAwesomeリスト（BehiSecc、VoltAgent、各リポジトリ）から収集した未インストールSkills。必要になったタイミングで導入を検討する。

### Anthropic公式（残り）

| スキル | 内容 | コマンド |
|--------|------|---------|
| web-artifacts-builder | React+Tailwind+shadcnでHTMLアーティファクト構築 | `npx skills add anthropics/skills --skill web-artifacts-builder` |
| internal-comms | 社内コミュニケーション作成（レポート、FAQ等） | `npx skills add anthropics/skills --skill internal-comms` |
| skill-creator | 新しいSkill構築テンプレート | `npx skills add anthropics/skills --skill skill-creator` |

### Stripe / Vercel / Sentry 公式

| スキル | 内容 | コマンド |
|--------|------|---------|
| stripe-agent-toolkit | Stripe API統合、決済、サブスク管理 | `npx skills add stripe/agent-toolkit` |
| vercel-v0-skill | v0でUI生成、Next.jsデプロイ | `npx skills add vercel-labs/v0-skill` |
| sentry-skill | Sentryエラー追跡・パフォーマンス監視 | `npx skills add getsentry/sentry-skill` |

### Microsoft

| スキル | 内容 |
|--------|------|
| azure-openai-ts | Azure OpenAI TypeScriptパターン |
| nextjs-app-router-ts | Next.js App Router |
| playwright-testing-ts | Playwrightテスト |
| prisma-schema-ts | Prismaスキーマ設計 |
| react-component-ts | Reactコンポーネント設計 |
| supabase-auth-ts | Supabase認証 |
| tailwind-ui-ts | Tailwind UIパターン |
| zustand-store-ts | Zustandストア |
| mcp-builder | MCPサーバー作成ガイド |

### 開発・コード品質

| スキル | 内容 | ソース |
|--------|------|--------|
| root-cause-tracing | ランタイムエラーから根本原因を特定 | obra/superpowers |
| subagent-driven-development | マルチサブエージェント開発 | obra/superpowers |
| verification-before-completion | 完了前の検証 | obra/superpowers |
| requesting-code-review | コードレビュー依頼 | obra/superpowers |
| receiving-code-review | コードレビュー受領・反映 | obra/superpowers |
| dispatching-parallel-agents | 並列エージェント管理 | obra/superpowers |
| defense-in-depth | 多層テスト・セキュリティ | obra/superpowers |
| varlock-claude-skill | 環境変数の安全管理 | wrsmith108 |
| agnix | SKILL.md/CLAUDE.md/hooks/MCPの156ルールリンター | avefenesh/agnix |
| changelog-generator | gitコミットからリリースノート生成 | ComposioHQ |
| recursive-decomposition-skill | 大規模タスク分解（100+ファイル/50k+トークン） | massimodeluisa |
| claude-bootstrap | セキュリティファーストのプロジェクト初期化 | alinaqi |

### プロジェクト管理・コラボ

| スキル | 内容 | ソース |
|--------|------|--------|
| writing-plans | 戦略ドキュメント作成 | obra/superpowers |
| executing-plans | 戦略プランの実行 | obra/superpowers |
| kanban-skill | Markdownベースカンバンボード | mattjoyce |
| Product-Manager-Skills | PMスキル（PRD作成等） | deanpeters |
| claude-memory-skill | 階層的メモリシステム | hanfang |

### ドキュメント・コンテンツ

| スキル | 内容 | ソース |
|--------|------|--------|
| content-research-writer | リサーチ付きコンテンツ執筆 | ComposioHQ |
| article-extractor | Web記事テキスト抽出 | michalparkola/tapestry |
| youtube-transcript | YouTube動画トランスクリプト取得・要約 | michalparkola/tapestry |
| claude-epub-skill | Markdown→epub変換 | smerchek |
| kreuzberg | 62+ドキュメント形式からテキスト抽出 | kreuzberg-dev |
| beautiful_prose | AI臭のない英語散文 | SHADOWPR0 |

### AI画像・メディア生成

| スキル | 内容 | ソース |
|--------|------|--------|
| imagen | Google Gemini画像生成 | sanjay3290/ai-skills |
| fal-generate | fal.aiで画像・動画生成 | fal-ai-community |
| fal-image-edit | AI画像編集 | fal-ai-community |
| video-prompting-skill | 動画生成モデル向けプロンプト作成 | Square-Zero-Labs |

### セキュリティ特化

| スキル | 内容 | ソース |
|--------|------|--------|
| Trail of Bits Skills | CodeQL/Semgrep静的解析 | trailofbits/skills |
| ffuf_claude_skill | FFUF Webファジング | jthack |

### インフラ・クラウド

| スキル | 内容 | ソース |
|--------|------|--------|
| aws-skills | CDKベスプラ、サーバーレス | zxkane |
| hashicorp/terraform-* | Terraform HCL生成 | hashicorp |
| cloudflare-skill | Workers, Pages, AI | dmmulroy |

### マーケティング

| スキル | 内容 | ソース |
|--------|------|--------|
| marketingskills | 23+のSEO・コピーライティング | coreyhaines31 |
| competitive-ads-extractor | 競合広告分析 | ComposioHQ |

### コンテキストエンジニアリング

| スキル | 内容 | ソース |
|--------|------|--------|
| context-fundamentals | コンテキストの基礎理解 | muratcankoylan |
| context-compression | 長期セッション圧縮戦略 | muratcankoylan |
| context-optimization | 最適化（圧縮、キャッシュ） | muratcankoylan |
| multi-agent-patterns | マルチエージェントアーキテクチャ | muratcankoylan |

### モバイル・ネイティブ

| スキル | 内容 | ソース |
|--------|------|--------|
| react-native-best-practices | React Nativeパフォーマンス最適化 | callstackincubator |
| swiftui-expert-skill | SwiftUIベスプラ | AvdLee |
| ios-simulator-skill | iOSシミュレータ制御 | conorluddy |

---

## 情報ソース

| リポジトリ | 特徴 |
|-----------|------|
| [VoltAgent/awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills) | クロスプラットフォーム最大規模300+ |
| [BehiSecc/awesome-claude-skills](https://github.com/BehiSecc/awesome-claude-skills) | カテゴリ整理が秀逸 |
| [sickn33/antigravity-awesome-skills](https://github.com/sickn33/antigravity-awesome-skills) | Antigravity特化700+ |
| [ComposioHQ/awesome-claude-skills](https://github.com/ComposioHQ/awesome-claude-skills) | 実用的な独自Skill（939個） |
| [anthropics/skills](https://github.com/anthropics/skills) | Anthropic公式 |
| [obra/superpowers](https://github.com/obra/superpowers) | 開発ワークフロー系の宝庫（14スキル） |
| [sanjay3290/ai-skills](https://github.com/sanjay3290/ai-skills) | 汎用AI Skills |

---

## スキル管理コマンド

```bash
# スキル検索
npx skills find [キーワード]

# インストール
npx skills add <owner/repo@skill> -g -y

# アップデート確認
npx skills check

# 全スキルアップデート
npx skills update
```

---

## 変更ログ

### 2026-02-20: v3.3 一覧+カタログ統合
- **統合**: Claude-Code-Skills一覧.md と Claude-Code-Skills-カタログ.md を1ファイルに統合
  - 未インストール・カタログ（Anthropic公式残り、Stripe/Vercel/Sentry、Microsoft、開発・品質、PM、ドキュメント、AI画像、セキュリティ、インフラ、マーケティング、コンテキストエンジニアリング、モバイル）を追加
  - 情報ソースセクションを追加
  - 削除済みスキル一覧を追加
  - HOLD/REJECTを両ファイルからマージ（カタログのsanjay3290/postgresをREJECTにも追加）

### 2026-02-15: v3.2 HOLD再評価 + Differentiation改善
- **HOLD再評価**: 7スキルを再評価
  - INSTALL検討: owasp-security（OWASP 2025-2026対応）
  - REJECT: sanjay3290/postgres, ui-ux-pro-max-skill（重複・過剰）
  - KEEP HOLD: 残り4スキル
- **Differentiation改善**: 3スキルのreference.mdに独自コンテンツ追加
  - ux-psychology: 現場UXアンチパターン10件
  - natural-japanese-writing: 定量チェックツール（括弧密度、語尾連続、接続詞頻度）
  - skill-forge: 55個運用の実践知10個＋失敗パターン5個＋品質分布データ
- **ansem-db-patterns レビュー**: 84点（B+）— Token Efficiency 7, Differentiation 7が改善ポイント

### 2026-02-14: v3.1 ansem-db-patterns追加
- **新規**: ansem-db-patterns（340行+320行）- PostgreSQL DB設計パターン集
  - ANSEM 32テーブルの設計経験から抽出した22パターン
  - 命名規則、データ型統一、FK削除ポリシー、楽観ロック、スナップショット方式、パーティション
  - 完全オリジナルの実践知（Differentiationが高い）
  - DB関連カテゴリ 2→3個、合計 54→55個

### 2026-02-14: v3.0 全Skills再レビュー＋最適化
- **アップデート（2）**: neon-postgres, supabase-postgres-best-practices（`npx skills update`で最新化）
- **自作Skills改善**:
  - ux-psychology: 自明な相互参照3件削除（Token Efficiency, Cross-reference改善）
  - natural-japanese-writing: description強化（polishing, rewriting, removing AI-like patterns追加）
  - skill-forge: description強化（refines, building, finding, refactoring, validating追加）
- **再レビュースコア**: ux-psychology 88点、natural-japanese-writing 93点、skill-forge 91点
  - 全スキル共通の課題: Differentiation（独自性）が4/10。実践知の追加で改善可能

### 2026-02-14: v2.9 フロントエンド・API 4スキル追加
- **新規（4）**: vercel-react-best-practices, nextjs-app-router-patterns, tailwind-design-system, api-design-principles
  - Vercel公式React/Next.jsパフォーマンス最適化（130K installs）
  - Next.js App Router パターン集（RSC、ストリーミング、並列ルート）
  - Tailwind CSS v4 デザインシステム構築ガイド
  - REST/GraphQL API設計原則
  - 同時発火の注意点を追記（React作業時に最大1,553行ロードの可能性）

### 2026-02-14: v2.8 natural-japanese-writing追加
- **新規**: natural-japanese-writing（176行+184行）- 日本語文書のAI臭排除スキル
  - 20ルール5カテゴリ: 記号・表記、文のリズム、スタンス、構造・進行、言葉選び
  - セルフチェック7項目、Before/After実例5組、ジャンル別注意点
  - 自己レビュー97点（全項目9点以上）

### 2026-02-14: v2.7 skill-forge追加
- **新規**: skill-forge（253行+330行）- Skills作成・検索・評価のメタスキル
  - 3モード: Create（8フェーズ）, Search（フィルター+比較）, Review（10項目100点）
  - Description Engineering方法論、5並列レビュー手法を内蔵
  - 自己レビュー100点達成

### 2026-02-14: v2.6 100点最適化
- **更新**: ux-psychology v4.3（410行+346行）
  - description強化: fixing/improving/usability/auditsトリガー追加
  - トークン最適化: 自明な相互参照5件削除、ゲシュタルト原則を箇条書きに圧縮
  - H4/H8に独立した説明文追加（純粋な参照→独立価値）

### 2026-02-14: v2.5 最終レビュー+最適化
- **更新**: ux-psychology v4.2（412行+346行）
  - SKILL.md最適化: When to Apply圧縮、Referenceセクション簡略化、Output Formatをreference.mdに移動
  - reference.md拡充: 通知・トースト設計、検索UI、モーダル設計の3セクション追加
  - UI Review Output Formatをreference.mdに移動（レビュー時のみ参照）

### 2026-02-14: v2.4 スコープ制御+レビューフォーマット追加
- **更新**: ux-psychology v4.1（450行+246行）
  - 「When NOT to Apply」セクション追加（スコープ外の明示で誤発火防止）
  - 「UI Review Output Format」セクション追加（レビュー出力テンプレート）

### 2026-02-14: v2.3 ux-psychology多方面レビュー版
- **更新**: ux-psychology v4.0（415行+246行）
  - 事実誤認3件修正（WCAGテキストサイズ、NNGroup引用、Doherty出典）
  - #8+#23統合（30→29原則）、ニールセン10Hスリム化（重複排除）
  - セクション重要度タグ [CRITICAL]/[HIGH]/[MEDIUM] 追加
  - description/When to Applyにトリガーキーワード大幅追加
  - reference.md にデータテーブル・AIチャットUI・ダッシュボード追加

### 2026-02-13: v2.2 ux-psychology初版リリース
- **更新**: ux-psychology v3.0（745行→587行）
  - マーケティング心理学22原則を削除、アプリ開発特化に最適化
  - AI UXパターン追加（NNGroup 2026準拠）
  - ニューロダイバーシティ対応追加
  - team/shared/skills/ でチーム共有化

### 2026-02-13: v2.1 最適化
- **削除**: creative-coder（fixing-motion-performanceが上位互換）
- **追加（4）**: docx, pdf, xlsx, pptx（Anthropic公式ドキュメント処理）
- **更新**: neon-postgres（最新版に更新）
- トリガー競合分析を実施、同時発火リスクを文書化

### 2026-02-13: v2.0 大幅追加
- **削除（2）**: remotion-animation（不正確）, postgres-pro（supabaseに置換）
- **新規（24）**: brainstorming, test-driven-development, systematic-debugging, using-git-worktrees, finishing-a-development-branch, deep-research, revealjs, ship-learn-next, youtube-downloader, invoice-organizer, vibe-security-skill, supabase-postgres-best-practices, baseline-ui, fixing-accessibility, fixing-metadata, fixing-motion-performance, ios/ipados/macos/tvos/visionos/watchos/android/web-design-guidelines

### 2026-02-12: v1.0 初期構築
- 23個のスキルをインストール

---

## 関連ノート

- [[自作Skills一覧]] — 自作24スキルの詳細（Tier分類・レビュー結果・セットアップ手順）
- [[Skills-49個スキャンレポート]] — v2.7時点の品質スキャン結果（仕様違反・重複・改善候補）

---

_最終更新: 2026-02-20_
