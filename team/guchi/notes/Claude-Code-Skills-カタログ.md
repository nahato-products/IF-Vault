---
date: 2026-02-13
tags: [Claude Code, Skills, カタログ, リソース]
status: active
---

# Claude Code Skills カタログ

3つのAwesomeリスト（BehiSecc、VoltAgent、各リポジトリ）から収集した全Skills一覧。
✅ インストール済み、🔒 HOLD（評価済み・保留）、無印は未インストール。

詳細な構成は [[Claude-Code-Skills一覧]] を参照。

---

## インストール済み一覧（48個 / 5.0MB）

| スキル | カテゴリ | ソース |
|--------|---------|--------|
| ✅ obsidian-markdown | オブ | kepano |
| ✅ obsidian-bases | オブ | kepano |
| ✅ supabase-postgres-best-practices | DB | supabase（公式） |
| ✅ neon-postgres | DB | neondatabase |
| ✅ docx | ドキュメント | anthropics（公式） |
| ✅ pdf | ドキュメント | anthropics（公式） |
| ✅ xlsx | ドキュメント | anthropics（公式） |
| ✅ pptx | ドキュメント | anthropics（公式） |
| ✅ remotion-best-practices | 動画 | プリインストール |
| ✅ video-motion-graphics | 動画 | dylantarre |
| ✅ motion-designer | 動画 | dylantarre |
| ✅ ffmpeg | 動画 | digitalsamba |
| ✅ marketing-visual-design | デザイン | vasilyu1983 |
| ✅ mermaid-visualizer | デザイン | axtonliu |
| ✅ ux-psychology | UX/UI | 自作 |
| ✅ baseline-ui | UX/UI | ibelick |
| ✅ fixing-accessibility | UX/UI | ibelick |
| ✅ fixing-metadata | UX/UI | ibelick |
| ✅ fixing-motion-performance | UX/UI | ibelick |
| ✅ ios-design-guidelines | UX/UI | ehmo |
| ✅ ipados-design-guidelines | UX/UI | ehmo |
| ✅ macos-design-guidelines | UX/UI | ehmo |
| ✅ tvos-design-guidelines | UX/UI | ehmo |
| ✅ visionos-design-guidelines | UX/UI | ehmo |
| ✅ watchos-design-guidelines | UX/UI | ehmo |
| ✅ android-design-guidelines | UX/UI | ehmo |
| ✅ web-design-guidelines | UX/UI | ehmo |
| ✅ git-advanced-workflows | 開発 | wshobson |
| ✅ using-git-worktrees | 開発 | obra/superpowers |
| ✅ finishing-a-development-branch | 開発 | obra/superpowers |
| ✅ brainstorming | 開発 | obra/superpowers |
| ✅ ship-learn-next | 開発 | michalparkola/tapestry |
| ✅ systematic-debugging | 開発 | obra/superpowers |
| ✅ slack-bot-builder | 開発 | sickn33 |
| ✅ find-skills | 開発 | プリインストール |
| ✅ keybindings-help | 開発 | プリインストール（ビルトイン） |
| ✅ security-review | セキュリティ | getsentry |
| ✅ vibe-security-skill | セキュリティ | BehiSecc |
| ✅ code-refactoring | 品質 | supercent-io |
| ✅ typescript-best-practices | 品質 | 0xbigboss |
| ✅ webapp-testing | テスト | anthropics |
| ✅ test-quality-analysis | テスト | secondsky |
| ✅ test-driven-development | テスト | obra/superpowers |
| ✅ docker-expert | インフラ | personamanagmentlayer |
| ✅ revealjs | プレゼン | ryanbbrown |
| ✅ deep-research | リサーチ | sanjay3290 |
| ✅ youtube-downloader | ユーティリティ | ComposioHQ |
| ✅ invoice-organizer | ユーティリティ | ComposioHQ |

### 削除済み
| スキル | 理由 |
|--------|------|
| ~~postgres-pro~~ | supabase版に置換（34ルール vs 5トピック） |
| ~~remotion-animation~~ | イージング実装が不正確、存在しないスキルを参照 |
| ~~creative-coder~~ | fixing-motion-performanceが上位互換 |

---

## HOLD（評価済み・保留）

| スキル | 理由 | ソース |
|--------|------|--------|
| 🔒 owasp-security | security-reviewと重複大。20+言語カバーは魅力だが現状不要 | agamm/claude-code-owasp |
| 🔒 sanjay3290/postgres | ツール実行型。supabase版で十分 | sanjay3290/ai-skills |
| 🔒 playwright-skill | webapp-testingと重複大（言語違いのみ） | lackeyjb |
| 🔒 ui-ux-pro-max-skill | テンプレ化リスク。ux-psychologyのUX部分と被る | nextlevelbuilder |

---

## 未インストール・カタログ

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
| agnix | SKILL.md/CLAUDE.md/hooks/MCPの156ルールリンター | avifenesh/agnix |
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

_最終更新: 2026-02-13_
