# Obsidian Power User — Reference

SKILL.md の補足資料。SKILL.md で `[reference.md](reference.md) 参照` と記された項目の詳細がここにある。内容: Bases file/summary properties、Vault設計、テンプレート例、Dataview暗黙フィールド全一覧、tp.* 関数、Dataview関数、DataviewJS API、QuickAdd変数、実用クエリ例、トラブルシューティング。

---

## Bases: File Properties 全一覧

| Property | Type | Description |
|----------|------|-------------|
| `file.name` | String | File name |
| `file.basename` | String | Name without extension |
| `file.path` | String | Full path |
| `file.folder` | String | Parent folder |
| `file.ext` | String | Extension |
| `file.size` | Number | Bytes |
| `file.ctime` | Date | Created time |
| `file.mtime` | Date | Modified time |
| `file.tags` | List | All tags |
| `file.links` | List | Internal links |
| `file.backlinks` | List | Files linking to this |
| `file.embeds` | List | Embeds in note |
| `file.properties` | Object | All frontmatter |

---

## Bases: Default Summary Formulas

| Name | Input | Description |
|------|-------|-------------|
| `Average` | Number | Mean |
| `Min`/`Max` | Number | Min/Max |
| `Sum` | Number | Sum |
| `Range` | Number | Max - Min |
| `Median` | Number | Median |
| `Stddev` | Number | Standard deviation |
| `Earliest`/`Latest` | Date | Earliest/Latest |
| `Checked`/`Unchecked` | Boolean | Count true/false |
| `Empty`/`Filled` | Any | Count empty/non-empty |
| `Unique` | Any | Count unique |

---

## Templater: Daily Note Template Example

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

---

## Vault Design

### Folder Structure (PARA)

```
Vault/
├── 00-Inbox/          # Unsorted
├── 10-Projects/       # Active projects
├── 20-Areas/          # Ongoing areas
├── 30-Resources/      # Reference material
├── 40-Archive/        # Completed/inactive
├── Templates/
└── Daily/
```

### Frontmatter Strategy

```yaml
---
title: "Note Title"
status: "draft"          # draft / active / completed / archived
type: "note"             # note / project / meeting / reference
created: YYYY-MM-DD
tags: [topic/ai, area/work]
---
```

- Consistent types: dates as YYYY-MM-DD, numbers as numbers
- Hierarchical tags: `topic/subtopic` for easy Dataview filtering
- `status`/`type`: primary Dataview WHERE filters

---

## Dataview 暗黙フィールド全一覧

### file.* フィールド

| フィールド | 型 | 説明 |
|-----------|-----|------|
| `file.name` | text | ファイル名（拡張子なし） |
| `file.path` | text | Vault内フルパス |
| `file.folder` | text | 親フォルダパス |
| `file.ext` | text | 拡張子 |
| `file.link` | link | ファイルへのリンク |
| `file.size` | number | バイト数 |
| `file.ctime` | date | 作成日時 |
| `file.cday` | date | 作成日（時刻なし） |
| `file.mtime` | date | 更新日時 |
| `file.mday` | date | 更新日（時刻なし） |
| `file.tags` | list | 全タグ（本文+frontmatter、ネスト親含む） |
| `file.etags` | list | 明示タグのみ（ネスト親を含まない） |
| `file.inlinks` | list | 被リンク（このファイルを参照するファイル） |
| `file.outlinks` | list | 発リンク（このファイルが参照するファイル） |
| `file.aliases` | list | frontmatter aliases |
| `file.tasks` | list | ファイル内の全タスク |
| `file.lists` | list | ファイル内の全リスト項目 |
| `file.frontmatter` | object | frontmatter全体 |
| `file.day` | date | ファイル名に含まれる日付（Daily Note用） |
| `file.starred` | boolean | ブックマーク済みか（Obsidian v1.0+ では Bookmarks プラグインに移行。`file.starred` の代わりに Bookmarks API を使用） |

### タスクフィールド（file.tasks 内）

| フィールド | 型 | 説明 |
|-----------|-----|------|
| `completed` | boolean | チェック済みか |
| `text` | text | タスクテキスト |
| `status` | text | ステータス文字（`x`, ` `, `-`, etc.） |
| `line` | number | 行番号 |
| `section` | link | 所属セクション |
| `tags` | list | タスク内のタグ |
| `due` | date | `[due:: YYYY-MM-DD]` |
| `created` | date | `[created:: YYYY-MM-DD]` |
| `scheduled` | date | `[scheduled:: YYYY-MM-DD]` |
| `completion` | date | `[completion:: YYYY-MM-DD]` |

---

## Dataview 関数リファレンス

### 文字列関数

