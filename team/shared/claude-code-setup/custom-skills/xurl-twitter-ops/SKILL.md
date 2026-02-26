---
name: xurl-twitter-ops
description: "Automate X/Twitter operations via xurl CLI. Use when posting tweets, fetching user profiles, searching posts, analyzing engagement metrics, or streaming real-time data from X platform. Covers OAuth 2.0 PKCE setup, rate limit handling, batch operations, and agent-friendly JSON workflows with jq integration. Do not trigger for general web scraping (use playwright) or social media content strategy without X data (use brainstorming). Invoke with /xurl-twitter-ops."
user-invocable: true
triggers:
  - Twitterに投稿したい
  - X/Twitterを操作
  - ツイートする
  - Xのエンゲージメントを分析
  - /xurl-twitter-ops
---

# xurl-twitter-ops

xurl CLI を使った X/Twitter 操作スキル。投稿・取得・検索・分析・ストリームの5モードをカバー。

## 前提

- `xurl` CLI がインストール済み（`brew install --cask xdevplatform/tap/xurl`）
- OAuth 2.0 認証が完了済み（初回は OAuth Setup セクション参照）
- `jq` 推奨（JSON パース用）

## 安全設計

- **ツイート投稿はデフォルト dry-run 表示**。本番投稿は内容確認後のみ実行
- **削除操作は事前確認必須**（取り消し不可）
- API キーは環境変数経由のみ。ハードコード禁止
- レート制限を常に意識（429 エラー時は自動バックオフ）

## モード一覧

| モード | 用途 | 主要コマンド |
|--------|------|-------------|
| **Post** | ツイート投稿・返信・削除 | `xurl post tweets` |
| **Fetch** | ユーザー情報・ツイート取得 | `xurl get users`, `xurl get tweets` |
| **Search** | キーワード・ハッシュタグ検索 | `xurl get tweets/search/recent` |
| **Analyze** | エンゲージメント分析・メトリクス | `xurl get tweets` + `jq` |
| **Stream** | リアルタイムデータ受信 | `xurl get tweets/search/stream` |

---

## Post モード

ツイートの投稿・返信・引用・削除。

### いつ使うか

- 新規ツイート投稿
- スレッド（連続ツイート）作成
- 既存ツイートへの返信・引用RT
- ツイート削除

### 基本コマンド

```bash
# 新規ツイート
xurl post tweets -d '{"text": "Hello from xurl!"}'

# 返信
xurl post tweets -d '{"text": "@user 返信です", "reply": {"in_reply_to_tweet_id": "TWEET_ID"}}'

# 引用RT
xurl post tweets -d '{"text": "これは良い", "quote_tweet_id": "TWEET_ID"}'

# 削除（事前確認必須）
xurl delete tweets/TWEET_ID
```

### レート制限

| エンドポイント | Free | Basic | Pro |
|---------------|------|-------|-----|
| POST tweets | 17/24h | 100/24h | 100/24h |

---

## Fetch モード

ユーザープロフィール・ツイート詳細の取得。

### いつ使うか

- ユーザープロフィール情報の取得
- 特定ツイートの詳細取得
- フォロワー・フォロイー一覧
- タイムライン取得

### 基本コマンド

```bash
# ユーザー情報（username指定）
xurl get users/by/username/TARGET_USER \
  --tweet-fields "public_metrics" \
  --user-fields "public_metrics,description,created_at"

# ツイート詳細
xurl get tweets/TWEET_ID \
  --tweet-fields "public_metrics,created_at,conversation_id" \
  --expansions "author_id"

# ユーザーのツイート一覧
xurl get users/USER_ID/tweets \
  --tweet-fields "public_metrics,created_at" \
  --max-results 100

# フォロワー一覧
xurl get users/USER_ID/followers \
  --user-fields "public_metrics" \
  --max-results 100
```

### レート制限

| エンドポイント | Free | Basic | Pro |
|---------------|------|-------|-----|
| GET users | 25/24h | 300/15min | 300/15min |
| GET tweets | 25/24h | 300/15min | 300/15min |
| GET users/:id/tweets | 25/24h | 300/15min | 300/15min |

---

## Search モード

キーワード・ハッシュタグ・メンションによる検索。

### いつ使うか

- キーワードでツイート検索
- ハッシュタグトレンド調査
- 競合アカウントのメンション分析
- 特定期間のツイート収集

### 基本コマンド

```bash
# キーワード検索（直近7日）
xurl get tweets/search/recent \
  --query "Next.js lang:ja -is:retweet" \
  --tweet-fields "public_metrics,created_at,author_id" \
  --max-results 100

# ハッシュタグ検索
xurl get tweets/search/recent \
  --query "#個人開発 -is:retweet" \
  --tweet-fields "public_metrics,created_at" \
  --max-results 50

# ユーザーのメンション検索
xurl get tweets/search/recent \
  --query "@TARGET_USER -is:retweet" \
  --max-results 100
```

### 検索クエリ構文

