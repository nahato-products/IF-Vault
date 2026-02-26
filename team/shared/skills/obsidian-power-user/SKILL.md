---
name: obsidian-power-user
description: "Obsidian vault management and automation across three domains. Flavored Markdown: wikilinks, callouts (13 types with folding), embeds (notes, images, PDFs, block refs), block IDs, highlights, footnotes, properties/frontmatter. Bases: .base YAML with table/cards/list/map views, filter logic (and/or/not), formulas, summaries. Automation: Dataview DQL (TABLE/LIST/TASK/CALENDAR, FROM/WHERE/SORT/GROUP BY, inline queries, DataviewJS dv.* API), Templater (tp.file/tp.date/tp.system), QuickAdd (template/capture/macro). Use when creating, editing, querying, or debugging .md or .base files in Obsidian vaults, writing Dataview queries, building templates, configuring macros, or designing vault structure. Does NOT cover Japanese prose quality (natural-japanese-writing), web HTML standards (web-design-guidelines), or database queries."
user-invocable: false
---

# Obsidian Power User

Obsidian固有構文、Basesファイル、Dataview/Templater/QuickAdd自動化の統合スキル。

## When to Apply

- `.md` ファイルでObsidian固有構文（wikilinks, callouts, embeds, block ID）を使う
- `.base` ファイルの作成・編集（views, filters, formulas）
- Dataview クエリの作成・デバッグ（TABLE/LIST/TASK/CALENDAR）
- Templater テンプレートの設計・tp.* 関数の使い方
- QuickAdd マクロ/キャプチャの設定
- Vault構造設計・frontmatter戦略・タグ設計

## When NOT to Apply

- 基本Markdown記法（見出し、太字、リスト、コードブロック等）→ Claudeの既知範囲
- プラグインなしの純粋なMarkdown編集

---

# PART A: Obsidian Flavored Markdown [CRITICAL]

## A1. Internal Links (Wikilinks) [CRITICAL]

```markdown
[[Note Name]]                     基本リンク
[[Note Name|Display Text]]        表示テキスト変更
[[Note Name#Heading]]             見出しリンク
[[#Heading in same note]]         同一ノート内見出し
[[Note Name#^block-id]]           ブロックリンク
[[Note Name#^block-id|Custom]]    ブロックリンク+表示テキスト
```

### Block ID [HIGH]

段落末尾に `^block-id` を追加してブロック参照可能にする:

```markdown
This is a paragraph that can be linked to. ^my-block-id
```

リスト・引用の場合は空行の後に:

```markdown
> Quote content
> Multiple lines

^quote-id
```

## A2. Embeds [CRITICAL]

```markdown
![[Note Name]]                    ノート埋め込み
![[Note Name#Heading]]            見出しセクション埋め込み
![[Note Name#^block-id]]          ブロック埋め込み
![[image.png]]                    画像
![[image.png|300]]                幅指定
![[image.png|640x480]]            幅x高さ指定
![[audio.mp3]]                    音声
![[document.pdf]]                 PDF
![[document.pdf#page=3]]          PDFページ指定
```

### Embed Search Results [MEDIUM]

`` ```query`` ブロックで検索結果を埋め込み

## A3. Callouts [CRITICAL]

```markdown
> [!note]
> Basic callout.

> [!info] Custom Title
> With custom title.

> [!faq]- Collapsed by default
> Foldable (collapsed).

> [!faq]+ Expanded by default
> Foldable (expanded).

> [!question] Outer
> > [!note] Nested
> > Nested callout content.
```

Types: `note`, `abstract` (summary/tldr), `info`, `todo`, `tip` (hint/important), `success` (check/done), `question` (help/faq), `warning` (caution/attention), `failure` (fail/missing), `danger` (error), `bug`, `example`, `quote` (cite)

## A4. Properties / Frontmatter [HIGH]

```yaml
---
title: My Note Title
date: YYYY-MM-DD
tags:
  - project
  - important
aliases:
  - My Note
cssclasses:
  - custom-class
status: in-progress
rating: 4.5
completed: false
due: YYYY-MM-DDThh:mm:ss
---
```

Property types: Text, Number, Checkbox (boolean), Date, Date & Time, List, Links (`"[[Other Note]]"`)

Default properties: `tags`, `aliases`, `cssclasses`

## A5. Tags [HIGH]

```markdown
#tag  #nested/tag  #tag-with-dashes  #tag_with_underscores
```

- Letters (any language), numbers (not first char), `_`, `-`, `/` (nesting)
- Frontmatter: `tags: [tag1, nested/tag2]`

## A6. Comments [MEDIUM]

```markdown
This is visible %%but this is hidden%% text.

