# Code Review — Reference

SKILL.md 補足: Multi-pass 詳細、アンチパターン集、レビューコメント例、Audit テンプレート、Technical Debt スコアリング。概要・判断フローは [SKILL.md](SKILL.md) を参照。

## 目次

1. [Multi-Pass Review チェックシート](#multi-pass-review-チェックシート)
2. [Review Output テンプレート](#review-output-テンプレート)
3. [React/Next.js アンチパターン](#reactnextjs-アンチパターン)
4. [TypeScript アンチパターン](#typescript-アンチパターン)
5. [Performance アンチパターン](#performance-アンチパターン)
6. [Security アンチパターン](#security-アンチパターン)
7. [レビューコメント例（Good vs Bad）](#レビューコメント例good-vs-bad)
8. [PR サイズ・Git Diff 分析](#pr-サイズgit-diff-分析)
9. [Technical Debt スコアリング](#technical-debt-スコアリング)
10. [Audit Report テンプレート](#audit-report-テンプレート)
11. [Team Review Standards テンプレート](#team-review-standards-テンプレート)
12. [建設的フィードバックテンプレート](#建設的フィードバックテンプレート)
13. [Before/After 集（よくある指摘）](#beforeafter-集よくある指摘)

---

## Multi-Pass Review チェックシート

### Pass 1: Architecture & Design

```markdown
- [ ] PR の目的は明確か（タイトル・説明と一致）
- [ ] 変更ファイル一覧を俯瞰（関係ないファイルが混じっていないか）
- [ ] 責務分離: 1ファイル = 1責務か
- [ ] レイヤー違反: UI → ビジネスロジック → データアクセスの方向性
- [ ] 既存パターンとの一貫性
- [ ] API 設計: エンドポイント命名、レスポンス形式、後方互換性
- [ ] 状態管理: サーバー状態 vs クライアント状態の分離
- [ ] ファイル配置: ディレクトリ規約に沿っているか
```

**判断ポイント:** 目的が複数 → 分割提案 / features/ に収めるべきロジックが app/ にないか / 新パターン導入 → 理由確認

### Pass 2: Logic & Correctness

```markdown
- [ ] 条件分岐: else / default の考慮
- [ ] 境界値: null, undefined, 0, 空配列, 空文字
- [ ] 非同期: await 漏れ, エラー伝播, 競合状態
- [ ] 型安全: any 不使用, 適切な型ガード
- [ ] 不変性: 意図しないミューテーション
- [ ] ループ: off-by-one, 無限ループリスク
- [ ] 早期リターン: ネストが深くなっていないか
- [ ] エラー: try-catch の範囲, 握りつぶし
```

**よくある見落とし:**

```typescript
// 1. Optional chaining の後の undefined 考慮漏れ
const name = user?.profile?.name // 後続で undefined を考慮しているか？

// 2. Array.find の結果チェック漏れ
const item = items.find(i => i.id === id)
item.name // TypeError: Cannot read property 'name' of undefined

// 3. async/await の漏れ → エラー捕捉不能
function handleSubmit() { saveData(formData) } // await がない

// 4. Promise.all vs Promise.allSettled
await Promise.all([apiA(), apiB()])       // 1つ失敗で全部失敗
await Promise.allSettled([apiA(), apiB()]) // 個別に結果を確認
```

### Pass 3: Security & Performance

```markdown
### Security
- [ ] 入力バリデーション（サーバーサイド Zod スキーマ）
- [ ] 認証・認可チェック（middleware or Route Handler）
- [ ] XSS: dangerouslySetInnerHTML, ユーザー入力の直接表示
- [ ] 機密情報: クライアント露出, console.log, エラーメッセージ
- [ ] SQL/NoSQL インジェクション: Prepared Statements / ORM

### Performance
- [ ] N+1 クエリ（ループ内の DB/API 呼び出し）
- [ ] 再レンダリング最適化（memo, useMemo, useCallback）
- [ ] バンドルサイズ（dynamic import, tree-shaking）
- [ ] キャッシュ（ISR, SWR staleTime, revalidate）
- [ ] データフェッチ（Server Component で取得しているか）
```

### Pass 4: Style & Maintainability

```markdown
- [ ] 命名: 意図を伝えているか
- [ ] 関数長: 30行超は分割候補
- [ ] コメント: Why を書いているか（What の繰り返し不要）
- [ ] テスト: 新機能にテストがあるか
- [ ] import: 未使用なし, 順序が規約通り
- [ ] マジックナンバー: 定数化されているか
- [ ] DRY: 同じロジックの重複がないか
```

---

## Review Output テンプレート

```markdown
# Code Review: {PR タイトル or ファイル名}
Date: {YYYY-MM-DD} | PR: #{number} ({branch})
Files: {n} | Lines: +{additions} / -{deletions}

## Summary
{全体の評価を1-2文}

## Positive Feedback
- {良い点1 + ファイル名}
- {良い点2}

## Findings

### 🔴 Critical ({n}件)
#### CR-001: {タイトル}
**File:** `path/to/file.ts:42` | **Pass:** {パス名}
**Description:** {問題の説明 + なぜ問題か}
**Impact:** {修正しない場合の影響}
**Suggestion:**
// Before
{問題のあるコード}
// After
{修正案}

### 🟡 Major ({n}件)
{同形式}

### 🔵 Minor ({n}件)
{同形式}

### 💭 Questions ({n}件)
#### Q-001: {質問タイトル}
**File:** `path/to/file.ts:42`
{質問内容}

## Statistics
| Severity | Count |
|----------|-------|
| 🔴 Critical | {n} |
| 🟡 Major | {n} |
| 🔵 Minor | {n} |
| 💭 Question | {n} |

## Verdict: {APPROVE / REQUEST_CHANGES / COMMENT}
- APPROVE: 🔴 = 0, 🟡 <= 1
- REQUEST_CHANGES: 🔴 >= 1 or 🟡 >= 3
- COMMENT: 🟡 = 2 or 💭 のみ
```

---

## React/Next.js アンチパターン

### useEffect の誤用 [CRITICAL]

```typescript
// ANTI-PATTERN: 派生状態を useEffect で計算
const [filteredItems, setFilteredItems] = useState<Item[]>([])
useEffect(() => { setFilteredItems(items.filter(i => i.active)) }, [items])

// CORRECT: useMemo or 直接計算
const filteredItems = useMemo(() => items.filter(i => i.active), [items])
// 計算が軽い場合はメモ化不要
const filteredItems = items.filter(i => i.active)
```

### Prop Drilling [MAJOR]

```typescript
// ANTI-PATTERN: 3層以上のバケツリレー
<Page user={user}><Sidebar user={user}><UserMenu user={user} /></Sidebar></Page>

// CORRECT: Composition（推奨）or Context
<Page>
  <Sidebar>
    <UserMenu><Avatar src={user.avatar} name={user.name} /></UserMenu>
  </Sidebar>
</Page>
```

### Client/Server 境界の混乱 [CRITICAL]

```typescript
// ANTI-PATTERN: 不要な "use client" でサーバーの利点を失う
'use client'
export default function Page() {
  const [data, setData] = useState(null)
  useEffect(() => { fetch('/api/data')... }, [])
}

// CORRECT: Server Component でデータ取得
export default async function Page() {
  const data = await getData()
  return <ClientComponent data={data} />
}
```

### Missing Key / Index as Key [MAJOR]

```typescript
// ANTI-PATTERN: index key（並び替え・削除時にバグ）
{items.map((item, i) => <ListItem key={i} item={item} />)}

// CORRECT: 一意な識別子
{items.map((item) => <ListItem key={item.id} item={item} />)}
```

### fetch の重複 [MAJOR]

```typescript
// ANTI-PATTERN: 複数コンポーネントで同じデータを取得
// Layout.tsx: const user = await getUser(id)
// Page.tsx:   const user = await getUser(id) // 重複

// CORRECT: fetch は自動デダプリケート。fetch 以外は cache() でラップ
import { cache } from 'react'
export const getUser = cache(async (id: string) => {
  return db.user.findUnique({ where: { id } })
})
```

---

## TypeScript アンチパターン

### any の濫用 [CRITICAL]

```typescript
// ANTI-PATTERN
const handleResponse = (data: any) => data.users.map((u: any) => u.name)

// CORRECT: 型定義 or Zod バリデーション
const ResponseSchema = z.object({
  users: z.array(z.object({ name: z.string(), id: z.string() }))
})
const handleResponse = (data: unknown) => {
  const parsed = ResponseSchema.parse(data)
  return parsed.users.map(u => u.name)
}
```

### Discriminated Union の不在 [MAJOR]

```typescript
// ANTI-PATTERN: 不正状態が表現可能
interface State { isLoading: boolean; isError: boolean; data: Data | null; error: Error | null }

// CORRECT: 型レベルで不正状態を排除
type State =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: Data }
  | { status: 'error'; error: Error }
```

### Non-null Assertion / as の濫用 [MAJOR]

```typescript
// ANTI-PATTERN: 根拠のない ! や as
const user = users.find(u => u.id === id)!
const config = JSON.parse(rawConfig) as AppConfig

// CORRECT: 適切なハンドリング or バリデーション
const user = users.find(u => u.id === id)
if (!user) throw new NotFoundError(`User ${id} not found`)

const config = ConfigSchema.parse(JSON.parse(rawConfig))
```

---

## Performance アンチパターン

### 不要な再レンダリング [MAJOR]

```typescript
// ANTI-PATTERN: レンダーごとに新参照
<Child style={{ color: 'red' }} onClick={() => handleClick()} />

// CORRECT: 安定した参照を渡す
const style = { color: 'red' } as const
const handleClick = useCallback(() => { /* ... */ }, [])
// NOTE: React Compiler (19+) が有効なら手動メモ化不要
```

### N+1 クエリ [CRITICAL]

```typescript
// ANTI-PATTERN: ループ内クエリ
const posts = await db.post.findMany()
for (const post of posts) {
  post.author = await db.user.findUnique({ where: { id: post.authorId } })
}

// CORRECT: include で一括取得
const posts = await db.post.findMany({ include: { author: true } })
```

### Missing Dynamic Import [MAJOR]

```typescript
// ANTI-PATTERN: 重いライブラリを静的 import
import { Chart } from 'chart.js'

// CORRECT: 遅延読み込み
const Chart = dynamic(() => import('@/components/Chart'), {
  loading: () => <ChartSkeleton />, ssr: false,
})
```

### useEffect でのデータフェッチ [MAJOR]

```typescript
// ANTI-PATTERN: Client Component で useEffect fetch
'use client'
function UserProfile({ userId }: { userId: string }) {
  const [user, setUser] = useState(null)
  useEffect(() => { fetch(`/api/users/${userId}`).then(r => r.json()).then(setUser) }, [userId])
}

// CORRECT A: Server Component（推奨）
async function UserProfile({ userId }: { userId: string }) {
  const user = await getUser(userId)
  return <div>{user.name}</div>
}

// CORRECT B: SWR（Client で必要な場合）
const { data: user, error, isLoading } = useSWR(`/api/users/${userId}`, fetcher)
```

---

## Security アンチパターン

### XSS ベクター [CRITICAL]

```typescript
// ANTI-PATTERN
<div dangerouslySetInnerHTML={{ __html: userComment }} />

// CORRECT: テキスト表示（最安全）or サニタイズ
<div>{userComment}</div>
// HTML 必要時:
import DOMPurify from 'isomorphic-dompurify'
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(userComment) }} />
```

### 認可チェック漏れ [CRITICAL]

```typescript
// ANTI-PATTERN: 認証・認可なしで取得
export async function GET(req: Request, { params }: { params: { id: string } }) {
  const post = await db.post.findUnique({ where: { id: params.id } })
  return Response.json(post)
}

// CORRECT: 認証 + 所有者チェック
export async function GET(req: Request, { params }: { params: { id: string } }) {
  const session = await getSession()
  if (!session) return Response.json({ error: 'Unauthorized' }, { status: 401 })
  const post = await db.post.findUnique({ where: { id: params.id } })
  if (!post) return Response.json({ error: 'Not found' }, { status: 404 })
  if (post.authorId !== session.user.id) {
    return Response.json({ error: 'Forbidden' }, { status: 403 })
  }
  return Response.json(post)
}
```

### クライアントへの機密情報露出 [CRITICAL]

```typescript
// ANTI-PATTERN: 全フィールド返却
return Response.json(user) // passwordHash 等が漏洩

// CORRECT: select で必要なフィールドのみ
const user = await db.user.findUnique({
  where: { id }, select: { id: true, name: true, avatar: true }
})
```

### Server Action の認証漏れ [MAJOR]

```typescript
// ANTI-PATTERN: 認証なし
'use server'
export async function deletePost(id: string) {
  await db.post.delete({ where: { id } })
}

// CORRECT: 認証 + 認可
'use server'
export async function deletePost(id: string) {
  const session = await getSession()
  if (!session) throw new Error('Unauthorized')
  const post = await db.post.findUnique({ where: { id } })
  if (!post || post.authorId !== session.user.id) throw new Error('Forbidden')
  await db.post.delete({ where: { id } })
  revalidatePath('/posts')
}
```

---

## レビューコメント例（Good vs Bad）

### Bad: 指摘だけ

```
「ここ any 使ってます」「この関数長すぎ」「テストがない」
```

### Good: 問題 + 理由 + 改善案

```markdown
🟡 [should-fix] `any` 型の使用 — `path/to/file.ts:42`

型安全性が失われランタイムエラーの原因に。Zod でバリデーションすると型+ランタイム両方安全。

// Before
const data: any = await res.json()

// After
const data = UserListSchema.parse(await res.json())
```

```markdown
🔵 [nit] `handleClick` → `handleDeletePost` が意図明確。
複数ハンドラがある場合、何をハンドルするかが名前で分かると読みやすい。
```

```markdown
💭 [question] useEffect の依存配列に `userId` がない理由は？
初回のみの意図なら ESLint 抑制コメントがあると混乱しない。
```

### Positive Feedback

```markdown
✅ Server Component でのデータ取得 + 最小限のクライアントデータ受け渡し + error boundary。
特に `getUserSafe` の Result パターンは参考にしたい実装。
```

---

## PR サイズ・Git Diff 分析

### サイズ分類

| 変更行数 | Size | レビュー品質 | アクション |
|---------|------|-----------|----------|
| 1-50 | XS | 高品質 | そのまま |
| 51-200 | S | 高品質 | そのまま |
| 201-400 | M | 注意深く可能 | 可能なら分割 |
| 401-800 | L | 品質低下 | 分割を強く推奨 |
| 800+ | XL | 見落としリスク高 | 分割必須 |

### 分割戦略

- **機能分割**: DB → API → UI → テスト の各 PR
- **レイヤー分割**: 型定義 → ロジック → API Route → UI
- **リファクタ分離**: 振る舞い変更なしの PR → 新機能の PR

### Git Diff の効率的な読み方

```bash
git diff --stat main...HEAD                           # 全体像
git diff --stat main...HEAD | sort -t'|' -k2 -rn     # 変更量順
git diff main...HEAD -- src/features/auth/            # ディレクトリ指定
git diff --diff-filter=A main...HEAD                  # 新規ファイルのみ
git diff --diff-filter=D main...HEAD                  # 削除ファイルのみ
```

**読む順序:** 設定ファイル → 型定義 → テスト → 実装（テストから期待する振る舞いを先に理解）

---

## Technical Debt スコアリング

### Debt Score 計算（各カテゴリ 1-5、合計 6-30）

| カテゴリ | 1 (Low) | 3 (Medium) | 5 (High) |
|---------|---------|-----------|----------|
| Complexity | 関数平均 <5 | 5-15 | >15 |
| Coupling | 低結合 | 一部循環 | 密結合・循環多数 |
| Coverage | >80% | 50-80% | <50% |
| Staleness | 依存最新 | 6ヶ月以内 | 1年超放置 |
| Documentation | 十分 | 部分的 | ほぼなし |
| Type Safety | any=0 | any<10 | any>10 |

### グレード判定

| 合計 | Grade | アクション |
|-----|-------|----------|
| 6-10 | A (Healthy) | 現状維持 |
| 11-18 | B (Manageable) | 計画的リファクタ |
| 19-24 | C (Concerning) | 次スプリント対応 |
| 25-30 | D (Critical) | 即対応計画 |

---

## Audit Report テンプレート

```markdown
# Code Audit Report
Date: {YYYY-MM-DD} | Scope: {対象} | Auditor: Claude Code

## Executive Summary
**Grade: {A/B/C/D}** — {1行サマリー}

## Metrics
| Metric | Value | Benchmark | Status |
|--------|-------|-----------|--------|
| Total Files | | | |
| Avg/Max File Size | | <300/<500 lines | |
| Complexity Hotspots (>10) | | 0 | |
| Test Coverage | | >80% | |
| `any` / `eslint-disable` | | 0 / <5 | |
| TODO/FIXME | | <10 | |

## Hotspots (Top 10)
| # | File | Lines | Complexity | Risk |
|---|------|-------|-----------|------|

## Dependency Analysis
- High Fan-out (>10 imports): {一覧}
- Circular Dependencies: {一覧}

## Technical Debt
| Category | Score (1-5) | Notes |
|----------|------------|-------|
| Complexity / Coupling / Coverage / Staleness / Docs / Types | | |
| **Total** | **{/30}** | **Grade: {X}** |

## Recommendations
1. [HIGH] {最優先}
2. [MEDIUM] {中期}
3. [LOW] {長期}
```

---

## Team Review Standards テンプレート

```markdown
# Code Review Standards

## Purpose
品質担保 + 知識共有。指摘ではなく対話。

## SLA
| PR Size | First Review | Completion |
|---------|-------------|------------|
| S (<100) | Same day | 1 biz day |
| M (100-400) | 1 biz day | 2 biz days |
| L (400+) | Split request | — |

## Author Checklist
- [ ] セルフレビュー完了
- [ ] PR テンプレート記入（Summary, Test Plan）
- [ ] CI パス確認
- [ ] 400行以下（超える場合は分割理由を説明）

## Reviewer Checklist
- [ ] SLA 内にレビュー開始
- [ ] 4-pass review 実施、severity 明記
- [ ] 改善案を提示 + 良い点にも言及
- [ ] APPROVE / REQUEST_CHANGES を明確に

## Etiquette
- 「コード」を批評。「人」を批評しない
- 提案は「〜はどうですか？」の形で
- nit は nit と明記（修正を強制しない）

## Merge Criteria
🔴 = 0, 🟡 <= 1, CI 全パス, Approval 1名以上
```

---

## 建設的フィードバックテンプレート

**Critical:**
```
🔴 [must-fix] {要約}
{なぜ Critical か} | 影響: {修正しない場合}
// Before → // After
```

**Major:**
```
🟡 [should-fix] {要約}
{理由} | // Before → // After
※ 別アプローチがあれば教えてください
```

**Minor:** `🔵 [nit] {提案} — {理由}`

**Question:** `💭 [question] {質問} — {背景}`

**Positive:** `✅ {何が良いか} — {チームにとっての価値}`

---

## Before/After 集（よくある指摘）

### エラー握りつぶし → 適切な処理

```typescript
// Before
try { await saveData(data) } catch (e) { /* 何もしない */ }

// After
try { await saveData(data) } catch (error) {
  console.error('Failed to save data:', error)
  toast.error('保存に失敗しました。もう一度お試しください。')
}
```

### 深いネスト → 早期リターン

```typescript
// Before
function getDiscount(user: User) {
  if (user) { if (user.isPremium) { if (user.years > 5) { return 0.3 } else { return 0.2 } } else { return 0.1 } } else { return 0 }
}
// After
function getDiscount(user: User | null) {
  if (!user) return 0
  if (!user.isPremium) return 0.1
  return user.years > 5 ? 0.3 : 0.2
}
```

### マジックナンバー → 定数化

```typescript
// Before
if (password.length < 8) { ... }
// After
const MIN_PASSWORD_LENGTH = 8
if (password.length < MIN_PASSWORD_LENGTH) { ... }
```

### 直列 → 並列実行

```typescript
// Before: 直列（遅い）
const user = await getUser(id)
const posts = await getPosts(id)
const comments = await getComments(id)

// After: 並列（独立クエリ）
const [user, posts, comments] = await Promise.all([
  getUser(id), getPosts(id), getComments(id),
])
```

### コンポーネント肥大化 → 責務分離

```typescript
// Before: 認証+フェッチ+バリデーション+表示が1コンポーネント
function UserDashboard() { /* 140行 */ }

// After: 責務を分離
async function UserDashboard() {
  const session = await requireAuth()
  const data = await getDashboardData(session)
  return <DashboardView data={data} />
}
```

### Server Action の throw → Result パターン

```typescript
// Before
'use server'
export async function createPost(data: FormData) {
  const title = data.get('title')
  if (!title) throw new Error('Title required')
  await db.post.create({ data: { title: String(title) } })
}

// After: 型安全な Result パターン
'use server'
export async function createPost(data: FormData): Promise<ActionResult<Post>> {
  const parsed = CreatePostSchema.safeParse(Object.fromEntries(data))
  if (!parsed.success) {
    return { success: false, error: parsed.error.flatten().fieldErrors }
  }
  try {
    const post = await db.post.create({ data: parsed.data })
    revalidatePath('/posts')
    return { success: true, data: post }
  } catch {
    return { success: false, error: { _form: ['投稿の作成に失敗しました'] } }
  }
}
```
