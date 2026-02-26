# Skill Loader Reference

本体: [SKILL.md](SKILL.md) — Procedure, Mapping Table, Collision Avoidance

## アーキテクチャ

```
ユーザー発言 → description キーワード照合 → autofire発火
  → Mapping Table で skill-key 特定
  → test -f で存在確認 → restore (mv / ln -s)
  → Read SKILL.md → スキル知識で回答
```

## 復元コマンド一覧

### mv type（2個）

```bash
mv ~/.claude/skills-inactive/_docker-expert ~/.claude/skills/
mv ~/.claude/skills-inactive/_web-quality-audit ~/.claude/skills/
```

### ln-s type — Core（14個）

```bash
ln -s ~/.agents/skills/mermaid-visualizer ~/.claude/skills/_mermaid-visualizer
ln -s ~/.agents/skills/git-advanced-workflows ~/.claude/skills/_git-advanced-workflows
ln -s ~/.agents/skills/api-design-principles ~/.claude/skills/_api-design-principles
ln -s ~/.agents/skills/test-quality-analysis ~/.claude/skills/_test-quality-analysis
ln -s ~/.agents/skills/skills-quality-guardian ~/.claude/skills/_skills-quality-guardian
ln -s ~/.agents/skills/find-skills ~/.claude/skills/_find-skills
ln -s ~/.codex/skills/openai-docs ~/.claude/skills/_openai-docs
ln -s ~/.codex/skills/remotion-best-practices ~/.claude/skills/_remotion-best-practices
ln -s ~/.codex/skills/screenshot ~/.claude/skills/_screenshot
ln -s ~/.agents/skills/docx ~/.claude/skills/_docx
ln -s ~/.agents/skills/xlsx ~/.claude/skills/_xlsx
ln -s ~/.agents/skills/ffmpeg ~/.claude/skills/_ffmpeg
ln -s ~/.agents/skills/pptx ~/.claude/skills/_pptx
ln -s ~/.agents/skills/pdf ~/.claude/skills/_pdf
```

### ln-s type — Platform Design（7個）

```bash
ln -s ~/.agents/skills/ios-design-guidelines ~/.claude/skills/_ios-design-guidelines
ln -s ~/.agents/skills/android-design-guidelines ~/.claude/skills/_android-design-guidelines
ln -s ~/.agents/skills/macos-design-guidelines ~/.claude/skills/_macos-design-guidelines
ln -s ~/.agents/skills/ipados-design-guidelines ~/.claude/skills/_ipados-design-guidelines
ln -s ~/.agents/skills/tvos-design-guidelines ~/.claude/skills/_tvos-design-guidelines
ln -s ~/.agents/skills/visionos-design-guidelines ~/.claude/skills/_visionos-design-guidelines
ln -s ~/.agents/skills/watchos-design-guidelines ~/.claude/skills/_watchos-design-guidelines
```

### ln-s type — Marketing（6個）

```bash
ln -s ~/.agents/skills/marketing-content-strategy ~/.claude/skills/_marketing-content-strategy
ln -s ~/.agents/skills/marketing-cro ~/.claude/skills/_marketing-cro
ln -s ~/.agents/skills/marketing-geo-localization ~/.claude/skills/_marketing-geo-localization
ln -s ~/.agents/skills/marketing-paid-advertising ~/.claude/skills/_marketing-paid-advertising
ln -s ~/.agents/skills/marketing-social-media ~/.claude/skills/_marketing-social-media
ln -s ~/.agents/skills/marketing-visual-design ~/.claude/skills/_marketing-visual-design
```

### ln-s type — Obsidian Extended（2個）

```bash
ln -s ~/.agents/skills/obsidian-bases ~/.claude/skills/_obsidian-bases
ln -s ~/.agents/skills/obsidian-markdown ~/.claude/skills/_obsidian-markdown
```

---

## 境界判断の具体例

| ユーザーの発言 | 判定 | 理由 |
|--------------|------|------|
| 「Lighthouseでサイト全体を監査」 | **web-quality** | 全カテゴリ一括 |
| 「LighthouseのSEOスコアを改善」 | _seo | 単一カテゴリ |
| 「rebaseしたい」 | **git-adv** | 高度Git操作 |
| 「コミットして」 | _code-refactoring | 基本Git |
| 「テストの品質を分析して」 | **test-quality** | 品質分析 |
| 「Vitestのセットアップ」 | testing-strategy | フレームワーク設定 |
| 「スキルを探して」 | skill-forge | スキル検索（forge経由） |
| 「スキルの品質を監査して」 | **skills-guardian** | 品質監査（guardian固有） |
| 「iOSアプリのデザインガイドライン教えて」 | **ios** | Platform固有 |
| 「レスポンシブデザインで実装して」 | _web-design-guidelines | Web CSS設計 |
| 「SNSのマーケティング戦略を立てて」 | **mkt-social** | Marketing固有 |
| 「SEOを改善して」 | _seo | SEO単体 |
| 「Obsidian Basesでビューを作って」 | **obsidian-bases** | Bases固有の高度機能 |
| 「オブにデイリーノートのテンプレ作って」 | obsidian-power-user | 基本的なテンプレート |

