# IF-memo

Obsidian を使用したチーム向けナレッジベース

## フォルダ構成

- **docs/** - ドキュメント
  - daily/ - デイリーノート
  - reference/ - リファレンス
- **team/** - チームメンバー別(muro/guchi/ikura)
- **templates/** - テンプレート
  - daily-note-template.md - デイリーノート用
  - meeting-note-template.md - 会議メモ用
  - code-snippet-template.md - コードスニペット用
  - project-template.md - プロジェクト管理用
- **assets/** - リソース

## インストール済みプラグイン

### 基本機能
1. **Obsidian Git** - Git自動バックアップ
2. **Dataview** - データベース機能でノート検索・集計
3. **Templater** - 高度なテンプレート機能
4. **Calendar** - カレンダー表示とデイリーノート作成
5. **Kanban** - タスク管理のカンバンボード
6. **Advanced Tables** - Markdownテーブルの自動整形

### エンジニア向け
7. **Execute Code** - オブ内でコード実行（Python、JS等）
8. **Editor Syntax Highlight** - コードのシンタックスハイライト
9. **Code Emitter** - Jupyter Notebook風のコード実行環境
10. **Format Code** - Prettier使用のコード自動整形

## カスタマイズ

### CSSスニペット
- **custom.css** - ファイル名の色とサイズ、GitHub Alert記法のサポート

### GitHub Alert記法の使い方
```markdown
> [!NOTE]
> 重要な情報

> [!WARNING]
> 警告メッセージ

> [!TIP]
> ヒント

> [!IMPORTANT]
> 重要事項

> [!CAUTION]
> 注意事項
```

## 使い方

### デイリーノート
- **Cmd + P** → "Open today's daily note" でその日のノートを作成
- 自動でテンプレートが適用されます

### テンプレート
- **Cmd + P** → "Templater: Insert template" でテンプレート挿入

### コード実行
- コードブロックを書いて「▶️」ボタンをクリック

### Git同期
- 自動バックアップ: 10分ごと
- 手動コミット: **Cmd + P** → "Git: Commit all changes"
