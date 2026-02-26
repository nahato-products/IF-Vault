# xurl-twitter-ops Reference

xurl CLI の全コマンドリファレンス、jq レシピ、バッチパターン、ワークフロー例。

---

## コマンド全量リファレンス

### 認証（auth）

```bash
xurl auth login            # OAuth 2.0 PKCE 認証開始
xurl auth status           # 認証状態確認
xurl auth refresh          # トークンリフレッシュ
xurl auth logout           # 認証情報削除
```

### ツイート操作（tweets）

```bash
# 投稿
xurl post tweets -d '{"text": "ツイート内容"}'

# 取得
xurl get tweets/TWEET_ID \
  --tweet-fields "public_metrics,created_at,conversation_id,entities" \
  --expansions "author_id,attachments.media_keys" \
  --media-fields "url,preview_image_url"

# 複数ツイート一括取得
xurl get tweets \
  --ids "ID1,ID2,ID3" \
  --tweet-fields "public_metrics,created_at"

# 削除
xurl delete tweets/TWEET_ID

# いいね
xurl post users/USER_ID/likes -d '{"tweet_id": "TWEET_ID"}'
xurl delete users/USER_ID/likes/TWEET_ID

# リツイート
xurl post users/USER_ID/retweets -d '{"tweet_id": "TWEET_ID"}'
xurl delete users/USER_ID/retweets/TWEET_ID

# ブックマーク
xurl post users/USER_ID/bookmarks -d '{"tweet_id": "TWEET_ID"}'
xurl delete users/USER_ID/bookmarks/TWEET_ID
xurl get users/USER_ID/bookmarks --tweet-fields "public_metrics"
```

### ユーザー操作（users）

```bash
# ユーザー情報（username指定）
xurl get users/by/username/USERNAME \
  --user-fields "public_metrics,description,created_at,profile_image_url,verified"

# ユーザー情報（ID指定）
xurl get users/USER_ID \
  --user-fields "public_metrics,description,created_at"

# 複数ユーザー一括取得
xurl get users/by \
  --usernames "user1,user2,user3" \
  --user-fields "public_metrics"

# フォロワー
xurl get users/USER_ID/followers \
  --user-fields "public_metrics,description" \
  --max-results 100

# フォロイー
xurl get users/USER_ID/following \
  --user-fields "public_metrics" \
  --max-results 100

# フォロー
xurl post users/USER_ID/following -d '{"target_user_id": "TARGET_ID"}'
xurl delete users/USER_ID/following/TARGET_ID

# ミュート
xurl post users/USER_ID/muting -d '{"target_user_id": "TARGET_ID"}'
xurl delete users/USER_ID/muting/TARGET_ID

# ブロック
xurl post users/USER_ID/blocking -d '{"target_user_id": "TARGET_ID"}'
xurl delete users/USER_ID/blocking/TARGET_ID
```

### タイムライン

```bash
# ユーザーのツイート
xurl get users/USER_ID/tweets \
  --tweet-fields "public_metrics,created_at" \
  --max-results 100

# ユーザーのメンション
xurl get users/USER_ID/mentions \
  --tweet-fields "public_metrics,created_at" \
  --max-results 100

# 逆時系列タイムライン
xurl get users/USER_ID/timelines/reverse_chronological \
  --tweet-fields "public_metrics,created_at" \
  --max-results 100
```

### 検索

```bash
# 直近7日検索
xurl get tweets/search/recent \
  --query "QUERY" \
  --tweet-fields "public_metrics,created_at,author_id,entities" \
  --expansions "author_id" \
  --user-fields "public_metrics,username" \
  --max-results 100 \
  --start-time "2026-02-01T00:00:00Z" \
  --end-time "2026-02-24T23:59:59Z"

# 全期間検索（Pro以上）
xurl get tweets/search/all \
  --query "QUERY" \
  --tweet-fields "public_metrics,created_at" \
  --max-results 500
```

### ストリーム

