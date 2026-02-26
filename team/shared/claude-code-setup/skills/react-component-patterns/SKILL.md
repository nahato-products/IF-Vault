---
name: react-component-patterns
description: "React compound components, asChild/Slot, CVA variants, SC/CC boundary, Hook Form + Zod, error boundaries, ARIA/focus"
user-invocable: false
---

# React Component Design Patterns

Next.js App Router + Shadcn/ui + Radix UI + Tailwind CSS + TypeScript 環境でのコンポーネント設計パターン集。

## When to Apply

- コンポーネントの設計・実装・リファクタリング・レビュー
- コンポーネントAPI設計（props、合成パターン、バリアント）
- Server Component / Client Component の境界設計
- フォームコンポーネントの構築（バリデーション、マルチステップ）
- エラーバウンダリとフォールバックUI
- コンポーネントレベルのアクセシビリティ実装

## 他スキルとの棲み分け

| スキル | このスキルの役割 | そのスキルの役割 |
|--------|----------------|----------------|
| nextjs-app-router-patterns | SC/CC境界の**コンポーネント設計** | ルーティング・データフェッチ・キャッシュ |
| vercel-react-best-practices | 合成パターン・CVA・フォーム設計 | ランタイム**パフォーマンス**最適化 |
| micro-interaction-patterns | error.tsx/useOptimisticの**コンポーネント構造** | ローディング/トースト等の**UXフィードバック実装** |
| tailwind-design-system | CVAバリアント・cn()の使い方 | Tailwind v4設定・トークンユーティリティ |
| design-token-system | バリアントでトークンを消費 | トークン定義・管理・配布 |
| typescript-best-practices | コンポーネントpropsの型設計 | 汎用TypeScriptパターン |
| web-design-guidelines | コンポーネントのARIA・フォーカス実装 | フレームワーク非依存のWCAG準拠 |
| error-handling-logging | error.tsxの**コンポーネント設計** | エラー分類・ロギング・Sentry連携 |
| testing-strategy | コンポーネント設計のテスタビリティ | テスト戦略・実行 |
| ux-psychology | a11y実装の「どうやるか」 | 認知心理学の「なぜそうすべきか」 |

**このスキルの焦点**: Reactコンポーネントの**内部設計**——合成パターン、props API、バリアント、フォーム構成、状態管理選択、a11y実装。アニメーション/UXフィードバック、ルーティング、パフォーマンス、汎用型設計は他スキルに委譲。

---

## Part 1: コンポーネント合成パターン [CRITICAL]

### 1. Compound Components

関連するコンポーネント群がContextを通じて暗黙的に状態を共有する。Tabs, Select, Accordion等に最適。

```tsx
// Context + useAccordion + Accordion本体 → reference.md「Compound Components 完全例」
// 使用: <Accordion><Accordion.Item id="1">...</Accordion.Item></Accordion>
```

**判断**: props drillingが3階層超、または子の順序・構成をユーザーに委ねたい場合に採用。

### 2. Slot / asChild パターン（Radix方式）

レンダリング要素を消費者が差し替え可能にする。Radix UI / Shadcn/uiの中核パターン。

```tsx
// BAD: const Comp = as ?? "button"; // TS推論が重い
// GOOD: const Comp = asChild ? Slot : "button"; // Radix/Shadcn標準
```

**仕組み**: `asChild=true`でSlotが子要素をcloneし、親のprops・ref・イベントハンドラをマージ注入。デフォルト要素は描画しない。

### 3. Ref の扱い（React 19）

React 19で`forwardRef`は不要。`ref`を通常のpropとして受け取る。

```tsx
// React 19: refは通常のprop
function Input({ className, ref, ...props }: InputProps & { ref?: React.Ref<HTMLInputElement> }) {
  return <input ref={ref} className={cn("border rounded px-3 py-2", className)} {...props} />;
}
```

### 4. Polymorphic Components

同一コンポーネントを異なるHTML要素でレンダリング。プリミティブ要素の切替に限定。

