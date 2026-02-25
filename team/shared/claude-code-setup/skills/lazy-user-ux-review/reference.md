# Lazy User UX Review — Reference

## A. 詳細採点基準

各カテゴリの得点帯ごとの具体的な条件。

### 1. First Impression（3秒テスト）

| 得点 | 条件 |
|------|------|
| 1-3 | ページの目的が不明。テキストだらけ or 空白だらけ。CTAが見つからない |
| 4-6 | 目的は何となく分かるが、視覚的階層が弱い。複数の要素が同じ強さで主張 |
| 7-8 | 目的が明確。見出し・ビジュアルが適切。ただし微調整の余地あり |
| 9-10 | 3秒以内に「何のページで何をすべきか」が完全に分かる。ノイズゼロ |

**チェックポイント**:
- `<h1>` が1つだけ存在し、ページの目的を端的に表現しているか
- ファーストビューに不要なバナー・ポップアップ・Cookie同意がかぶっていないか
- 背景とテキストのコントラスト比が十分か（WCAG AA: 4.5:1以上）

### 2. CTA Clarity（メインアクション明確性）

| 得点 | 条件 |
|------|------|
| 1-3 | CTAが見つからない or 複数のCTAが同じ優先度で存在 |
| 4-6 | CTAはあるが、周囲の要素に埋もれている。テキストが曖昧（「こちら」「詳細」） |
| 7-8 | CTAが視覚的に目立つ。テキストがアクション動詞。ただしセカンダリとの差が小さい |
| 9-10 | プライマリCTAが1つだけ圧倒的に目立つ。動詞+結果のテキスト（「無料で始める」） |

**チェックポイント**:
- プライマリCTAに `variant="default"` 相当のスタイル、セカンダリに `variant="outline"` or `variant="ghost"` の差があるか
- CTAテキストが動詞で始まっているか（NG: 「詳細」「こちら」/ OK: 「始める」「登録する」）
- ファーストビュー内にプライマリCTAが配置されているか

### 3. Form Friction（入力の少なさ）

| 得点 | 条件 |
|------|------|
| 1-3 | 5フィールド以上が一画面に表示。必須/任意の区別なし。バリデーションはsubmit後 |
| 4-6 | 4フィールド以下だが、不要な入力がある（確認用メール再入力等）。バリデーション遅延 |
| 7-8 | 3フィールド以下。リアルタイムバリデーション。ただしオートコンプリート未活用 |
| 9-10 | 最小限の入力（1-2フィールド or ソーシャルログイン）。オートコンプリート完備。段階的入力 |

**チェックポイント**:
- `<input>` の `autocomplete` 属性が適切に設定されているか
- `type="email"`, `type="tel"` 等で適切なモバイルキーボードが出るか
- 必須フィールドが `required` + 視覚的マークで区別されているか
- フォームが長い場合、ウィザード形式（ステップ分割）になっているか

### 4. Loading Tolerance（待機時間）

| 得点 | 条件 |
|------|------|
| 1-3 | ローディング表示なし or 真っ白画面。2秒以上何も表示されない |
| 4-6 | スピナーはあるが、何を読み込んでいるか不明。スケルトンなし |
| 7-8 | スケルトンUIで構造が見える。ただし一部のセクションが遅延表示で画面がガタつく |
| 9-10 | Suspense境界が適切。スケルトンでレイアウトシフトなし。楽観的UI更新あり |

**チェックポイント**:
- `loading.tsx` が存在し、Suspense境界が適切に配置されているか
- `useOptimistic` or 楽観的更新パターンが実装されているか
- Cumulative Layout Shift (CLS) を引き起こす遅延コンテンツがないか
- 画像に `width`/`height` or `fill` + `sizes` が設定されているか

### 5. Error Recovery（エラーからの復帰）

| 得点 | 条件 |
|------|------|
| 1-3 | エラー表示なし or 技術的エラーメッセージ（「500 Internal Server Error」）。復帰手段なし |
| 4-6 | エラーは表示されるが、何が間違っているか不明確。「もう一度お試しください」のみ |
| 7-8 | エラー原因が平文で説明。フィールド近くに表示。ただしリトライ/修正の導線が弱い |
| 9-10 | エラー原因+具体的修正方法。フィールドにフォーカス移動。1クリックでリトライ可能 |

