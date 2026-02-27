# クイックスタートガイド

**5分でQiita記事執筆システムを使い始める！**

## 🚀 インストール（自動）

```bash
# qiita-writing-systemディレクトリに移動
cd qiita-writing-system

# インストールスクリプトを実行
./install.sh
```

画面の指示に従って:
1. Obsidian Vaultのパスを入力
2. Qiitaアクセストークンを入力

→ 自動でセットアップ完了！

## 📝 初めての記事を書く

### 1. Claude Codeを再起動

```bash
# ターミナルを完全に閉じて再度開く
claude code
```

### 2. Obsidian Vaultに移動

```bash
cd /path/to/your/obsidian-vault
```

### 3. ワークフローを開始

```bash
/qiita-workflow start
```

### 4. 提案に答えるだけ

```
Claude: 「Slackから記事ネタを探しますか？」
あなた: 「はい」

Claude: 「これらの候補から選んでください」
あなた: 「2」（興味のあるトピックを選択）

Claude: 「どんなきっかけで始めましたか？」
あなた: 「〜〜〜」（体験を語る）

... インタビュー形式で進む ...

Claude: 「下書きが完成しました！次は文体チェックしますか？」
あなた: 「はい」

... 自動で文体チェック ...

Claude: 「Qiitaに投稿しますか？」
あなた: 「はい」

→ 投稿完了！🎉
```

## 🎯 たったこれだけ！

**コマンド数: 1つ**
**時間: 30分〜1時間**（従来は2-3時間）

## 💡 次のステップ

### 記事ネタをSlackから探す

```bash
/qiita-topics-from-slack
```

過去1週間のSlackメッセージから記事候補を自動抽出します。

### 既存のメモから記事を書く

Obsidian Daily Notesにメモがあれば:

```bash
/qiita-draft
```

自動的にメモを見つけて記事候補を提案してくれます。

### 既存の記事を推敲

```bash
/qiita-review 11_Qiita/drafts/記事ファイル名.md
```

AIっぽい表現を自動検出して修正提案します。

## 🆘 困ったら

### MCPツールが認識されない

```bash
# Claude Codeを完全に再起動（重要！）
# ターミナルを閉じて再度開く
```

### トークンエラー

```bash
# トークンを確認
cat /path/to/your/obsidian-vault/11_Qiita/qiita-mcp-server/.env

# 正しく設定されていない場合は再設定
echo "QIITA_ACCESS_TOKEN=your_token" > /path/to/your/obsidian-vault/11_Qiita/qiita-mcp-server/.env
```

### それでも困ったら

Claudeに聞いてください:

```
「Qiita記事システムが動かない。エラーメッセージは〇〇です」
```

## 📚 もっと詳しく知りたい

- `README.md` - 詳細なセットアップ手順
- `docs/USER_GUIDE.md` - 全機能の使い方
- `mcp-server/qiita-mcp-server/README.md` - MCPサーバーの詳細

---

**さあ、記事執筆を楽しみましょう！🎉**
