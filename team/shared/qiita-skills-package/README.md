# Qiita Skills Package for Claude Code

Claude Codeを使って、**唯一無二かつAIっぽくない**Qiita記事を執筆するための統合Skillsパッケージです。

## 🎯 このパッケージの特徴

- **あなたの生の声を引き出す** - インタビュー形式で体験・感情を記事化
- **AIっぽい文章を排除** - 堅苦しい表現を検出し、カジュアルな文体に修正
- **記事候補を自動発見** - Daily NotesやArchivesから記事ネタを探索
- **完全統合ワークフロー** - 下書き→推敲→投稿まで一貫してサポート
- **チーム配布可能** - 簡単にチームメンバーに共有できる

## 📦 含まれるSkills

| Skill | 説明 |
|-------|------|
| `qiita-draft` | 記事の下書きを作成。インタビュー形式で体験を引き出す |
| `qiita-review` | 文体チェック・推敲。AIっぽい表現を検出して修正 |
| `qiita-publish` | Qiita投稿用フォーマットに変換。Claude Codeから直接投稿も可能 |
| `qiita-workflow` | ワークフロー管理。次にやるべきステップを自動案内 |
| `qiita-topics-from-slack` | (オプション) Slackから記事ネタを探索 |

## 📋 前提条件

- **Claude Code** がインストールされていること
  - https://github.com/anthropics/claude-code
- **Obsidian** がインストールされていること（推奨）
  - https://obsidian.md
- macOS / Linux（Windowsは未テスト）

## 🚀 インストール方法

### 方法1: インストールスクリプトを使う（推奨）

```bash
# パッケージを解凍
unzip qiita-skills-package.zip
cd qiita-skills-package

# インストールスクリプトを実行
./install.sh
```

インストーラーが以下を自動的に行います：
1. Claude Code Skillsディレクトリへのインストール
2. Obsidian Vault内にQiitaディレクトリ構造を作成
3. 設定ファイルとテンプレートのコピー

### 方法2: 手動でインストール

```bash
# Skills を Claude Code ディレクトリにコピー
cp -r skills/* ~/.claude/skills/

# Obsidian Vault に Qiita ディレクトリを作成
mkdir -p "$HOME/path/to/vault/11_Qiita"/{drafts,published,templates}

# 設定ファイルをコピー
cp config/.qiita-config.yaml "$HOME/path/to/vault/11_Qiita/"
cp config/templates/article-template.md "$HOME/path/to/vault/11_Qiita/templates/"

# ドキュメントをコピー
cp docs/*.md "$HOME/path/to/vault/11_Qiita/"
```

**インストール後、Claude Code を再起動してください。**

## 📚 使い方

### クイックスタート

インストール完了後、Claude Codeで以下を実行：

```bash
/qiita-workflow start
```

あとは提案に「はい」と答えるだけで、自動的に次のステップに進みます！

### 基本的なワークフロー

#### 1. 記事の下書きを作成

```bash
/qiita-draft
```

または、トピックを指定：

```bash
/qiita-draft Next.jsでハマったこと
```

**何が起きるか:**
- Daily Notesから記事候補を探索（トピック未指定時）
- インタビュー形式であなたの体験・感情を引き出す
- カジュアルで人間味のある文章で下書きを作成
- `11_Qiita/drafts/` に保存

#### 2. 文体チェック・推敲

```bash
/qiita-review
```

**何が起きるか:**
- AIっぽい表現（「〜について説明します」など）を検出
- カジュアルな表現への修正案を提示
- 体験・感情の記述があるかチェック
- 自動修正または手動修正を選択可能

#### 3. Qiitaに投稿

```bash
/qiita-publish
```

**何が起きるか:**
- フロントマターを削除し、Qiita投稿用フォーマットに変換
- Obsidianリンクを通常のテキストに変換
- コピペ用の本文を表示、または直接投稿（MCP設定時）

### 中断した記事を再開

```bash
/qiita-workflow continue
```

### 進捗状況を確認

```bash
/qiita-workflow
```

## ⚙️ オプション機能

### Slack連携（記事ネタ探索）

Slackの会話から記事ネタを自動発見できます。

**前提条件:**
- Claude Code に Slack MCP サーバーが設定されていること
- インストール時に `qiita-topics-from-slack` をインストール

**使い方:**
```bash
/qiita-topics-from-slack dev 7
```

詳しくは `docs/QUICKSTART.md` を参照。

### Qiita MCP サーバー（直接投稿）