**チェックポイント**:
- `error.tsx` boundary が存在し、reset機能があるか
- フォームバリデーションエラーが該当フィールド直下に表示されるか
- Server Actionのエラーがresult objectパターン（`{ error: string }` or `{ data: T }`）で返されるか
- ネットワークエラー時のフォールバック表示があるか

### 6. Navigation Simplicity（迷わなさ）

| 得点 | 条件 |
|------|------|
| 1-3 | ナビゲーションが複雑。3層以上のドロップダウン。現在地が不明 |
| 4-6 | ナビはあるが項目が多すぎる（7個以上）。アクティブ状態の区別が弱い |
| 7-8 | 5項目以下のナビ。アクティブ状態明確。ただしモバイルナビに改善の余地 |
| 9-10 | 主要ナビ3-5項目。アクティブ状態+パンくず。目的地まで2クリック以内 |

**チェックポイント**:
- ナビゲーション項目が7個以下か
- 現在のページが `aria-current="page"` でマークされているか
- モバイルでハンバーガーメニュー内の項目数が適切か
- 「戻る」操作でブラウザ履歴が正しく機能するか

### 7. Mobile Thumb Zone（片手操作）

| 得点 | 条件 |
|------|------|
| 1-3 | 主要操作が画面上部。タップターゲット44px未満。ピンチズーム必須のテキスト |
| 4-6 | タップターゲットは十分だが、主要CTAが画面上部に固定 |
| 7-8 | 主要CTAが下部寄り。タップターゲット48px。ただし一部の操作が到達困難 |
| 9-10 | 主要操作が全てThumb Zone内。ボトムナビ or FAB。スワイプジェスチャー対応 |

**チェックポイント**:
- タップターゲットが最低44px（推奨48px）か
- 主要CTAがモバイルで画面下半分に配置されているか
- `safe-area-inset-*` が適切に設定されているか（ノッチ端末対応）
- 隣接するタップターゲット間のスペースが8px以上か

### 8. Visual Feedback（操作結果の即時性）

| 得点 | 条件 |
|------|------|
| 1-3 | ボタン押下後に何も変化しない。成功/失敗のフィードバックなし |
| 4-6 | ローディング表示はあるが、完了時のフィードバックが弱い。toast通知なし |
| 7-8 | 操作中のローディング+完了のtoast。ただしボタン自体の状態変化が不足 |
| 9-10 | ボタン状態変化（disabled+spinner）→ 成功toast → 楽観的UI更新。全操作に一貫したFBパターン |

**チェックポイント**:
- ボタンに `disabled` + ローディングスピナーの状態があるか
- Server Action / mutation 後に toast 通知が表示されるか
- `useFormStatus` の `pending` を活用しているか
- 削除等の不可逆操作前に確認ダイアログがあるか

### 9. Progressive Disclosure（情報の段階的提示）

| 得点 | 条件 |
|------|------|
| 1-3 | 全情報が一画面にフラットに表示。スクロール量が膨大 |
| 4-6 | セクション分けはあるが折りたたみなし。「もっと見る」がない |
| 7-8 | Accordion/Tab で情報整理。ただし初期表示の情報選定に改善余地 |
| 9-10 | 初期表示は必要最小限。詳細は「もっと見る」「詳細設定」で段階的に。Empty Stateが導線として機能 |

**チェックポイント**:
- 設定画面が「基本」と「詳細」に分かれているか
- テーブルにページネーション or 無限スクロールがあるか
- FAQ/ヘルプがAccordionで折りたたまれているか
- Empty Stateが次のアクションを案内しているか

### 10. Zero-Config Experience（設定なしで使える度）

| 得点 | 条件 |
|------|------|
| 1-3 | 使用前に必須設定が3つ以上。初回セットアップウィザードが長い |
| 4-6 | デフォルト値はあるが、一部の設定が不親切（タイムゾーン手動選択等） |
| 7-8 | スマートデフォルトで即使用可能。ただし一部の高度な機能で設定が必要 |
| 9-10 | 設定ゼロで全機能利用可能。必要な情報は使用中に段階的に収集。環境自動検出 |

