# プロジェクトメモリ: IF-memo (Obsidian Vault)

## 基本方針

- **必ず日本語で応対してください**
- Obsidianを「オブ」と呼ぶ
- 絵文字は明示的に要求されない限り使用しない
- プロフェッショナルで簡潔な回答を心がける

## プロジェクト概要

このプロジェクトは、nahato-Inc チームのナレッジベースです：
- Obsidianを使ったMarkdown形式のメモ管理
- Git（10分ごと自動コミット）でバージョン管理・バックアップ
- チームメンバーが個人フォルダ（team/名前/）で作業
- テンプレート、プラグイン、CSSカスタマイズを活用

## ディレクトリ構造

```
/
├── docs/                    # ドキュメント（オンボーディング等）
├── team/
│   └── guchi/              # guchiの作業スペース
│       ├── daily/          # デイリーノート
│       ├── projects/       # プロジェクト管理
│       ├── notes/          # 技術メモ
│       └── code-snippets/  # コードスニペット
├── templates/              # テンプレート
└── assets/                 # リソース
```

## インストール済みプラグイン

1. Obsidian Git - 自動バックアップ
2. Dataview - ノート検索・集計
3. Templater - テンプレート機能
4. Calendar - カレンダー表示
5. Kanban - タスク管理
6. Advanced Tables - テーブル編集
7. Execute Code - コード実行
8. Editor Syntax Highlight - シンタックスハイライト
9. Code Emitter - Jupyter風コード実行
10. Format Code - コード整形

## チーム運用ルール

### ✅ やること
- team/配下で各自のフォルダで作業
- 毎日デイリーノートを記録
- タグ（#名前、#project等）を活用
- 内部リンク [[]] でノートを接続

### ❌ やらないこと
- 他メンバーのフォルダを編集しない（参照はOK）
- 機密情報（パスワード、APIキー等）をコミットしない
- 大きなファイル（動画、10MB超の画像）をコミットしない
- Gitを無効化しない

## コーディング規約

- Markdownファイルは全てUTF-8
- 見出しは日本語でわかりやすく
- コードブロックには必ず言語指定
- GitHub Alert記法（[!NOTE]等）を活用

## よく使うコマンド

- `Cmd + P` - コマンドパレット
- `Cmd + O` - ファイル検索
- `Cmd + N` - 新規ノート
- `[[` - 内部リンク作成

## 注意事項

- Obsidian内のファイル操作は慎重に（Git履歴が残る）
- プラグインの追加・削除はチームで相談
- テンプレート変更時はチームに通知
- 新入社員向けには docs/クイックスタートガイド.md を案内

## 外観設定

- テーマ: Pink Topaz
- アクセントカラー: #a85cf5（紫）
- フォントサイズ: 30px
- CSSスニペット: `custom` が有効

## カスタムCSS (`snippets/custom.css`)

- 見出し（h1-h6）を大文字表示（text-transform: uppercase）
- ファイル名の色変更（青 #4a9eff）
- GitHub Alert記法のスタイリング（NOTE, WARNING, IMPORTANT, TIP, CAUTION）
- コードブロックのフォント設定（JetBrains Mono）
- テーブルスタイリング

## トラブルシューティング

### プラグイン読み込みエラー
GitHubからソースをクローンした場合、`main.js`がビルドフォルダ内にあり読み込めないことがある：
- **dataview**: `build/main.js` → ルートにコピー
- **code-emitter**: `dist/main.js` → ルートにコピー

確認コマンド：
```bash
for dir in ".obsidian/plugins/"*/; do
  [ -f "$dir/main.js" ] && echo "$(basename $dir): OK" || echo "$(basename $dir): MISSING main.js"
done
```

---

_このファイルはClaude Codeがプロジェクトコンテキストを理解するための永続メモリです_
_最終更新: 2026-02-02_
