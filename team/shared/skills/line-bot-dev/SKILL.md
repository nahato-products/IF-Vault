---
name: line-bot-dev
description: "LINE Bot development with Messaging API, @line/bot-sdk, and LIFF mini apps for Node.js/Next.js. Covers webhook signature verification, message types (text, template, flex, quick reply), rich menus, LIFF initialization, channel access tokens, reply vs push cost optimization, multicast and broadcast, postback routing, Supabase user sync, webhook idempotency, and conversational UX. Use when building LINE bots, implementing webhooks, verifying signatures, designing flex messages, creating template messages, setting up rich menus, developing LIFF apps, integrating LINE with Next.js, handling postback events, syncing LINE users to database, optimizing delivery costs, or debugging LINE bot issues. Does NOT cover general web architecture (nextjs-app-router-patterns), auth/RLS design (supabase-auth-patterns), or cognitive UX (ux-psychology)."
user-invocable: false
---

# LINE Bot Development

LINE Messaging API + @line/bot-sdk (Node.js) の実装パターン集。Moltbot等の社内Bot開発に使う。

> **Related skills**: `nextjs-app-router-patterns` (Route Handlers for webhooks), `supabase-auth-patterns` (LINE Login integration), `error-handling-logging` (webhook error handling), `security-review` (webhook signature verification audit), `mobile-first-responsive` (LIFF viewport/safe-area), `ux-psychology` (conversational UX, serial position for quick reply)

## When to Apply

- LINE Bot の新規作成・機能追加
- Webhook の実装・署名検証
- Flex Message / テンプレートメッセージ / Quick Reply の設計
- Rich Menu の作成・切替
- LIFF（ミニアプリ）の開発
- Next.js API Routes での LINE Webhook 処理
- Bot のエラーハンドリング・リトライ戦略

## When NOT to Apply

- LINE Login / OAuth 認証フロー → `supabase-auth-patterns`
- LINE 以外のメッセージングプラットフォーム
- LINE 公式アカウントの管理画面操作（API経由でない場合）
- LIFF の viewport / safe-area / レスポンシブ実装 → `mobile-first-responsive`
- Webhook の構造化ログ設計 → `error-handling-logging`

## Scope Boundaries

| Topic | This Skill | Other Skill |
|-------|-----------|-------------|
| Messaging API, Webhook, Flex | Here | - |
| LINE Login / OAuth | - | `supabase-auth-patterns` |
| Webhook Route Handler patterns | Partial (LINE固有) | `nextjs-app-router-patterns` |
| Webhook error handling | Partial (LINE固有) | `error-handling-logging` |
| DB schema for LINE users | Partial (upsert例) | `ansem-db-patterns` |
| LIFF viewport / safe-area | - | `mobile-first-responsive` |
| Webhook署名検証のセキュリティ監査 | Partial (実装) | `security-review` |
| Quick Reply / Rich Menu の UX設計 | Partial (会話UX) | `ux-psychology` |

---

## Decision Tree: メッセージ送信方式 [CRITICAL]

```
メッセージを送りたい
  +-- ユーザーアクションへの応答？
  |     -> Reply（無料、replyToken使用、即座に）
  +-- Bot起点の通知？
        +-- 1人に送る -> Push（有料、userId指定）
        +-- 複数人(〜500人) -> Multicast（有料）
        +-- 全友だち -> Broadcast（有料、60req/h制限）
        +-- 条件絞り込み -> Narrowcast（有料、60req/h制限）
```

**鉄則**: できる限り Reply を使う。Push はユーザーアクション外の通知だけに限定。

---

## Part 1: SDK と認証 [CRITICAL]

### 1. セットアップ

```bash
npm install @line/bot-sdk
```

```js
import { messagingApi } from '@line/bot-sdk';

const client = new messagingApi.MessagingApiClient({
  channelAccessToken: process.env.LINE_CHANNEL_ACCESS_TOKEN,
});
```

Node.js >= 20 必須（SDK v10.x）。**Breaking change**: v10.x で `replyMessage` 等は位置引数 `(token, messages)` からオブジェクト引数 `({ replyToken, messages })` に変更。