%%
This entire block is hidden in reading view.
%%
```

## A7. Other Obsidian Extensions [MEDIUM]

- **Highlight**: `==highlighted text==`
- **Footnotes**: `[^1]` / `[^1]: content` / `^[inline footnote]`
- **Math**: `$inline$` / `$$block$$` (LaTeX)
- **Mermaid**: ` ```mermaid ` code blocks
- **HTML**: `<details><summary>...</summary>...</details>` etc.
- **Pipes in tables**: Escape with `\|` inside wikilinks in tables

---

# PART B: Obsidian Bases (.base Files) [CRITICAL]

## B1. File Format [HIGH]

`.base` 拡張子のYAMLファイル。Markdown内に `![[MyBase.base]]` で埋め込み可能。

## B2. Complete Schema [CRITICAL]

```yaml
# Global filters (all views)
filters:
  and: []
  or: []
  not: []

# Computed properties
formulas:
  formula_name: 'expression'

# Display name overrides
properties:
  property_name:
    displayName: "Display Name"
  formula.formula_name:
    displayName: "Formula Display"

# Custom summary formulas
summaries:
  custom_name: 'values.mean().round(3)'

# Views
views:
  - type: table | cards | list | map
    name: "View Name"
    limit: 10
    groupBy:
      property: property_name
      direction: ASC | DESC
    filters:
      and: []
    order:
      - file.name
      - property_name
      - formula.formula_name
    summaries:
      property_name: Average
```

## B3. Filter Syntax [CRITICAL]

```yaml
# Single filter
filters: 'status == "done"'

# AND - all must be true
filters:
  and:
    - 'status == "done"'
    - 'priority > 3'

# OR - any can be true
filters:
  or:
    - file.hasTag("book")
    - file.hasTag("article")

# NOT - exclude
filters:
  not:
    - file.hasTag("archived")

# Nested
filters:
  or:
    - file.hasTag("tag")
    - and:
        - file.hasTag("book")
        - file.hasLink("Textbook")
    - not:
        - file.hasTag("book")
        - file.inFolder("Required Reading")
```

Operators: `==`, `!=`, `>`, `<`, `>=`, `<=`, `&&`, `||`, `!`

## B4. Property Types [HIGH]

1. **Note properties** (frontmatter): `author` or `note.author`
2. **File properties**: `file.name`, `file.mtime`, etc.
3. **Formula properties**: `formula.my_formula`

### File Properties

主要: `file.name`, `file.path`, `file.ctime`, `file.mtime`, `file.tags` → 全一覧は [reference.md](reference.md) 参照

### `this` Keyword [HIGH]

- Main content: refers to the base file itself
- Embedded: refers to the embedding file
- Sidebar: refers to the active file

## B5. Formula Syntax [CRITICAL]

```yaml
formulas:
  total: "price * quantity"
  status_icon: 'if(done, "✅", "⏳")'
  formatted: 'if(price, price.toFixed(2) + " dollars")'
  created: 'file.ctime.format("YYYY-MM-DD")'
  days_old: '(now() - file.ctime).days'
  days_until: 'if(due_date, (date(due_date) - today()).days, "")'
```

**IMPORTANT**: Date subtraction returns **Duration** type. Access `.days`, `.hours` etc. for numeric value. Duration does NOT support `.round()` directly -- use `(expr).days.round(0)`.

## B6. View Types [HIGH]

```yaml
# Table
views:
  - type: table
    name: "My Table"
    order: [file.name, status, due_date]
    summaries:
      price: Sum

# Cards
views:
  - type: cards
    name: "Gallery"
    order: [file.name, cover_image, description]

# List
views:
  - type: list
    name: "Simple List"
    order: [file.name, status]

# Map (requires Maps plugin + lat/lng properties)
views:
  - type: map
    name: "Locations"
```

## B7. Default Summary Formulas [MEDIUM]

主要: `Average`, `Sum`, `Min`/`Max`, `Earliest`/`Latest`, `Empty`/`Filled` → 全一覧は [reference.md](reference.md) 参照

## B8. Complete Base Example [HIGH]

→ タスク管理Baseの実用例: [reference.md](reference.md) 参照

## B9. Embedding Bases [HIGH]

```markdown
![[MyBase.base]]
![[MyBase.base#View Name]]
```

## B10. YAML Quoting Rules [HIGH]

- Single quotes for formulas with double quotes: `'if(done, "Yes", "No")'`
- Double quotes for simple strings: `"My View Name"`

---

# PART C: Automation (Dataview, Templater, QuickAdd) [CRITICAL]

## C1. Dataview DQL [CRITICAL]

### 4 Query Types

