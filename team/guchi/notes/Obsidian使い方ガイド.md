# 📚 Obsidian使い方ガイド（guchi用）

## 🚀 はじめに

このガイドは、guchiさんがObsidianを効率的に使うための手引きです。

---

## 📁 あなたの作業エリア

```
team/guchi/
├── README.md           ← ダッシュボード（ここから始める）
├── daily/              ← デイリーノート
├── projects/           ← プロジェクト管理
├── notes/              ← 技術メモ
└── code-snippets/      ← コードスニペット
```

---

## ⌨️ よく使うショートカット

| ショートカット | 機能 |
|--------------|------|
| `Cmd + P` | コマンドパレット |
| `Cmd + O` | ファイル検索 |
| `Cmd + N` | 新規ノート |
| `Cmd + E` | 編集/プレビュー切り替え |
| `[[` | 内部リンク作成 |
| `Cmd + K` | リンク挿入 |

---

## 🎯 毎日の作業フロー

### 朝（9:00）
1. **Cmd + P** → "Open today's daily note"
2. 今日のタスクを記入
3. デイリーノートに目標を書く

### 作業中
- コードを書いたら `code-snippets/` に保存
- 学んだことは `notes/` に記録
- プロジェクトは `projects/` で管理

### 終業前（18:00）
1. デイリーノートに作業記録を追記
2. **Cmd + P** → "Git: Commit all changes"
3. 明日の予定を書く

---

## 📝 テンプレートの使い方

### デイリーノート
**Cmd + P** → "Templater: Insert template" → `guchi-daily-template`

### 会議メモ
**Cmd + P** → "Templater: Insert template" → `meeting-note-template`

### プロジェクト
**Cmd + P** → "Templater: Insert template" → `project-template`

### コードスニペット
**Cmd + P** → "Templater: Insert template" → `code-snippet-template`

---

## 💻 コード実行の使い方

### Python
````markdown
```python
print("Hello, Obsidian!")
```
````
→ 「▶️」ボタンで実行

### JavaScript
````markdown
```javascript
console.log("Hello, World!");
```
````
→ 「▶️」ボタンで実行

---

## 🎨 GitHub Alert記法

カラフルなブロックを使える：

```markdown
> [!NOTE]
> 青い枠の注記

> [!TIP]
> 緑の枠のヒント

> [!WARNING]
> 黄色い枠の警告

> [!IMPORTANT]
> 紫の枠の重要事項

> [!CAUTION]
> 赤い枠の注意
```

---

## 🔍 Dataviewでノート検索

### guchiのすべてのノート
```dataview
list
from "team/guchi"
sort file.mtime desc
```

### 今週作成したノート
```dataview
table file.cday as 作成日
from "team/guchi"
where file.cday >= date(today) - dur(7 days)
```

### タグで検索
```dataview
list
from #guchi
```

---

## 🔗 リンクの使い方

### 内部リンク
```markdown
[[team/guchi/README|ダッシュボード]]
[[2026-01-28|今日のノート]]
```

### 見出しへのリンク
```markdown
[[ファイル名#見出し]]
```

### ブロックへのリンク
```markdown
[[ファイル名#^ブロックID]]
```

---

## 🎯 Kanbanボードでタスク管理

1. 新規ノートを作成
2. **Cmd + P** → "Kanban: Create new board"
3. カラムを作成（Not Started / In Progress / Done）
4. カードをドラッグ&ドロップ

---

## 📊 便利な機能

### グラフビュー
- **Cmd + P** → "Open graph view"
- ノート間のつながりを可視化

### バックリンク
- 右サイドバーで関連ノートを確認

### タグペイン
- 左サイドバーでタグ一覧

---

## 🔧 トラブルシューティング

### プラグインが表示されない
1. Obsidianを再起動
2. 設定 → コミュニティプラグイン → 有効化

### Gitが動かない
1. **Cmd + P** → "Git: Initialize a new repo"
2. 設定確認

### コードが実行できない
1. Execute Codeプラグインが有効か確認
2. 言語のランタイムがインストールされているか確認

---

## 📚 もっと学ぶ

- [Obsidian公式ドキュメント](https://help.obsidian.md/)
- [Dataviewガイド](https://blacksmithgu.github.io/obsidian-dataview/)
- チーム内のREADME: `[[README]]`

---

_このガイドは随時更新されます_

Tags: #guide #guchi #obsidian
