---
name: obsidian-automation
description: Obsidian automation with Dataview, Templater, and QuickAdd plugins. Covers DQL queries (TABLE/LIST/TASK/CALENDAR), inline Dataview, Templater tp.* functions, daily note templates, QuickAdd macros/captures, tag strategies, frontmatter design, and plugin development basics. Use when writing Dataview queries, creating Templater templates, setting up QuickAdd macros, automating daily notes, designing vault structure, building Obsidian plugins, querying frontmatter, or filtering tasks in Obsidian. Do not trigger for basic Obsidian Markdown syntax (use obsidian-markdown), Bases files (use obsidian-bases), or plain Markdown editing without plugins.
user-invocable: false
triggers:
  - Dataviewクエリを書く
  - Templaterテンプレートを作る
  - QuickAddマクロを設定する
  - デイリーノートを自動化する
  - Vault構造を設計する
---

# Obsidian Automation

Dataview, Templater, QuickAdd を中心としたオブの自動化パターン集。

## When to Apply

- Dataview クエリの作成・デバッグ（TABLE/LIST/TASK/CALENDAR）
- Templater テンプレートの設計・tp.* 関数の使い方
- QuickAdd マクロ/キャプチャの設定
- Vault構造設計・frontmatter戦略・タグ設計

## When NOT to Apply

- Obsidian の基本Markdown記法 → obsidian-markdown 参照
- Obsidian Bases (.base ファイル) → obsidian-bases 参照
- プラグインなしの純粋なMarkdown編集

---

## Part 1: Dataview 基本 [CRITICAL]

### 1. DQL クエリ4種

| 種類 | 出力 | 用途 |
|------|------|------|
| `TABLE` | 表形式 | 一覧・ダッシュボード |
| `LIST` | 箇条書き | シンプルな列挙 |
| `TASK` | チェックリスト | TODO管理 |
| `CALENDAR` | カレンダー | 日付ベースの可視化 |

### 2. TABLE クエリ構文

````
```dataview
TABLE filed1 AS "表示名", field2
FROM "folder" OR #tag
WHERE condition
SORT field DESC
LIMIT 20
GROUP BY field
```
````

### 3. FROM ソース指定

| ソース | 例 | 説明 |
|--------|-----|------|
| フォルダ | `FROM "Projects"` | フォルダ内のノート |
| タグ | `FROM #status/active` | タグ付きノート |
| リンク元 | `FROM [[Note]]` | Noteへリンクしているノート |
| リンク先 | `FROM outgoing([[Note]])` | Noteからリンクされたノート |
| 複合 | `FROM "Projects" AND #active` | AND/OR/NOT で結合 |

### 4. WHERE 条件式

```
WHERE file.name != "Template"
WHERE status = "進行中"
WHERE date >= date(today) - dur(7 days)
WHERE contains(tags, "#important")
WHERE !completed
WHERE length(file.outlinks) > 0
```

### 5. 暗黙フィールド（Implicit Fields）

| フィールド | 型 | 説明 |
|-----------|-----|------|
| `file.name` | text | ファイル名（拡張子なし） |
| `file.path` | text | Vault内パス |
| `file.folder` | text | 親フォルダ |
| `file.ctime` | date | 作成日時 |
| `file.mtime` | date | 更新日時 |
| `file.size` | number | バイト数 |
| `file.tags` | list | 全タグ（ネスト含む） |
| `file.outlinks` | list | 発リンク |
| `file.inlinks` | list | 被リンク |
| `file.tasks` | list | タスク一覧 |
| `file.day` | date | ファイル名内の日付（Daily Note） |

全フィールドは [reference.md](reference.md) を参照。

---

## Part 2: Dataview 応用 [HIGH]

### 6. インライン Dataview

本文中に埋め込み可能。バッククォート内に `=` プレフィックス。

```markdown
今日: `= date(today)`
このノートのタグ: `= this.file.tags`
未完了タスク数: `= length(filter(this.file.tasks, (t) => !t.completed))"`
```

### 7. DataviewJS

DQLで表現できない複雑なロジック用。`dataviewjs` コードブロックで記述。

````
```dataviewjs
const pages = dv.pages('"Projects"')
  .where(p => p.status === "active")
  .sort(p => p.priority, "asc");