**チェックポイント**:
- 初回利用時に必須の設定項目がいくつあるか
- タイムゾーン・言語・通貨が自動検出されているか
- オンボーディングが「使いながら学ぶ」形式か
- デフォルト値が「最も安全で一般的な選択」になっているか

---

## B. Before/After コード例

### B-1. CTA改善（Next.js App Router + Tailwind v4）

```tsx
// BEFORE: CTAが埋もれている（スコア: 4/10）
export default function Hero() {
  return (
    <section className="p-8">
      <h1 className="text-2xl font-bold">プロジェクト管理ツール</h1>
      <p className="mt-4 text-gray-600">
        チームの生産性を向上させるツールです。
        多機能で使いやすく、導入も簡単です。
      </p>
      <div className="mt-4 flex gap-2">
        <a href="/about" className="rounded bg-blue-500 px-4 py-2 text-white">詳細を見る</a>
        <a href="/pricing" className="rounded bg-blue-500 px-4 py-2 text-white">料金</a>
        <a href="/signup" className="rounded bg-blue-500 px-4 py-2 text-white">登録</a>
      </div>
    </section>
  )
}

// AFTER: プライマリCTAが圧倒的に目立つ（スコア: 9/10）
import Link from 'next/link'
import { Button } from '@/components/ui/button'

export default function Hero() {
  return (
    <section className="mx-auto max-w-2xl px-6 py-16 text-center">
      <h1 className="text-4xl font-bold tracking-tight">
        チームの仕事を、もっとシンプルに
      </h1>
      <p className="mt-4 text-lg text-muted-foreground">
        3人から300人まで。設定不要で今すぐ始められます。
      </p>
      <div className="mt-8 flex flex-col items-center gap-3 sm:flex-row sm:justify-center">
        <Button size="lg" asChild>
          <Link href="/signup">無料で始める</Link>
        </Button>
        <Button variant="outline" size="lg" asChild>
          <Link href="/demo">デモを見る</Link>
        </Button>
      </div>
    </section>
  )
}
```

### B-2. フォーム簡略化

```tsx
// BEFORE: フィールド多すぎ（スコア: 3/10）
export default function SignupForm() {
  return (
    <form className="space-y-4">
      <input type="text" placeholder="姓" required />
      <input type="text" placeholder="名" required />
      <input type="email" placeholder="メールアドレス" required />
      <input type="email" placeholder="メールアドレス（確認）" required />
      <input type="password" placeholder="パスワード" required />
      <input type="password" placeholder="パスワード（確認）" required />
      <input type="tel" placeholder="電話番号" />
      <input type="text" placeholder="会社名" />
      <button type="submit">登録</button>
    </form>
  )
}

// AFTER: 最小限の入力（スコア: 9/10）
'use client'

import { useActionState } from 'react'
import { signup } from '@/app/actions/auth'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'

export default function SignupForm() {
  const [state, action, pending] = useActionState(signup, null)

  return (
    <form action={action} className="mx-auto max-w-sm space-y-4">
      <div className="space-y-2">
        <Label htmlFor="email">メールアドレス</Label>
        <Input
          id="email"
          name="email"
          type="email"
          autoComplete="email"
          required
          aria-describedby={state?.error ? 'email-error' : undefined}
        />
        {state?.error && (
          <p id="email-error" className="text-sm text-destructive">{state.error}</p>
        )}
      </div>
      <Button type="submit" className="w-full" disabled={pending}>
        {pending ? '送信中...' : 'メールで登録する'}
      </Button>
      <div className="relative my-4">
        <div className="absolute inset-0 flex items-center">
          <span className="w-full border-t" />
        </div>
        <div className="relative flex justify-center text-xs uppercase">
          <span className="bg-background px-2 text-muted-foreground">または</span>
        </div>
      </div>
      <Button variant="outline" className="w-full" type="button">
        Googleで続ける
      </Button>
    </form>
  )
}
```

### B-3. ローディング改善