```bash
# ルール追加
xurl post tweets/search/stream/rules \
  -d '{"add": [{"value": "QUERY", "tag": "TAG_NAME"}]}'

# ルール一覧
xurl get tweets/search/stream/rules

# ルール削除
xurl post tweets/search/stream/rules \
  -d '{"delete": {"ids": ["RULE_ID_1", "RULE_ID_2"]}}'

# ストリーム接続
xurl get tweets/search/stream \
  --tweet-fields "public_metrics,created_at,author_id" \
  --expansions "author_id"
```

### リスト

```bash
# リスト作成
xurl post lists -d '{"name": "Tech JP", "description": "日本語テック系", "private": true}'

# リストにメンバー追加
xurl post lists/LIST_ID/members -d '{"user_id": "USER_ID"}'

# リストのツイート取得
xurl get lists/LIST_ID/tweets \
  --tweet-fields "public_metrics,created_at" \
  --max-results 100
```

### スペース

```bash
# スペース検索
xurl get spaces/search --query "keyword" --space-fields "title,participant_count"

# スペース詳細
xurl get spaces/SPACE_ID --space-fields "title,participant_count,started_at"
```

---

## tweet-fields / user-fields / expansions 一覧

### tweet-fields

| フィールド | 内容 |
|-----------|------|
| `public_metrics` | いいね・RT・返信・インプレッション数 |
| `created_at` | 投稿日時 |
| `author_id` | 投稿者ID |
| `conversation_id` | スレッドの起点ツイートID |
| `entities` | URL・ハッシュタグ・メンション |
| `referenced_tweets` | 引用RT・返信元の情報 |
| `attachments` | メディア・投票 |
| `context_annotations` | トピック・エンティティ分類 |
| `lang` | 言語コード |
| `source` | 投稿元アプリ |

### user-fields

| フィールド | 内容 |
|-----------|------|
| `public_metrics` | フォロワー・フォロー・ツイート数 |
| `description` | 自己紹介 |
| `created_at` | アカウント作成日 |
| `profile_image_url` | アイコンURL |
| `verified` | 認証バッジ |
| `location` | 場所 |
| `url` | プロフィールURL |
| `pinned_tweet_id` | 固定ツイートID |

### expansions

| 値 | 展開される情報 |
|----|--------------|
| `author_id` | ツイート投稿者のユーザー情報 |
| `attachments.media_keys` | メディア詳細 |
| `referenced_tweets.id` | 引用元・返信元ツイート |
| `in_reply_to_user_id` | 返信先ユーザー |

---

## jq レシピ集

### 基本パース

```bash
# ツイートテキスト一覧
| jq -r '.data[] | .text'

# ユーザー名 + テキスト
| jq -r '.data[] | "\(.author_id): \(.text[:80])"'

# public_metrics だけ抽出
| jq '.data[] | .public_metrics'
```

### エンゲージメント分析

```bash
# エンゲージメント率計算（降順）
| jq '[.data[] | {
    text: .text[:60],
    likes: .public_metrics.like_count,
    rts: .public_metrics.retweet_count,
    replies: .public_metrics.reply_count,
    impressions: .public_metrics.impression_count,
    engagement_rate: (
      ((.public_metrics.like_count + .public_metrics.retweet_count + .public_metrics.reply_count)
      / (.public_metrics.impression_count + 1)) * 100 | . * 100 | floor / 100
    )
  }] | sort_by(-.engagement_rate)'

# 合計メトリクス
| jq '{
    total_tweets: (.data | length),
    total_likes: [.data[].public_metrics.like_count] | add,
    total_rts: [.data[].public_metrics.retweet_count] | add,
    total_impressions: [.data[].public_metrics.impression_count] | add,
    avg_likes: ([.data[].public_metrics.like_count] | add / length | . * 10 | floor / 10)
  }'
```

### 時間帯分析

