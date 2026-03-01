# Qiita MCP Server トラブルシューティングガイド

## 🔍 問題の診断と解決

### 1. Unauthorized エラーが発生する

**症状:**
```
Qiita API Error: {"message":"Unauthorized","type":"unauthorized"}
```

**原因と解決策:**

#### A. config.json に MCP サーバー設定がない

**診断:**
```bash
grep -q '"qiita"' ~/.claude/config.json && echo "設定あり" || echo "設定なし"
```

**解決策:**
```bash
# 自動修復
~/.claude/skills/qiita-publish/.qiita-mcp-healthcheck.sh

# または手動で追加
cat ~/.claude/config.json
# 以下の内容を追加:
{
  "mcpServers": {
    "qiita": {
      "command": "node",
      "args": [
        "/Users/kawamurohirokazu/Documents/Obsidian Vault/11_Qiita/qiita-mcp-server/index.js"
      ]
    }
  }
}
```

**完了後:** Claude Code を完全に再起動

---

#### B. .env ファイルにトークンが設定されていない

**診断:**
```bash
cat ~/Documents/Obsidian\ Vault/11_Qiita/qiita-mcp-server/.env
```

**解決策:**
1. [Qiita設定ページ](https://qiita.com/settings/tokens/new) でアクセストークンを作成
2. スコープ: `read_qiita`, `write_qiita` を選択
3. `.env` ファイルに追加:
   ```bash
   echo "QIITA_ACCESS_TOKEN=your_token_here" > ~/Documents/Obsidian\ Vault/11_Qiita/qiita-mcp-server/.env
   ```

**完了後:** Claude Code を完全に再起動

---

#### C. アクセストークンが無効または期限切れ

**診断:**
```bash
# トークンの有効性を確認
TOKEN=$(cat ~/Documents/Obsidian\ Vault/11_Qiita/qiita-mcp-server/.env | grep QIITA_ACCESS_TOKEN | cut -d'=' -f2)
curl -H "Authorization: Bearer $TOKEN" https://qiita.com/api/v2/authenticated_user
```

**解決策:**
1. [Qiita設定ページ](https://qiita.com/settings/tokens) で既存のトークンを確認
2. 無効な場合は新しいトークンを作成
3. `.env` ファイルを更新

**完了後:** Claude Code を完全に再起動

---

### 2. MCP サーバーが起動しない

**症状:**
- ToolSearch で `qiita_post_article` が見つからない
- `/qiita-publish` で「Claude Codeから直接投稿」が選択できない

**診断:**
```bash
# 最新のデバッグログを確認
tail -100 ~/.claude/debug/latest | grep -i "qiita\|mcp.*server"
```

**原因と解決策:**

#### A. Node.js がインストールされていない

**診断:**
```bash
node --version
```

**解決策:**
```bash
# Node.js をインストール（Homebrew使用の場合）
brew install node
```

---

#### B. MCPサーバーの依存関係がインストールされていない

**診断:**
```bash
ls ~/Documents/Obsidian\ Vault/11_Qiita/qiita-mcp-server/node_modules
```

**解決策:**
```bash
cd ~/Documents/Obsidian\ Vault/11_Qiita/qiita-mcp-server
npm install
```

**完了後:** Claude Code を完全に再起動

---

#### C. MCPサーバーのパスが間違っている

**診断:**
```bash
cat ~/.claude/config.json | grep -A5 '"qiita"'
```

**解決策:**
正しいパスに修正:
```json
{
  "mcpServers": {
    "qiita": {
      "command": "node",
      "args": [
        "/Users/kawamurohirokazu/Documents/Obsidian Vault/11_Qiita/qiita-mcp-server/index.js"
      ]
    }
  }
}
```

**完了後:** Claude Code を完全に再起動

---

### 3. config.json が勝手にリセットされる

**症状:**
- 以前は動作していたのに、突然 Unauthorized エラーが発生
- config.json を確認すると `"mcpServers": {}` になっている

**原因:**
- Claude Code のアップデートで設定がリセットされた
- 別のツールが config.json を上書きした
- ファイル破損

**恒常的な対策:**

#### A. 定期的な自動バックアップを設定

**cron で毎日自動バックアップ（推奨）:**
```bash
# crontab を編集
crontab -e

# 以下を追加（毎日朝9時にバックアップ）
0 9 * * * ~/.claude/skills/qiita-publish/.config-backup.sh
```

**または、Claude Code 起動時にバックアップ:**
```bash
# ~/.zshrc に追加
alias claude-code='~/.claude/skills/qiita-publish/.config-backup.sh && claude code'
```

---

#### B. バックアップから復元

**方法1: 対話式復元スクリプト（推奨）:**
```bash
~/.claude/skills/qiita-publish/.config-restore.sh
```

**方法2: 手動で復元:**
```bash
# 利用可能なバックアップを確認
ls -lt ~/.claude/backups/config/

# 最新のバックアップを復元
cp ~/.claude/backups/config/config.json.YYYYMMDD_HHMMSS ~/.claude/config.json

# Claude Code を再起動
```

---

#### C. ヘルスチェックの定期実行

**週次でヘルスチェックを実行（推奨）:**
```bash
# crontab を編集
crontab -e

# 以下を追加（毎週月曜日朝9時にヘルスチェック）
0 9 * * 1 ~/.claude/skills/qiita-publish/.qiita-mcp-healthcheck.sh
```

---

## 🛠️ ユーティリティスクリプト一覧

| スクリプト | 用途 | 使用タイミング |
|-----------|------|--------------|
| `.qiita-mcp-healthcheck.sh` | 設定の診断と自動修復 | エラー発生時、定期メンテナンス |
| `.config-backup.sh` | config.json の自動バックアップ | 定期実行（cron）、Claude起動前 |
| `.config-restore.sh` | バックアップからの復元 | config.json が破損した時 |

---

## 📋 チェックリスト

問題が発生したら、以下の順序で確認してください:

- [ ] 1. ヘルスチェックを実行
  ```bash
  ~/.claude/skills/qiita-publish/.qiita-mcp-healthcheck.sh
  ```

- [ ] 2. デバッグログを確認
  ```bash
  tail -100 ~/.claude/debug/latest | grep -i qiita
  ```

- [ ] 3. config.json を確認
  ```bash
  cat ~/.claude/config.json
  ```

- [ ] 4. .env ファイルを確認
  ```bash
  cat ~/Documents/Obsidian\ Vault/11_Qiita/qiita-mcp-server/.env | head -1
  ```

- [ ] 5. Claude Code を完全に再起動

- [ ] 6. それでも解決しない場合、バックアップから復元
  ```bash
  ~/.claude/skills/qiita-publish/.config-restore.sh
  ```

---

## 🔗 参考リンク

- [Qiita MCP Server README](~/Documents/Obsidian Vault/11_Qiita/qiita-mcp-server/README.md)
- [Qiita API v2 ドキュメント](https://qiita.com/api/v2/docs)
- [Model Context Protocol](https://modelcontextprotocol.io/)

---

## 💡 よくある質問

### Q: 以前は動作していたのに、突然エラーが発生するようになった

A: `config.json` がリセットされた可能性が高いです。以下を実行してください:
```bash
~/.claude/skills/qiita-publish/.qiita-mcp-healthcheck.sh
```

### Q: ヘルスチェックを実行しても解決しない

A: 以下を確認してください:
1. Node.js がインストールされているか: `node --version`
2. MCPサーバーの依存関係がインストールされているか: `ls ~/Documents/Obsidian\ Vault/11_Qiita/qiita-mcp-server/node_modules`
3. アクセストークンが有効か: Qiita設定ページで確認

### Q: バックアップから復元したい

A: 対話式復元スクリプトを使用してください:
```bash
~/.claude/skills/qiita-publish/.config-restore.sh
```
