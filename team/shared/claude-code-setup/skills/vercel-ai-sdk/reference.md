# Vercel AI SDK — Reference

## A. Route Handler テンプレート

### A-1. チャット API（streamText）

```typescript
// app/api/chat/route.ts
import { streamText } from 'ai'
import { anthropic } from '@ai-sdk/anthropic'

export async function POST(req: Request) {
  const { messages } = await req.json()

  const result = streamText({
    model: anthropic('claude-sonnet-4-5-20250929'),
    system: `You are a helpful assistant. Today is ${new Date().toISOString().split('T')[0]}.`,
    messages,
    // オプション: ツール, 構造化出力, stopWhen
  })

  return result.toDataStreamResponse()
}
```

### A-2. Server Action でのテキスト生成

```typescript
// app/actions/ai.ts
'use server'
import { generateText } from 'ai'
import { anthropic } from '@ai-sdk/anthropic'

export async function summarize(text: string) {
  const { text: summary } = await generateText({
    model: anthropic('claude-sonnet-4-5-20250929'),
    prompt: `Summarize the following text in 3 bullet points:\n\n${text}`,
  })
  return summary
}
```

### A-3. ストリーミング Server Action（experimental）

```typescript
'use server'
import { streamText } from 'ai'
import { anthropic } from '@ai-sdk/anthropic'
import { createStreamableValue } from 'ai/rsc'

export async function streamAnswer(question: string) {
  const stream = createStreamableValue('')
  ;(async () => {
    const result = streamText({
      model: anthropic('claude-sonnet-4-5-20250929'),
      prompt: question,
    })
    for await (const text of result.textStream) {
      stream.update(text)
    }
    stream.done()
  })()
  return stream.value
}
```

---

## B. クライアントフック完全実装

### B-1. useChat フルテンプレート

```typescript
'use client'
import { useChat } from 'ai/react'
import { useRef, useEffect } from 'react'

export function ChatUI() {
  const {
    messages,
    input,
    handleInputChange,
    handleSubmit,
    isLoading,
    error,
    reload,
    stop,
  } = useChat({
    api: '/api/chat',
    onError: (err) => console.error('Chat error:', err),
    // initialMessages: [], // 会話履歴の復元
  })

  const scrollRef = useRef<HTMLDivElement>(null)
  useEffect(() => {
    scrollRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  return (
    <div className="flex h-dvh flex-col">
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.map((m) => (
          <div
            key={m.id}
            className={m.role === 'user' ? 'ml-auto max-w-[80%]' : 'max-w-[80%]'}
          >
            {m.parts.map((part, i) => {
              if (part.type === 'text') return <p key={i}>{part.text}</p>
              return null
            })}
          </div>
        ))}
        {isLoading && <div className="animate-pulse">thinking...</div>}
        {error && (
          <button onClick={() => reload()} className="text-red-500">
            エラーが発生しました。リトライ
          </button>
        )}
        <div ref={scrollRef} />
      </div>
      <form onSubmit={handleSubmit} className="border-t p-4 flex gap-2">
        <input
          value={input}
          onChange={handleInputChange}
          placeholder="メッセージを入力..."
          className="flex-1 rounded border px-3 py-2"
          disabled={isLoading}
        />
        {isLoading ? (
          <button type="button" onClick={stop}>停止</button>
        ) : (
          <button type="submit">送信</button>
        )}
      </form>
    </div>
  )
}
```

### B-2. useObject テンプレート

```typescript
'use client'
import { useObject } from 'ai/react'
import { z } from 'zod'

const expenseSchema = z.object({
  item: z.string().describe('The expense item'),
  amount: z.number().describe('Amount in USD'),
  date: z.string().describe('Date in YYYY-MM-DD format'),
  category: z.enum(['food', 'transport', 'entertainment', 'other']),
})

export function ExpenseExtractor() {
  const { object, submit, isLoading, error } = useObject({
    api: '/api/extract-expense',
    schema: expenseSchema,
  })

  return (
    <div>
      <textarea
        onBlur={(e) => submit(e.target.value)}
        placeholder="Paste receipt text..."
      />
      {isLoading && <p>Extracting...</p>}
      {object && (
        <dl>
          <dt>Item</dt><dd>{object.item}</dd>
          <dt>Amount</dt><dd>${object.amount}</dd>
          <dt>Date</dt><dd>{object.date}</dd>
          <dt>Category</dt><dd>{object.category}</dd>
        </dl>
      )}
    </div>
  )
}
```

