# Qiita MCP Server

Claude CodeからQiitaに直接記事を投稿できるMCPサーバーです。

## セットアップ

### 1. 依存関係のインストール

```bash
cd ~/Documents/Obsidian\ Vault/11_Qiita/qiita-mcp-server
npm install
```

### 2. Qiitaアクセストークンの取得

1. [Qiitaの設定ページ](https://qiita.com/settings/tokens/new)を開く
2. 「個人用アクセストークン」を作成
3. 以下のスコープを選択:
   - `read_qiita` - 記事の読み取り
   - `write_qiita` - 記事の投稿・更新・削除
4. トークンをコピー

### 3. 環境変数の設定

`~/.zshenv` に以下を追加:

```bash
export QIITA_ACCESS_TOKEN="your_qiita_access_token_here"
```

> **⚠️ `~/.zshrc` ではなく `~/.zshenv` に設定してください**
> Claude CodeはMCPサーバーを非インタラクティブシェルで起動します。`.zshrc` はインタラクティブシェルのみで読み込まれるため、`.zshenv` に設定する必要があります。

### 4. Claude Code設定への追加

`~/.claude/config.json` を編集して、MCPサーバーを追加:

```json
{
  "mcpServers": {
    "qiita": {
      "command": "node",
      "args": [
        "/Users/kawamurohirokazu/Documents/Obsidian Vault/11_Qiita/qiita-mcp-server/index.js"
      ],
      "env": {
        "QIITA_ACCESS_TOKEN": "${QIITA_ACCESS_TOKEN}"
      }
    }
  }
}
```

**注意:** 既存の`mcpServers`がある場合は、その中に`"qiita": {...}`を追加してください。

### 5. Claude Codeを再起動

```bash
# Claude Codeを終了して再起動
claude code
```

## 利用可能なツール

### 1. `qiita_post_article` - 記事を投稿

```javascript
{
  title: "記事タイトル",
  body: "記事本文（Markdown）",
  tags: [
    { name: "JavaScript" },
    { name: "Node.js", versions: ["18.0"] }
  ],
  private: false,  // true: 限定共有, false: 公開
  tweet: false     // Twitterに投稿するか
}
```

### 2. `qiita_update_article` - 記事を更新

```javascript
{
  article_id: "記事のID",
  title: "新しいタイトル",
  body: "新しい本文",
  tags: [...],
  private: false
}
```

### 3. `qiita_get_my_articles` - 自分の記事一覧を取得

```javascript
{
  page: 1,
  per_page: 20
}
```

### 4. `qiita_get_article` - 記事の詳細を取得

```javascript
{
  article_id: "記事のID"
}
```

### 5. `qiita_delete_article` - 記事を削除

```javascript
{
  article_id: "記事のID"
}
```

### 6. `qiita_get_article_stats` - 記事の統計情報を取得

```javascript
{
  article_id: "記事のID"
}
```

## 使い方

### Claude Codeから記事を投稿

`/qiita-publish`を実行すると、自動的にQiita MCPサーバーを使って投稿できるようになります。

**以前:**
```
1. 記事をコピー
2. Qiita Web UIを開く
3. 貼り付けて投稿
```

**これから:**
```
1. `/qiita-publish` を実行
2. 「Claude Codeから直接投稿」を選択
3. 完了！
```

### 記事の統計情報を確認

```
「記事 [記事ID] の閲覧数といいね数を教えて」
```

Claude Codeが自動的に `qiita_get_article_stats` を使って情報を取得します。

## トラブルシューティング

### エラー: `QIITA_ACCESS_TOKEN environment variable is required`

環境変数が設定されていません。手順3を再度確認してください。

### エラー: `Qiita API Error: {...}`

- アクセストークンが正しいか確認
- トークンのスコープ（`read_qiita`, `write_qiita`）が設定されているか確認
- Qiitaのレート制限に引っかかっていないか確認（1時間に60リクエストまで）

### MCPサーバーが認識されない

```bash
# Claude Codeの設定を確認
cat ~/.claude/config.json

# Claude Codeを再起動
# 完全に終了してから再起動してください
```

## セキュリティ

- アクセストークンは **絶対に** GitHubなどに公開しないでください
- 環境変数に保存し、`.gitignore`で除外してください
- トークンが漏洩した場合は、すぐにQiitaの設定で削除してください

## 参考

- [Qiita API v2 ドキュメント](https://qiita.com/api/v2/docs)
- [Model Context Protocol](https://modelcontextprotocol.io/)