```tsx
type PolymorphicProps<T extends React.ElementType> = { as?: T; children?: React.ReactNode } & Omit<React.ComponentPropsWithoutRef<T>, "as">;
function Text<T extends React.ElementType = "p">({ as, children, ...props }: PolymorphicProps<T>) {
  const Comp = as || "p";
  return <Comp {...props}>{children}</Comp>;
}
```

**注意**: TS推論が重い。div/span/p/h1-h6の切替に限定。コンポーネント間の切替には`asChild`を使う。

---

## Part 2: Server / Client Component 境界 [CRITICAL]

### 5. 境界設計の原則

**Server Component (SC) がデフォルト**。`"use client"`は必要最小限だけ。

| CCにする条件 | 例 |
|---|---|
| useState / useReducer / useEffect | フォーム、トグル |
| ブラウザAPI | localStorage, IntersectionObserver |
| イベントハンドラ (onClick等) | ボタン、入力 |

### 6. SC -> CC パターン（基本）

データ取得はSC、インタラクションはCC。シリアライズ可能なデータだけをpropsで渡す。

```tsx
// SC: const data = await db.metrics.findMany();
// SC -> CC: <InteractiveChart data={data} />  // シリアライズ可能なpropsのみ
```

### 7. CC children slot パターン

CCがSCを包含する場合、`children`または任意のReactNode propで渡す。

```tsx
// CC: SidebarLayout({ children, nav }: { children: ReactNode; nav: ReactNode })
// SC: <SidebarLayout nav={<NavMenu />}>{children}</SidebarLayout>
```

完全例は reference.md 参照。

### 8. シリアライゼーション制約

SC -> CC のprops境界を越えられるのはシリアライズ可能な値のみ。詳細な型一覧は reference.md 参照。

コールバックが必要 -> CC内でハンドラを定義し、Server Action（`"use server"`）を呼ぶ。

### 9. Suspense と use() による非同期データ受け渡し

SCからPromiseをCCに渡し、`use()` hookで消費。ストリーミング描画を実現。

```tsx
// SC: const promise = fetchData(); // awaitしない
// SC: <Suspense fallback={<Skeleton />}><DataView dataPromise={promise} /></Suspense>
// CC: const data = use(dataPromise); // Suspense境界内で使用
```

完全例は reference.md 参照。

---

## Part 3: CVA バリアントシステム [HIGH]

### 10. cva によるバリアント定義

class-variance-authority (CVA) + `cn()` で型安全なスタイルバリアント管理。

```tsx
const buttonVariants = cva("inline-flex items-center ...", {
  variants: { variant: { default: "...", destructive: "..." }, size: { sm: "...", default: "...", lg: "..." } },
  defaultVariants: { variant: "default", size: "default" },
});
```

完全なテンプレートは reference.md 参照。

### 11. cn() と Shadcn/ui拡張

`cn()` = `twMerge(clsx(...))` でTailwindクラス競合を自動解決。実装は reference.md 参照。

Shadcnはコピー&オウン方式。`components/ui/`のコードを直接編集してプロジェクト固有のvariantを追加。compoundVariantsで組み合わせ条件付きスタイルを定義。

---

## Part 4: フォーム設計 [HIGH]

### 12. React Hook Form + Zod + Shadcn/ui

Zodスキーマをクライアント/サーバーで共有。二重バリデーションで安全性担保。

```tsx
// lib/validations/user.ts（クライアント/サーバー共有）
export const userSchema = z.object({ name: z.string().min(1).max(50), email: z.string().email(), role: z.enum(["admin", "member", "viewer"]) });
// CC: useForm<UserFormValues>({ resolver: zodResolver(userSchema) })
// Server Action: userSchema.safeParse(data) で再検証
```

### 13. マルチステップフォーム

各ステップが独立したuseFormインスタンス、共有stateで値を保持。`useState`で共有state + ステップ毎の`useForm`が推奨。完全例は reference.md 参照。

### 14. useActionState（フォーム送信の状態管理）

Server Action の結果と pending 状態を一括管理。`useFormStatus` より上位のコンポーネントで使える。

```tsx
// const [state, formAction, isPending] = useActionState(serverAction, initialState);
// <form action={formAction}> + isPendingでUI制御
```

完全例は reference.md 参照。

### 15. useOptimistic のコンポーネント設計