---

## C. ツール定義パターン集

### C-1. 基本ツール

```typescript
import { tool } from 'ai'
import { z } from 'zod'

const tools = {
  getWeather: tool({
    description: 'Get current weather for a location',
    parameters: z.object({
      location: z.string().describe('City name'),
      unit: z.enum(['celsius', 'fahrenheit']).default('celsius'),
    }),
    execute: async ({ location, unit }) => {
      const data = await fetch(`https://api.weather.com/${location}`)
      return { temperature: 22, condition: 'sunny', unit }
    },
  }),
}
```

### C-2. Supabase データ取得ツール

```typescript
const tools = {
  searchProducts: tool({
    description: 'Search products in the database',
    parameters: z.object({
      query: z.string(),
      category: z.string().optional(),
      limit: z.number().default(10),
    }),
    execute: async ({ query, category, limit }) => {
      let q = supabase
        .from('products')
        .select('id, name, price, description')
        .textSearch('name', query)
        .limit(limit)
      if (category) q = q.eq('category', category)
      const { data } = await q
      return data ?? []
    },
  }),
}
```

### C-3. needsApproval（Human-in-the-Loop 承認）

```typescript
const tools = {
  deleteRecord: tool({
    description: 'Delete a record from the database',
    parameters: z.object({
      table: z.string(),
      id: z.string(),
    }),
    execute: async ({ table, id }) => {
      await supabase.from(table).delete().eq('id', id)
      return { deleted: true }
    },
    needsApproval: true, // 全呼び出しで承認要求
  }),
  chargePayment: tool({
    description: 'Process a payment',
    parameters: z.object({
      amount: z.number(),
      currency: z.string(),
    }),
    execute: async ({ amount, currency }) => { /* ... */ },
    // 条件付き承認: 高額のみ
    needsApproval: ({ amount }) => amount > 10000,
  }),
}
```

### C-4. クライアント側ツール（UI 操作）

```typescript
// クライアントで useChat に onToolCall を設定
const { messages, ... } = useChat({
  api: '/api/chat',
  onToolCall: async ({ toolCall }) => {
    if (toolCall.toolName === 'showConfirmation') {
      const confirmed = window.confirm(toolCall.args.message)
      return confirmed ? 'User confirmed' : 'User cancelled'
    }
  },
})
```

### C-5. addToolResult（ユーザー入力を返す）

```typescript
const { messages, addToolResult } = useChat({ api: '/api/chat' })

// ツールがユーザー入力を要求する場合
function handleUserSelection(toolCallId: string, selection: string) {
  addToolResult({ toolCallId, result: selection })
}
```

---

## D. 構造化出力テンプレート

### D-1. Output.object（ストリーミング）

```typescript
// app/api/extract/route.ts
import { streamText, Output } from 'ai'
import { anthropic } from '@ai-sdk/anthropic'
import { z } from 'zod'

export async function POST(req: Request) {
  const { text } = await req.json()

  const result = streamText({
    model: anthropic('claude-sonnet-4-5-20250929'),
    prompt: `Extract structured data from: ${text}`,
    output: Output.object({
      schema: z.object({
        title: z.string(),
        summary: z.string(),
        tags: z.array(z.string()),
        sentiment: z.enum(['positive', 'neutral', 'negative']),
        confidence: z.number().min(0).max(1),
      }),
    }),
  })

  return result.toDataStreamResponse()
}
```

### D-2. Output.object（非ストリーミング）

```typescript
import { generateText, Output } from 'ai'

