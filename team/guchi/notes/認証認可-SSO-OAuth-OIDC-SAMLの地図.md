---
date: 2026-02-14
tags: [認証, 認可, OAuth, OIDC, SAML, SSO, セキュリティ]
source: https://qiita.com/ryucciarati/items/800beee69019ca84855c
author: ryucciarati（林 龍蔵）
status: active
---

# 認証・認可・SSO・OAuth/OIDC/SAMLの地図

ログイン周りがごちゃつく原因は、専門用語の多さではない。種類の違う言葉が同じレイヤーに置かれがちだから混乱する。レイヤーを分けて整理すると見通しが良くなる。

## レイヤー構造

| レイヤー | 何の話か | 具体例 |
|---------|---------|--------|
| 体験 | ユーザーが感じること | SSO |
| 信頼の仕組み | システム間の信頼構造 | フェデレーション |
| 登場人物 | 誰が何をするか | IdP / SP / RP |
| 規格 | 受け渡しのルール | OAuth 2.0 / OIDC / SAML 2.0 |

「SSO = SAML」は誤り。SSOは体験の名前、SAMLは規格。SSOを実現するためにSAMLやOIDCを使う。

## 認証と認可

ホテルのチェックインで考えるとわかりやすい。

**認証（AuthN）** — チェックインで本人確認する行為。「あなたは誰？」

**認可（AuthZ）** — 部屋のキーで入れる範囲が決まる。「あなたは何ができる？」

HTTPステータスコードとの対応:
- `401 Unauthorized` — 認証が必要、または認証失敗
- `403 Forbidden` — 認証済みだが権限不足

「ログインできるのに403」は認証の問題ではなく認可の問題。この区別がつくだけで原因切り分けが速くなる。

## SSOとフェデレーション

**SSO（Single Sign-On）** はユーザー視点の体験。朝ポータルで1回ログインすれば、勤怠、メール、社内Wikiに追加ログインなしでアクセスできる。

**フェデレーション**はシステム視点の仕組み。「Aが認証した結果をBが受け入れる」という信頼構造を指す。SSOはフェデレーションの上に成り立つ体験だ。

## IdPとSP/RP

フェデレーションの登場人物は2つ。

**IdP（Identity Provider）** — 本人確認を実施し、「認証済み」を発行する側。Entra ID、Okta、Google Workspaceが典型。

**SP/RP（Service Provider / Relying Party）** — IdPの結果を受け取り、検証してサービスを提供する側。SAMLの文脈ではSP、OIDCの文脈ではRPと呼ぶ。

## OAuth 2.0

認証ではなく認可（権限委譲）の仕組み。

写真プリントアプリがGoogle Photosにアクセスしたい場面を想像する。ユーザーのID/パスワードを直接渡すのは危険すぎる。OAuth 2.0は「写真の読み取りだけOK」と範囲を限定して許可を出す仕組みだ。

### Authorization Code Flow

```
ユーザー → クライアント: 連携操作
クライアント → 認可サーバ: 認可リクエスト
認可サーバ → ユーザー: ログイン/同意画面
ユーザー → 認可サーバ: 同意
認可サーバ → クライアント: 認可コード発行
クライアント → 認可サーバ: コードをトークンに交換
認可サーバ → クライアント: Access Token発行
クライアント → リソースサーバ: Access TokenでAPI呼び出し
リソースサーバ → クライアント: データ返却
```

核心はパスワードを渡さず権限だけ渡すこと。「OAuthで認証」という表現は厳密には不正確で、OAuthの中心は認可。

## OIDC（OpenID Connect）

OAuth 2.0に認証機能を追加した規格。OAuthの仕組みを流用しつつ「あなたは誰か」を扱えるようにした。

### 3つのトークン

| トークン | 用途 | 比喩 |
|---------|------|------|
| Access Token | APIへの通行証（権限） | 入館パス |
| ID Token | 「あなたは誰か」の身分証 | 社員証 |
| Refresh Token | Access Token更新の鍵 | 更新手続きの委任状 |

OIDCが「認証+認可」に見えるのは、実装時にAccess Tokenも扱うから。OIDCの核はID Tokenによる認証。

OIDCを使いたくなる場面:
- ユーザーとして登録したい
- ログイン状態を作りたい
- メールアドレスやユーザーIDが必要

## SAML 2.0

企業SSOで頻出する認証結果の受け渡し方式。XMLベースのアサーション（認証結果文書）をIdPからSPに送る。

### SP-Initiated Flow

```
ユーザー → SP: サービスにアクセス
SP → IdP: 認証をリダイレクト
IdP → ユーザー: ログイン画面
ユーザー → IdP: 認証情報入力
IdP → SP: SAML Assertion送信
SP: Assertionを検証（署名・期限）
SP → ユーザー: ログイン完了
```

OIDCとSAMLは骨格が似ている。IdPが認証し、SP/RPが受け取って検証し、ログインが成立する。違いは「何をどう渡すか」という規格の部分。

## OIDCとSAMLの比較

| 観点 | OIDC | SAML 2.0 |
|------|------|----------|
| データ形式 | JSON（JWT） | XML |
| 主な利用場面 | Web/モバイルアプリ、API連携 | 企業SSO、B2B |
| 軽量さ | 軽い | 重い |
| 実装難易度 | 比較的簡単 | 複雑 |
| ベース | OAuth 2.0の拡張 | 独立した仕様 |

新規のアプリ開発ならOIDCを推奨する。SAMLは既存の企業IdP連携で求められる場面が多い。

## ANSEMへの適用メモ

ANSEMのm_agent_securityとm_influencer_securityは現時点でパスワードハッシュベースの認証設計。将来的にSSOを導入する場合、以下が検討対象になる。

- 社内エージェント向け: SAML連携（会社のIdPと統合）
- インフルエンサー向け: OIDCでSNSログイン（Google、LINE）
- API連携: OAuth 2.0のAccess Tokenで外部システム連携

フェデレーション対応を入れるなら、m_agent_securityにexternal_idp_idやfederation_typeのカラム追加が必要になる。Phase 4以降の検討事項。

---

_元記事: [「ログイン周り」がごちゃつく人へ：認証・認可・SSO・OAuth/OIDC/SAMLの地図](https://qiita.com/ryucciarati/items/800beee69019ca84855c)（333いいね、ryucciarati）_
_メモ作成: 2026-02-14_
