---
name: line-bot-dev
description: "LINE Messaging API + bot-sdk: webhook, flex/quick reply, rich menus, postback routing, LIFF, Supabase user sync, idempotency"
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
ユーザーアクションへの応答? -> Reply（無料、replyToken）
Bot起点の通知? -> 1人:Push / 複数:Multicast / 全員:Broadcast / 絞込:Narrowcast（全て有料）
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

raw body を HMAC-SHA256 でハッシュし `X-Line-Signature` と比較。**raw body を先に取得**（body-parser 後は失敗する）。

```typescript
const body = await request.text(); // raw body必須
const signature = request.headers.get('x-line-signature') || '';
const hash = crypto.createHmac('SHA256', process.env.LINE_CHANNEL_SECRET!).update(body).digest('base64');
try {
  if (!crypto.timingSafeEqual(Buffer.from(hash, 'base64'), Buffer.from(signature, 'base64'))) {
    return new Response('Unauthorized', { status: 401 });
  }
} catch {
  return new Response('Unauthorized', { status: 401 });
}
```

完全な Route Handler 実装 → [reference.md](reference.md)「Webhook 署名検証」

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
// Quick Reply は messages[].quickReply.items[] に action を並べる
{ type: 'action', action: { type: 'message', label: 'はい', text: 'はい' } }
```

最大**13**アイテム、1回タップで消える。UX設計（系列位置効果）は `ux-psychology` 参照。完全な実装例 → [reference.md](reference.md)「Quick Reply」

### 6. 画像・スタンプ・動画の送信

```js
// 画像: HTTPS必須、originalContentUrl(最大10MB) + previewImageUrl(最大1MB)
{ type: 'image', originalContentUrl: 'https://...', previewImageUrl: 'https://...' }
// スタンプ: packageId + stickerId は LINE Sticker List 参照
{ type: 'sticker', packageId: '446', stickerId: '1988' }
```

完全な送信コード → [reference.md](reference.md)「画像・スタンプ・動画の送信」

### 7. ユーザー送信コンテンツの取得

`MessagingApiBlobClient.getMessageContent(messageId)` で Readable stream を取得（SDK v10.x で `MessagingApiClient` から移動）。**コンテンツは一定期間後に削除**されるため即ダウンロード必須。

完全な実装 → [reference.md](reference.md)「ユーザー送信コンテンツの取得」

---

## Part 3: テンプレートとFlex [HIGH]

### 8. テンプレートメッセージ

| テンプレート | ボタン数 | 用途 |
|------------|--------|------|
| Buttons | 最大4 | 選択肢提示 |
| Confirm | 2 | Yes/No確認 |
| Carousel | 各カラム最大3、最大10カラム | スワイプ閲覧 |
| Image Carousel | 最大10画像 | 画像スワイプ |

### 9. Flex Message 構造

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

### 10. 作成フロー（API経由）

1. Rich Menu オブジェクト作成（`POST /v2/bot/richmenu`）
2. 画像アップロード（`POST /v2/bot/richmenu/{id}/content`）
3. デフォルト設定（`POST /v2/bot/user/all/richmenu/{id}`）

### 11. Per-User Rich Menu

- ユーザー単位で割り当て可能
- **Per-user > Default** の優先順位
- `richmenuswitch` アクションでタブ切替を実装
- Rich Menu Alias でエイリアス管理

画像サイズ: 2500x1686px or 2500x843px。エリアは座標 + アクションで定義。

---

## Part 5: Webhook イベント [HIGH]

### 12. イベント型

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

### 13. イベントハンドリング

```js
// event.type で分岐、postback.data は URLSearchParams でパース
if (type === 'postback') {
  const params = new URLSearchParams(event.postback.data); // "action=buy&itemId=123"
}
```

完全な handleEvent 実装 → [reference.md](reference.md)「イベントハンドリング」

### 14. Webhook ベストプラクティス

- Webhookは**1秒以内に200応答**を返し、処理はバックグラウンドで
- `webhookEventId`（リクエストボディのトップレベル）で重複イベントを検知（冪等性確保）
- イベント順序は保証されない。`timestamp` で確認
- replyToken は短時間で失効、**1回限り** → 即座に reply すること
- タイムアウトするとLINEがリトライする → 冪等な処理設計が必須

エラー分類・構造化ログの設計は `error-handling-logging` スキル参照。

---

## Part 6: グループ・LIFF・統合 [MEDIUM]

### 15. グループチャット

- Console で「Allow bot to join group chats」を有効化
- 1グループに1 Official Account のみ
- `source.type` で `'user'` / `'group'` / `'room'` を判別
- グループへの Push は `to` に groupId を指定

### 16. LIFF（ミニアプリ）

```js
await liff.init({ liffId: 'YOUR_LIFF_ID' });
if (!liff.isLoggedIn()) liff.login();
const profile = await liff.getProfile(); // { userId, displayName, pictureUrl }
```

表示モード: `full` / `tall` / `compact`。`liff.init()` はページ開くたびに必要。ビューポート・safe-area → `mobile-first-responsive`。完全な実装 → [reference.md](reference.md)「LIFF（ミニアプリ）初期化」

### 17. Supabase ユーザー同期

follow 時に `getProfile()` → `supabase.from('users').upsert()`。message 時に履歴 insert。DB設計 → `ansem-db-patterns`、LINE Login → `supabase-auth-patterns`。

完全な実装 → [reference.md](reference.md)「Supabase ユーザー同期」

---

## Part 7: 会話UXパターン [HIGH]

### 18. Bot 会話設計の原則

- **初回メッセージ**（follow時）: Bot の機能を簡潔に説明 + Quick Reply で主要アクションを提示
- **エラー時**: 「申し訳ありません」+ 具体的な次のアクション（再試行ボタン等）
- **想定外入力**: 「〇〇の操作はこちらから」と誘導（無視しない）
- **応答なし防止**: 全てのメッセージタイプにフォールバック応答を用意

### 19. Quick Reply / Rich Menu の UX

- Quick Reply の項目順序は**系列位置効果**を活用 → 最重要を先頭と末尾に配置（`ux-psychology` 参照）
- Rich Menu は**最も使う機能を左下**に配置（親指の届きやすさ）
- 選択肢が5個超 → Carousel テンプレートに切替（Hick's Law: 選択肢過多は放棄を招く）

### 20. Loading Indicator

Doherty閾値（400ms）を超える処理前に `client.showLoadingAnimation({ chatId, loadingSeconds })` を呼ぶ。`loadingSeconds`: 5/10/15/20 から選択。

完全な実装 → [reference.md](reference.md)「Loading Indicator」

---

## Checklist

- [ ] Webhook署名検証（`validateSignature`）が実装されているか
- [ ] チャネルアクセストークンがハードコードされていないか（環境変数使用）
- [ ] replyToken の30秒有効期限を考慮した即時レスポンス設計か
- [ ] Push API の従量課金を考慮し reply 優先の設計か
- [ ] Webhook の冪等性（同一eventId重複処理防止）が実装されているか
- [ ] LIFF `liff.init()` の初期化エラーハンドリングがあるか
- [ ] リッチメニューのアクション定義が正しいか（postback / uri / message）

## Cross-references [MEDIUM]

- **supabase-auth-patterns**: LINE Login OAuth連携・Supabase Authとのユーザー同期
- **error-handling-logging**: Webhookエラーの分類・構造化ログ・Sentryでの監視設計
- **ansem-db-patterns**: LINEユーザーテーブルのスキーマ設計・upsertパターン

## Reference

署名検証の完全実装、画像/スタンプ送信、コンテンツ取得、イベントハンドリング、LIFF初期化、Supabase同期、Loading Indicator、アクションタイプ一覧、Flex レイアウト詳細、Quick Reply詳細、レート制限表、料金プラン、エラーコード、メッセージオブジェクト型、トラブルシューティング、Webhook冪等性テンプレート、Bot初回メッセージ/エラー応答テンプレート、実装チェックリストは [reference.md](reference.md) を参照。
