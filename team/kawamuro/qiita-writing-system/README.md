# Qiita記事執筆システム - チーム配布版

Claude Code × Obsidianで、**アイディア出しから投稿まで完全自動化**するQiita記事執筆システムです。

## 🎯 このシステムでできること

- **記事ネタ探索** - SlackやObsidianから記事候補を自動抽出
- **下書き作成** - インタビュー形式で体験を引き出し、カジュアルな文章で執筆
- **文体チェック** - AIっぽい表現を自動検出・修正提案
- **直接投稿** - Claude CodeからQiitaに直接投稿
- **Organization紐付け** - 会社・チームのOrganizationに記事を紐付け（NEW!）
- **ワークフロー管理** - 次に何をすべきか自動提案

## 📦 パッケージ内容

```
qiita-writing-system/
├── README.md              # このファイル
├── skills/                # Claude Code Skills（5つ）
│   ├── qiita-workflow/
│   ├── qiita-draft/
│   ├── qiita-review/
│   ├── qiita-publish/
│   └── qiita-topics-from-slack/
├── mcp-server/            # Qiita MCP Server
│   └── qiita-mcp-server/
├── config/                # 設定ファイル
│   ├── .qiita-config.yaml
│   └── .mcp.json.example
├── templates/             # 記事テンプレート
└── docs/                  # ドキュメント
    └── USER_GUIDE.md      # 詳細な使い方
```

## 🚀 セットアップ手順

### ステップ1: Skillsのインストール

```bash
# Skillsをコピー
cp -r skills/* ~/.claude/skills/
```

### ステップ2: Obsidian Vaultのセットアップ

あなたのObsidian Vaultに以下のディレクトリを作成:

```bash
cd /path/to/your/obsidian-vault

mkdir -p 11_Qiita/drafts
mkdir -p 11_Qiita/published
mkdir -p 11_Qiita/templates
```

設定ファイルをコピー:

```bash
cp config/.qiita-config.yaml 11_Qiita/
```

### ステップ3: Qiita MCPサーバーのセットアップ

#### 3-1. MCPサーバーをコピー

```bash
cp -r mcp-server/qiita-mcp-server /path/to/your/obsidian-vault/11_Qiita/
cd /path/to/your/obsidian-vault/11_Qiita/qiita-mcp-server
npm install
```

#### 3-2. Qiitaアクセストークンを取得

1. [Qiita設定ページ](https://qiita.com/settings/tokens/new)を開く
2. 「個人用アクセストークン」を作成
3. スコープを選択: `read_qiita`, `write_qiita`
4. トークンをコピー

#### 3-3. 環境変数を設定

`.env`ファイルを作成:

```bash
cd /path/to/your/obsidian-vault/11_Qiita/qiita-mcp-server
echo "QIITA_ACCESS_TOKEN=your_token_here" > .env
```

> **⚠️ 重要**: `.env`ファイルは絶対にGitにコミットしないでください！

#### 3-4. MCP設定ファイルを配置

プロジェクトルート（Obsidian Vault）に`.mcp.json`を配置:

```bash
cp config/.mcp.json.example /path/to/your/obsidian-vault/.mcp.json
```

`.mcp.json`を編集して、パスを自分の環境に合わせて修正:

```json
{
  "qiita": {
    "command": "node",
    "args": [
      "/path/to/your/obsidian-vault/11_Qiita/qiita-mcp-server/index.js"
    ]
  }
}
```

### ステップ4: Claude Codeを再起動

設定を反映させるため、Claude Codeを**完全に終了してから再起動**します。

```bash
# Claude Codeを終了
# ターミナルを閉じて再度開く

# Claude Codeを起動
claude code
```

### ステップ5: 動作確認

```bash
# Obsidian Vaultに移動
cd /path/to/your/obsidian-vault

# ワークフローを開始
/qiita-workflow
```

MCPツールが認識されているか確認:

```
「Qiitaの記事一覧を取得して」
```

## 📝 使い方

### 基本的なワークフロー

```bash
# 1. ワークフローを開始
/qiita-workflow start

# あとは提案に「はい」と答えるだけで、記事執筆の全ステップが自動で進みます
```

### 個別のコマンド

```bash
# 記事ネタをSlackから探す
/qiita-topics-from-slack

# 下書きを作成
/qiita-draft

# 文体チェック
/qiita-review

# Qiitaに投稿
/qiita-publish
```

詳しい使い方は `docs/USER_GUIDE.md` を参照してください。

## 🔧 カスタマイズ

### 文体チェックのルールを変更

`11_Qiita/.qiita-config.yaml` を編集:

```yaml
ai_like_patterns:
  - pattern: "〜について説明します"
    suggestion: "〜を見ていきます"
  # 自分のルールを追加
```

### 記事ネタの探索先を変更

Skillsを編集して、探索するディレクトリを変更できます:

```bash
# 例: qiita-draftのskill.mdを編集
vim ~/.claude/skills/qiita-draft/skill.md
```

## 🆘 トラブルシューティング

### MCPサーバーが認識されない

```bash
# 1. .mcp.jsonのパスが正しいか確認
cat /path/to/your/obsidian-vault/.mcp.json

# 2. MCPサーバーが起動するか確認
node /path/to/your/obsidian-vault/11_Qiita/qiita-mcp-server/index.js
# "Qiita MCP server running on stdio" と表示されればOK

# 3. Claude Codeを完全に再起動
```

### トークンエラーが出る

```bash
# .envファイルにトークンが設定されているか確認
cat /path/to/your/obsidian-vault/11_Qiita/qiita-mcp-server/.env

# トークンが正しいか、Qiitaの設定ページで確認
# https://qiita.com/settings/tokens
```

### Skillsが認識されない

```bash
# Skillsが正しくコピーされているか確認
ls ~/.claude/skills/ | grep qiita

# Claude Codeを再起動
```

## 📚 関連ドキュメント

- `docs/USER_GUIDE.md` - 詳細な使い方
- `docs/ORGANIZATION_GUIDE.md` - Qiita Organization紐付けガイド（NEW!）
- `mcp-server/qiita-mcp-server/README.md` - MCPサーバーの詳細

## 🎉 これで準備完了！

```bash
cd /path/to/your/obsidian-vault
/qiita-workflow start
```

記事執筆を楽しんでください！

## 📞 サポート

質問や問題があれば、Claudeに聞いてください：

```
「Qiita記事システムの〇〇がうまく動かない」
```

---

**作成者**: kawamuro
**バージョン**: 1.0.0
**最終更新**: 2026-02-24
