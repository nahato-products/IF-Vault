# LINE Bot Development -- Reference

SKILL.md の補足資料。署名検証、メッセージ送信、イベントハンドリング、LIFF、Supabase同期、アクションタイプ、Flex詳細、Quick Reply、レート制限、料金、エラーコード、メッセージ型、トラブルシューティング、冪等性テンプレート、チェックリスト。

---

## Webhook 署名検証（Next.js App Router）

```typescript
import crypto from 'node:crypto';

// Next.js App Router
export async function POST(request: Request) {
  const body = await request.text(); // raw body必須
  const signature = request.headers.get('x-line-signature') || '';

  const hash = crypto
    .createHmac('SHA256', process.env.LINE_CHANNEL_SECRET!)
    .update(body)
    .digest('base64');

  try {
    if (!crypto.timingSafeEqual(Buffer.from(hash, 'base64'), Buffer.from(signature, 'base64'))) {
      return new Response('Unauthorized', { status: 401 });
    }
  } catch {
    return new Response('Unauthorized', { status: 401 });
  }

  let events: WebhookEvent[];
  let webhookEventId: string | undefined;
  try {
    const parsed = JSON.parse(body);
    events = parsed.events;
    webhookEventId = parsed.webhookEventId; // top-level property of request body
  } catch {
    return new Response('Bad Request', { status: 400 });
  }

  await Promise.allSettled(events.map((event) => handleEvent(event, webhookEventId)));
  return Response.json({ status: 'ok' });
}
```

**落とし穴**: body-parser でJSONをパースしてから検証すると失敗する。raw body を先に取得すること。

---

## 画像・スタンプ・動画の送信

```js
// 画像メッセージ
await client.replyMessage({
  replyToken: event.replyToken,
  messages: [{
    type: 'image',
    originalContentUrl: 'https://example.com/image.jpg',  // HTTPS必須、最大10MB
    previewImageUrl: 'https://example.com/image_preview.jpg',  // 最大1MB
  }],
});

// スタンプ（packageId + stickerId は LINE Sticker List 参照）
await client.replyMessage({
  replyToken: event.replyToken,
  messages: [{ type: 'sticker', packageId: '446', stickerId: '1988' }],
});
```

---

## ユーザー送信コンテンツの取得

ユーザーが送った画像・動画・音声・ファイルをダウンロードする。

```typescript
import { messagingApi } from '@line/bot-sdk';

// SDK v10.x: getMessageContent は MessagingApiBlobClient に移動
const blobClient = new messagingApi.MessagingApiBlobClient({
  channelAccessToken: process.env.LINE_CHANNEL_ACCESS_TOKEN!,
});

if (event.type === 'message' && event.message.type === 'image') {
  const stream = await blobClient.getMessageContent(event.message.id);
  // stream は Readable — ファイル保存やクラウドストレージにパイプ
  const chunks: Buffer[] = [];
  for await (const chunk of stream) chunks.push(chunk as Buffer);
  const buffer = Buffer.concat(chunks);
  // Supabase Storage 等にアップロード
}
```

**注意**: コンテンツは一定期間後に削除される。受信後すぐにダウンロードすること。

---

## イベントハンドリング

```js
async function handleEvent(event) {
  const { type, source } = event;

  if (type === 'message' && event.message.type === 'text') {
    const text = event.message.text;
    // テキスト処理...
  }

  if (type === 'postback') {
    const data = event.postback.data; // "action=buy&itemid=123"
    const params = new URLSearchParams(data);
    // Postback処理...
  }
}
```

---

## LIFF（ミニアプリ）初期化

```js
import liff from '@line/liff';

await liff.init({ liffId: 'YOUR_LIFF_ID' });
if (!liff.isLoggedIn()) liff.login();

const profile = await liff.getProfile();
// { userId, displayName, pictureUrl, statusMessage }

// 開いているチャットにメッセージ送信
await liff.sendMessages([{ type: 'text', text: 'Hello!' }]);
```