dv.table(["Name", "Priority", "Due"],
  pages.map(p => [p.file.link, p.priority, p.due])
);
```
````

**注意**: DataviewJS は任意のJS実行が可能。セキュリティを意識し、信頼できるVaultでのみ使用。

### 8. GROUP BY と集計

```
TABLE length(rows) AS "件数", rows.file.link AS "ノート"
FROM "Projects"
GROUP BY status
```

`GROUP BY` 使用時、各行は `rows` 配列に格納される。`rows.field` でグループ内の値リストにアクセス。

### 9. 日付操作

```
WHERE file.ctime >= date(today) - dur(30 days)
WHERE due <= date(today)
WHERE date(created) = date("2025-01-15")
```

| 関数 | 例 | 説明 |
|------|-----|------|
| `date(today)` | 今日 | 現在日 |
| `date(now)` | 現在 | 日時 |
| `dur(N days)` | 期間 | days/weeks/months/years |
| `date("YYYY-MM-DD")` | 指定日 | 文字列→日付変換 |

---

## Part 3: Templater [CRITICAL]

### 10. tp.* 関数カテゴリ

| カテゴリ | プレフィックス | 主な用途 |
|---------|-------------|---------|
| File | `tp.file.*` | ファイル名、パス、作成、移動 |
| Date | `tp.date.*` | 日付フォーマット、計算 |
| System | `tp.system.*` | ユーザー入力、クリップボード |
| Frontmatter | `tp.frontmatter.*` | frontmatter値の読取り |
| Web | `tp.web.*` | Web API呼出し |
| Hooks | `tp.hooks.*` | イベントフック |

### 11. よく使う tp.file

```markdown
ファイル名: <% tp.file.title %>
作成日: <% tp.file.creation_date("YYYY-MM-DD") %>
フォルダ: <% tp.file.folder() %>
```

```markdown
<%*
// 新規ファイル作成
await tp.file.create_new(tp.file.find_tfile("Template"), "NewNote", "Folder");

// ファイル移動
await tp.file.move("/Archive/" + tp.file.title);

// リネーム
await tp.file.rename("新しい名前");
%>
```

### 12. tp.date

```markdown
今日: <% tp.date.now("YYYY-MM-DD") %>
昨日: <% tp.date.now("YYYY-MM-DD", -1) %>
来週: <% tp.date.now("YYYY-MM-DD", 7) %>
曜日: <% tp.date.now("dddd", 0, tp.file.title, "YYYY-MM-DD") %>
```

第4引数でファイル名の日付フォーマットを指定 → Daily Noteのファイル名から日付パース。

### 13. tp.system（ユーザー入力）

```markdown
<%*
const title = await tp.system.prompt("タイトルを入力");
const category = await tp.system.suggester(
  ["Work", "Personal", "Study"],  // 表示テキスト
  ["work", "personal", "study"]    // 実際の値
);
%>
---
title: <% title %>
category: <% category %>
---
```

---

## Part 4: Daily Note テンプレート [HIGH]

### 14. Daily Note テンプレ例

```markdown
---
date: <% tp.date.now("YYYY-MM-DD") %>
day: <% tp.date.now("dddd") %>
tags: [daily]
---

# <% tp.date.now("YYYY年MM月DD日 (ddd)") %>

## Tasks
- [ ]

## Notes


## Log

---
<< [[<% tp.date.now("YYYY-MM-DD", -1) %>]] | [[<% tp.date.now("YYYY-MM-DD", 1) %>]] >>
```

### 15. Weekly Note テンプレ例

```markdown
---
week: <% tp.date.now("YYYY-[W]ww") %>
tags: [weekly]
---

# Week <% tp.date.now("ww") %> (<% tp.date.now("YYYY") %>)

## Goals
1.

