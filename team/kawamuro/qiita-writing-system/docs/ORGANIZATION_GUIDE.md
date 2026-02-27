# Qiita Organization 紐付けガイド

Qiita記事を会社やチームのOrganizationに紐付けて投稿する方法を説明します。

## 🏢 Organizationとは

Qiita Organizationは、会社やチームの技術記事をまとめて管理できる機能です。

- 記事がOrganizationのページに表示される
- 組織の技術力をアピールできる
- チームメンバーの記事をまとめて見られる

## 📋 前提条件

- Qiita OrganizationのメンバーになっていることOrganizationの管理者に追加してもらう必要があります）

## 🚀 使い方

### 方法1: 投稿時に毎回確認する（推奨）

`.qiita-config.yaml` を編集:

```yaml
organization:
  default_url_name: ""
  always_ask: true  # ← これをtrueに
```

こうすると、`/qiita-publish` を実行したときに毎回確認されます:

```
Claude: 「所属しているOrganizationがあります。紐付けますか？」
- 会社名 (company-name)
- チーム名 (team-name)

あなた: 「1」（会社名を選択）または「いいえ」（個人投稿）
```

### 方法2: デフォルトのOrganizationを設定する

`.qiita-config.yaml` を編集:

```yaml
organization:
  default_url_name: "your-organization-url-name"  # ← Organization の URL名
  always_ask: false  # 常にデフォルトを使用
```

この設定にすると、毎回同じOrganizationに自動で紐付けられます。

### 方法3: 手動で指定する

Claude Codeで直接指定:

```
「11_Qiita/drafts/記事.md を company-name Organizationに紐付けて投稿して」
```

## 🔍 Organization URL名の確認方法

### 自分の所属Organization一覧を確認

```
「所属しているQiita Organizationを教えて」
```

Claude Codeが自動的に `qiita_get_organizations` ツールを使って一覧を表示します。

### Qiita Webで確認

1. Qiitaにログイン
2. プロフィールページを開く
3. 「Organizations」タブを確認
4. Organization名の下に表示されているURL (`@organization-name`) がURL名です

例:
- 表示名: 株式会社Example
- URL: `https://qiita.com/organizations/example-inc`
- **URL名: `example-inc`** ← これを使う

## 📝 投稿例

### 個人投稿（Organizationなし）

```bash
/qiita-publish
# 「個人投稿」を選択
```

### Organization投稿

```bash
/qiita-publish
# 「company-name Organizationに紐付け」を選択
```

または:

```
「11_Qiita/drafts/記事.md を company-name に紐付けて投稿」
```

## ⚙️ 設定の詳細

### `default_url_name`

- 空文字列 `""` : 個人投稿（デフォルト）
- `"company-name"` : 指定したOrganizationに自動紐付け

### `always_ask`

- `true` : 毎回確認（推奨）
- `false` : `default_url_name` を自動使用

## 🆘 トラブルシューティング

### 「Organizationが見つかりません」エラー

原因:
- Organizationのメンバーになっていない
- URL名が間違っている

解決方法:
1. Organization管理者にメンバー追加を依頼
2. URL名を確認（`qiita_get_organizations` で確認）

### 「Organization一覧が空です」

原因:
- どのOrganizationにも所属していない

解決方法:
1. 個人投稿する（`default_url_name: ""`）
2. またはOrganization管理者に追加を依頼

### 投稿後にOrganizationを変更したい

残念ながら、投稿後にOrganizationの紐付けは変更できません。

対応方法:
1. 記事を削除
2. 正しいOrganizationで再投稿

## 💡 ベストプラクティス

### チーム全体で使う場合

1. `.qiita-config.yaml` にデフォルトのOrganizationを設定
2. `always_ask: false` にして自動紐付け
3. 個人ブログ用の記事は手動で「個人投稿」を選択

### 個人と会社を使い分ける場合

1. `always_ask: true` にして毎回確認
2. 投稿時に選択する

### プロジェクトごとに設定を変える

Obsidian Vaultごとに `.qiita-config.yaml` を配置すれば、プロジェクトごとに設定を変えられます。

## 📚 参考

- [Qiita Organization公式ドキュメント](https://help.qiita.com/ja/articles/qiita-organization)
- [Qiita API - Organizations](https://qiita.com/api/v2/docs#get-apiv2authenticated_userorganizations)

---

**Organization投稿で、チームの技術力をアピールしましょう！🎉**
