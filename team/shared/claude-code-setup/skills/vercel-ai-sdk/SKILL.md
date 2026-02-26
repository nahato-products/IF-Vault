---
name: vercel-ai-sdk
description: "Build AI-powered features with Vercel AI SDK: generateText, streamText, useChat, tool calling, Generative UI, agent loops, structured output with Zod, RAG with Supabase pgvector, middleware guardrails. Use when adding AI chat, streaming responses, building agents, implementing tool use, generating structured data, creating AI-powered UI, or integrating LLMs into Next.js applications."
user-invocable: false
---

# Vercel AI SDK Patterns

Next.js App Router + TypeScript + Supabase で AI 機能を実装するためのパターン集。AI SDK 6 (2026) 対応。

## When to Apply

- AI チャット / ストリーミング応答 / AI アシスタント UI
- ツール呼び出し / エージェントループ / マルチステップ処理
- 構造化データ生成（Zod スキーマ） / Generative UI
- RAG（Supabase pgvector + Embeddings）
- LLM プロバイダ切替（OpenAI / Anthropic / Google）

## When NOT to Apply

- LLM を使わない純粋な CRUD → `nextjs-app-router-patterns`
- チャット UI のコンポーネント設計 → `react-component-patterns`
- Supabase の DB 設計・RLS → `supabase-postgres-best-practices`
- エラーハンドリング全般 → `error-handling-logging`

## Scope & Cross-references

| 領域 | このスキル | 委譲先 |
|------|-----------|--------|
| AI コア API（generate/stream） | ここ | - |
| チャット UI コンポーネント設計 | useChat/useObject | `react-component-patterns` |
| RAG の DB スキーマ（pgvector） | クエリパターン | `supabase-postgres-best-practices` |
| ストリーミング SSR | RSC 統合 | `nextjs-app-router-patterns` |
| AI 応答のエラー処理 | リトライ・フォールバック | `error-handling-logging` |
| AI UX 設計原則 | 実装 | `ux-psychology` |
| 型安全 Zod スキーマ | AI 出力バリデーション | `typescript-best-practices` |

---

## Part 1: セットアップ & プロバイダ [CRITICAL]

```bash
npm install ai @ai-sdk/openai @ai-sdk/anthropic @ai-sdk/google
```

```typescript
// プロバイダ初期化 — 環境変数で API キーを管理
import { openai } from '@ai-sdk/openai'
import { anthropic } from '@ai-sdk/anthropic'
import { google } from '@ai-sdk/google'

// モデル切替はプロバイダ関数を変えるだけ
const model = anthropic('claude-sonnet-4-5-20250929')
// const model = openai('gpt-4o')
// const model = google('gemini-2.0-flash')
```

**環境変数**: `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GOOGLE_GENERATIVE_AI_API_KEY`

**AI SDK 6 の主な変更**: v3 Language Model Spec, `stopWhen`エージェント制御, `needsApproval`ツール承認, `Output.object`/`Output.array`, Middleware安定化, Full MCP Support, DevTools。`streamUI`(AI SDK RSC)は開発停止→ツールベースGenerative UIに移行。

---

## Part 2: テキスト生成 [CRITICAL]

### generateText（非ストリーミング）

Server Action / Route Handler でワンショット生成。

```typescript
import { generateText } from 'ai'
const { text, usage } = await generateText({
  model: anthropic('claude-sonnet-4-5-20250929'),
  system: 'You are a helpful assistant.',
  prompt: userMessage,
})
```

### streamText（ストリーミング）

チャット UI の標準パターン。`toDataStreamResponse()` で Next.js Route Handler に直結。

```typescript
import { streamText } from 'ai'
export async function POST(req: Request) {
  const { messages } = await req.json()
  const result = streamText({
    model: anthropic('claude-sonnet-4-5-20250929'),
    system: 'You are a helpful assistant.',
    messages,
  })
  return result.toDataStreamResponse()
}
```

→ 完全な実装: [reference.md](reference.md) Part A

---

## Part 3: クライアントフック [CRITICAL]

### useChat

チャット UI の状態管理を自動化。`messages`, `input`, `handleSubmit`, `isLoading` を提供。

```typescript
'use client'
import { useChat } from 'ai/react'
export function ChatUI() {
  const { messages, input, handleInputChange, handleSubmit, isLoading } = useChat({
    api: '/api/chat',
  })
  // messages.map → 描画, form → handleSubmit
}
```

### useObject

構造化オブジェクトをストリーミング受信。フォーム自動入力、データ抽出 UI に最適。

```typescript
'use client'
import { useObject } from 'ai/react'
import { expenseSchema } from '@/lib/schemas'
const { object, submit, isLoading } = useObject({
  api: '/api/extract',
  schema: expenseSchema,
})
// object はストリーミング中に部分的に更新される
```

→ 完全な実装: [reference.md](reference.md) Part B

---

## Part 4: ツール呼び出し [HIGH]

LLM がツール（関数）を呼び出し、結果を元に応答を生成。