## Daily Links
<%* for(let i = 1; i <= 5; i++) { %>
- [[<% tp.date.now("YYYY-MM-DD", i - tp.date.now("d")) %>]]
<%* } %>
```

---

## Part 5: QuickAdd [HIGH]

### 16. 3つのモード

| モード | 用途 | 説明 |
|-------|------|------|
| Template | ノート作成 | Templater テンプレートからノート生成 |
| Capture | 追記 | 既存ノートにテキスト追記 |
| Macro | 自動化 | 複数ステップの連続実行 |

### 17. Capture 設定例

```
対象ファイル: "Inbox/Quick Notes.md"
挿入位置: ファイル末尾
フォーマット: "- {{DATE:HH:mm}} {{VALUE}}"
```

`{{VALUE}}` でユーザー入力、`{{DATE:format}}` で日時挿入。

### 18. Macro でワークフロー自動化

```
Macro: "New Project"
  1. Template → Projects/{{VALUE}}.md（テンプレから作成）
  2. Capture → Projects/Index.md（インデックスに追記）
  3. ユーザーChoice → ステータス選択
```

---

## Part 6: Vault 設計 [MEDIUM]

### 19. フォルダ構造パターン

```
Vault/
├── 00-Inbox/          # 未整理ノート
├── 10-Projects/       # アクティブプロジェクト
├── 20-Areas/          # 継続的な関心領域
├── 30-Resources/      # 参考資料
├── 40-Archive/        # 完了・非アクティブ
├── Templates/         # テンプレート
└── Daily/             # Daily Notes
```

PARA メソッド準拠。番号プレフィックスでソート安定化。

### 20. Frontmatter 設計原則

```yaml
---
title: "ノートタイトル"
status: "draft"          # draft / active / completed / archived
type: "note"             # note / project / meeting / reference
created: 2025-01-15
tags: [topic/ai, area/work]
---
```

- **型を統一**: 日付はYYYY-MM-DD、数値は数値型で
- **タグは階層化**: `topic/subtopic` 形式でDataviewフィルタしやすく
- **statusとtype**: Dataview WHERE句の主要フィルタ条件

### 21. タグ vs フォルダ vs リンク

| 分類手段 | 強み | 弱み | 推奨用途 |
|---------|------|------|---------|
| フォルダ | 排他的分類、視覚的 | 1ノート1フォルダ | プロジェクト、ライフサイクル |
| タグ | 複数付与可、階層化 | 増殖しやすい | 属性、ステータス、トピック |
| リンク | コンテキスト豊富 | 構造化しにくい | 関連性、参照 |

---

## Part 7: プラグイン開発基礎 [MEDIUM]

### 22. 開発環境

```bash
# 公式テンプレートを使用
git clone https://github.com/obsidianmd/obsidian-sample-plugin.git
cd obsidian-sample-plugin
npm install && npm run dev
```

### 23. main.ts 基本構造

```typescript
import { Plugin, PluginSettingTab, Setting } from 'obsidian';

export default class MyPlugin extends Plugin {
  async onload() {
    // コマンド登録
    this.addCommand({
      id: 'my-command',
      name: 'My Command',
      callback: () => { /* ... */ }
    });

    // リボンアイコン
    this.addRibbonIcon('dice', 'My Plugin', () => { /* ... */ });

    // 設定タブ
    this.addSettingTab(new MySettingTab(this.app, this));
  }

  onunload() { /* クリーンアップ */ }
}
```

### 24. 主要API

| API | 用途 |
|-----|------|
| `this.app.vault` | ファイル操作（CRUD） |
| `this.app.workspace` | エディタ、ペイン操作 |
| `this.app.metadataCache` | frontmatter、リンク情報 |
| `this.registerEvent()` | イベントリスナー（自動クリーンアップ） |
| `this.registerInterval()` | setInterval（自動クリーンアップ） |

---

## Reference

暗黙フィールド全一覧、tp.*関数リファレンス、Dataview関数一覧、DataviewJS dv.* API、QuickAdd変数一覧は [reference.md](reference.md) を参照。

## Cross-references

- **obsidian-power-user**: Obsidian全体の活用法
- **_obsidian-markdown**: 基本Markdown記法
- **_obsidian-bases**: Bases (.base) ファイル操作
