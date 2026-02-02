---
created: 2026-01-30
tags: [setup, guide, team]
author: guchi
---

# 🚀 Obsidian Vault と Claude Code のセットアップガイド

このガイドは、hirokazuさんがnahato-IncのObsidian VaultとClaude Codeを使い始めるための完全ガイドです。

## 📋 目次

1. [Obsidian Vaultのセットアップ](#obsidian-vaultのセットアップ)
2. [Claude Codeのセットアップ](#claude-codeのセットアップ)
3. [カスタムエージェントの使い方](#カスタムエージェントの使い方)
4. [チーム運用ルール](#チーム運用ルール)

---

## 1. Obsidian Vaultのセットアップ

### ステップ1: リポジトリをクローン

```bash
# ホームディレクトリのDocumentsに移動
cd ~/Documents

# GitHubからクローン
git clone https://github.com/nahato-Inc/IF-memo.git "Obsidian Vault"

# クローン完了
cd "Obsidian Vault"
```

### ステップ2: Obsidianでvaultを開く

1. **Obsidianアプリをダウンロード**（まだの場合）
   - https://obsidian.md/download
   - macOS版をインストール

2. **Vaultを開く**
   - Obsidianを起動
   - 「Open folder as vault」を選択
   - クローンした `~/Documents/Obsidian Vault` を選択

3. **プラグインの確認**
   - 設定（⚙️）→ コミュニティプラグイン
   - 以下のプラグインが有効になっていることを確認：
     - ✅ Obsidian Git（自動同期）
     - ✅ Dataview（データ検索）
     - ✅ Templater（テンプレート）
     - ✅ Calendar（カレンダー）
     - ✅ その他

### ステップ3: 個人フォルダの作成

```bash
# hirokazuさん用のフォルダを作成
mkdir -p ~/Documents/Obsidian\ Vault/team/hirokazu/{daily,projects,notes,code-snippets}
```

または、Obsidian内で手動作成してもOK。

### ステップ4: Gitの設定確認

```bash
cd ~/Documents/Obsidian\ Vault

# Git設定確認
git config user.name
git config user.email

# 設定されていない場合は設定
git config user.name "Hirokazu Kawamuro"
git config user.email "your-email@example.com"
```

### ステップ5: 自動同期の動作確認

Obsidian Gitプラグインの設定：
- **自動コミット**: 10分ごと
- **自動プル**: 10分ごと
- **プッシュ前プル**: 有効

**手動同期**（即座に反映したい場合）:
- `Cmd + P` → `Obsidian Git: Commit all changes`
- `Cmd + P` → `Obsidian Git: Push`
- `Cmd + P` → `Obsidian Git: Pull`

---

## 2. Claude Codeのセットアップ

### ステップ1: Claude Codeのインストール

```bash
# npmでインストール（推奨）
npm install -g @anthropic-ai/claude-code

# または、公式サイトからダウンロード
# https://claude.ai/claude-code
```

### ステップ2: APIキーの設定

```bash
# APIキーを設定（初回のみ）
claude auth login

# ブラウザが開くので、Anthropicアカウントでログイン
```

### ステップ3: カスタムエージェントのインストール

guchiが作成したセットアップスクリプトを実行：

```bash
# スクリプトをダウンロード（guchiに依頼してください）
# または、guchiの環境からコピー
cp /Users/sekiguchiyuki/.claude/claude-agents-setup.sh ~/

# 実行権限を付与
chmod +x ~/claude-agents-setup.sh

# セットアップ実行
./claude-agents-setup.sh
```

**インストールされるもの**:
- 🟦 **GAS Expert** - Google Apps Script自動化の専門家
- 🟪 **Obsidian Automator** - Obsidian最適化の専門家
- 🟩 **Database Analyzer** - データベース分析の専門家
- 🟨 **Team Collaborator** - チーム協働支援の専門家

### ステップ4: 動作確認

```bash
# Claude Codeを起動
claude

# エージェント一覧を確認
~/.claude/scripts/use-agent.sh

# エージェント詳細を確認
~/.claude/scripts/use-agent.sh gas-expert
```

---

## 3. カスタムエージェントの使い方

### 🟦 GAS Expert の使い方

**専門分野**: Google Apps Script自動化

**使用例**:
```
"GAS Expertとして、スプレッドシートの動的範囲を
 QUERY関数で抽出するコードを書いて"
```

**得意なタスク**:
- スプレッドシート操作（QUERY関数、データ集計）
- Gmail自動化（メール送信、ラベル管理）
- Google Drive操作（ファイル管理、共有設定）
- トリガー設定（時間駆動、イベント駆動）

---

### 🟪 Obsidian Automator の使い方

**専門分野**: Obsidian最適化

**使用例**:
```
"Obsidian Automatorとして、PARAメソッドで
 フォルダ構造を最適化して"
```

**得意なタスク**:
- フォルダ構造の最適化（PARA、Zettelkasten）
- テンプレート作成（デイリーノート、プロジェクト）
- プラグイン設定（Dataview、Templater、Kanban）
- Git統合とチーム運用

---

### 🟩 Database Analyzer の使い方

**専門分野**: データベース分析

**使用例**:
```
"Database Analyzerとして、このExcelファイルから
 ER図を作成して"
```

**得意なタスク**:
- ER図作成（Mermaid記法）
- テーブル設計レビューと正規化
- インデックス戦略とパフォーマンス最適化
- Excelからのテーブル定義抽出

---

### 🟨 Team Collaborator の使い方

**専門分野**: チーム協働支援

**使用例**:
```
"Team Collaboratorとして、チーム全員に
 共有するドキュメントを作成して"
```

**得意なタスク**:
- チームメンバー間のタスク調整
- Obsidian Vaultでのナレッジ共有
- Gitを使った協働フロー
- ドキュメント作成とテンプレート管理

---

## 4. チーム運用ルール

### ✅ やること

1. **個人フォルダで作業**
   - `team/hirokazu/` 配下で自由に作業してください
   - 競合を避けるため、個人フォルダ外の編集は慎重に

2. **デイリーノートを記録**
   - `team/hirokazu/daily/` に毎日の作業記録
   - テンプレートは後日共有します

3. **タグを活用**
   - `#hirokazu` - hirokazuさんのノート
   - `#project` - プロジェクト関連
   - `#meeting` - ミーティング記録

4. **内部リンクで接続**
   - `[[ノート名]]` で他のノートにリンク
   - ナレッジグラフを作る

5. **編集前にプル**
   - 共有ファイルを編集する前に最新を取得
   - `Cmd + P` → `Obsidian Git: Pull`

### ❌ やらないこと

1. **他メンバーのフォルダを編集しない**
   - 参照はOKですが、編集は避けてください
   - 必要な場合は事前相談

2. **機密情報をコミットしない**
   - パスワード、APIキー等は `.gitignore` で除外
   - 既に設定済みですが、念のため確認

3. **大きなファイルをコミットしない**
   - 動画、10MB超の画像はNG
   - Google Driveなど別の場所を使用

4. **Gitを無効化しない**
   - Obsidian Gitプラグインは常に有効にしておく
   - 自動同期で全員の作業を共有

---

## 🔧 トラブルシューティング

### Q1: Gitの競合が発生した

**A**: Obsidian Gitがマージヘルプを表示します。以下の手順で解決：

```bash
cd ~/Documents/Obsidian\ Vault

# 競合を確認
git status

# 手動でマージ
# 競合ファイルを開いて、<<<<<<< と >>>>>>> の間を編集

# マージ完了後
git add .
git commit -m "Merge conflict resolved"
git push
```

### Q2: 自動同期が動作しない

**A**: Obsidian Gitプラグインの設定を確認：

1. 設定 → コミュニティプラグイン → Obsidian Git
2. 「Auto backup after file change」が有効か確認
3. 「Auto save interval」が10分に設定されているか確認

### Q3: Claude Codeのエージェントが動作しない

**A**: セットアップスクリプトを再実行：

```bash
./claude-agents-setup.sh
```

または、guchiに相談してください。

---

## 📚 参考リンク

- [Obsidian公式ドキュメント](https://help.obsidian.md/)
- [Obsidian Git Plugin](https://github.com/denolehov/obsidian-git)
- [Claude Code公式ドキュメント](https://github.com/anthropics/claude-code)
- [Google Apps Scriptリファレンス](https://developers.google.com/apps-script)

---

## 🤝 サポート

わからないことがあれば、以下に連絡してください：

- **guchi (関口)**: エンジニアリング、Claude Code、Obsidian全般
- **Slackチャンネル**: #nahato-tech（仮）
- **このドキュメント**: 随時更新していきます

---

**作成日**: 2026-01-30
**作成者**: guchi (関口)
**バージョン**: 1.0.0
**最終更新**: 2026-01-30

---

## 🎉 セットアップが完了したら

1. **最初のノートを作成**
   ```bash
   # Obsidianのクイックノート作成
   ~/.claude/skills/obsidian-quick-note.sh "初めてのノート" "これはhirokazuの最初のノートです"
   ```

2. **guchiにSlackで報告**
   - セットアップ完了の報告
   - 質問があれば気軽に

3. **実際に使ってみる**
   - デイリーノートを書いてみる
   - Claude Codeでエージェントを試してみる
   - チームメンバーのノートを見てみる

---

よろしくお願いします！