| Type | Output | Use |
|------|--------|-----|
| `TABLE` | Table | Dashboards, listings |
| `LIST` | Bullet list | Simple enumeration |
| `TASK` | Checklist | TODO management |
| `CALENDAR` | Calendar | Date-based visualization |

### TABLE Syntax

````
```dataview
TABLE field1 AS "Display", field2
FROM "folder" OR #tag
WHERE condition
SORT field DESC
LIMIT 20
GROUP BY field
```
````

### FROM Sources

| Source | Example |
|--------|---------|
| Folder | `FROM "Projects"` |
| Tag | `FROM #status/active` |
| Incoming links | `FROM [[Note]]` |
| Outgoing links | `FROM outgoing([[Note]])` |
| Combined | `FROM "Projects" AND #active` |

### WHERE Conditions

```
WHERE file.name != "Template"
WHERE status = "active"
WHERE date >= date(today) - dur(7 days)
WHERE contains(tags, "#important")
WHERE !completed
WHERE length(file.outlinks) > 0
```

### Implicit Fields (Top 5)

| Field | Type | Description |
|-------|------|-------------|
| `file.name` | text | File name (no ext) |
| `file.link` | link | Link to file |
| `file.ctime`/`file.mtime` | date | Created/Modified |
| `file.tags` | list | All tags |
| `file.tasks` | list | All tasks |

Full field list: see [reference.md](reference.md)

### Inline Dataview

```markdown
Today: `= date(today)`
Tags: `= this.file.tags`
Open tasks: `= length(filter(this.file.tasks, (t) => !t.completed))`
```

### DataviewJS

→ `dv.pages()` / `dv.table()` 等の使い方: [reference.md](reference.md) DataviewJS dv.* API 参照

### GROUP BY

```
TABLE length(rows) AS "Count", rows.file.link AS "Notes"
FROM "Projects"
GROUP BY status
```

`GROUP BY` 使用時、各行は `rows` 配列に格納。`rows.field` でグループ内値へアクセス。

### Date Operations

```
WHERE file.ctime >= date(today) - dur(30 days)
WHERE due <= date(today)
```

| Function | Description |
|----------|-------------|
| `date(today)` | Today |
| `date(now)` | Now (with time) |
| `dur(N days)` | Duration (days/weeks/months/years) |
| `date("YYYY-MM-DD")` | Parse date string |

## C2. Templater [CRITICAL]

### tp.* Categories

| Category | Prefix | Use |
|----------|--------|-----|
| File | `tp.file.*` | Name, path, create, move |
| Date | `tp.date.*` | Format, calc |
| System | `tp.system.*` | User input, clipboard |
| Frontmatter | `tp.frontmatter.*` | Read frontmatter values |

### tp.file

```markdown
File: <% tp.file.title %>
Created: <% tp.file.creation_date("YYYY-MM-DD") %>
```

`tp.file.create_new()`, `tp.file.move()`, `tp.file.rename()` → [reference.md](reference.md) tp.file 参照

### tp.date

```markdown
Today: <% tp.date.now("YYYY-MM-DD") %>
Yesterday: <% tp.date.now("YYYY-MM-DD", -1) %>
```

4th arg (`tp.date.now(fmt, offset, ref, refFmt)`) でファイル名から日付パース（Daily Notes用）

### tp.system

`tp.system.prompt()` でテキスト入力、`tp.system.suggester()` で選択UI → [reference.md](reference.md) tp.system 参照

### Daily Note Template Example

→ [reference.md](reference.md) 参照

## C3. QuickAdd [HIGH]

### 3 Modes

| Mode | Use |
|------|-----|
| Template | Create note from Templater template |
| Capture | Append text to existing note |
| Macro | Chain multiple steps |

### Capture Format

```
Target: "Inbox/Quick Notes.md"
Position: End of file
Format: "- {{DATE:HH:mm}} {{VALUE}}"
```

`{{VALUE}}` = user input, `{{DATE:format}}` = datetime

### Macro Workflow

```
Macro: "New Project"
  1. Template → Projects/{{VALUE}}.md
  2. Capture → Projects/Index.md
  3. User Choice → status selection
```

## C4. Vault Design [MEDIUM]

→ PARA構造、Frontmatter戦略は [reference.md](reference.md) 参照

---

## Cross-references [MEDIUM]

- **natural-japanese-writing**: Obsidianノートの日本語ライティング品質向上に併用
- **typescript-best-practices**: DataviewJS コード記述時の型安全パターン
- **dashboard-data-viz**: Bases viewsのダッシュボード設計をデータ可視化原則と組み合わせる

## Reference

Full function lists, field references, and API details: see [reference.md](reference.md)
