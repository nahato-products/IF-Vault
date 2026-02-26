# LINE Bot Development — Reference

SKILL.md の補足資料。アクションタイプ、Flex詳細、レート制限、料金、エラーコード。

---

## アクションタイプ一覧

| アクション | 説明 | 使用場所 |
|-----------|------|---------|
| `uri` | URLを開く | ボタン、Rich Menu |
| `message` | テキスト送信（ユーザー発言として） | ボタン、Quick Reply |
| `postback` | データをWebhookに送信（チャット非表示可） | ボタン、テンプレート |
| `datetimepicker` | 日時選択UI | テンプレート、Flex |
| `camera` | カメラ起動 | Quick Reply |
| `cameraRoll` | カメラロール起動 | Quick Reply |
| `location` | 位置情報送信 | Quick Reply |
| `richmenuswitch` | Rich Menuタブ切替 | Rich Menu |
| `clipboard` | テキストをクリップボードにコピー | Flex Message |

### postback のベストプラクティス

```js
// data はクエリ文字列形式が扱いやすい
{
  "type": "postback",
  "label": "購入",
  "data": "action=buy&itemId=123&qty=1",
  "displayText": "購入します"  // チャットに表示するテキスト（任意）
}

// Webhook側でパース
const params = new URLSearchParams(event.postback.data);
const action = params.get("action"); // "buy"
```

---

## Flex Message レイアウト詳細

### Box プロパティ

| プロパティ | 値 | 説明 |
|-----------|-----|------|
| `layout` | `vertical` / `horizontal` / `baseline` | 子要素の配置方向 |
| `spacing` | `none` / `xs` / `sm` / `md` / `lg` / `xl` / `xxl` | 子要素間のスペース |
| `margin` | 同上 | Box自体のマージン |
| `paddingAll` | `none` / `xs` 〜 `xxl` / `{N}px` | 全方向パディング |
| `backgroundColor` | `#RRGGBB` / `#RRGGBBAA` | 背景色 |
| `cornerRadius` | `none` / `xs` 〜 `xxl` / `{N}px` | 角丸 |
| `flex` | 整数 | 親Box内での占有比率 |
| `justifyContent` | `center` / `flex-start` / `flex-end` / `space-between` / `space-around` / `space-evenly` | 主軸配置 |
| `alignItems` | `center` / `flex-start` / `flex-end` | 交差軸配置 |

### サイズ定数表

| 定数 | Text (px) | Icon (px) | Image |
|------|-----------|-----------|-------|
| `xxs` | 11 | — | — |
| `xs` | 13 | 17 | 60x60 |
| `sm` | 14 | 20 | 120x120 |
| `md` | 16 (default) | 24 | 240x240 |
| `lg` | 19 | 30 | 480x480 |
| `xl` | 22 | 36 | 720x720 |
| `xxl` | 29 | — | 1040x1040 |

### Flex Message サイズ制限

| Container | 上限 | 注意 |
|-----------|------|------|
| Bubble | 10KB | JSON文字列換算 |
| Carousel | 50KB | 最大12 Bubble |

---

## Quick Reply

```json
{
  "type": "text",
  "text": "どちらを選びますか？",
  "quickReply": {
    "items": [
      {
        "type": "action",
        "imageUrl": "https://example.com/icon.png",
        "action": { "type": "message", "label": "オプションA", "text": "A" }
      },
      {
        "type": "action",
        "action": { "type": "location", "label": "位置情報" }
      }
    ]
  }
}
```

- 最大13アイテム
- imageUrl は任意（1000x1000px正方形推奨）
- 1回タップで消える（再送不可）

---

## レート制限

| API | 制限 |
|-----|------|
| Reply | 特に明示なし（高い） |
| Push / Multicast | 2,000 req/sec |
| Broadcast / Narrowcast | 60 req/hour |
| Get Profile | 2,000 req/sec |
| Get Content (画像等) | 2,000 req/sec |
| Rich Menu (作成) | 100 req/min |
| Rich Menu (リンク) | 1,000 req/sec |

---

## 料金プラン（2025年時点）

| プラン | 月額 | 無料メッセージ | 追加 |
|-------|------|--------------|------|
| コミュニケーション | 無料 | 200通 | 不可 |
| ライト | ¥5,000 | 5,000通 | ¥3/通（税別） |
| スタンダード | ¥15,000 | 30,000通 | ~¥3/通（税別） |

カウント対象: Push / Multicast / Broadcast / Narrowcast。**Replyはカウント対象外**。

---

## エラーコード

| HTTP | エラー | 原因 | 対策 |
|------|-------|------|------|
| 400 | Invalid request | リクエスト形式不正 | JSON構造確認 |
| 401 | Unauthorized | トークン無効/期限切れ | トークン再発行 |
| 403 | Forbidden | 権限不足 | チャネル設定確認 |
| 404 | Not found | リソース不存在 | userId/groupId確認 |
| 408 | Timeout | Webhook応答遅延 | 即座に200返す設計に |
| 429 | Rate limited | レート制限超過 | リトライ（Exponential backoff） |
| 500 | Internal error | LINE側障害 | リトライ |

### Webhook 応答のルール

- **1秒以内**に200-299を返す
- タイムアウトすると LINE がリトライ → **冪等性**を確保
- `webhookEventId` で重複排除

---

## メッセージオブジェクト型

| type | 説明 | 主なフィールド |
|------|------|--------------|
| `text` | テキスト | `text`, `emojis` |
| `sticker` | スタンプ | `packageId`, `stickerId` |
| `image` | 画像 | `originalContentUrl`, `previewImageUrl` |
| `video` | 動画 | `originalContentUrl`, `previewImageUrl`, `trackingId` |
| `audio` | 音声 | `originalContentUrl`, `duration` |
| `location` | 位置情報 | `title`, `address`, `latitude`, `longitude` |
| `imagemap` | イメージマップ | `baseUrl`, `baseSize`, `actions` |
| `template` | テンプレート | `template` (buttons/confirm/carousel/image_carousel) |
| `flex` | Flex | `contents` (bubble/carousel) |

---

## トラブルシューティング

| 問題 | 原因 | 対策 |
|------|------|------|
| 署名検証が常に失敗 | body-parserでJSON化後に検証 | raw bodyを先に取得 |
| replyToken が無効 | 時間経過 or 2回目の使用 | 即座にreply、1回限り |
| Push が届かない | ユーザーがBot未フォロー | follow状態確認 |
| Flex が表示されない | サイズ超過 or 構文エラー | Simulator で検証、10KB以下に |
| Webhook が来ない | URL未設定 or HTTPS非対応 | Console確認、ngrokでテスト |
| グループで反応しない | グループ参加権限OFF | Console > Messaging API設定 |
| 画像が送れない | URLがHTTPS非対応 or アクセス不可 | 公開HTTPSのURL使用 |

---

## 開発・テスト

### ngrok でローカルテスト

```bash
ngrok http 3000
# 表示されたHTTPS URLをLINE Developers ConsoleのWebhook URLに設定
```

### Webhook URL 検証

Console の「Verify」ボタンでテストイベント送信可能。正常なら200応答を確認。

### ログ確認

LINE Developers Console > Messaging API > Error Statistics でエラー率を監視。