```tsx
// BEFORE: 真っ白画面（スコア: 2/10）
// app/dashboard/page.tsx
export default async function Dashboard() {
  const data = await fetchDashboardData() // 3秒かかる
  return <DashboardContent data={data} />
}

// AFTER: Suspense + スケルトン（スコア: 9/10）
// app/dashboard/page.tsx
import { Suspense } from 'react'
import { DashboardSkeleton } from '@/components/skeletons'

export default function Dashboard() {
  return (
    <div className="space-y-6 p-6">
      <h1 className="text-2xl font-bold">ダッシュボード</h1>
      <Suspense fallback={<DashboardSkeleton />}>
        <DashboardContent />
      </Suspense>
    </div>
  )
}

// components/skeletons.tsx
export function DashboardSkeleton() {
  return (
    <div className="space-y-6">
      {/* KPIカード */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {Array.from({ length: 4 }).map((_, i) => (
          <div key={i} className="h-28 animate-pulse rounded-lg bg-muted" />
        ))}
      </div>
      {/* チャート */}
      <div className="h-64 animate-pulse rounded-lg bg-muted" />
      {/* テーブル */}
      <div className="space-y-2">
        {Array.from({ length: 5 }).map((_, i) => (
          <div key={i} className="h-12 animate-pulse rounded bg-muted" />
        ))}
      </div>
    </div>
  )
}
```

### B-4. エラー回復

```tsx
// BEFORE: 技術的エラーメッセージ（スコア: 2/10）
// app/error.tsx
'use client'
export default function Error({ error }: { error: Error }) {
  return <div>Error: {error.message}</div>
}

// AFTER: ユーザーフレンドリーな回復UI（スコア: 9/10）
// app/error.tsx
'use client'

import { useEffect } from 'react'
import { Button } from '@/components/ui/button'

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  useEffect(() => {
    // Sentry等にエラーを送信
    console.error(error)
  }, [error])

  return (
    <div className="flex min-h-[50vh] flex-col items-center justify-center gap-4 px-6 text-center">
      <div className="rounded-full bg-destructive/10 p-4">
        <svg className="h-8 w-8 text-destructive" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
      </div>
      <h2 className="text-xl font-semibold">表示できませんでした</h2>
      <p className="max-w-md text-muted-foreground">
        一時的な問題が発生しました。もう一度お試しいただくか、
        問題が続く場合はサポートまでご連絡ください。
      </p>
      <div className="flex gap-3">
        <Button onClick={reset}>もう一度試す</Button>
        <Button variant="outline" asChild>
          <a href="/">トップに戻る</a>
        </Button>
      </div>
    </div>
  )
}
```

### B-5. ナビゲーション改善

```tsx
// BEFORE: ナビ項目多すぎ（スコア: 4/10）
function Nav() {
  return (
    <nav>
      <a href="/">ホーム</a>
      <a href="/features">機能</a>
      <a href="/pricing">料金</a>
      <a href="/about">会社情報</a>
      <a href="/blog">ブログ</a>
      <a href="/careers">採用</a>
      <a href="/docs">ドキュメント</a>
      <a href="/contact">お問い合わせ</a>
      <a href="/faq">FAQ</a>
      <a href="/terms">利用規約</a>
    </nav>
  )
}

// AFTER: 最小限ナビ + フッターに補足（スコア: 9/10）
'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { cn } from '@/lib/utils'

const navItems = [
  { href: '/', label: 'ホーム' },
  { href: '/features', label: '機能' },
  { href: '/pricing', label: '料金' },
  { href: '/docs', label: 'ドキュメント' },
] as const

export function Nav() {
  const pathname = usePathname()

  return (
    <nav className="flex items-center gap-1">
      {navItems.map(({ href, label }) => (
        <Link
          key={href}
          href={href}
          aria-current={pathname === href ? 'page' : undefined}
          className={cn(
            'rounded-md px-3 py-2 text-sm font-medium transition-colors hover:bg-accent',
            pathname === href
              ? 'bg-accent text-accent-foreground'
              : 'text-muted-foreground'
          )}
        >
          {label}
        </Link>
      ))}
    </nav>
  )
}
```

