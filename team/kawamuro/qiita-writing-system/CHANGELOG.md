# Changelog

All notable changes to this project will be documented in this file.

## [1.1.0] - 2026-02-24

### Added
- **Qiita Organization紐付け機能**
  - `qiita_get_organizations` ツール - 所属Organization一覧を取得
  - `qiita_post_article` に `organization_url_name` パラメータを追加
  - 設定ファイルでデフォルトOrganizationを設定可能
  - 投稿時にOrganizationを選択できる機能
- ドキュメント追加
  - `docs/ORGANIZATION_GUIDE.md` - Organization紐付けガイド

### Changed
- MCPサーバーのバージョンを 1.1.0 に更新
- 設定ファイル `.qiita-config.yaml` に `organization` セクションを追加

## [1.0.0] - 2026-02-24

### Added
- 初回リリース
- 5つのClaude Code Skills
  - `/qiita-workflow` - ワークフロー管理
  - `/qiita-draft` - 下書き作成
  - `/qiita-review` - 文体チェック
  - `/qiita-publish` - Qiita投稿
  - `/qiita-topics-from-slack` - Slackネタ探索
- Qiita MCP Server
  - 記事の投稿・更新・削除・取得機能
- 設定ファイル
  - `.qiita-config.yaml` - 文体チェック設定
  - `.mcp.json.example` - MCP設定例
- ドキュメント
  - README.md - セットアップガイド
  - USER_GUIDE.md - 詳細な使い方
- インストールスクリプト
  - `install.sh` - 自動インストール

### Features
- アイディア出しから投稿まで完全自動化
- インタビュー形式で人間味のある文章を生成
- AIっぽい表現を自動検出・修正提案
- Claude CodeからQiitaに直接投稿
- Slackから記事ネタを自動抽出
- Obsidian Daily Notesから記事候補を自動発見
