---
name: obsidian-power-user
description: "Obsidian vault: wikilinks, callouts, embeds, frontmatter, Bases YAML views/formulas, Dataview DQL, Templater, QuickAdd"
user-invocable: true
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

基本形: `[[Note]]`, `[[Note|Display]]`, `[[Note#Heading]]`, `[[#Same note heading]]`, `[[Note#^block-id]]`, `[[Note#^block-id|Custom]]`

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
![[Note]]  ![[Note#Heading]]  ![[Note#^block-id]]
![[image.png|300]]  ![[image.png|640x480]]
![[audio.mp3]]  ![[doc.pdf]]  ![[doc.pdf#page=3]]
```

### Embed Search Results [MEDIUM]

`` ```query`` ブロックで検索結果を埋め込み

## A3. Callouts [CRITICAL]

```markdown
> [!note] Title              ← タイトル付き、ネスト可 (> > [!tip])
> [!warning]- Collapsed      ← `-` で折り畳み（閉）、`+` で開
```

Types: `note`, `abstract`(summary/tldr), `info`, `todo`, `tip`(hint/important), `success`(check/done), `question`(help/faq), `warning`(caution/attention), `failure`(fail/missing), `danger`(error), `bug`, `example`, `quote`(cite)

## A4. Properties / Frontmatter [HIGH]

```yaml
---
title: My Note Title
date: YYYY-MM-DD
tags: [project, important]
---
```

他キー: `aliases`, `cssclasses`, `status`, `rating` (Number), `completed` (Boolean), `due` (DateTime)。全プロパティ型: reference.md「Frontmatter Strategy」

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
Visible %%inline hidden%% text.   %%block: wrap in %% on separate lines%%
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

Top-level keys: `filters`, `formulas`, `properties`, `summaries`, `views`

```yaml
views:
  - type: table | cards | list | map
    name: "View Name"
    order: [file.name, property_name, formula.formula_name]
    groupBy: { property: prop_name, direction: ASC | DESC }
```

-> 全キー展開形式: reference.md「Bases: Complete Schema (Verbose)」

Full schema with comments: see [reference.md](reference.md)

## B3. Filter Syntax [CRITICAL]

```yaml
filters: 'status == "done"'                              # Single
filters: { and: ['status == "done"', 'priority > 3'] }   # AND
filters: { or: [...], not: [...] }                        # OR / NOT
```

ネスト: `or:` 内に `and:` / `not:` を組み合わせ可能。

-> ネストフィルタの完全例: reference.md「Bases Filter Nested Example」

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
  days_until: 'if(due_date, (date(due_date) - today()).days, "")'
```

More examples (`formatted`, `created`, `days_old`): see [reference.md](reference.md)

**IMPORTANT**: Date subtraction returns **Duration** type. Access `.days`, `.hours` etc. for numeric value. Duration does NOT support `.round()` directly -- use `(expr).days.round(0)`.

## B6. View Types [HIGH]

```yaml
views:
  - type: table
    name: "My Table"
    order: [file.name, status, due_date]
    summaries: { price: Sum }
```

- **cards**: Gallery view. `order` に `cover_image` 等を含める
- **list**: シンプルなリスト表示。`order` で表示プロパティ指定
- **map**: Maps plugin + `lat`/`lng` プロパティが必要

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

よく使う条件: `file.name != "Template"`, `status = "active"`, `date >= date(today) - dur(7 days)`, `contains(tags, "#important")`, `!completed`, `length(file.outlinks) > 0`

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

`` `= expression` `` 構文でインライン出力。例: `` `= date(today)` ``, `` `= this.file.tags` ``, `` `= length(filter(this.file.tasks, (t) => !t.completed))` ``

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

### tp.date / tp.system

```markdown
Today: <% tp.date.now("YYYY-MM-DD") %>
Yesterday: <% tp.date.now("YYYY-MM-DD", -1) %>
```

- `tp.date.now(fmt, offset, ref, refFmt)` — 4th arg でファイル名から日付パース（Daily Notes用）
- `tp.system.prompt()` でテキスト入力、`tp.system.suggester()` で選択UI → [reference.md](reference.md) 参照

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

## Decision Tree

やりたいこと → ノート間リンク？ → `[[Wikilinks]]`（エイリアス: `[[Note|Display]]`、ブロック参照: `[[Note#^block-id]]`） / データ集計？ → Dataview（TABLE/LIST/TASK/CALENDAR、DQLクエリ） / テンプレ？ → Templater（`tp.file.*`, `tp.date.*`, `tp.system.*`） / 自動化？ → QuickAdd（Template/Capture/Macro の3モード）

Dataview クエリ選択 → 表形式？ → `TABLE field FROM "folder" WHERE condition SORT field` / リスト？ → `LIST` / タスク管理？ → `TASK` / 日付ベース？ → `CALENDAR`

データ表示の選択 → 動的クエリ（自動更新）？ → Dataview DQL / 静的ビュー（フィルタ・ソート・集計UI付き）？ → Bases `.base` ファイル / インライン値？ → `` `= expression` `` インラインDataview

テンプレート入力 → ユーザー入力が必要？ → `tp.system.prompt()` or `tp.system.suggester()` / 日付自動挿入？ → `tp.date.now()` / ファイル情報？ → `tp.file.title`, `tp.file.creation_date()`

## Checklist

- [ ] Wikilink `[[]]` とエイリアス `[[target|display]]` の使い分けが正しいか
- [ ] Properties（frontmatter）に必要なメタデータが含まれているか
- [ ] Callout の種類（note/warning/tip等）が内容に適しているか
- [ ] Dataview クエリの FROM / WHERE / SORT が意図通りか
- [ ] Templater テンプレートの `tp.system.prompt()` にデフォルト値があるか
- [ ] Bases `.base` ファイルのフィルタ条件が正しく設定されているか
- [ ] 埋め込み `![[note]]` の対象ファイルが存在するか

## Cross-references [MEDIUM]

- **natural-japanese-writing**: Obsidianノートの日本語ライティング品質向上に併用
- **typescript-best-practices**: DataviewJS コード記述時の型安全パターン
- **dashboard-data-viz**: Bases viewsのダッシュボード設計をデータ可視化原則と組み合わせる

## Reference

Full function lists, field references, and API details: see [reference.md](reference.md)
