# Code Refactoring — Reference

## A. Behavior Analysis テンプレート

リファクタリング前に現在の振る舞いを記録する。

```markdown
## Behavior Analysis: [関数/モジュール名]

### Inputs
- パラメータ: [型と制約]
- 暗黙の依存: [環境変数、グローバル状態]

### Outputs
- 戻り値: [型]
- 副作用: [DB書き込み、API呼び出し、ログ出力]

### Invariants
- [常に成り立つ条件]
- [境界条件: 空配列、null、0]

### Error Cases
- [どの条件でどのエラーが投げられるか]
```

---

## B. Refactoring Summary テンプレート

リファクタリング後にコミットメッセージ or PRに添付する。

```markdown
## Refactoring Summary

### Changes
1. [変更]: [理由]
2. [変更]: [理由]

### Behavior Preserved
- [x] 同一入力 → 同一出力
- [x] 副作用の変化なし
- [x] エラーハンドリング同一

### Test Status
- [x] Unit tests: passing
- [x] Type check: passing
- [x] Lint: passing
```

---

## C. Next.js App Router 特有のリファクタリング

### C-1. Server Component → Client Component 分離

```tsx
// BEFORE: Server Component内にインタラクティブ要素が混在
export default async function ProductPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const product = await getProduct(id)

  // この部分はクライアントで動く必要がある
  const [quantity, setQuantity] = useState(1)

  return (
    <div>
      <h1>{product.name}</h1>
      <p>{product.description}</p>
      <input value={quantity} onChange={(e) => setQuantity(Number(e.target.value))} />
      <button onClick={() => addToCart(product.id, quantity)}>カートに追加</button>
    </div>
  )
}

// AFTER: Server Component（データ取得）+ Client Component（インタラクション）
// app/products/[id]/page.tsx (Server Component)
export default async function ProductPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const product = await getProduct(id)

  return (
    <div>
      <h1>{product.name}</h1>
      <p>{product.description}</p>
      <AddToCartButton productId={product.id} />
    </div>
  )
}

// components/add-to-cart-button.tsx (Client Component)
'use client'

import { useState } from 'react'

export function AddToCartButton({ productId }: { productId: string }) {
  const [quantity, setQuantity] = useState(1)
  return (
    <div className="flex items-center gap-2">
      <input
        type="number"
        min={1}
        value={quantity}
        onChange={(e) => setQuantity(Number(e.target.value))}
        className="w-16 rounded border px-2 py-1"
      />
      <button onClick={() => addToCart(productId, quantity)}>カートに追加</button>
    </div>
  )
}
```

### C-2. Server Action のエラーハンドリング統合

```tsx
// BEFORE: try/catch が各所に散在
async function createItem(formData: FormData) {
  'use server'
  try {
    const name = formData.get('name') as string
    if (!name) throw new Error('Name required')
    const item = await db.item.create({ data: { name } })
    revalidatePath('/items')
    return item
  } catch (e) {
    console.error(e)
    throw e
  }
}

// AFTER: Result Object パターンで統一
type ActionResult<T> =
  | { data: T; error?: never }
  | { data?: never; error: string }

async function createItem(
  _prev: ActionResult<Item> | null,
  formData: FormData
): Promise<ActionResult<Item>> {
  'use server'
  const parsed = itemSchema.safeParse({ name: formData.get('name') })
  if (!parsed.success) return { error: parsed.error.issues[0].message }

  try {
    const item = await db.item.create({ data: parsed.data })
    revalidatePath('/items')
    return { data: item }
  } catch {
    return { error: '作成に失敗しました' }
  }
}
```

---

## D. Supabase クエリのリファクタリング

### D-1. N+1 クエリの解消

```typescript
// BEFORE: N+1（ユーザーごとにクエリ）
async function getOrdersWithUsers(orderIds: string[]) {
  const orders = await supabase.from('orders').select('*').in('id', orderIds)
  for (const order of orders.data!) {
    const { data: user } = await supabase
      .from('users')
      .select('name, email')
      .eq('id', order.user_id)
      .single()
    order.user = user
  }
  return orders.data
}

// AFTER: JOINで1クエリ
async function getOrdersWithUsers(orderIds: string[]) {
  const { data } = await supabase
    .from('orders')
    .select('*, user:users(name, email)')
    .in('id', orderIds)
  return data
}
```

### D-2. RPC関数への移行

```typescript
// BEFORE: 複雑なクライアントサイドロジック
async function getDashboardStats() {
  const { data: orders } = await supabase.from('orders').select('total, created_at')
  const { data: users } = await supabase.from('users').select('id').eq('status', 'active')
  const totalRevenue = orders?.reduce((sum, o) => sum + o.total, 0) ?? 0
  const activeUsers = users?.length ?? 0
  return { totalRevenue, activeUsers }
}

// AFTER: DB側で集計（Supabase RPC）
async function getDashboardStats() {
  const { data } = await supabase.rpc('get_dashboard_stats')
  return data
}
// SQL: CREATE FUNCTION get_dashboard_stats() で集計ロジックをDB側に移動
```

---

## E. トラブルシューティング

| 問題 | 原因 | 対策 |
|------|------|------|
| テストが失敗 | 振る舞いが変わった | 変更を戻して1ステップずつ再試行 |
| まだ複雑 | 1関数に責務が混在 | Extract Methodをさらに適用 |
| パフォーマンス劣化 | 過剰な抽象化 | プロファイリングでホットパス特定 |
| 型エラー | 抽出時にジェネリクスが必要 | typescript-best-practices のユーティリティ型参照 |
| テストがない | レガシーコード | characterization testを先に書く（testing-strategy参照） |

---

## F. リファクタリングの優先度判断

| 条件 | 優先度 | アクション |
|------|--------|----------|
| バグの温床（直近3ヶ月で2回以上バグ） | HIGH | 即リファクタ |
| 今から機能追加する箇所 | HIGH | 追加前にリファクタ |
| 複雑だが安定している | LOW | 触らない（Boy Scout Rule の範囲で） |
| 1箇所しか使われていない | LOW | 問題が出るまで放置 |