useOptimisticをコンポーネントに組み込む際の**設計判断**（UXフィードバックの実装詳細は micro-interaction-patterns 参照）。

```tsx
// optimistic stateをpropsの初期値として受け取り、内部で管理
// const [optimistic, setOptimistic] = useOptimistic(todo);
// startTransition内でsetOptimistic -> Server Action呼び出し
```

**設計原則**: optimistic stateを持つコンポーネントは表示層に閉じる。Server Action呼び出しを内包し、親はデータを渡すだけ。完全例は reference.md 参照。

### 15b. Controlled / Uncontrolled 両対応 [HIGH]

外部制御と内部state両方をサポートするコンポーネントAPI設計。

```tsx
// value?: T (controlled) / defaultValue?: T (uncontrolled) / onChange?: (v: T) => void
// const isControlled = controlledValue !== undefined;
// const value = isControlled ? controlledValue : internalValue;
```

**判断**: フォーム連携やテストでcontrolled必須。スタンドアロン利用ではuncontrolledが便利。両対応で汎用性を確保。完全例は reference.md 参照。

---

## Part 5: State管理の選択 [HIGH]

### 16. 選択判断表

| 質問 | Yes | No |
|------|-----|-----|
| URLに反映すべき？ | `useSearchParams` | 次へ |
| 複数コンポーネントで共有？ | 次へ | `useState` / `useReducer` |
| サーバーデータ？ | SC props / fetch | 次へ |
| 2-3階層以内？ | props drilling (OK) | Context / Zustand |

### 17. 各手法の判断基準

| 手法 | 使う場面 | 避ける場面 |
|------|---------|-----------|
| `useState` | 単一値、トグル、入力値 | 相互依存する3+のstate |
| `useReducer` | 複雑なstate遷移、ウィザード | 単純なon/off |
| Context | テーマ、認証、ロケール（低頻度更新） | 高頻度更新（再レンダリング地雷） |
| URL state | フィルター、ページ、ソート、タブ | 一時的UI状態 |
| Server state | DBデータ、API応答 | クライアント限定のUI状態 |
| `useOptimistic` | Server Actionの即時フィードバック | クライアント限定操作 |

**Context再レンダリング対策**: (1) Contextを責務で分割 (2) 値とdispatchを別Contextに (3) 高頻度更新はZustand等の外部ストア。詳細コードは reference.md 参照。

### 18. key propによるコンポーネントリセット

keyを変更するとReactはコンポーネントを破棄・再作成する。フォームリセットや表示切替に活用。

```tsx
<UserProfileForm key={userId} userId={userId} />  // ユーザー切替時にリセット
<ContentPanel key={activeTab} tab={activeTab} />   // タブ切替時にリセット
```

**注意**: 頻繁にkeyが変わるとパフォーマンス低下。意図的なリセットにのみ使用。

---

## Part 6: エラーバウンダリ [HIGH]

### 19. App Router のエラー処理体系

| ファイル | キャッチ範囲 | 備考 |
|---|---|---|
| `app/global-error.tsx` | root layout含む全て | `<html>`自前描画が必要 |
| `app/error.tsx` | app配下のpage/component | アプリ全体のフォールバック |
| `app/[route]/error.tsx` | セグメント配下 | セクション単位 |
| `app/not-found.tsx` | 404 | notFound()呼び出し |

### 20. error.tsx の実装

必ずClient Component。`error`と`reset`を受け取る。同階層のlayout.tsxのエラーはキャッチしない（親階層がキャッチ）。

```tsx
// "use client" + error: Error & { digest?: string } + reset: () => void
// useEffect(() => reportError(error), [error]) + <Button onClick={reset}>再試行</Button>
```

エラー種別ごとの対応方針・UIテンプレート・完全例は [reference.md](reference.md) 参照。

---

## Part 7: メモ化の判断 [MEDIUM]

### 21. React Compiler時代の方針

React Compiler（`babel-plugin-react-compiler`）が自動メモ化。手動メモ化の必要性は大幅低下。React 19自体の機能ではなく、別途導入するBabelプラグイン。

**手動が有効**: 巨大リスト(1000+)のアイテム、重い計算のuseMemo、サードパーティが参照等価性要求