| 関数 | 説明 | 例 |
|------|------|-----|
| `contains(str, sub)` | 部分文字列検索 | `contains(file.name, "Meeting")` |
| `startswith(str, prefix)` | 前方一致 | `startswith(status, "active")` |
| `endswith(str, suffix)` | 後方一致 | |
| `replace(str, old, new)` | 置換 | |
| `lower(str)` | 小文字化 | |
| `upper(str)` | 大文字化 | |
| `length(str)` | 文字数 | |
| `regexmatch(pattern, str)` | 正規表現マッチ | `regexmatch("^2025", string(date))` |
| `split(str, sep)` | 分割 | |
| `join(list, sep)` | 結合 | `join(file.tags, ", ")` |

### リスト関数

| 関数 | 説明 | 例 |
|------|------|-----|
| `length(list)` | 要素数 | `length(file.tags)` |
| `contains(list, item)` | 要素含有 | `contains(tags, "#work")` |
| `filter(list, fn)` | フィルタ | `filter(file.tasks, (t) => !t.completed)` |
| `map(list, fn)` | 変換 | `map(file.tags, (t) => upper(t))` |
| `flat(list)` | ネスト解除 | |
| `sort(list)` | ソート | |
| `reverse(list)` | 逆順 | |
| `all(list, fn)` | 全要素が条件満たす | |
| `any(list, fn)` | いずれかが条件満たす | |
| `sum(list)` | 合計 | `sum(rows.amount)` |
| `min(list)` / `max(list)` | 最小/最大 | |

### 日付関数

| 関数 | 説明 |
|------|------|
| `date(today)` | 今日の日付 |
| `date(now)` | 現在日時 |
| `date(tomorrow)` / `date(yesterday)` | 明日/昨日 |
| `date("YYYY-MM-DD")` | 文字列→日付 |
| `dur(N unit)` | 期間（days/weeks/months/years） |
| `dateformat(date, fmt)` | 日付フォーマット |

---

## Templater tp.* 関数リファレンス

### tp.file

| 関数 | 説明 |
|------|------|
| `tp.file.title` | 現在のファイル名 |
| `tp.file.path(relative?)` | ファイルパス |
| `tp.file.folder(relative?)` | フォルダパス |
| `tp.file.tags` | タグ一覧 |
| `tp.file.content` | ファイル全内容 |
| `tp.file.creation_date(fmt)` | 作成日 |
| `tp.file.last_modified_date(fmt)` | 更新日 |
| `tp.file.selection()` | 選択テキスト |
| `tp.file.cursor(n?)` | カーソル位置マーカー |
| `tp.file.create_new(template, name, open?, folder?)` | 新規作成 |
| `tp.file.move(path)` | ファイル移動 |
| `tp.file.rename(name)` | リネーム |
| `tp.file.include(tfile_or_section)` | テンプレート挿入 |
| `tp.file.find_tfile(name)` | TFile検索 |
| `tp.file.exists(path)` | ファイル存在確認 |

### tp.date

| 関数 | 説明 |
|------|------|
| `tp.date.now(fmt, offset?, ref?, refFmt?)` | 日付出力 |
| `tp.date.tomorrow(fmt)` | 明日 |
| `tp.date.yesterday(fmt)` | 昨日 |
| `tp.date.weekday(fmt, n, ref?, refFmt?)` | 曜日指定（0=日曜） |

fmt: moment.js フォーマット（`YYYY-MM-DD`, `HH:mm`, `dddd`, `ww` 等）

### tp.system

| 関数 | 説明 |
|------|------|
| `tp.system.prompt(header, default?, throw?, multiline?, width?)` | テキスト入力 |
| `tp.system.suggester(labels, values, throw?, placeholder?, limit?)` | 選択UI |
| `tp.system.clipboard()` | クリップボード内容 |

### tp.web

| 関数 | 説明 |
|------|------|
| `tp.web.daily_quote()` | ランダム名言 |
| `tp.web.random_picture(size?, query?, include_size?)` | Unsplash画像 |
| `tp.web.request(url, path?)` | HTTP GET（JSON パース対応） |

### tp.frontmatter

```markdown
<%* const status = tp.frontmatter.status %>
<%* const tags = tp.frontmatter.tags %>
```

frontmatter のキーに直接アクセス。存在しないキーは `undefined`。

---

## DataviewJS dv.* API