const { output } = await generateText({
  model: anthropic('claude-sonnet-4-5-20250929'),
  prompt: `Classify this support ticket: ${ticket}`,
  output: Output.object({
    schema: z.object({
      priority: z.enum(['low', 'medium', 'high', 'critical']),
      category: z.string(),
      suggestedAction: z.string(),
    }),
  }),
})
// output は型安全: { priority: 'high', category: '...', suggestedAction: '...' }
```

### D-3. Output.array（配列ストリーミング）

```typescript
const { output } = await generateText({
  model: anthropic('claude-sonnet-4-5-20250929'),
  prompt: 'Generate 5 blog post ideas about AI',
  output: Output.array({
    element: z.object({
      title: z.string(),
      summary: z.string(),
      tags: z.array(z.string()),
    }),
  }),
})
// output: Array<{ title, summary, tags }> — 要素単位でストリーミング
```

---

## E. RAG パイプライン（Supabase pgvector）

### E-1. DB セットアップ

```sql
-- pgvector 拡張を有効化
create extension if not exists vector;

-- ドキュメントテーブル
create table documents (
  id bigserial primary key,
  content text not null,
  metadata jsonb default '{}',
  embedding vector(1536), -- text-embedding-3-small の次元数
  created_at timestamptz default now()
);

-- インデックス（cosine距離）
create index on documents using ivfflat (embedding vector_cosine_ops)
  with (lists = 100);

-- 類似検索関数
create or replace function match_documents(
  query_embedding vector(1536),
  match_count int default 5,
  filter jsonb default '{}'
)
returns table (id bigint, content text, metadata jsonb, similarity float)
language plpgsql as $$
begin
  return query
  select d.id, d.content, d.metadata,
    1 - (d.embedding <=> query_embedding) as similarity
  from documents d
  where d.metadata @> filter
  order by d.embedding <=> query_embedding
  limit match_count;
end;
$$;
```

### E-2. Embedding 生成 & 保存

```typescript
import { embedMany } from 'ai'
import { openai } from '@ai-sdk/openai'
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
)

async function indexDocuments(chunks: { content: string; metadata: object }[]) {
  const { embeddings } = await embedMany({
    model: openai.embedding('text-embedding-3-small'),
    values: chunks.map((c) => c.content),
  })

  const rows = chunks.map((chunk, i) => ({
    content: chunk.content,
    metadata: chunk.metadata,
    embedding: embeddings[i],
  }))

  const { error } = await supabase.from('documents').insert(rows)
  if (error) throw error
}
```

### E-3. RAG チャット Route Handler

```typescript
// app/api/chat/route.ts
import { streamText } from 'ai'
import { anthropic } from '@ai-sdk/anthropic'
import { embed } from 'ai'
import { openai } from '@ai-sdk/openai'

export async function POST(req: Request) {
  const { messages } = await req.json()
  const lastMessage = messages[messages.length - 1].content

  // 1. クエリの Embedding 生成
  const { embedding } = await embed({
    model: openai.embedding('text-embedding-3-small'),
    value: lastMessage,
  })

  // 2. 類似ドキュメント検索
  const { data: docs } = await supabase.rpc('match_documents', {
    query_embedding: embedding,
    match_count: 5,
  })

  // 3. コンテキスト注入してストリーミング生成
  const context = docs?.map((d) => d.content).join('\n\n') ?? ''

  const result = streamText({
    model: anthropic('claude-sonnet-4-5-20250929'),
    system: `Answer based on the following context. If the context doesn't contain relevant information, say so.\n\nContext:\n${context}`,
    messages,
  })

  return result.toDataStreamResponse()
}
```

---

## F. ミドルウェアパターン

### F-1. ロギングミドルウェア

```typescript
import { wrapLanguageModel } from 'ai'

const loggingMiddleware = {
  wrapGenerate: async ({ doGenerate, params }) => {
    const start = Date.now()
    const result = await doGenerate()
    console.log({
      model: params.model,
      duration: Date.now() - start,
      inputTokens: result.usage?.promptTokens,
      outputTokens: result.usage?.completionTokens,
    })
    return result
  },
}