---

## 再退避ポリシー

復元したスキルは**そのまま残す**（セッション終了後も有効）。明示的に退避する場合のみ以下を実行:

### mv type を再退避

```bash
mv ~/.claude/skills/_docker-expert ~/.claude/skills-inactive/
mv ~/.claude/skills/_web-quality-audit ~/.claude/skills-inactive/
```

### ln-s type を再退避（リンク削除のみ。ソースは残る）

```bash
# Core
rm ~/.claude/skills/_mermaid-visualizer
rm ~/.claude/skills/_git-advanced-workflows
rm ~/.claude/skills/_api-design-principles
rm ~/.claude/skills/_test-quality-analysis
rm ~/.claude/skills/_skills-quality-guardian
rm ~/.claude/skills/_find-skills
rm ~/.claude/skills/_openai-docs
rm ~/.claude/skills/_remotion-best-practices
rm ~/.claude/skills/_screenshot
rm ~/.claude/skills/_docx
rm ~/.claude/skills/_xlsx
rm ~/.claude/skills/_ffmpeg
rm ~/.claude/skills/_pptx
rm ~/.claude/skills/_pdf

# Platform Design
rm ~/.claude/skills/_ios-design-guidelines
rm ~/.claude/skills/_android-design-guidelines
rm ~/.claude/skills/_macos-design-guidelines
rm ~/.claude/skills/_ipados-design-guidelines
rm ~/.claude/skills/_tvos-design-guidelines
rm ~/.claude/skills/_visionos-design-guidelines
rm ~/.claude/skills/_watchos-design-guidelines

# Marketing
rm ~/.claude/skills/_marketing-content-strategy
rm ~/.claude/skills/_marketing-cro
rm ~/.claude/skills/_marketing-geo-localization
rm ~/.claude/skills/_marketing-paid-advertising
rm ~/.claude/skills/_marketing-social-media
rm ~/.claude/skills/_marketing-visual-design

# Obsidian Extended
rm ~/.claude/skills/_obsidian-bases
rm ~/.claude/skills/_obsidian-markdown
```

---

## 全退避スキルの一括復元

```bash
# mv type
mv ~/.claude/skills-inactive/_docker-expert ~/.claude/skills/ 2>/dev/null
mv ~/.claude/skills-inactive/_web-quality-audit ~/.claude/skills/ 2>/dev/null

# Core ln-s
ln -s ~/.agents/skills/mermaid-visualizer ~/.claude/skills/_mermaid-visualizer 2>/dev/null
ln -s ~/.agents/skills/git-advanced-workflows ~/.claude/skills/_git-advanced-workflows 2>/dev/null
ln -s ~/.agents/skills/api-design-principles ~/.claude/skills/_api-design-principles 2>/dev/null
ln -s ~/.agents/skills/test-quality-analysis ~/.claude/skills/_test-quality-analysis 2>/dev/null
ln -s ~/.agents/skills/skills-quality-guardian ~/.claude/skills/_skills-quality-guardian 2>/dev/null
ln -s ~/.agents/skills/find-skills ~/.claude/skills/_find-skills 2>/dev/null
ln -s ~/.codex/skills/openai-docs ~/.claude/skills/_openai-docs 2>/dev/null
ln -s ~/.codex/skills/remotion-best-practices ~/.claude/skills/_remotion-best-practices 2>/dev/null
ln -s ~/.codex/skills/screenshot ~/.claude/skills/_screenshot 2>/dev/null
ln -s ~/.agents/skills/docx ~/.claude/skills/_docx 2>/dev/null
ln -s ~/.agents/skills/xlsx ~/.claude/skills/_xlsx 2>/dev/null
ln -s ~/.agents/skills/ffmpeg ~/.claude/skills/_ffmpeg 2>/dev/null
ln -s ~/.agents/skills/pptx ~/.claude/skills/_pptx 2>/dev/null
ln -s ~/.agents/skills/pdf ~/.claude/skills/_pdf 2>/dev/null

# Platform Design
ln -s ~/.agents/skills/ios-design-guidelines ~/.claude/skills/_ios-design-guidelines 2>/dev/null
ln -s ~/.agents/skills/android-design-guidelines ~/.claude/skills/_android-design-guidelines 2>/dev/null
ln -s ~/.agents/skills/macos-design-guidelines ~/.claude/skills/_macos-design-guidelines 2>/dev/null
ln -s ~/.agents/skills/ipados-design-guidelines ~/.claude/skills/_ipados-design-guidelines 2>/dev/null
ln -s ~/.agents/skills/tvos-design-guidelines ~/.claude/skills/_tvos-design-guidelines 2>/dev/null
ln -s ~/.agents/skills/visionos-design-guidelines ~/.claude/skills/_visionos-design-guidelines 2>/dev/null
ln -s ~/.agents/skills/watchos-design-guidelines ~/.claude/skills/_watchos-design-guidelines 2>/dev/null

# Marketing
ln -s ~/.agents/skills/marketing-content-strategy ~/.claude/skills/_marketing-content-strategy 2>/dev/null
ln -s ~/.agents/skills/marketing-cro ~/.claude/skills/_marketing-cro 2>/dev/null
ln -s ~/.agents/skills/marketing-geo-localization ~/.claude/skills/_marketing-geo-localization 2>/dev/null
ln -s ~/.agents/skills/marketing-paid-advertising ~/.claude/skills/_marketing-paid-advertising 2>/dev/null
ln -s ~/.agents/skills/marketing-social-media ~/.claude/skills/_marketing-social-media 2>/dev/null
ln -s ~/.agents/skills/marketing-visual-design ~/.claude/skills/_marketing-visual-design 2>/dev/null

# Obsidian Extended
ln -s ~/.agents/skills/obsidian-bases ~/.claude/skills/_obsidian-bases 2>/dev/null
ln -s ~/.agents/skills/obsidian-markdown ~/.claude/skills/_obsidian-markdown 2>/dev/null
```