| 演算子 | 例 | 意味 |
|--------|-----|------|
| キーワード | `Next.js` | 含むツイート |
| `#` | `#個人開発` | ハッシュタグ |
| `@` | `@username` | メンション |
| `from:` | `from:username` | 特定ユーザーの投稿 |
| `to:` | `to:username` | 特定ユーザーへの返信 |
| `is:retweet` | `-is:retweet` | RT除外 |
| `has:media` | `has:media` | メディア付き |
| `has:links` | `has:links` | リンク付き |
| `lang:` | `lang:ja` | 言語指定 |
| `OR` | `Next.js OR Nuxt` | OR検索 |

### レート制限

| エンドポイント | Free | Basic | Pro |
|---------------|------|-------|-----|
| GET tweets/search/recent | 10/24h | 60/15min | 300/15min |
| GET tweets/search/all | - | - | 300/15min |

---

## Analyze モード

取得データを jq でパース・集計してエンゲージメント分析。

### いつ使うか

- ツイートのエンゲージメント率計算
- 投稿時間帯別パフォーマンス分析
- フォロワー増減トラッキング
- 競合比較分析

### パイプライン例

```bash
# エンゲージメント率TOP10
xurl get users/USER_ID/tweets \
  --tweet-fields "public_metrics,created_at" \
  --max-results 100 \
| jq '[.data[] | {
    text: .text[:50],
    engagement: ((.public_metrics.like_count + .public_metrics.retweet_count + .public_metrics.reply_count) / .public_metrics.impression_count * 100),
    likes: .public_metrics.like_count
  }] | sort_by(-.engagement) | .[:10]'

# CSV出力（duckdb-csv 連携用）
xurl get users/USER_ID/tweets \
  --tweet-fields "public_metrics,created_at" \
  --max-results 100 \
| jq -r '.data[] | [.created_at, .public_metrics.like_count, .public_metrics.retweet_count, .public_metrics.impression_count, .text[:80]] | @csv' \
> /tmp/claude/tweets.csv
```

詳細な jq レシピ・分析テンプレートは [reference.md](reference.md) を参照。

---

## Stream モード

フィルタードストリームでリアルタイムデータ受信。

### いつ使うか

- 特定キーワードのリアルタイム監視
- ブランドメンションの即時検知
- トレンド発生の早期検出

### 基本コマンド

```bash
# ストリームルール追加
xurl post tweets/search/stream/rules \
  -d '{"add": [{"value": "Next.js OR React lang:ja", "tag": "tech-ja"}]}'

# ルール確認
xurl get tweets/search/stream/rules

# ストリーム開始
xurl get tweets/search/stream \
  --tweet-fields "public_metrics,created_at,author_id"

# ルール削除
xurl post tweets/search/stream/rules \
  -d '{"delete": {"ids": ["RULE_ID"]}}'
```

### レート制限

| エンドポイント | Free | Basic | Pro |
|---------------|------|-------|-----|
| Stream 接続 | 1 | 1 | 2 |
| Stream ルール数 | 5 | 25 | 1000 |

---

## OAuth Setup

### 初回認証フロー

```bash
# 1. 認証開始（ブラウザが開く）
xurl auth login

# 2. 認証状態確認
xurl auth status

# 3. トークンリフレッシュ（有効期限切れ時）
xurl auth refresh
```

### 環境変数

```bash
export XURL_CLIENT_ID="$YOUR_CLIENT_ID"
export XURL_CLIENT_SECRET="$YOUR_CLIENT_SECRET"
```

**注意**: API キーは絶対にハードコードしない。`.env` に書いて `.gitignore` に追加。

---

## レート制限戦略

### バックオフ戦略

```bash
# 429 を検知して exponential backoff
xurl get tweets/search/recent --query "keyword" 2>&1 || {
  echo "Rate limited. Waiting..."
  sleep 60
}
```

### ティア別残量確認

```bash
# レート制限ヘッダー確認
xurl get users/by/username/TARGET_USER --verbose 2>&1 \
| grep -i "x-rate-limit"
```

詳細なティア別制限テーブル・バッチ運用パターンは [reference.md](reference.md) を参照。

---

## エラーハンドリング

| コード | 意味 | 対処 |
|--------|------|------|
| `401` | 認証エラー | `xurl auth login` で再認証 |
| `403` | 権限不足 | Developer Portal でスコープ確認 |
| `429` | レート制限 | `x-rate-limit-reset` まで待機 |
| `400` | リクエスト不正 | クエリ構文・パラメータ確認 |
| `503` | サービス一時停止 | 数分後にリトライ |

---

## Cross-References

### Referenced by

- **deep-research**: X データを使った市場調査・トレンド分析
- **brainstorming**: コンテンツ戦略立案時の X エンゲージメントデータ活用
- **duckdb-csv**: CSV エクスポートしたツイートデータの SQL 分析

### Outgoing

- **deep-research**: X データを使った市場調査・トレンド分析
- **brainstorming**: コンテンツ戦略立案時のエンゲージメントデータ活用
- **duckdb-csv**: CSV エクスポートしたツイートデータの SQL 分析

### References

- [reference.md](reference.md): コマンド全量リファレンス・jq レシピ・バッチパターン・ワークフロー例

## Cross-references

- **gog-gmail**: メール連携でDMや通知を管理
- **marketing-social-media**: Xのコンテンツ戦略と連動
- **natural-japanese-writing**: 日本語ツイートの文体最適化
