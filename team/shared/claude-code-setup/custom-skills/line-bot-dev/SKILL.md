---
name: line-bot-dev
description: "Build LINE bots and LIFF (LINE Front-end Framework) applications covering webhook handling, message types, rich menus, Flex Messages, LIFF SDK, and authentication with LINE Login. Use when creating LINE chatbots, building LIFF apps, implementing LINE Pay integration, creating rich interactive messages, or setting up LINE Notify webhooks. Do not trigger for Slack bot development (use slack-bot-builder), general webhook handling (use api-design-patterns), or mobile-first web design (use mobile-first-responsive)."
user-invocable: false
triggers:
  - LINE Botを作りたい
  - LIFFアプリを開発
  - Flex Messageを実装
  - LINE Loginを設定
  - リッチメニューを作る
---

# LINE Bot Development

LINE Messaging API と LIFF を使ったボット・アプリ開発パターン。

## Webhook Handler (Next.js)

```typescript
// app/api/line/route.ts
import { middleware, TextMessage, WebhookRequestBody } from '@line/bot-sdk'

export async function POST(req: Request) {
  const body: WebhookRequestBody = await req.json()
  
  for (const event of body.events) {
    if (event.type === 'message' && event.message.type === 'text') {
      await client.replyMessage(event.replyToken, {
        type: 'text',
        text: `Echo: ${event.message.text}`,
      })
    }
  }
  return Response.json({ ok: true })
}
```

## Flex Message Template

```json
{
  "type": "bubble",
  "hero": { "type": "image", "url": "https://...", "size": "full" },
  "body": {
    "type": "box", "layout": "vertical",
    "contents": [
      { "type": "text", "text": "タイトル", "weight": "bold", "size": "xl" }
    ]
  }
}
```

## Cross-references

- **slack-bot-builder**: Slack Botとの設計比較
- **_supabase-auth-patterns**: LINE LoginとSupabase認証の統合
- **mobile-first-responsive**: LIFF画面のモバイル最適化