### 2. Channel Access Token

| 種類 | 有効期限 | 推奨度 |
|-----|---------|-------|
| Long-lived | 無期限 | **非推奨**（漏洩リスク大） |
| Short-lived | 30日 | 推奨 |
| v2.1 (JWT) | 最大30日（指定可能） | **推奨** |
| Stateless | 15分 | **最もセキュア**（毎回発行のオーバーヘッドあり） |

Long-lived は絶対使わない。環境変数で管理し、コードにハードコードしない。セキュリティ詳細は `security-review` スキル参照。

### 3. Webhook 署名検証

リクエストボディの**raw文字列**をHMAC-SHA256でハッシュし、`X-Line-Signature` ヘッダーと比較。

```typescript
// Next.js App Router
export async function POST(request: Request) {
  const body = await request.text(); // raw body必須
  const signature = request.headers.get('x-line-signature') || '';

  const hash = crypto
    .createHmac('SHA256', process.env.LINE_CHANNEL_SECRET!)
    .update(body)
    .digest('base64');

  if (hash !== signature) {
    return new Response('Unauthorized', { status: 401 });
  }

  const { events } = JSON.parse(body);
  for (const event of events) await handleEvent(event);
  return Response.json({ status: 'ok' });
}
```

**落とし穴**: body-parser でJSONをパースしてから検証すると失敗する。raw body を先に取得すること。

---

## Part 2: メッセージ送信 [CRITICAL]

### 4. 送信方式の使い分け

| 方式 | 対象 | レート制限 | コスト |
|-----|------|-----------|-------|
| Reply | replyToken で1人 | 高い | **無料** |
| Push | userId で1人 | 2,000 req/sec | 有料 |
| Multicast | 最大500人 | 2,000 req/sec | 有料 |
| Broadcast | 全友だち | 60 req/hour | 有料 |
| Narrowcast | 条件絞り込み | 60 req/hour | 有料 |

カウント単位は**宛先人数**。5人グループに4メッセージ → 5カウント。1回のreply/pushで最大**5つ**のメッセージオブジェクトを送信可能。

### 5. テキストメッセージ + Quick Reply

```js
await client.replyMessage({
  replyToken: event.replyToken,
  messages: [{
    type: 'text',
    text: 'どちらを選びますか？',
    quickReply: {
      items: [
        { type: 'action', action: { type: 'message', label: 'はい', text: 'はい' } },
        { type: 'action', action: { type: 'location', label: '位置情報' } },
      ],
    },
  }],
});
```

Quick Reply: 最大**13**アイテム、1回タップで消える。UX設計（項目順序の系列位置効果）は `ux-psychology` 参照。詳細は [reference.md](reference.md) 参照。

### 6. 画像・スタンプ・動画の送信

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

### 7. ユーザー送信コンテンツの取得

ユーザーが送った画像・動画・音声・ファイルをダウンロードする。

```typescript
if (event.type === 'message' && event.message.type === 'image') {
  const stream = await client.getMessageContent(event.message.id);
  // stream は Readable — ファイル保存やクラウドストレージにパイプ
  const chunks: Buffer[] = [];
  for await (const chunk of stream) chunks.push(chunk as Buffer);
  const buffer = Buffer.concat(chunks);
  // Supabase Storage 等にアップロード
}
```

**注意**: コンテンツは一定期間後に削除される。受信後すぐにダウンロードすること。

---

## Part 3: テンプレートとFlex [HIGH]

### 6. テンプレートメッセージ

| テンプレート | ボタン数 | 用途 |
|------------|--------|------|
| Buttons | 最大4 | 選択肢提示 |
| Confirm | 2 | Yes/No確認 |
| Carousel | 各カラム最大3、最大10カラム | スワイプ閲覧 |
| Image Carousel | 最大10画像 | 画像スワイプ |

### 7. Flex Message 構造

```
FlexMessage
  └── Container (bubble | carousel)
        └── Blocks (header, hero, body, footer)
              └── Components (box, text, image, button)
```