表示モード: `full` / `tall` / `compact`。`liff.init()` はページ開くたびに必要。LIFF でのビューポート・safe-area設計は `mobile-first-responsive` スキル参照。

---

## Supabase ユーザー同期

```typescript
async function handleEvent(event) {
  if (event.type === 'follow') {
    // source.userId はグループ/ルームイベントでは undefined の場合がある
    if (!event.source.userId) return;
    const profile = await client.getProfile(event.source.userId);
    await supabase.from('users').upsert({
      line_user_id: event.source.userId,
      display_name: profile.displayName,
      followed_at: new Date().toISOString(),
    });
  }
}
```

follow 時に upsert、message 時に履歴 insert。DB設計は `ansem-db-patterns` 参照。LINE Login 認証フローは `supabase-auth-patterns` 参照。

---

## Loading Indicator

```typescript
await client.showLoadingAnimation({
  chatId: event.source.userId,
  loadingSeconds: 10, // 5, 10, 15, 20 から選択
});
// 重い処理...
await client.replyMessage({ replyToken, messages });
```

Doherty閾値（400ms）を超える処理時に使用。

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
| `xxs` | 11 | -- | -- |
| `xs` | 13 | 17 | 60x60 |
| `sm` | 14 | 20 | 120x120 |
| `md` | 16 (default) | 24 | 240x240 |
| `lg` | 19 | 30 | 480x480 |
| `xl` | 22 | 36 | 720x720 |
| `xxl` | 29 | -- | 1040x1040 |

### Flex Message サイズ制限

| Container | 上限 | 注意 |
|-----------|------|------|
| Bubble | 10KB | JSON文字列換算 |
| Carousel | 50KB | 最大12 Bubble |

### Flex Message 例

```json
{
  "type": "flex",
  "altText": "注文確認",
  "contents": {
    "type": "bubble",
    "body": {
      "type": "box",
      "layout": "vertical",
      "contents": [
        { "type": "text", "text": "注文確認", "weight": "bold", "size": "xl" },
        { "type": "text", "text": "¥1,000", "color": "#999999" }
      ]
    },
    "footer": {
      "type": "box",
      "layout": "vertical",
      "contents": [{
        "type": "button",
        "action": { "type": "uri", "label": "詳細", "uri": "https://example.com" },
        "style": "primary"
      }]
    }
  }
}
```

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
| Loading Animation | 1 req/chatId/sec |

---

## 料金プラン

