# チームメンバーへの配布方法

このドキュメントは、Qiita Skills Packageをチームメンバーに配布する方法を説明します。

## 📦 配布用パッケージの作成

### 方法1: ZIP形式で配布（シンプル）

```bash
# このディレクトリで以下を実行
zip -r qiita-skills-package-v1.0.0.zip \
  skills/ \
  config/ \
  docs/ \
  install.sh \
  uninstall.sh \
  README.md \
  VERSION \
  CHANGELOG.md
```

生成された `qiita-skills-package-v1.0.0.zip` をメンバーに共有します。

**メンバーへの案内文（例）:**

```
Qiita記事執筆を効率化するClaude Code Skillsパッケージを作成しました！

📦 インストール方法:
1. 添付のZIPファイルを解凍
2. ターミナルで `cd qiita-skills-package` に移動
3. `./install.sh` を実行
4. Claude Codeを再起動

詳しくは README.md をご覧ください。

🚀 使い方:
Claude Codeで `/qiita-workflow start` を実行するだけ！
あとは自動的に案内されます。
```

### 方法2: Gitリポジトリで配布（更新管理がしやすい）

```bash
cd qiita-skills-package

# Gitリポジトリを初期化
git init

# .gitignoreを作成
cat > .gitignore << 'EOF'
.DS_Store
*.swp
*.swo
*~
EOF

# 初回コミット
git add .
git commit -m "v1.0.0: 初回リリース - Qiita Skills Package"

# タグを作成
git tag -a v1.0.0 -m "Version 1.0.0"

# GitHubなどにプッシュ
git remote add origin git@github.com:your-org/qiita-skills-package.git
git push -u origin main
git push origin v1.0.0
```

**メンバーへの案内文（例）:**

```
Qiita記事執筆を効率化するClaude Code Skillsパッケージを作成しました！

📦 インストール方法:
1. `git clone git@github.com:your-org/qiita-skills-package.git`
2. `cd qiita-skills-package`
3. `./install.sh`
4. Claude Codeを再起動

詳しくは README.md をご覧ください。

🔄 更新方法:
`git pull origin main && ./install.sh`
```

### 方法3: 社内ファイル共有サービス（Box, Google Drive等）

1. `qiita-skills-package-v1.0.0.zip` を作成
2. 社内ファイル共有サービスにアップロード
3. 共有リンクをメンバーに送付
4. README.md の内容を Slack や社内Wikiにも掲載

## 📋 配布前のチェックリスト

配布する前に、以下を確認してください：

- [ ] `install.sh` と `uninstall.sh` に実行権限がある（`chmod +x`）
- [ ] `VERSION` ファイルが正しいバージョン番号を示している
- [ ] `README.md` にチーム固有の情報（リポジトリURL等）を追記
- [ ] `CHANGELOG.md` が最新の変更を反映している
- [ ] 全てのSkillが正しくコピーされている
- [ ] サンプルで自分の環境でインストールテストをした

## 🛠 チーム固有のカスタマイズ

配布前に、以下をカスタマイズすると良いでしょう：

### 1. `.qiita-config.yaml` をチーム向けに調整

```yaml
# チーム固有のタグを追加
default_tags:
  - "技術"
  - "チーム名"
  - "プロジェクト名"

# チームの記事ネタディレクトリを追加
source_directories:
  - "05_Daily Notes"
  - "04_Archives"
  - "06_Knowledge"
  - "01_Projects"
  - "team/tech-discussions"  # チーム固有
```

### 2. `article-template.md` にチーム固有のフィールドを追加

```markdown
---
title: ""
tags: []
status: draft
workflow_step: idea
created: {{date}}
updated: {{date}}
qiita_url: ""
team: "your-team"  # 追加
project: ""        # 追加
---
```

### 3. `README.md` にチーム固有の情報を追加

- 社内のQiita Organization情報
- チーム内の記事執筆ガイドライン
- サポート窓口（Slackチャンネル等）

### 4. インストールスクリプトのカスタマイズ

```bash
# install.sh に以下を追加

# チーム固有のディレクトリも作成
mkdir -p "$VAULT_PATH/team/tech-discussions"

# チーム向けのウェルカムメッセージ
echo ""
echo -e "${BLUE}📢 チーム向けTips:${NC}"
echo -e "  - #tech-discussions チャンネルで記事ネタを共有しよう"
echo -e "  - 記事を書いたら #blog-posts で共有しよう"
echo ""
```

## 📊 利用状況の追跡（オプション）

チームでの利用状況を把握したい場合：

### 方法1: Googleフォームでフィードバック収集

```markdown
## インストール後のお願い

以下のフォームから、インストール完了をお知らせください！
https://forms.google.com/...

記事を投稿したら、こちらのフォームで共有してください！
https://forms.google.com/...
```

### 方法2: Slackでの共有を促す

```markdown
## 記事を書いたら

1. #blog-posts チャンネルで記事URLを共有
2. 絵文字リアクション 📝 で「執筆中」、🚀 で「公開済み」
```

## 🔄 更新の配布

新しいバージョンをリリースする際：

### 1. バージョンを更新

```bash
# VERSIONファイルを更新
echo "1.1.0" > VERSION

# CHANGELOGを更新
# CHANGELOG.md に新しいバージョンのエントリを追加
```

### 2. 変更をコミット（Git使用時）

```bash
git add .
git commit -m "v1.1.0: 新機能追加"
git tag -a v1.1.0 -m "Version 1.1.0"
git push origin main v1.1.0
```

### 3. メンバーに通知

```
📢 Qiita Skills Package の新バージョン（v1.1.0）をリリースしました！

🆕 新機能:
- [機能1の説明]
- [機能2の説明]

🔄 更新方法:
# Gitの場合
cd qiita-skills-package
git pull origin main
./install.sh

# ZIPの場合
新しいZIPファイルをダウンロードして、再度 install.sh を実行

詳しくは CHANGELOG.md をご覧ください。
```

## 📞 サポート体制

配布後のサポート体制を整えましょう：

### 推奨されるサポートチャネル

1. **Slackチャンネル**: `#qiita-skills-support`
   - 質問・トラブルシューティング
   - 使い方のTips共有

2. **社内Wiki/ドキュメント**:
   - インストール手順
   - FAQ
   - トラブルシューティングガイド

3. **定期的なワークショップ**:
   - 月1回程度のハンズオン
   - 新規メンバーへのオンボーディング

## 📝 配布時のアナウンステンプレート

### Slack通知例

```
🎉 Qiita記事執筆を効率化する新ツールをリリースしました！

**Qiita Skills Package for Claude Code**

Claude Codeを使って、記事の下書きから推敲、投稿まで一貫してサポートします。

✨ 主な機能:
• インタビュー形式で体験を引き出す下書き作成
• AIっぽい文章を検出して修正提案
• Daily Notesから記事候補を自動探索
• ワークフロー管理で次のステップを自動案内

📦 インストール方法:
1. 添付のZIPファイルを解凍（または git clone）
2. `./install.sh` を実行
3. Claude Codeを再起動
4. `/qiita-workflow start` で開始！

📚 詳しくは README.md をご覧ください。
🙋 質問は #qiita-skills-support まで！

Happy Writing! 🚀
```

---

**配布方法について質問があれば、いつでもお知らせください！**