---

## C. 修正テンプレート5種

### C-1. CTA改善テンプレート

```tsx
// 1. プライマリ/セカンダリの視覚的差を明確にする
<Button size="lg" asChild>
  <Link href="/signup">{/* 動詞 + 結果: 「無料で始める」 */}</Link>
</Button>
<Button variant="outline" size="lg" asChild>
  <Link href="/demo">{/* 代替アクション: 「デモを見る」 */}</Link>
</Button>

// 2. CTA周辺のノイズを除去
// - バナー、サイドバーCTA、フローティングボタンを削除/統合
// - CTAの上下に十分な余白（py-8以上）

// 3. CTAテキスト改善チェック
// NG: 「こちら」「詳細」「送信」「次へ」
// OK: 「無料で始める」「デモを見る」「見積もりを取る」「ダウンロードする」
```

### C-2. フォーム簡略化テンプレート

```tsx
// 1. フィールド削減チェック
// - 確認用再入力（メール、パスワード）→ 削除
// - 登録時に不要な情報（電話、住所）→ 後から収集
// - 手動入力 → オートコンプリート or ソーシャルログイン

// 2. input に適切な属性を設定
<Input
  type="email"
  autoComplete="email"       // ブラウザ自動補完
  inputMode="email"          // モバイルキーボード最適化
  required
  aria-invalid={!!error}     // エラー状態
  aria-describedby="email-error"
/>

// 3. 長いフォームはステップ分割
// Step 1: メールアドレスだけ → Step 2: プロフィール → Step 3: 設定
```

### C-3. ローディング改善テンプレート

```tsx
// 1. loading.tsx を追加
// app/[route]/loading.tsx
export default function Loading() {
  return <PageSkeleton />
}

// 2. 個別セクションをSuspenseで包む
<Suspense fallback={<SectionSkeleton />}>
  <AsyncSection />
</Suspense>

// 3. 楽観的UI更新
'use client'
import { useOptimistic } from 'react'

function TodoList({ todos }: { todos: Todo[] }) {
  const [optimisticTodos, addOptimistic] = useOptimistic(
    todos,
    (state, newTodo: Todo) => [...state, newTodo]
  )
  // addOptimistic(newTodo) を Server Action 開始時に呼ぶ
}
```

### C-4. エラー回復テンプレート

```tsx
// 1. Server Action の result object パターン
type ActionResult<T> = { data: T; error?: never } | { data?: never; error: string }

async function createItem(prev: ActionResult<Item> | null, formData: FormData): Promise<ActionResult<Item>> {
  const parsed = schema.safeParse(Object.fromEntries(formData))
  if (!parsed.success) {
    return { error: parsed.error.issues[0].message }
  }
  try {
    const item = await db.items.create(parsed.data)
    return { data: item }
  } catch {
    return { error: '保存に失敗しました。もう一度お試しください。' }
  }
}

// 2. フォームエラーの表示位置
// フィールド直下に表示 + aria-describedby で紐付け
{state?.error && (
  <p id="field-error" role="alert" className="text-sm text-destructive">
    {state.error}
  </p>
)}
```

### C-5. ナビゲーション改善テンプレート

```tsx
// 1. モバイルボトムナビ
const bottomNav = [
  { href: '/', icon: HomeIcon, label: 'ホーム' },
  { href: '/search', icon: SearchIcon, label: '検索' },
  { href: '/notifications', icon: BellIcon, label: '通知' },
  { href: '/profile', icon: UserIcon, label: 'マイページ' },
] as const // 4項目以下

// 2. パンくずリスト
<nav aria-label="パンくず">
  <ol className="flex items-center gap-1.5 text-sm text-muted-foreground">
    <li><Link href="/">ホーム</Link></li>
    <li>/</li>
    <li><Link href="/settings">設定</Link></li>
    <li>/</li>
    <li aria-current="page" className="text-foreground">プロフィール</li>
  </ol>
</nav>
```

---

## D. 画面別チェックリスト

### D-1. ランディングページ (LP)