---

## アンチパターン

| やってはいけないこと | なぜダメか | 正しい対応 |
|-------------------|----------|-----------|
| 復元せずにスキルの知識を推測で回答 | 古い情報・不正確な知識で回答するリスク | 必ず Step 2→3 で復元＆Read してから回答 |
| Collision Avoidance 対象を無視して発火 | アクティブスキルの方が専門的で正確 | SKILL.md の Collision Avoidance テーブルを必ず確認 |
| mv type を ln-s で復元 | skills-inactive からのパスが変わり、再退避不能に | Mapping Table の type 列に従う |
| 壊れたリンクを放置して「source not found」と返す | Step 5 で自動修復できる場合がある | `rm` + 再 `ln -s` を試みる |
| 1リクエストで大量復元（4つ以上） | コンテキストが溢れて回答品質が低下 | 3つまで。4つ以上は要件を絞るよう確認 |

---

## トラブルシュート

### ソースが見つからない

```bash
ls ~/.agents/skills/     # agents スキル確認
ls ~/.codex/skills/      # codex スキル確認
ls ~/.claude/skills-inactive/  # inactive 確認
```

ソース不在 → スキルが移動・削除された可能性。パスを確認して SKILL.md の Mapping Table を更新。

### シンボリックリンクが壊れている

```bash
# 壊れたリンクを検出
find ~/.claude/skills/ -type l ! -exec test -e {} \; -print

# 修復: 削除して再作成
rm ~/.claude/skills/_broken-link
ln -s /correct/source/path ~/.claude/skills/_correct-name
```

### restore が permission denied

```bash
ls -la ~/.claude/skills-inactive/
ls -la ~/.agents/skills/
```

---

## メンテナンス

### スキル追加チェックリスト

1. [ ] SKILL.md の Mapping Table に行追加（key, keywords, dir, type, source）
2. [ ] SKILL.md の description にキーワード追加
3. [ ] description が 1024文字以内:
   ```bash
   sed -n '4p' ~/.claude/skills/_skill-loader/SKILL.md | wc -c
   ```
4. [ ] SKILL.md が 10KB / 500行以内:
   ```bash
   wc -c -l ~/.claude/skills/_skill-loader/SKILL.md
   ```
5. [ ] Collision Avoidance テーブルに衝突がないか確認
6. [ ] 本ファイルの復元コマンド・再退避コマンド・一括復元にも追加
7. [ ] 境界判断の具体例に該当ケースを追加

### FAQ

**Q: 復元したスキルはいつ消える？**
A: 消えない。明示的に再退避コマンドを実行するまでアクティブなまま。

**Q: 同時に複数スキルを復元できる？**
A: 3つまで推奨。4つ以上は要件を絞るよう確認してから。

**Q: ln-s で復元したスキルのソースを更新したら？**
A: シンボリックリンクなので自動的に最新が反映される。再復元不要。

**Q: skill-loader 自体を更新するには？**
A: `~/.claude/skills/_skill-loader/SKILL.md` を直接編集。description の文字数とファイルサイズの制限を確認すること。

**Q: Platform系を全部まとめて復元したい場合は？**
A: 一括復元スクリプト（上記）のPlatform Designセクションをコピー実行。