```bash
# 投稿時間帯（時）ごとの平均いいね
| jq '[.data[] | {
    hour: (.created_at | split("T")[1] | split(":")[0] | tonumber),
    likes: .public_metrics.like_count
  }] | group_by(.hour) | map({
    hour: .[0].hour,
    count: length,
    avg_likes: ([.[].likes] | add / length | . * 10 | floor / 10)
  }) | sort_by(.hour)'
```

### CSV 出力

```bash
# ヘッダー付きCSV
(echo "created_at,text,likes,retweets,replies,impressions" && \
xurl get users/USER_ID/tweets \
  --tweet-fields "public_metrics,created_at" \
  --max-results 100 \
| jq -r '.data[] | [
    .created_at,
    (.text | gsub("[\\n\\r]"; " ") | gsub(","; "、"))[:80],
    .public_metrics.like_count,
    .public_metrics.retweet_count,
    .public_metrics.reply_count,
    .public_metrics.impression_count
  ] | @csv') > /tmp/claude/tweets.csv
```

### ページネーション

```bash
# next_token を使った全件取得
TOKEN=""
PAGE=1
while true; do
  ARGS="--tweet-fields public_metrics,created_at --max-results 100"
  [ -n "$TOKEN" ] && ARGS="$ARGS --pagination-token $TOKEN"

  RESULT=$(xurl get users/USER_ID/tweets $ARGS)
  echo "$RESULT" | jq '.data[]' >> /tmp/claude/all_tweets.jsonl

  TOKEN=$(echo "$RESULT" | jq -r '.meta.next_token // empty')
  [ -z "$TOKEN" ] && break

  echo "Page $PAGE done. Next: $TOKEN"
  PAGE=$((PAGE + 1))
  sleep 2  # レート制限配慮
done
```

---

## レート制限ティア別テーブル

### 読み取り系

| エンドポイント | Free | Basic | Pro | Enterprise |
|---------------|------|-------|-----|-----------|
| GET tweets | 25/24h | 300/15min | 300/15min | カスタム |
| GET users | 25/24h | 300/15min | 300/15min | カスタム |
| GET users/:id/tweets | 25/24h | 300/15min | 300/15min | カスタム |
| GET tweets/search/recent | 10/24h | 60/15min | 300/15min | カスタム |
| GET tweets/search/all | - | - | 300/15min | カスタム |
| GET users/:id/followers | 15/24h | 15/15min | 15/15min | カスタム |

### 書き込み系

| エンドポイント | Free | Basic | Pro | Enterprise |
|---------------|------|-------|-----|-----------|
| POST tweets | 17/24h | 100/24h | 100/24h | カスタム |
| DELETE tweets | 50/24h | 50/24h | 50/24h | カスタム |
| POST likes | 200/24h | 200/24h | 200/24h | カスタム |
| POST retweets | 300/24h | 300/24h | 300/24h | カスタム |

### ストリーム

| 項目 | Free | Basic | Pro | Enterprise |
|------|------|-------|-----|-----------|
| 同時接続数 | 1 | 1 | 2 | カスタム |
| ルール数 | 5 | 25 | 1000 | カスタム |
| ルール文字数 | 512 | 512 | 1024 | カスタム |

### 月額ツイート取得上限

| ティア | 月間取得数 | 月額（参考） |
|--------|-----------|------------|
| Free | 10,000 | $0 |
| Basic | 10,000 | $100 |
| Pro | 1,000,000 | $5,000 |
| Enterprise | カスタム | 要問合せ |

---

## OAuth 2.0 PKCE フロー

```
┌────────────┐     1. auth login      ┌──────────────┐
│   xurl CLI │ ──────────────────────> │  X Developer │
│            │                         │    Portal    │
│            │     2. ブラウザ認可      │              │
│            │ <─ ─ ─ (redirect) ─ ─ > │              │
│            │                         │              │
│            │     3. auth code        │              │
│            │ ──────────────────────> │              │
│            │                         │              │
│            │     4. access_token     │              │
│            │ <────────────────────── │              │
│            │        + refresh_token  │              │
└────────────┘                         └──────────────┘
        │
        │  5. API リクエスト
        │     Authorization: Bearer <access_token>
        ▼
┌──────────────┐
│  X API v2    │
└──────────────┘
```

