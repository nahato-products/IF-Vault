# Dataview検索のサンプル

## 📌 概要
Obsidian Dataviewプラグインを使った便利な検索クエリ集

## 💻 コード

### 最近更新したノート一覧
```dataview
table file.mtime as 更新日時
from "team/sekiguchi"
sort file.mtime desc
limit 10
```

### タグで絞り込み
```dataview
list
from #sekiguchi
sort file.name
```

### 進行中のプロジェクト
```dataview
table status as ステータス, file.cday as 作成日
from "team/sekiguchi/projects"
where status = "🟡 進行中"
```

### 今週のデイリーノート
```dataview
table file.cday as 日付
from "team/sekiguchi/daily"
where file.cday >= date(today) - dur(7 days)
sort file.cday desc
```

## 📖 説明
Dataviewはノートをデータベースのように扱えるプラグインです。
SQLライクなクエリでノートを検索・集計できます。

## 🔧 使い方
1. コードブロックに `dataview` を指定
2. クエリを記述
3. 自動でリストやテーブルが生成される

## 🔗 参考リンク
- [Dataview公式ドキュメント](https://blacksmithgu.github.io/obsidian-dataview/)

---
Created: 2026-01-28 19:35
Tags: #code #dataview #obsidian
language: dataview
