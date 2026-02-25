# プロジェクトメモリ: IF-memo (Obsidian Vault)

## 基本方針

- **日本語で応対**
- 機密情報（APIキー、パスワード等）・10MB超のファイルは絶対にコミットしない
- 各メンバーの個人設定は `team/名前/CLAUDE.md` で管理

## プロジェクト概要

nahato-Inc チームのナレッジベース:
- Obsidian + Markdown形式。Git（10分ごと自動コミット）でバックアップ
- チームメンバーが `team/名前/` で作業

## 他メンバー保護ルール（絶対）

- **`team/` 配下は自分のフォルダのみ編集可能**。他メンバーのフォルダは読み取り専用
- 変更・移動・削除・リネームは一切禁止。提案もしない
- 編集が必要な場合は該当メンバーに依頼する旨をユーザーに伝える
- `team/shared/` は全員が編集可能

## ディレクトリ構造

```
/
├── .claude/                # Claude Code設定
├── docs/
│   ├── onboarding/         # オンボーディング資料
│   ├── reference/          # リファレンス
│   └── technical/          # 技術資料
├── projects/
│   └── If-DB/              # IF-DBプロジェクト
├── task_rules/             # タスク管理ルール
├── team/
│   ├── ikuta/
│   ├── kawamuro/
│   ├── sekiguchi/
│   └── shared/             # 共有リソース
├── templates/              # テンプレート
└── assets/                 # リソース
```

## チーム運用ルール

- team/配下で各自のフォルダで作業。他メンバーのフォルダは参照のみ
- タグ（#名前、#project等）と内部リンク `[[]]` を活用
- プラグインの追加・削除はチームで相談

## コーディング規約

- Markdown: UTF-8、日本語見出し、コードブロックに言語指定、GitHub Alert記法活用

## プラグイン

Obsidian Git, Dataview, Templater, Calendar, Kanban, Advanced Tables, Execute Code, Editor Syntax Highlight, Code Emitter, Format Code

_最終更新: 2026-02-18_