### PKCE の仕組み

1. `code_verifier`（ランダム文字列）を生成
2. `code_challenge` = SHA256(code_verifier) の Base64URL
3. 認可リクエストに `code_challenge` を含める
4. トークン交換時に `code_verifier` を送信（サーバー側で検証）

### トークン管理

```bash
# トークン有効期限: 2時間（access_token）
# リフレッシュトークン: 長期間有効

# 自動リフレッシュ（xurl が内部で処理）
xurl auth refresh

# 認証情報の保存場所
# ~/.xurl/credentials.json（自動管理）
```

---

## エラーコードリファレンス

| HTTP | エラータイトル | 原因 | 対処法 |
|------|-------------|------|--------|
| 400 | Invalid Request | パラメータ不正・クエリ構文エラー | リクエストボディ・クエリを確認 |
| 401 | Unauthorized | トークン期限切れ・無効 | `xurl auth login` で再認証 |
| 403 | Forbidden | スコープ不足・アカウント制限 | Developer Portal でスコープ確認 |
| 404 | Not Found | ID が存在しない・削除済み | ID を再確認 |
| 429 | Too Many Requests | レート制限超過 | `x-rate-limit-reset` ヘッダーの時刻まで待機 |
| 503 | Service Unavailable | X 側の一時障害 | 数分後にリトライ |

### 429 エラーの Exponential Backoff

```bash
MAX_RETRIES=5
RETRY=0
WAIT=60

while [ $RETRY -lt $MAX_RETRIES ]; do
  RESULT=$(xurl get tweets/search/recent --query "keyword" 2>&1)

  if echo "$RESULT" | jq -e '.data' > /dev/null 2>&1; then
    echo "$RESULT"
    break
  fi

  RETRY=$((RETRY + 1))
  echo "Rate limited. Retry $RETRY/$MAX_RETRIES in ${WAIT}s..."
  sleep $WAIT
  WAIT=$((WAIT * 2))
done
```

---

## バッチ操作パターン

### 複数ユーザーの一括プロフィール取得

```bash
# ユーザー名リストから一括取得
USERS="user1,user2,user3,user4,user5"
xurl get users/by \
  --usernames "$USERS" \
  --user-fields "public_metrics,description,created_at" \
| jq '.data[] | {
    username: .username,
    followers: .public_metrics.followers_count,
    tweets: .public_metrics.tweet_count,
    description: .description[:60]
  }'
```

### 複数ツイートの一括取得

```bash
# ID リストから一括取得（最大100件）
IDS="1234567890,1234567891,1234567892"
xurl get tweets \
  --ids "$IDS" \
  --tweet-fields "public_metrics,created_at"
```

### ファイルからの連続投稿（スレッド作成）

```bash
# thread.jsonl の各行を連続投稿
PREV_ID=""
while IFS= read -r TEXT; do
  PAYLOAD="{\"text\": \"$TEXT\""
  [ -n "$PREV_ID" ] && PAYLOAD="$PAYLOAD, \"reply\": {\"in_reply_to_tweet_id\": \"$PREV_ID\"}"
  PAYLOAD="$PAYLOAD}"

  RESULT=$(xurl post tweets -d "$PAYLOAD")
  PREV_ID=$(echo "$RESULT" | jq -r '.data.id')
  echo "Posted: $PREV_ID - $TEXT"
  sleep 3  # レート制限配慮
done < /tmp/claude/thread.txt
```

### 定期取得スクリプト

```bash
# 日次データ収集（cron 用）
DATE=$(date +%Y-%m-%d)
xurl get users/USER_ID/tweets \
  --tweet-fields "public_metrics,created_at" \
  --max-results 100 \
  --start-time "${DATE}T00:00:00Z" \
> "/tmp/claude/daily_${DATE}.json"
```