Claude Codeから直接Qiitaに投稿できます。

**セットアップ:**
1. Qiitaアクセストークンを取得
2. `~/.zshrc` に `export QIITA_ACCESS_TOKEN="..."` を追加
3. Qiita MCP サーバーをインストール（別途配布）
4. Claude Code再起動

設定後、`/qiita-publish` で直接投稿できるようになります。

## 📂 ディレクトリ構造

インストール後、Obsidian Vaultに以下の構造が作成されます：

```
11_Qiita/
├── drafts/           # 執筆中の記事
├── published/        # 公開済みの記事
├── templates/        # 記事テンプレート
├── .qiita-config.yaml # 文体チェック設定
├── QUICKSTART.md     # クイックスタートガイド
├── WORKFLOW_GUIDE.md # ワークフローガイド
└── SYSTEM_ARCHITECTURE.md # システム構成
```

## 🎨 文体のルール

### ❌ 避けるべき表現（AIっぽい）

- 「〜について説明します」→ 「〜を見ていきます」
- 「〜することができます」→ 「〜できます」
- 「本記事では」→ 「今回は」「この記事では」
- 「以下の通りです」→ 「こんな感じです」

### ✅ 推奨する表現（カジュアル・人間味）

- 「〜してみました」「〜だと思います」
- 「〜ですね」「〜って感じ」
- 「ちょっと〜」「けっこう〜」
- 「個人的には〜」「正直〜」
- 「躓いた」「ハマった」「嬉しかった」

## 📖 ドキュメント

| ドキュメント | 説明 |
|-------------|------|
| `QUICKSTART.md` | 最短で記事を書き始めるためのガイド |
| `WORKFLOW_GUIDE.md` | ワークフロー管理の詳細 |
| `SYSTEM_ARCHITECTURE.md` | システム構成と設計思想 |

インストール後、`11_Qiita/` ディレクトリ内に配置されます。

## 🔧 カスタマイズ

### 文体チェックのカスタマイズ

`11_Qiita/.qiita-config.yaml` を編集することで、以下をカスタマイズできます：

- `ai_like_patterns` - 検出するNGパターン
- `recommended_expressions` - 推奨する表現
- `source_directories` - 記事ネタを探すディレクトリ
- `interview_questions` - インタビューの質問テンプレート

### 記事テンプレートのカスタマイズ

`11_Qiita/templates/article-template.md` を編集することで、記事の基本構造を変更できます。

## 🆘 トラブルシューティング

### Skillが認識されない場合

```bash
# Claude Codeを再起動
claude code
```

### 記事候補が見つからない場合

- Daily Notesに作業ログを書く習慣をつける
- イベントに参加したら、必ずメモを残す
- 技術的な問題にぶつかったら、解決過程を記録する

### インストールに失敗する場合

手動インストール（方法2）を試してください。それでも失敗する場合は、以下を確認：
- Claude Codeが正しくインストールされているか
- `~/.claude/skills/` ディレクトリが存在するか
- Obsidian Vaultのパスが正しいか

## 📦 配布方法（チームメンバー向け）

### ZIP形式で配布

```bash
cd qiita-skills-package
zip -r qiita-skills-package.zip .
```

メンバーに `qiita-skills-package.zip` を共有し、上記のインストール方法を案内してください。

### Git リポジトリで配布

```bash
cd qiita-skills-package
git init
git add .
git commit -m "Initial commit: Qiita Skills Package"
git remote add origin <repository-url>
git push -u origin main
```

メンバーは以下でクローン：

```bash
git clone <repository-url>
cd qiita-skills-package
./install.sh
```

## 🎯 良い記事を書くコツ

1. **体験を具体的に書く** - 「困った」「嬉しかった」などの感情を含める
2. **失敗談を恐れない** - ハマったポイントは貴重な情報
3. **完璧を目指さない** - ラフで読みやすい文章を心がける
4. **あなたの言葉で書く** - 一般論ではなく、個人の意見・感想を書く
5. **具体例を入れる** - 抽象的な説明だけでなく、実際の例を示す

## 📞 サポート

質問や改善提案がある場合は、Claude Codeに直接聞いてください！

```
「Qiita記事システムの〇〇がうまく動かない」
「〇〇の機能を追加したい」
```

## 📝 ライセンス

MIT License

## 🙏 謝辞

このパッケージは、Claude Codeの強力なAgent機能と、Obsidianの柔軟な管理機能を組み合わせて実現しています。

---

**Happy Writing! 🎉**
