# Changelog

All notable changes to Qiita Skills Package will be documented in this file.

## [1.0.0] - 2026-02-27

### 初回リリース 🎉

#### Added
- **qiita-draft**: 記事の下書きを作成するSkill
  - インタビュー形式で体験・感情を引き出す
  - Daily Notesから記事候補を自動探索
  - カジュアルで人間味のある文章で下書き作成

- **qiita-review**: 文体チェック・推敲Skill
  - AIっぽい表現を自動検出
  - カジュアルな表現への修正提案
  - 体験・感情の記述チェック

- **qiita-publish**: Qiita投稿用フォーマット変換Skill
  - フロントマター削除
  - Obsidianリンク変換
  - Claude Codeから直接投稿（MCP設定時）

- **qiita-workflow**: ワークフロー管理Skill
  - 進行中の記事を自動追跡
  - 次のステップを自動案内
  - 記事統計の表示

- **qiita-topics-from-slack**: Slack記事ネタ探索Skill（オプション）
  - Slackの会話から記事候補を自動発見
  - 技術的な話題を優先的に抽出

- **インストールスクリプト**: 簡単にインストールできる自動化スクリプト
- **アンインストールスクリプト**: クリーンな削除をサポート
- **設定ファイル**: `.qiita-config.yaml` で文体ルールをカスタマイズ可能
- **テンプレート**: 記事の基本構造を定義
- **ドキュメント**: QUICKSTART, WORKFLOW_GUIDE, SYSTEM_ARCHITECTURE

#### Features
- 完全統合ワークフロー（下書き→推敲→投稿）
- AIっぽい文章の自動検出・修正提案
- インタビュー形式での執筆サポート
- 記事候補の自動探索
- チーム配布可能なパッケージ構成

---

## [1.1.0] - 2026-03-01

### Added
- **qiita-publish**: エラー自動診断・修復機能
  - `.qiita-auto-fix.sh`: config.jsonのenv設定を自動チェック・修復
  - `.config-backup.sh`: 設定の自動バックアップスクリプト
  - `.config-restore.sh`: 設定の復元スクリプト
  - `.qiita-mcp-healthcheck.sh`: MCPサーバーのヘルスチェック
  - `TROUBLESHOOTING.md`: トラブルシューティングガイド

### Fixed
- **qiita-publish**: Unauthorized エラーの根本的な解決
  - config.jsonに環境変数を直接埋め込む方式に変更
  - .zshenvに依存せず確実に環境変数が渡される
  - 自動診断・修復により、エラー発生時に即座に対処可能

---

## [Unreleased]

### Planned
- GitHub Actions連携（記事の自動PR作成）
- Notion連携（記事管理ダッシュボード）
- 記事統計の可視化
- AIレビュアー機能（より高度な文章チェック）
- 記事テンプレートのバリエーション追加