| メソッド | 説明 |
|---------|------|
| `dv.pages(source?)` | ページ取得（FROM相当） |
| `dv.pagePaths(source?)` | パスのみ取得 |
| `dv.page(path)` | 単一ページ取得 |
| `dv.current()` | 現在のページ |
| `dv.table(headers, rows)` | TABLE出力 |
| `dv.list(items)` | LIST出力 |
| `dv.taskList(tasks, groupByFile?)` | TASK出力 |
| `dv.paragraph(text)` | テキスト出力 |
| `dv.header(level, text)` | 見出し出力 |
| `dv.span(text)` | インライン出力 |
| `dv.el(tag, text, attrs?)` | HTML要素出力 |
| `dv.fileLink(path, embed?, display?)` | リンク生成 |

### チェーンAPI

```js
dv.pages('"Projects"')
  .where(p => p.status === "active")
  .sort(p => p.due, "asc")
  .limit(10)
  .map(p => [p.file.link, p.status, p.due])
```

---

## QuickAdd 変数一覧

| 変数 | 説明 |
|------|------|
| `{{VALUE}}` | ユーザー入力テキスト |
| `{{NAME}}` | ファイル名 |
| `{{DATE}}` | 現在日付（デフォルトYYYY-MM-DD） |
| `{{DATE:fmt}}` | 指定フォーマットの日時 |
| `{{TIME}}` | 現在時刻 |
| `{{TITLE}}` | テンプレートで生成されたタイトル |
| `{{LINKCURRENT}}` | 現在ファイルへのリンク |
| `{{TEMPLATE:path}}` | テンプレート展開 |
| `{{MACRO:name}}` | マクロ呼出し |
| `{{VAULTPATH}}` | Vaultのパス |
| `{{FOLDER:path}}` | フォルダ指定 |

---

## Dataview クエリ実用例

### 未完了タスクダッシュボード

````
```dataview
TASK
FROM "Projects"
WHERE !completed
SORT due ASC
GROUP BY file.link
```
````

### 最近更新されたノート

````
```dataview
TABLE file.mtime AS "更新日", file.size AS "サイズ"
FROM ""
WHERE file.name != "Template"
SORT file.mtime DESC
LIMIT 10
```
````

### プロジェクト進捗サマリー

````
```dataview
TABLE length(filter(file.tasks, (t) => t.completed)) AS "完了",
      length(filter(file.tasks, (t) => !t.completed)) AS "残り",
      round(length(filter(file.tasks, (t) => t.completed)) / length(file.tasks) * 100) + "%" AS "進捗"
FROM "Projects"
WHERE length(file.tasks) > 0
SORT file.mtime DESC
```
````

### 孤立ノート検出

````
```dataview
LIST
FROM ""
WHERE length(file.inlinks) = 0 AND length(file.outlinks) = 0
SORT file.ctime ASC
```
````

---

## トラブルシューティング

| 問題 | 原因 | 対策 |
|------|------|------|
| Dataview結果が空 | FROM パス不一致 | 大文字小文字・スペース確認 |
| frontmatter値が取得できない | YAML構文エラー | `:` 後にスペース必須 |
| Templater が展開されない | テンプレ設定未完了 | Settings > Templater > Template folder設定 |
| 日付比較が効かない | 文字列型のまま比較 | `date()` で明示変換 |
| DataviewJS エラー | 構文エラー | DevTools Console (Ctrl+Shift+I) で確認 |
| QuickAdd で変数展開されない | 二重波括弧の記法ミス | `{{VALUE}}` 正確に記述 |

---

## Bases Filter Nested Example

```yaml
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

---

## Bases: Complete Schema (Verbose)

SKILL.md B2 の展開形式:

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

---

## Bases: Additional Formula Examples

SKILL.md B5 から移動:

```yaml
formulas:
  formatted: 'if(price, price.toFixed(2) + " dollars")'
  created: 'file.ctime.format("YYYY-MM-DD")'
  days_old: '(now() - file.ctime).days'
```

---

## Bases: タスク管理Base実用例

SKILL.md B8 から参照。

```yaml
# tasks.base — タスク管理Base
filters:
  and:
    - 'tags == "task"'
    - 'status != "done"'

formulas:
  overdue: 'if(due, date(due) < today(), false)'
  days_left: 'if(due, (date(due) - today()).days, "")'
  status_icon: 'if(status == "done", "✅", if(status == "in-progress", "🔧", "📋"))'

properties:
  status:
    displayName: "ステータス"
  due:
    displayName: "期限"
  assignee:
    displayName: "担当"
  formula.status_icon:
    displayName: "状態"
  formula.days_left:
    displayName: "残り日数"

views:
  - type: table
    name: "未完了タスク"
    order: [formula.status_icon, file.name, status, due, assignee, formula.days_left]
    filters:
      and:
        - 'status != "done"'
    groupBy:
      property: status
      direction: ASC
    summaries:
      status: Filled

  - type: table
    name: "全タスク"
    order: [formula.status_icon, file.name, status, due, assignee]
```