```typescript
import { streamText, tool } from 'ai'
import { z } from 'zod'

const result = streamText({
  model: anthropic('claude-sonnet-4-5-20250929'),
  messages,
  tools: {
    getWeather: tool({
      description: 'Get weather for a location',
      parameters: z.object({ location: z.string() }),
      execute: async ({ location }) => {
        const data = await fetchWeather(location)
        return { temperature: data.temp, condition: data.condition }
      },
    }),
  },
})
```

クライアント側: `onToolCall`+`addToolResult`。Human-in-the-Loop: `needsApproval: true`（破壊的操作に必須）。

→ 完全な実装: [reference.md](reference.md) Part C

---

## Part 5: エージェントループ [HIGH]

`stopWhen` + `stepCountIs` でマルチステップのエージェント実行を制御。

```typescript
import { streamText, stepCountIs } from 'ai'
const result = streamText({
  model: anthropic('claude-sonnet-4-5-20250929'),
  messages,
  tools: { search, calculate, lookupDB },
  stopWhen: stepCountIs(10), // 最大10ステップ
})
```

**ループフロー**: プロンプト送信 → LLM がテキスト or ツール呼び出しを選択 → ツール実行 → 結果を会話履歴に追加 → 再生成 → `stopWhen` 条件 or テキスト応答で終了

デフォルト上限: 20ステップ。コスト管理のため明示的に `stepCountIs(N)` を設定すること。

---

## Part 6: 構造化データ生成 [HIGH]

Zod スキーマで型安全な AI 出力。AI SDK 6 では `Output.object` / `Output.array` を使用。

```typescript
import { generateText, Output } from 'ai'
import { z } from 'zod'

const { output } = await generateText({
  model: anthropic('claude-sonnet-4-5-20250929'),
  prompt: 'Extract expense info from: "Coffee at Starbucks, $4.50, yesterday"',
  output: Output.object({
    schema: z.object({
      item: z.string(),
      amount: z.number(),
      date: z.string().describe('ISO 8601 format'),
      category: z.enum(['food', 'transport', 'entertainment', 'other']),
    }),
  }),
})
// output は型安全: { item: string, amount: number, ... }
```

**配列出力**: `Output.array({ element: z.object({...}) })` で配列をストリーミング（要素単位で受信）。

**注意**: `generateObject` / `streamObject` は AI SDK 6 で非推奨。`Output.object` / `Output.array` を使用。

→ 完全な実装: [reference.md](reference.md) Part D

---

## Part 7: Generative UI [HIGH]

ツール呼び出しの結果を React コンポーネントとして描画。

`messages.parts` 配列で `tool-${toolName}` 型のパーツを識別し、React コンポーネントで描画。ステータス遷移: `input-available` → `output-available` → `output-error`。`loading` 時は Skeleton 表示。→ [reference.md](reference.md) Part B

---

## Part 8: RAG (Supabase pgvector) [MEDIUM]

### Embedding 生成 & 保存

```typescript
import { embed, embedMany } from 'ai'
import { openai } from '@ai-sdk/openai'

// 単一
const { embedding } = await embed({
  model: openai.embedding('text-embedding-3-small'),
  value: 'テキスト内容',
})
// Supabase に保存
await supabase.from('documents').insert({ content, embedding })

// 複数一括
const { embeddings } = await embedMany({
  model: openai.embedding('text-embedding-3-small'),
  values: chunks,
})
```

検索: pgvector `<=>` 演算子で類似検索。`match_documents` RPC 関数パターン。→ 完全な RAG パイプライン: [reference.md](reference.md) Part E

---

## Part 9: ミドルウェア [MEDIUM]

ガードレール、ログ、キャッシュをプロバイダ非依存で実装。

`wrapLanguageModel()` で `wrapGenerate` / `wrapStream` を実装。複数ミドルウェアは配列で渡し、順序通りに適用。→ [reference.md](reference.md) Part F

---

## Decision Tree

```
テキスト生成 → generateText(ワンショット) / streamText(ストリーミング)
チャット UI → useChat + /api/chat Route Handler
構造化データ → streamText + output: z.object({...})
ツール使用 → tools パラメータ + tool() ヘルパー
エージェント → streamText + tools + stopWhen: stepCountIs(N)
Generative UI → useChat + parts 配列で tool パーツを描画
RAG → embed/embedMany + pgvector + コンテキスト注入
ガードレール → wrapLanguageModel + middleware
```

## Checklist

- [ ] API キーが環境変数で管理されている（ハードコード禁止）
- [ ] `streamText` でストリーミング応答（UX 向上）
- [ ] エージェントに `stopWhen: stepCountIs(N)` を明示設定（コスト制御）
- [ ] ツールの `parameters` に Zod スキーマ（型安全）
- [ ] Generative UI で `loading` / `error` 状態のフォールバック
- [ ] RAG: Embedding モデルとドキュメント分割戦略を決定
- [ ] ミドルウェアでコンテンツフィルタリング（本番環境）
- [ ] `useChat` の `onError` でエラーハンドリング

## Reference

[reference.md](reference.md): Route Handler テンプレート(A) / useChat・useObject 完全実装(B) / ツール定義パターン集(C) / 構造化出力テンプレート(D) / RAG パイプライン(E) / ミドルウェアパターン(F) / プロバイダ切替ガイド(G) / コスト最適化(H)
