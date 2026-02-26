---
name: code-refactoring
description: "Simplify and refactor code while preserving behavior. Extract Method, DRY, SOLID, Replace Conditional with Strategy, Parameter Object. Use when simplifying complex functions, removing duplication, applying design patterns, reducing cyclomatic complexity, or cleaning up technical debt."
user-invocable: false
---

# Code Refactoring

コードの振る舞いを保ったまま、構造・可読性・保守性を改善する。

## When to Apply

- 関数が20行を超えた or 責務が2つ以上混在
- 同じロジックが2箇所以上にコピーされている
- if/switch が3分岐以上で拡張が困難
- パラメータが4個以上の関数
- コードレビューで「複雑」「読みにくい」と指摘された
- バグ修正後に根本原因を構造的に除去したい

## When NOT to Apply

- パフォーマンスクリティカルなホットパス（プロファイリング先）
- 動作テストが一切ない状態（テスト作成が先 → testing-strategy）
- リファクタリングと機能追加を同時にやろうとしている
- 「きれいにしたい」だけで具体的な問題がない

## Decision Tree

```
関数が長い？ → Yes → Extract Method (#1)
重複コード？ → Yes → 共通関数抽出 (#2)
if/switch 3分岐+？ → Yes → Strategy Pattern (#3)
パラメータ 4個+？ → Yes → Parameter Object (#4)
クラスに責務混在？ → Yes → SRP分離 (#5)
上記なし → リファクタ不要。触らない
```

---

## Iron Rules [CRITICAL]

1. **テスト先行**: リファクタリング前にテストを確認 or 作成。テストなしのリファクタ禁止
2. **1ステップ1変更**: Extract → commit → Rename → commit。一度に複数の変更をしない
3. **振る舞い保存**: 同じ入力 → 同じ出力 + 同じ副作用。機能変更は別コミット
4. **リファクタ中は機能追加しない**: 混ぜると切り戻し不可能になる

---

## Pattern 1: Extract Method [CRITICAL]

長い関数を意味のある単位に分割する。

```typescript
// BEFORE: 1関数に検証・計算・DB操作が混在
async function processOrder(order: Order) {
  if (!order.items?.length) throw new Error('Order must have items')
  if (!order.customerId) throw new Error('Order must have customer')

  const subtotal = order.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  const tax = subtotal * 0.1
  const shipping = subtotal > 100 ? 0 : 10
  const total = subtotal + tax + shipping

  for (const item of order.items) {
    const product = await db.product.findUnique({ where: { id: item.productId } })
    if (product!.stock < item.quantity) {
      throw new Error(`Insufficient stock for ${product!.name}`)
    }
  }

  return await db.order.create({
    data: { customerId: order.customerId, items: order.items, total, status: 'pending' },
  })
}

// AFTER: 各責務が独立した関数
async function processOrder(order: Order) {
  validateOrder(order)
  const total = calculateTotal(order)
  await checkInventory(order)
  return createOrder(order, total)
}

function validateOrder(order: Order) {
  if (!order.items?.length) throw new Error('Order must have items')
  if (!order.customerId) throw new Error('Order must have customer')
}

function calculateTotal(order: Order): number {
  const subtotal = order.items.reduce((sum, i) => sum + i.price * i.quantity, 0)
  const tax = subtotal * 0.1
  const shipping = subtotal > 100 ? 0 : 10
  return subtotal + tax + shipping
}
```

**判断基準**: コメントで「// 〜〜処理」と区切っていたら、そこがExtract境界。

---

## Pattern 2: Remove Duplication [HIGH]

同じWhere条件・Select・ロジックが2箇所以上にあれば統合。

