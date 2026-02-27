# Qiita記事執筆システム - アーキテクチャ

## 🏗️ システム構成

```
┌─────────────────────────────────────────────────────────────┐
│                     Obsidian Vault                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │ Daily Notes │  │  Archives   │  │  Knowledge  │        │
│  │             │  │             │  │             │        │
│  │ 作業ログ    │  │イベントレポ │  │  学習記録   │        │
│  │ 学習メモ    │  │トラブル解決 │  │  技術メモ   │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
│         │                 │                 │               │
│         └─────────────────┼─────────────────┘               │
│                           ↓                                 │
│                  ┌──────────────────┐                       │
│                  │  11_Qiita/       │                       │
│                  │  ├─ drafts/      │                       │
│                  │  ├─ published/   │                       │
│                  │  ├─ templates/   │                       │
│                  │  └─ .qiita-config│                       │
│                  └──────────────────┘                       │
└─────────────────────────────────────────────────────────────┘
                           ↕
┌─────────────────────────────────────────────────────────────┐
│                    Claude Code (CLI)                        │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ qiita-draft  │  │ qiita-review │  │qiita-publish │     │
│  │    Skill     │  │    Skill     │  │    Skill     │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│         │                 │                 │               │
│         ↓                 ↓                 ↓               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Explore    │  │Style Checker │  │  Formatter   │     │
│  │  SubAgent    │  │  SubAgent    │  │  SubAgent    │     │
│  │              │  │              │  │              │     │
│  │記事候補探索  │  │文体チェック  │  │フォーマット  │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│                    Qiita (投稿先)                           │
│  ┌──────────────┐  ┌──────────────┐                        │
│  │   Web UI     │  │  Qiita CLI   │  ← 今後MCP連携予定    │
│  └──────────────┘  └──────────────┘                        │
└─────────────────────────────────────────────────────────────┘
```

## 📦 各コンポーネントの役割

### 1. Skills（Claude Code Skills）

#### `/qiita-draft` - 記事下書き作成
- **場所:** `~/.claude/skills/qiita-draft/skill.md`
- **役割:**
  - Daily NotesやArchivesから記事候補を探索
  - ユーザーにインタビューして生の声を引き出す
  - カジュアルな文体で下書きを作成
- **使用ツール:**
  - Task (subagent_type=Explore) - 記事候補探索
  - AskUserQuestion - インタビュー実施
  - Write - 下書き保存

#### `/qiita-review` - 文体チェック・推敲
- **場所:** `~/.claude/skills/qiita-review/skill.md`
- **役割:**
  - AIっぽい表現を検出（「〜について説明します」など）
  - カジュアルな表現への修正案を提示
  - 体験・感情の記述をチェック
- **使用ツール:**
  - Read - 記事と設定ファイルの読み込み
  - Edit - 修正の実施
  - AskUserQuestion - 修正方法の確認

#### `/qiita-publish` - 投稿フォーマット変換
- **場所:** `~/.claude/skills/qiita-publish/skill.md`
- **役割:**
  - フロントマターを削除
  - ObsidianリンクをMarkdownに変換
  - Qiita投稿用フォーマットに変換
- **使用ツール:**
  - Read - 記事の読み込み
  - Bash - ファイル移動
  - AskUserQuestion - 投稿方法の確認

### 2. SubAgents（Task Tool）

#### Explore Agent（記事候補探索）
- **タイミング:** `/qiita-draft` 実行時
- **役割:**
  - 指定ディレクトリを探索
  - 技術的な発見、トラブル解決、イベント参加記録を抽出
  - 記事にできそうなトピックを3-5個提案

#### Style Checker Agent（文体チェック）
- **タイミング:** `/qiita-review` 実行時
- **役割:**
  - `.qiita-config.yaml` のパターンに基づき文体をチェック
  - AIっぽい表現を検出
  - カジュアルな修正案を提示

### 3. 設定ファイル

#### `.qiita-config.yaml`
```yaml
# AIっぽい表現パターン
ai_like_patterns:
  - pattern: "〜について説明します"
    suggestion: "〜を見ていきましょう"

# 推奨する表現
recommended_expressions:
  - "〜してみました"
  - "〜だと思います"

# 記事ネタ探索対象
source_directories:
  - "05_Daily Notes"
  - "04_Archives"
```

### 4. テンプレート

#### `templates/article-template.md`
- YAMLフロントマター（title, tags, status）
- 基本的な記事構成（はじめに、本文、まとめ）

## 🔄 ワークフロー

### Phase 1: 下書き作成

```
/qiita-draft
  ↓
1. Explore Agentが記事候補を探索
  ↓
2. ユーザーが トピックを選択
  ↓
3. インタビュー形式で体験・感情を引き出す
  ↓
4. カジュアルな文体で下書きを作成
  ↓
5. 11_Qiita/drafts/ に保存
```