- [ ] ファーストビューに `<h1>` + 価値提案 + プライマリCTA
- [ ] CTAテキストが動詞+結果（「無料で始める」等）
- [ ] セカンダリCTAとの視覚的差が明確
- [ ] ソーシャルプルーフ（導入実績、レビュー）がファーストビュー近く
- [ ] 料金・プランが明確（隠れた費用なし）
- [ ] モバイルでCTAがThumb Zone内

### D-2. ダッシュボード

- [ ] KPI/サマリーが最上部（スクロール不要）
- [ ] データ更新のローディングがSuspense + スケルトン
- [ ] Empty Stateが次のアクションを案内
- [ ] フィルター/検索がアクセスしやすい位置
- [ ] テーブルにソート・ページネーション
- [ ] 主要アクション（作成、エクスポート）が1クリック

### D-3. フォーム画面

- [ ] フィールド数が3以下（理想は1-2）
- [ ] `autocomplete` 属性が全inputに設定
- [ ] リアルタイムバリデーション（blur時）
- [ ] エラーメッセージがフィールド直下
- [ ] 送信ボタンにローディング状態
- [ ] 成功時のフィードバック（toast or リダイレクト）

### D-4. 設定画面

- [ ] 「基本」と「詳細」の2層構造
- [ ] デフォルト値が適切（変更不要な項目が多い）
- [ ] 保存前にプレビュー or 変更のdiff表示
- [ ] 「デフォルトに戻す」ボタン
- [ ] 変更の即時反映 or 「保存」ボタンの明確な位置

### D-5. 検索結果画面

- [ ] 検索中のローディング表示
- [ ] 0件時に代替案（類似キーワード、人気コンテンツ）
- [ ] フィルター/ソートが上部でアクセス可能
- [ ] 結果のプレビュー情報が十分（クリック前に判断可能）
- [ ] ページネーション or 無限スクロール
- [ ] 検索クエリの保持（戻るで消えない）

---

## E. Lazy User Flow Analysis テンプレート

レビュー時に各画面のフローを分析するためのテンプレート。

```markdown
## Lazy User Flow Analysis: [画面名]

### 画面概要
- 目的: [この画面でユーザーが達成したいこと]
- 主要ファイル: [app/xxx/page.tsx, components/xxx.tsx]

### 4ステップ評価

#### Step 1: 発見（3秒テスト）
- ページの目的: [即座に分かる / 曖昧 / 不明]
- 視覚的ノイズ: [なし / 軽度 / 重度]
- 具体的問題: [あれば記述]

#### Step 2: 理解（10秒テスト）
- 次のアクション: [明確 / やや曖昧 / 不明]
- 説明文依存度: [低 / 中 / 高（ラベルだけで理解不可）]
- 具体的問題: [あれば記述]

#### Step 3: 操作（タスク完了テスト）
- 目的達成までのクリック数: [X回]
- フォーム入力フィールド数: [X個]
- エラー時の復帰難易度: [簡単 / 普通 / 困難]
- 具体的問題: [あれば記述]

#### Step 4: 完了（満足テスト）
- 完了フィードバック: [あり / なし]
- 次のアクション案内: [あり / なし]
- 「戻る/やり直す」: [可能 / 不可能]
- 具体的問題: [あれば記述]

### スコアリング

| # | カテゴリ | スコア | 根拠 |
|---|---------|--------|------|
| 1 | First Impression | /10 | |
| 2 | CTA Clarity | /10 | |
| 3 | Form Friction | /10 | |
| 4 | Loading Tolerance | /10 | |
| 5 | Error Recovery | /10 | |
| 6 | Navigation Simplicity | /10 | |
| 7 | Mobile Thumb Zone | /10 | |
| 8 | Visual Feedback | /10 | |
| 9 | Progressive Disclosure | /10 | |
| 10 | Zero-Config Experience | /10 | |
| | **合計** | **/100** | |

### TOP修正提案
1. [最も効果的な修正]
2. [次に効果的な修正]
3. [3番目の修正]

### Quick Wins
- [ ] [5分以内で修正可能な改善1]
- [ ] [5分以内で修正可能な改善2]
- [ ] [5分以内で修正可能な改善3]
```
