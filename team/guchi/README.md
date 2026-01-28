# 🚀 guchiの作業スペース

最終更新: 2026-01-28

---

## 📁 フォルダ構成

- **daily/** - デイリーノート（日々の作業記録）
- **projects/** - プロジェクト管理
- **notes/** - 技術メモ・学習ノート
- **code-snippets/** - コードスニペット集

---

## 📊 クイックリンク

### 📅 デイリーノート
- [[team/guchi/daily/2026-01-28|今日のノート]]

### 🎯 進行中のプロジェクト
```dataview
table file.cday as 作成日, status as ステータス
from "team/guchi/projects"
where status = "🟡 進行中"
sort file.mtime desc
```

### 📝 最近のノート
```dataview
table file.mtime as 更新日時
from "team/guchi/notes"
sort file.mtime desc
limit 5
```

### 💻 コードスニペット
```dataview
table language as 言語, file.mtime as 更新日
from "team/guchi/code-snippets"
sort file.mtime desc
limit 5
```

---

## 🔧 便利なコマンド

- **Cmd + P** → "Open today's daily note" - 今日のノート作成
- **Cmd + P** → "Templater: Insert template" - テンプレート挿入
- **Cmd + P** → "Git: Commit all changes" - Git保存

---

## 📌 タスク管理

### 今日のタスク
- [ ]

### 今週のタスク
- [ ]

---

_このREADMEはguchiさん専用のダッシュボードです_