### Phase 2: 文体チェック・推敲

```
/qiita-review
  ↓
1. drafts/ から記事を選択
  ↓
2. .qiita-config.yaml を読み込み
  ↓
3. Style Checker Agentが文体をチェック
  ↓
4. AIっぽい表現を検出・修正提案
  ↓
5. ユーザーが修正方法を選択（自動/手動/一部）
  ↓
6. 修正を実施
```

### Phase 3: 投稿準備

```
/qiita-publish
  ↓
1. drafts/ から記事を選択
  ↓
2. フロントマターを抽出・削除
  ↓
3. Obsidianリンクを変換
  ↓
4. Qiita投稿フォーマットに変換
  ↓
5. コピペ用本文を表示 or Qiita CLIファイル生成
  ↓
6. 投稿後、published/ に移動
```

## 🚀 今後の拡張（ロードマップ）

### Phase 4: Hooks統合（中期目標）

#### 記事保存時の自動チェック
```yaml
# ~/.claude/hooks.yaml
on-file-save:
  - pattern: "11_Qiita/drafts/*.md"
    command: "qiita-review --auto-check"
    description: "記事保存時に文体を自動チェック"
```

#### 記事作成時のテンプレート適用
```yaml
on-file-create:
  - pattern: "11_Qiita/drafts/*.md"
    command: "apply-template article-template.md"
    description: "新規記事にテンプレートを適用"
```

### Phase 5: MCP統合（長期目標）

#### Qiita MCP Server
```typescript
// qiita-mcp-server (概念)
{
  "name": "qiita",
  "tools": [
    "qiita-post-article",    // 記事を直接投稿
    "qiita-update-article",  // 記事を更新
    "qiita-get-stats",       // 閲覧数・いいね数取得
    "qiita-search-my-articles" // 自分の記事を検索
  ]
}
```

**使用例:**
```
/qiita-publish
  ↓
Qiita MCPサーバーを使用して直接投稿
  ↓
投稿URLをフロントマターに自動記入
  ↓
閲覧数・いいね数を定期的に取得してObsidianに記録
```

#### 文体分析MCP Server
```typescript
// style-checker-mcp-server (概念)
{
  "name": "style-checker",
  "tools": [
    "analyze-writing-style",  // 文体を分析
    "detect-ai-patterns",     // AIっぽい表現を検出
    "suggest-improvements"    // 改善案を提示
  ]
}
```

### Phase 6: 高度な機能（将来構想）

#### 記事パフォーマンス分析
- 閲覧数・いいね数の推移をObsidianでグラフ化
- どんな記事が読まれているか分析
- 次に書くべきトピックを提案

#### 記事シリーズ管理
- 関連記事を自動でリンク
- シリーズ記事の進捗管理
- シリーズ全体の構成を最適化

#### AIによる記事改善提案
- 定期的に過去記事をレビュー
- 古くなった情報を検出
- 更新すべき記事を提案

## 🔧 技術スタック

### 現在
- **Obsidian** - ナレッジベース
- **Claude Code** - AI統合CLI
- **Skills** - カスタムコマンド
- **SubAgents** - タスク分散処理
- **YAML** - 設定ファイル
- **Markdown** - 記事フォーマット

### 今後追加予定
- **Hooks** - イベント駆動処理
- **MCP (Model Context Protocol)** - 外部ツール連携
- **Qiita CLI** - Qiita API連携
- **GitHub Actions** - 定期的な記事レビュー（オプション）

## 📊 システムの利点

### 1. 完全統合ワークフロー
- Obsidian内で記事のライフサイクル全体を管理
- 執筆・推敲・投稿が一貫したインターフェース

### 2. 唯一無二の記事を生成
- インタビュー形式で個人の体験を引き出す
- AIっぽい表現を排除し、人間味のある文章に

### 3. 記事ネタの自動発見
- Daily Notesから自動で記事候補を抽出
- 書くべきことを忘れない

### 4. 文体の一貫性
- 設定ファイルで文体ルールを統一
- すべての記事で同じカジュアルさを保つ

### 5. 拡張性
- Skills、Hooks、MCPで柔軟にカスタマイズ可能
- 将来的にはさらに高度な機能を追加できる

## 🎓 学習リソース

- [Claude Code Skills ドキュメント](https://github.com/anthropics/claude-code)
- [MCP (Model Context Protocol)](https://modelcontextprotocol.io/)
- [Qiita API ドキュメント](https://qiita.com/api/v2/docs)
- [Obsidian ドキュメント](https://help.obsidian.md/)

---

**このシステムで、あなただけの唯一無二の技術記事を書きましょう！ 🚀**