**やめるべき**: 軽いコンポーネントへのReact.memo、プリミティブ値のuseMemo、単純ハンドラのuseCallback

### 22. コード分割

App Routerはルート単位で自動分割。追加は重いコンポーネントのみ。

```tsx
// next/dynamic: ssr: false で重いコンポーネントをクライアント限定読み込み
// React.lazy: CC内で <Suspense fallback={<Skeleton />}><LazyComponent /></Suspense>
```

完全例は reference.md 参照。

---

## Part 8: アクセシビリティ実装 [CRITICAL]

### 23. Radix/Shadcnの自動処理

Radix Primitivesが内蔵: ARIA属性、キーボードナビ(Arrow/Enter/Space/Esc)、フォーカストラップ/復元、スクリーンリーダー対応。**開発者の責任はラベリングとコンテキスト情報の提供。**

### 24. 必須パターン

- **Dialog**: `DialogTitle` + `DialogDescription` を必ず設定
- **アイコンボタン**: `aria-label="設定を開く"` または `<span className="sr-only">設定を開く</span>`
- **フォーム**: `<FormLabel>` を全フィールドに。エラーは `role="alert"` で通知
- **動的コンテンツ**: `aria-live="polite"` (情報) / `aria-live="assertive"` (エラー)

### 25. フォーカス管理

- 動的コンテンツ表示時: `useRef` + `useEffect` でフォーカス移動
- カスタムリスト: ArrowUp/Down + Enter でキーボードナビ実装
- `tabIndex`: `0`（自然順序）か `-1`（プログラム的）のみ。正の値は禁止
- モーダルを閉じたら元のトリガーにフォーカス復元（Radixは自動対応）

詳細なコード例は [reference.md](reference.md) を参照。

---

## Decision Tree

コンポーネント設計 → 状態を持つ？ → Yes → Custom Hook抽出検討（ロジック再利用・テスタビリティ向上） / 表示のみ？ → Server Component検討（`"use client"` 不要、データ取得はSC側）

合成パターン選択 → props drilling 3階層超？ → Compound Components（Context共有） / レンダリング要素を差し替えたい？ → asChild/Slot（Radix方式） / HTML要素だけ切り替え？ → Polymorphic（`as` prop、div/span/p/h系に限定）

SC/CC境界 → useState/useEffect/onClick 必要？ → Yes → Client Component / No → Server Component がデフォルト → CCがSCを包含？ → children slot パターン

状態管理 → URLに反映すべき？ → `useSearchParams` / サーバーデータ？ → SC props / 複数コンポーネント共有？ → 2-3階層以内なら props drilling、超えるなら Context or Zustand / 単一コンポーネント？ → `useState`

フォーム設計 → バリデーション必要？ → Zod スキーマ（クライアント/サーバー共有） + React Hook Form → マルチステップ？ → ステップ毎 useForm + 共有 useState → Server Action で再検証

## Checklist

- [ ] Server Component / Client Component の境界が明確か（`'use client'` 最小化）
- [ ] Compound Components に Context が適切に使われているか
- [ ] CVA バリアントに `cn()` でクラスマージしているか
- [ ] フォームに Zod スキーマ + React Hook Form + Server Action の構成があるか
- [ ] `ref` を React 19 の props 直接受け取りで処理しているか（forwardRef 不使用）
- [ ] エラー境界（error.tsx）がルートセグメント毎に配置されているか
- [ ] コンポーネントが200行以下で単一責任を保っているか

## Cross-references [MEDIUM]

- **typescript-best-practices**: 型安全なprops設計 — discriminated unions でバリアント型定義、generics でコンポーネントAPI の型推論強化
- **vercel-react-best-practices**: レンダリング最適化 — React Compiler 自動メモ化、バンドルサイズ削減、Core Web Vitals 改善との連携
- **testing-strategy**: コンポーネントテストパターン — Compound Components のインテグレーションテスト、CVA バリアントの視覚回帰テスト、フォームの E2E テスト設計

## Reference

[reference.md](reference.md): パターン比較表、SC/CC境界図、CVAテンプレート、フォーム構成、State選択表、ARIAチェックリスト、レビューフォーマット、スニペット集。