---

## 分析クエリテンプレート

### 1. エンゲージメントレポート

```bash
# ユーザーの直近100ツイートのエンゲージメントサマリ
xurl get users/USER_ID/tweets \
  --tweet-fields "public_metrics,created_at" \
  --max-results 100 \
| jq '{
    period: {
      from: (.data | last | .created_at),
      to: (.data | first | .created_at)
    },
    summary: {
      total_tweets: (.data | length),
      total_likes: [.data[].public_metrics.like_count] | add,
      total_rts: [.data[].public_metrics.retweet_count] | add,
      total_replies: [.data[].public_metrics.reply_count] | add,
      total_impressions: [.data[].public_metrics.impression_count] | add
    },
    averages: {
      avg_likes: ([.data[].public_metrics.like_count] | add / length | . * 10 | floor / 10),
      avg_rts: ([.data[].public_metrics.retweet_count] | add / length | . * 10 | floor / 10),
      avg_engagement_rate: (
        ([.data[] | .public_metrics.like_count + .public_metrics.retweet_count + .public_metrics.reply_count] | add)
        / ([.data[].public_metrics.impression_count] | add + 1) * 100
        | . * 100 | floor / 100
      )
    },
    top3: [.data | sort_by(-.public_metrics.like_count)[:3][] | {
      text: .text[:60],
      likes: .public_metrics.like_count,
      impressions: .public_metrics.impression_count
    }]
  }'
```

### 2. 競合比較分析

```bash
# 複数アカウントのメトリクス比較
for USER in competitor1 competitor2 competitor3; do
  xurl get users/by/username/$USER \
    --user-fields "public_metrics" \
  | jq "{username: \"$USER\", metrics: .data.public_metrics}"
done | jq -s 'sort_by(-.metrics.followers_count)'
```

### 3. ハッシュタグトレンド分析

```bash
# ハッシュタグの投稿頻度・エンゲージメント
xurl get tweets/search/recent \
  --query "#個人開発 lang:ja -is:retweet" \
  --tweet-fields "public_metrics,created_at" \
  --max-results 100 \
| jq '{
    hashtag: "#個人開発",
    total: (.data | length),
    period: {from: (.data | last | .created_at), to: (.data | first | .created_at)},
    avg_likes: ([.data[].public_metrics.like_count] | add / length | . * 10 | floor / 10),
    avg_rts: ([.data[].public_metrics.retweet_count] | add / length | . * 10 | floor / 10),
    high_engagement: [.data | sort_by(-.public_metrics.like_count)[:5][] | {
      text: .text[:60],
      likes: .public_metrics.like_count
    }]
  }'
```

---

## 実践ワークフロー例

### 1. 競合アカウント定点観測

```bash
# Step 1: 競合リスト定義
COMPETITORS="competitor1,competitor2,competitor3"

# Step 2: プロフィール一括取得
xurl get users/by \
  --usernames "$COMPETITORS" \
  --user-fields "public_metrics,description" \
| jq -r '.data[] | [.username, .public_metrics.followers_count, .public_metrics.tweet_count] | @csv' \
> /tmp/claude/competitors.csv

# Step 3: DuckDB で分析（duckdb-csv 連携）
duckdb -markdown -c "
SELECT * FROM '/tmp/claude/competitors.csv'
ORDER BY column1 DESC
"
```

### 2. コンテンツカレンダー作成

```bash
# Step 1: 過去の高エンゲージメントツイートを分析
xurl get users/USER_ID/tweets \
  --tweet-fields "public_metrics,created_at" \
  --max-results 100 \
| jq '[.data[] | select(.public_metrics.like_count > 10) | {
    text: .text[:80],
    hour: (.created_at | split("T")[1][:2]),
    day: (.created_at | split("T")[0]),
    likes: .public_metrics.like_count
  }]' > /tmp/claude/high_engagement.json

# Step 2: 最適投稿時間帯を特定
cat /tmp/claude/high_engagement.json \
| jq 'group_by(.hour) | map({
    hour: .[0].hour,
    count: length,
    avg_likes: ([.[].likes] | add / length)
  }) | sort_by(-.avg_likes) | .[:5]'
```