無料プランと有料プランがあり、プランによって月間の送信可能メッセージ数が異なる。具体的な料金・メッセージ数は変更される可能性があるため、[LINE公式アカウント料金プラン](https://www.lycbiz.com/jp/service/line-official-account/plan/)で最新情報を確認すること。

**構造的な違い（プランに関わらず共通）:**
- カウント対象: Push / Multicast / Broadcast / Narrowcast
- **Replyはカウント対象外**（どのプランでも無料）
- 無料プランでは追加メッセージの購入不可
- 有料プランでは追加メッセージを従量課金で購入可能

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

## Webhook 冪等性テンプレート

```typescript
// Supabase で webhookEventId を記録して重複排除（UPSERT で TOCTOU 防止）
// webhookEventId はリクエストボディのトップレベルプロパティ（個別eventのプロパティではない）
async function processWebhookIdempotent(event: WebhookEvent, webhookEventId?: string) {
  // webhookEventId が無い場合はイベント固有のキーで代替
  const eventId = webhookEventId
    ?? `${event.type}-${event.timestamp}-${event.source?.userId ?? 'unknown'}`;

  // INSERT with ON CONFLICT で原子的に重複チェック + 記録
  // webhook_events.event_id に UNIQUE 制約が必要
  const { error } = await supabase
    .from('webhook_events')
    .upsert(
      { event_id: eventId, event_type: event.type, status: 'processing' },
      { onConflict: 'event_id', ignoreDuplicates: true }
    );

  if (error) return; // 既に処理中 or 処理済み → スキップ

  try {
    await handleEvent(event);
    await supabase
      .from('webhook_events')
      .update({ status: 'completed', processed_at: new Date().toISOString() })
      .eq('event_id', eventId);
  } catch (e) {
    await supabase
      .from('webhook_events')
      .update({ status: 'failed' })
      .eq('event_id', eventId);
    throw e;
  }
}
```

**`X-Line-Retry-Key` header**: LINE はリトライ時にこのヘッダーを付与する。`webhookEventId` と併用して重複検知の信頼性を高める。初回リクエストにはこのヘッダーは含まれないため、存在自体がリトライの証拠になる。

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
| Loading表示されない | chatIdが不正 or レート超過 | userId確認、1req/sec制限 |
| リトライでイベント重複 | Webhook応答遅延 | webhookEventIdで冪等性確保 |

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

LINE Developers Console > Messaging API > Error Statistics でエラー率を監視。構造化ログ設計は `error-handling-logging` スキル参照。

---

## Bot 初回メッセージテンプレート

```typescript
// follow イベント時の初回メッセージ
async function handleFollow(event: FollowEvent) {
  await client.replyMessage({
    replyToken: event.replyToken,
    messages: [{
      type: 'text',
      text: 'こんにちは！\n\n以下の機能が使えます:',
      quickReply: {
        items: [
          { type: 'action', action: { type: 'message', label: '予約する', text: '予約' } },
          { type: 'action', action: { type: 'message', label: '確認する', text: '確認' } },
          { type: 'action', action: { type: 'message', label: 'ヘルプ', text: 'ヘルプ' } },
        ],
      },
    }],
  });
}
```

---

## エラー応答テンプレート

```typescript
// ユーザーフレンドリーなエラー応答
async function replyError(replyToken: string, errorType: string) {
  const messages: Record<string, string> = {
    not_found: 'お探しの情報が見つかりませんでした。もう一度お試しください。',
    server_error: '一時的にエラーが発生しています。しばらく経ってからお試しください。',
    invalid_input: '入力内容を確認してください。以下から選択できます:',
    rate_limit: 'リクエストが多すぎます。少し待ってからお試しください。',
  };

  await client.replyMessage({
    replyToken,
    messages: [{
      type: 'text',
      text: messages[errorType] || messages.server_error,
    }],
  });
}
```

---

## LINE Bot 実装チェックリスト

### セットアップ
- [ ] `@line/bot-sdk` インストール済み
- [ ] `LINE_CHANNEL_ACCESS_TOKEN` と `LINE_CHANNEL_SECRET` を環境変数に設定
- [ ] Channel Access Token は Long-lived 以外を使用
- [ ] Webhook URL は HTTPS で設定

### Webhook
- [ ] 署名検証を raw body で実施（body-parser より先）
- [ ] 1秒以内に200応答を返す設計
- [ ] `webhookEventId` で冪等性を確保
- [ ] 全イベントタイプにハンドラ or フォールバックを用意
- [ ] replyToken は即座に使用（遅延させない）

### メッセージ
- [ ] Reply を優先、Push は通知用途のみ
- [ ] 1回の送信でメッセージオブジェクトは5つ以内
- [ ] Flex Message は Bubble 10KB / Carousel 50KB 以内
- [ ] `altText` を全てのテンプレート/Flex に設定

### セキュリティ
- [ ] Channel Secret はコードにハードコードしない
- [ ] Webhook endpoint は署名検証をバイパスしない
- [ ] ユーザー入力をそのまま外部APIに渡さない

### UX
- [ ] follow 時に初回メッセージを送信
- [ ] 想定外入力にフォールバック応答を用意
- [ ] Quick Reply の重要項目は先頭と末尾に配置
- [ ] 処理に時間がかかる場合は Loading Indicator を表示
- [ ] エラー時はユーザーフレンドリーなメッセージを返す