```typescript
// BEFORE: where条件が重複
async function getActiveUsers() {
  return db.user.findMany({
    where: { status: 'active', deletedAt: null },
    select: { id: true, name: true, email: true },
  })
}
async function getActivePremiumUsers() {
  return db.user.findMany({
    where: { status: 'active', deletedAt: null, plan: 'premium' },
    select: { id: true, name: true, email: true },
  })
}

// AFTER: フィルタをパラメータ化
async function getActiveUsers(filter: Partial<User> = {}) {
  return db.user.findMany({
    where: { status: 'active', deletedAt: null, ...filter },
    select: { id: true, name: true, email: true },
  })
}
// Usage: getActiveUsers() / getActiveUsers({ plan: 'premium' })
```

---

## Pattern 3: Replace Conditional with Strategy [HIGH]

3分岐以上のif/switchを、Strategy PatternまたはMapに置き換える。

```typescript
// BEFORE: if-else chain（新しい支払い方法追加のたびに肥大化）
function processPayment(method: string, amount: number) {
  if (method === 'credit_card') { /* ... */ }
  else if (method === 'paypal') { /* ... */ }
  else if (method === 'bank_transfer') { /* ... */ }
}

// AFTER: Mapベースの Strategy
type PaymentHandler = (amount: number) => Promise<PaymentResult>

const paymentHandlers: Record<string, PaymentHandler> = {
  credit_card: processCreditCard,
  paypal: processPayPal,
  bank_transfer: processBankTransfer,
}

async function processPayment(method: string, amount: number) {
  const handler = paymentHandlers[method]
  if (!handler) throw new Error(`Unknown payment method: ${method}`)
  return handler(amount)
}
```

**TypeScript最適**: discriminated unionとexhaustive switchを使えば型安全に。詳細は typescript-best-practices 参照。

---

## Pattern 4: Introduce Parameter Object [MEDIUM]

パラメータ4個以上 → オブジェクトにグループ化。

```typescript
// BEFORE: 8パラメータ
function createUser(name: string, email: string, age: number, country: string, city: string, postalCode: string, phone: string, plan: string) {}

// AFTER: 意味のあるグループに分割
interface CreateUserParams {
  profile: { name: string; email: string; age: number }
  address: { country: string; city: string; postalCode: string }
  phone: string
  plan: string
}
function createUser(params: CreateUserParams) {}
```

---

## Pattern 5: Single Responsibility [MEDIUM]

1クラス/1関数 = 1つの変更理由。

```typescript
// BEFORE: User が DB保存・メール・レポートを全部持つ
class User {
  save() { /* DB */ }
  sendEmail() { /* Mail */ }
  generateReport() { /* PDF */ }
}

// AFTER: 責務を分離
class User { constructor(public name: string, public email: string) {} }
class UserRepository { save(user: User) {} }
class EmailService { send(to: string, subject: string, body: string) {} }
```

---

## Validation Workflow [HIGH]

リファクタリング後の検証手順:

```bash
# 1. テスト（カバレッジ含む）
pnpm test -- --coverage

# 2. 型チェック
pnpm tsc --noEmit

# 3. Lint
pnpm lint
```

**振る舞い保存チェック**:
- 同じ入力 → 同じ出力か
- 副作用（DB書き込み、API呼び出し）は同じか
- エラーハンドリングは同じか

---

## Refactoring Checklist

```markdown
- [ ] 関数は1つの仕事だけ（SRP）
- [ ] 関数名が振る舞いを説明している
- [ ] 関数は20行以下（目安）
- [ ] パラメータは3個以下
- [ ] 重複コードなし（DRY）
- [ ] if/switchのネストは2段以下
- [ ] マジックナンバーなし（定数化）
- [ ] テストが通っている
```

---

## Cross-references

- **testing-strategy**: リファクタリング前のテスト作成・TDD Red-Green-Refactor
- **typescript-best-practices**: 型安全なリファクタリング・discriminated union・exhaustive switch
- **code-review**: リファクタリング結果のレビュー・品質検証
- **systematic-debugging**: バグ修正後の根本原因除去リファクタリング
- **error-handling-logging**: エラーハンドリングパターンの構造化

## Reference

Behavior Analysisテンプレート、Refactoring Summaryテンプレート、トラブルシューティングは [reference.md](reference.md) 参照。