### 3. エンゲージメントトラッキング（日次）

```bash
# 毎日実行して CSV に追記
DATE=$(date +%Y-%m-%d)

xurl get users/by/username/MY_USERNAME \
  --user-fields "public_metrics" \
| jq -r --arg date "$DATE" \
  '[$date, .data.public_metrics.followers_count, .data.public_metrics.tweet_count, .data.public_metrics.listed_count] | @csv' \
>> /tmp/claude/follower_tracking.csv
```

### 4. メンション監視・自動集計

```bash
# 自分へのメンション直近分を取得・分類
xurl get users/USER_ID/mentions \
  --tweet-fields "public_metrics,created_at,author_id" \
  --max-results 50 \
| jq '{
    total_mentions: (.data | length),
    sentiment_proxy: {
      high_engagement: [.data[] | select(.public_metrics.like_count > 5)] | length,
      questions: [.data[] | select(.text | test("\\?|？"))] | length
    },
    recent: [.data[:10][] | {
      from: .author_id,
      text: .text[:80],
      likes: .public_metrics.like_count
    }]
  }'
```

### 5. トピック調査（deep-research 連携）

```bash
# Step 1: X でリアルなユーザーの声を収集
xurl get tweets/search/recent \
  --query "Next.js 15 困った OR つらい OR バグ lang:ja -is:retweet" \
  --tweet-fields "public_metrics,created_at" \
  --max-results 100 \
| jq '[.data[] | {text: .text, likes: .public_metrics.like_count}]' \
> /tmp/claude/user_pain_points.json

# Step 2: CSV変換 → DuckDB で集計
cat /tmp/claude/user_pain_points.json \
| jq -r '.[] | [.likes, (.text | gsub("[\\n\\r]"; " "))[:120]] | @csv' \
> /tmp/claude/pain_points.csv

# Step 3: deep-research スキルでペインポイントを深掘り
```

---

## 検索クエリ高度パターン

### 演算子の組み合わせ

```bash
# 日本語テック系 + メディア付き + 人気ツイートのみ
"(Next.js OR React OR TypeScript) lang:ja has:media -is:retweet min_faves:10"

# 特定ユーザーへの返信のうち質問を含むもの
"to:username (? OR ？ OR 教えて OR 方法) -is:retweet"

# 特定ドメインのリンクを含むツイート
"url:\"zenn.dev\" lang:ja -is:retweet"

# コンバセーション内の全ツイート
"conversation_id:TWEET_ID"
```

### 期間指定のパターン

```bash
# ISO 8601 形式
--start-time "2026-02-01T00:00:00Z"
--end-time "2026-02-24T23:59:59Z"

# 組み合わせ例
xurl get tweets/search/recent \
  --query "keyword lang:ja" \
  --start-time "2026-02-17T00:00:00Z" \
  --end-time "2026-02-24T00:00:00Z" \
  --tweet-fields "public_metrics,created_at" \
  --max-results 100
```

---

## トラブルシューティング

| 症状 | 原因 | 対処 |
|------|------|------|
| `401` が連発 | トークン期限切れ | `xurl auth refresh` → ダメなら `xurl auth login` |
| 検索結果が空 | クエリ構文エラー or 該当なし | クエリを簡略化して再試行 |
| `next_token` が取れない | 最終ページ到達 | 正常終了。ループを抜ける |
| ストリームが切断 | ネットワーク障害 or サーバー側切断 | 自動再接続 or 手動で再実行 |
| JSON パースエラー | xurl のエラーメッセージ混入 | `2>/dev/null` でstderr除外 |
| Free ティアで 403 | エンドポイント未対応 | Basic 以上へのアップグレードを検討 |