- Bubble: **10KB** 制限
- Carousel: **50KB** 制限、最大**12** Bubble
- Box layout: `vertical` / `horizontal` / `baseline`
- デザインツール: [Flex Message Simulator](https://developers.line.biz/flex-message-simulator/)

Flex Message の JSON 例、レイアウト詳細は [reference.md](reference.md) 参照。

---

## Part 4: Rich Menu [HIGH]

### 8. 作成フロー（API経由）

1. Rich Menu オブジェクト作成（`POST /v2/bot/richmenu`）
2. 画像アップロード（`POST /v2/bot/richmenu/{id}/content`）
3. デフォルト設定（`POST /v2/bot/user/all/richmenu/{id}`）

### 9. Per-User Rich Menu

- ユーザー単位で割り当て可能
- **Per-user > Default** の優先順位
- `richmenuswitch` アクションでタブ切替を実装
- Rich Menu Alias でエイリアス管理

画像サイズ: 2500x1686px or 2500x843px。エリアは座標 + アクションで定義。

---

## Part 5: Webhook イベント [HIGH]

### 10. イベント型

| イベント | replyToken | 説明 |
|---------|-----------|------|
| `message` | あり | テキスト/画像/動画等の受信 |
| `follow` | あり | 友だち追加 |
| `unfollow` | なし | ブロック/削除 |
| `join` | あり | Bot がグループに参加 |
| `leave` | なし | Bot がグループから退出 |
| `postback` | あり | Postback アクション発火 |
| `memberJoined` | あり | メンバーがグループ参加 |
| `memberLeft` | なし | メンバーがグループ退出 |

### 11. イベントハンドリング

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

### 12. Webhook ベストプラクティス

- Webhookは**1秒以内に200応答**を返し、処理はバックグラウンドで
- `webhookEventId` で重複イベントを検知（冪等性確保）
- イベント順序は保証されない。`timestamp` で確認
- replyToken は短時間で失効、**1回限り** → 即座に reply すること
- タイムアウトするとLINEがリトライする → 冪等な処理設計が必須

エラー分類・構造化ログの設計は `error-handling-logging` スキル参照。

---

## Part 6: グループ・LIFF・統合 [MEDIUM]

### 13. グループチャット

- Console で「Allow bot to join group chats」を有効化
- 1グループに1 Official Account のみ
- `source.type` で `'user'` / `'group'` / `'room'` を判別
- グループへの Push は `to` に groupId を指定

### 14. LIFF（ミニアプリ）

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

### 15. Supabase ユーザー同期

```typescript
async function handleEvent(event) {
  if (event.type === 'follow') {
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

## Part 7: 会話UXパターン [HIGH]

### 16. Bot 会話設計の原則

- **初回メッセージ**（follow時）: Bot の機能を簡潔に説明 + Quick Reply で主要アクションを提示
- **エラー時**: 「申し訳ありません」+ 具体的な次のアクション（再試行ボタン等）
- **想定外入力**: 「〇〇の操作はこちらから」と誘導（無視しない）
- **応答なし防止**: 全てのメッセージタイプにフォールバック応答を用意

### 17. Quick Reply / Rich Menu の UX

- Quick Reply の項目順序は**系列位置効果**を活用 → 最重要を先頭と末尾に配置（`ux-psychology` 参照）
- Rich Menu は**最も使う機能を左下**に配置（親指の届きやすさ）
- 選択肢が5個超 → Carousel テンプレートに切替（Hick's Law: 選択肢過多は放棄を招く）

### 18. Loading Indicator

ユーザーにBot処理中を伝える。Doherty閾値（400ms）を超える処理時に使用。

```typescript
await client.showLoadingAnimation({
  chatId: event.source.userId,
  loadingSeconds: 10, // 5, 10, 15, 20 から選択
});
// 重い処理...
await client.replyMessage({ replyToken, messages });
```

---

## Reference

アクションタイプ一覧、Flex レイアウト詳細、Quick Reply詳細、レート制限表、料金プラン、エラーコード、メッセージオブジェクト型、トラブルシューティング、Webhook冪等性テンプレート、実装チェックリストは [reference.md](reference.md) を参照。
