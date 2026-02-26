---
name: skill-loader
user-invocable: false
description: "Restore inactive skills on demand. Use when writing Dockerfiles/docker-compose, creating Mermaid diagrams, doing git rebase/cherry-pick/bisect/worktree, designing REST APIs (OpenAPI), analyzing test quality (mutation testing), running Lighthouse/CWV audits, using OpenAI API, building Remotion videos, generating docx/xlsx/pptx/pdf, encoding with ffmpeg, following platform design guidelines (iOS/Android/macOS), or planning marketing campaigns. Do not trigger for SEO (_seo), a11y (_web-design-guidelines), basic git (_code-refactoring), test setup (testing-strategy), skill creation (skill-forge), or env diagnostics (_claude-env-optimizer)."
triggers:
  - スキルを読み込む
  - 非アクティブなスキルを使う
  - Dockerfileを書く
  - Mermaidダイアグラム
  - /skill-loader
---

# On-Demand Skill Loader

常駐せず必要時だけ復元することで、セッション開始時のトークンコストをゼロに保つ遅延ローダー。

## Procedure [CRITICAL]

### Step 1: Topic Match

ユーザーの質問を Mapping Table の keywords と照合 → skill-key を特定。

- 複数マッチ → 最も具体的なキーワード優先
- マッチなし → このスキルは何もしない

### Step 2: Restore

1. `test -f ~/.claude/skills/{dir}/SKILL.md` で復元済みか確認
2. 成功 → skip（Step 3 へ）
3. 失敗 → Mapping Table の type / source から復元:
   - **mv**: `mv ~/.claude/skills-inactive/{dir} ~/.claude/skills/`
   - **ln-s**: `ln -s {source} ~/.claude/skills/{dir}`
4. 再度 `test -f ~/.claude/skills/{dir}/SKILL.md` で成功確認
5. それでも失敗 → 壊れたシンボリックリンクの可能性。`rm ~/.claude/skills/{dir}` で削除後 3 を再実行

**エラー時**: source 不在 → `[skill-loader: {name} source not found]` と報告。対処は [reference.md](reference.md) 参照。

### Step 3: Load

`~/.claude/skills/{dir}/SKILL.md` を Read ツールで読み込む。

### Step 4: Respond

読み込んだスキルの知識で回答。末尾に `[skill-loader: {name} restored]`（新規）または `[skill-loader: {name} already active]`（既存）を付記。

---

## Mapping Table [CRITICAL]

mv type の source は `~/.claude/skills-inactive/{dir}`。表では「—」で省略。

### Core Skills

| key | keywords | dir | type | source |
|-----|----------|-----|------|--------|
| docker | Dockerfile, compose, container, multi-stage | _docker-expert | mv | — |
| web-quality | full Lighthouse, CWV全体監査, bundle analysis | _web-quality-audit | mv | — |
| mermaid | Mermaid, flowchart, sequence, ER diagram, Gantt | _mermaid-visualizer | ln-s | ~/.agents/skills/mermaid-visualizer |
| git-adv | rebase, cherry-pick, bisect, worktree, reflog | _git-advanced-workflows | ln-s | ~/.agents/skills/git-advanced-workflows |
| api-design | REST API設計, OpenAPI, Swagger, HATEOAS | _api-design-principles | ln-s | ~/.agents/skills/api-design-principles |
| test-quality | mutation testing, test smell, coverage gap | _test-quality-analysis | ln-s | ~/.agents/skills/test-quality-analysis |
| skills-guardian | スキル品質監査, skills audit scoring | _skills-quality-guardian | ln-s | ~/.agents/skills/skills-quality-guardian |
| find-skills | スキル検索, community skills, find skill | _find-skills | ln-s | ~/.agents/skills/find-skills |
| openai | OpenAI API, GPT API, function calling, embeddings | _openai-docs | ln-s | ~/.codex/skills/openai-docs |
| remotion | Remotion, React動画, video rendering | _remotion-best-practices | ln-s | ~/.codex/skills/remotion-best-practices |
| screenshot | スクリーンショット, visual diff, page capture | _screenshot | ln-s | ~/.codex/skills/screenshot |
| docx | Word生成, docx, Word文書 | _docx | ln-s | ~/.agents/skills/docx |
| xlsx | Excel生成, xlsx, spreadsheet | _xlsx | ln-s | ~/.agents/skills/xlsx |
| ffmpeg | ffmpeg, 動画エンコード, transcoding | _ffmpeg | ln-s | ~/.agents/skills/ffmpeg |
| pptx | PowerPoint生成, pptx, slides | _pptx | ln-s | ~/.agents/skills/pptx |
| pdf | PDF生成, PDFパース, PDF extraction | _pdf | ln-s | ~/.agents/skills/pdf |