const model = wrapLanguageModel({
  model: anthropic('claude-sonnet-4-5-20250929'),
  middleware: loggingMiddleware,
})
```

### F-2. コンテンツフィルタリング（ガードレール）

```typescript
const safetyMiddleware = {
  wrapGenerate: async ({ doGenerate }) => {
    const result = await doGenerate()
    if (containsPII(result.text)) {
      return { ...result, text: '[Content filtered for safety]' }
    }
    return result
  },
}
```

### F-3. キャッシュミドルウェア

```typescript
const cacheMiddleware = {
  wrapGenerate: async ({ doGenerate, params }) => {
    const key = createHash(JSON.stringify(params))
    const cached = await redis.get(key)
    if (cached) return JSON.parse(cached)
    const result = await doGenerate()
    await redis.setex(key, 3600, JSON.stringify(result))
    return result
  },
}
```

### F-4. 複数ミドルウェアの合成

```typescript
const model = wrapLanguageModel({
  model: anthropic('claude-sonnet-4-5-20250929'),
  middleware: [loggingMiddleware, safetyMiddleware, cacheMiddleware],
})
```

---

## G. プロバイダ切替ガイド

| プロバイダ | パッケージ | 推奨モデル | 特徴 |
|-----------|-----------|-----------|------|
| Anthropic | `@ai-sdk/anthropic` | claude-sonnet-4-5 | 長文コンテキスト、ツール使用に強い |
| OpenAI | `@ai-sdk/openai` | gpt-4o | 汎用、画像理解 |
| Google | `@ai-sdk/google` | gemini-2.0-flash | 高速、コスパ良 |

**Embedding モデル**: `openai.embedding('text-embedding-3-small')` が標準。低コスト・高品質。

**プロバイダ抽象化**: 環境変数でモデルを切替可能に。

```typescript
function getModel() {
  const provider = process.env.AI_PROVIDER ?? 'anthropic'
  switch (provider) {
    case 'openai': return openai(process.env.AI_MODEL ?? 'gpt-4o')
    case 'google': return google(process.env.AI_MODEL ?? 'gemini-2.0-flash')
    default: return anthropic(process.env.AI_MODEL ?? 'claude-sonnet-4-5-20250929')
  }
}
```

---

## H. Provider Registry & Custom Provider

### H-1. Provider Registry（本番向け）

```typescript
import { createProviderRegistry } from 'ai'
import { openai } from '@ai-sdk/openai'
import { anthropic } from '@ai-sdk/anthropic'
import { google } from '@ai-sdk/google'

const registry = createProviderRegistry({ openai, anthropic, google })

// 文字列 ID でモデル取得
const model = registry.languageModel('anthropic:claude-sonnet-4-5-20250929')
```

### H-2. Custom Provider（モデルエイリアス）

```typescript
import { customProvider } from 'ai'

const ai = customProvider({
  languageModels: {
    fast: openai('gpt-4o-mini'),
    smart: anthropic('claude-opus-4-5-20250414'),
    balanced: anthropic('claude-sonnet-4-5-20250929'),
  },
  embeddingModels: {
    default: openai.embedding('text-embedding-3-small'),
  },
})
// 使用: ai.languageModel('fast'), ai.embeddingModel('default')
```

### H-3. Vercel AI Gateway

```typescript
import { gateway } from '@ai-sdk/vercel'
// 一元管理: バジェット、負荷分散、フォールバック自動処理
const model = gateway('anthropic:claude-sonnet-4-5-20250929')
```

---

## I. コスト最適化

| 戦略 | 効果 | 実装 |
|------|------|------|
| キャッシュ | 同一クエリのコスト削減 | ミドルウェア F-3 |
| モデル使い分け | 簡単タスクに安価モデル | `gemini-2.0-flash` for classification |
| ストリーミング | UX 向上（コスト同等） | `streamText` |
| `stepCountIs` 制限 | エージェント暴走防止 | 明示的に上限設定 |
| Embedding バッチ | API 呼び出し削減 | `embedMany` |
| 短い system プロンプト | 入力トークン削減 | 簡潔な指示 |
