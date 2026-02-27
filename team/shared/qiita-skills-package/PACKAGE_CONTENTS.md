# Qiita Skills Package - パッケージ構成

## 📦 パッケージ概要

**バージョン**: 1.0.0
**サイズ**: 約37KB
**形式**: ZIP圧縮
**対応OS**: macOS, Linux

## 📂 ディレクトリ構造

```
qiita-skills-package/
├── README.md                    # メインドキュメント
├── VERSION                      # バージョン情報
├── CHANGELOG.md                 # 変更履歴
├── DISTRIBUTION.md              # 配布方法ガイド
├── PACKAGE_CONTENTS.md          # このファイル
├── install.sh                   # インストールスクリプト
├── uninstall.sh                 # アンインストールスクリプト
│
├── skills/                      # Claude Code Skills
│   ├── qiita-draft/
│   │   └── skill.md            # 下書き作成Skill
│   ├── qiita-review/
│   │   └── skill.md            # 文体チェックSkill
│   ├── qiita-publish/
│   │   └── skill.md            # 投稿準備Skill
│   ├── qiita-workflow/
│   │   └── skill.md            # ワークフロー管理Skill
│   └── qiita-topics-from-slack/
│       └── skill.md            # Slack連携Skill（オプション）
│
├── config/                      # 設定ファイル
│   ├── .qiita-config.yaml      # 文体チェック設定
│   └── templates/
│       └── article-template.md # 記事テンプレート
│
└── docs/                        # ドキュメント
    ├── QUICKSTART.md           # クイックスタート
    ├── WORKFLOW_GUIDE.md       # ワークフローガイド
    └── SYSTEM_ARCHITECTURE.md  # システム構成
```

## 📄 各ファイルの説明

### ルートディレクトリ

| ファイル | 説明 | 必須 |
|---------|------|------|
| `README.md` | メインドキュメント。インストール方法と使い方 | ✅ |
| `install.sh` | 自動インストールスクリプト | ✅ |
| `uninstall.sh` | アンインストールスクリプト | ✅ |
| `VERSION` | バージョン番号（Semantic Versioning） | ✅ |
| `CHANGELOG.md` | バージョンごとの変更履歴 | ✅ |
| `DISTRIBUTION.md` | チーム配布方法ガイド | 📖 |
| `PACKAGE_CONTENTS.md` | パッケージ構成の説明（このファイル） | 📖 |

### skills/ - Claude Code Skills

| Skill | 説明 | 依存関係 |
|-------|------|---------|
| `qiita-draft` | 記事の下書きを作成 | なし |
| `qiita-review` | 文体チェック・推敲 | `.qiita-config.yaml` |
| `qiita-publish` | Qiita投稿用に変換 | なし |
| `qiita-workflow` | ワークフロー管理 | 上記3つのSkill |
| `qiita-topics-from-slack` | Slackから記事ネタ探索 | Slack MCP（オプション） |

### config/ - 設定ファイル

| ファイル | 説明 | カスタマイズ |
|---------|------|-------------|
| `.qiita-config.yaml` | 文体チェックのルール定義 | ✅ 推奨 |
| `templates/article-template.md` | 記事の基本構造 | ✅ 推奨 |

### docs/ - ドキュメント

| ファイル | 説明 | 対象読者 |
|---------|------|---------|
| `QUICKSTART.md` | 最速で記事を書き始める方法 | 初心者 |
| `WORKFLOW_GUIDE.md` | ワークフロー管理の詳細 | 中級者 |
| `SYSTEM_ARCHITECTURE.md` | システム構成と設計思想 | 開発者 |

## 🔧 インストール後の配置

インストール後、以下の場所にファイルが配置されます：

### Claude Code Skills

```
~/.claude/skills/
├── qiita-draft/
│   └── skill.md
├── qiita-review/
│   └── skill.md
├── qiita-publish/
│   └── skill.md
├── qiita-workflow/
│   └── skill.md
└── qiita-topics-from-slack/  # オプション
    └── skill.md
```

### Obsidian Vault

```
~/path/to/vault/11_Qiita/
├── drafts/                    # 執筆中の記事
├── published/                 # 公開済みの記事
├── templates/
│   └── article-template.md
├── .qiita-config.yaml
├── QUICKSTART.md
├── WORKFLOW_GUIDE.md
└── SYSTEM_ARCHITECTURE.md
```

## 📊 ファイルサイズ

| カテゴリ | サイズ（概算） |
|---------|--------------|
| Skills | 27KB |
| Config | 3KB |
| Docs | 25KB |
| Scripts | 5KB |
| **合計** | **60KB (非圧縮)** |
| **ZIP圧縮後** | **37KB** |

## 🔐 セキュリティ

### 含まれないもの

このパッケージには以下は**含まれません**：
- ✅ Qiitaアクセストークン
- ✅ Slackトークン
- ✅ 個人の記事ファイル
- ✅ ユーザー固有の設定

### 安全性

- スクリプトは標準的なbashコマンドのみ使用
- 外部ネットワークへの接続なし
- ユーザーの既存ファイルを自動削除しない
- 上書き時は必ず確認プロンプトを表示

## 🚀 動作環境

### 必須

- **Claude Code**: 最新版推奨
- **Obsidian**: v1.0.0以上（推奨）
- **OS**: macOS または Linux
- **Shell**: bash, zsh

### オプション

- **Slack MCP**: Slack連携を使う場合
- **Qiita MCP**: Claude Codeから直接投稿する場合
- **Git**: バージョン管理する場合

## 📝 ライセンス

MIT License

## 🔄 更新履歴

| バージョン | リリース日 | 主な変更 |
|-----------|----------|---------|
| 1.0.0 | 2026-02-27 | 初回リリース |

---

**最新バージョンは CHANGELOG.md で確認できます。**