### Platform Design Guidelines

| key | keywords | dir | type | source |
|-----|----------|-----|------|--------|
| ios | iOS design, HIG, UIKit, SwiftUI guidelines | _ios-design-guidelines | ln-s | ~/.agents/skills/ios-design-guidelines |
| android | Android design, Material Design guidelines | _android-design-guidelines | ln-s | ~/.agents/skills/android-design-guidelines |
| macos | macOS design, AppKit, desktop app design | _macos-design-guidelines | ln-s | ~/.agents/skills/macos-design-guidelines |
| ipados | iPadOS design, iPad UI, Split View | _ipados-design-guidelines | ln-s | ~/.agents/skills/ipados-design-guidelines |
| tvos | tvOS design, Apple TV UI, focus-based | _tvos-design-guidelines | ln-s | ~/.agents/skills/tvos-design-guidelines |
| visionos | visionOS design, spatial UI, Vision Pro | _visionos-design-guidelines | ln-s | ~/.agents/skills/visionos-design-guidelines |
| watchos | watchOS design, Apple Watch, complications | _watchos-design-guidelines | ln-s | ~/.agents/skills/watchos-design-guidelines |

### Marketing

| key | keywords | dir | type | source |
|-----|----------|-----|------|--------|
| mkt-content | コンテンツ戦略, content strategy, blog戦略 | _marketing-content-strategy | ln-s | ~/.agents/skills/marketing-content-strategy |
| mkt-cro | CRO, conversion rate, A/Bテスト, ファネル | _marketing-cro | ln-s | ~/.agents/skills/marketing-cro |
| mkt-geo | ローカライゼーション, geo targeting, 多言語対応 | _marketing-geo-localization | ln-s | ~/.agents/skills/marketing-geo-localization |
| mkt-ads | 広告運用, paid advertising, PPC, リスティング | _marketing-paid-advertising | ln-s | ~/.agents/skills/marketing-paid-advertising |
| mkt-social | SNS運用, social media marketing, X/Instagram | _marketing-social-media | ln-s | ~/.agents/skills/marketing-social-media |
| mkt-visual | マーケティングデザイン, banner, 広告クリエイティブ | _marketing-visual-design | ln-s | ~/.agents/skills/marketing-visual-design |

### Obsidian Extended

| key | keywords | dir | type | source |
|-----|----------|-----|------|--------|
| obsidian-bases | Obsidian Bases, YAML view, formula, bases設計 | _obsidian-bases | ln-s | ~/.agents/skills/obsidian-bases |
| obsidian-md | Obsidian Markdown拡張, callout高度, embed拡張 | _obsidian-markdown | ln-s | ~/.agents/skills/obsidian-markdown |

---

## Collision Avoidance (When NOT to Apply) [HIGH]

以下のトピックでは発火**しない**。該当スキルに委譲:

| Topic | Delegate to |
|-------|------------|
| SEO, meta tags, structured data | _seo |
| WCAG, a11y, semantic HTML | _web-design-guidelines |
| 基本Git (commit, branch, merge) | _code-refactoring |
| テスト設計, Vitest/Playwright setup | testing-strategy |
| スキル作成・レビュー | skill-forge |
| 環境診断, hooks, MCP | _claude-env-optimizer |
| Lighthouse 単一カテゴリ | _seo or _web-design-guidelines |
| Obsidian 基本操作 (vault, wikilink, Dataview, Templater) | obsidian-power-user |
| Web/responsive design, CSS設計 | _web-design-guidelines |

境界が曖昧なケースの判断例 → [reference.md](reference.md)

---

## Reference

- 復元コマンド一覧・一括復元スクリプト → [reference.md](reference.md)
- 境界判断の具体例 → [reference.md](reference.md)
- 再退避ポリシー・トラブルシュート・FAQ → [reference.md](reference.md)
- アンチパターン（やってはいけないこと） → [reference.md](reference.md)

## Cross-references

- **ci-cd-deployment**: Docker関連スキルのオンデマンドロード先
