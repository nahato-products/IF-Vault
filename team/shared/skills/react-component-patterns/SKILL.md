---
name: react-component-patterns
description: "Use when designing, building, refactoring, reviewing, or architecting React component APIs and composition. Covers compound components, asChild/Slot, polymorphic components, Server/Client boundary design, CVA variant systems, form composition with React Hook Form + Zod + Server Actions, state management selection, error boundary component design, context providers, ref forwarding, controlled/uncontrolled patterns, and component-level ARIA/focus. Does NOT cover animation/state-feedback (micro-interaction-patterns), routing/data-fetching (nextjs-app-router-patterns), runtime performance (vercel-react-best-practices), or generic TypeScript (typescript-best-practices)."
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
const AccordionContext = createContext<AccordionContextType | null>(null);

function useAccordion() {
  const ctx = useContext(AccordionContext);
  if (!ctx) throw new Error("useAccordion must be used within <Accordion>");
  return ctx;
}

function Accordion({ children }: { children: ReactNode }) {
  const [openItem, setOpenItem] = useState<string | null>(null);
  return (
    <AccordionContext value={{ openItem, toggle: (id) => setOpenItem(p => p === id ? null : id) }}>
      <div>{children}</div>
    </AccordionContext>
  );
}
// サブコンポーネント: Accordion.Item, Accordion.Trigger, Accordion.Content
// 使用: <Accordion><Accordion.Item id="1">...</Accordion.Item></Accordion>
```

**判断**: props drillingが3階層超、または子の順序・構成をユーザーに委ねたい場合に採用。

### 2. Slot / asChild パターン（Radix方式）

レンダリング要素を消費者が差し替え可能にする。Radix UI / Shadcn/uiの中核パターン。

```tsx
import { Slot } from "@radix-ui/react-slot";

function Button({ asChild, className, ...props }: ButtonProps) {
  const Comp = asChild ? Slot : "button";
  return <Comp className={cn(buttonVariants({ variant }), className)} {...props} />;
}

// ボタンとして: <Button>保存</Button>
// Linkとして:  <Button asChild><Link href="/settings">設定</Link></Button>
```

**仕組み**: `asChild=true`でSlotが子要素をcloneし、親のprops・ref・イベントハンドラをマージ注入。デフォルト要素は描画しない。

**`as` prop vs `asChild`**: `as`はTS型推論が重くジェネリクスが複雑化。`asChild`がRadix/Shadcnの標準。新規コードでは`asChild`を使う。

### 3. Ref の扱い（React 19）

React 19で`forwardRef`は不要。`ref`を通常のpropとして受け取る。

```tsx
// React 19: refは通常のprop
function Input({ className, ref, ...props }: InputProps & { ref?: React.Ref<HTMLInputElement> }) {
  return <input ref={ref} className={cn("border rounded px-3 py-2", className)} {...props} />;
}
// React 18以前はforwardRefが必要だった。Shadcn/uiコンポーネントは順次移行中。
```

### 4. Polymorphic Components

同一コンポーネントを異なるHTML要素でレンダリング。プリミティブ要素の切替に限定して使う。

```tsx
type PolymorphicProps<T extends React.ElementType> = {
  as?: T;
} & Omit<React.ComponentPropsWithoutRef<T>, "as">;

function Text<T extends React.ElementType = "p">({ as, className, ...props }: PolymorphicProps<T>) {
  const Component = as || "p";
  return <Component className={cn("text-base", className)} {...props} />;
}
// <Text as="span">インライン</Text>  <Text as="label" htmlFor="name">ラベル</Text>
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
// app/dashboard/page.tsx (SC) -> InteractiveChart (CC)
export default async function DashboardPage() {
  const data = await db.metrics.findMany();
  return <InteractiveChart data={data} />; // シリアライズ可能なpropsのみ
}
```

### 7. CC children slot パターン

CCがSCを包含する場合、`children`または任意のReactNode propで渡す。

```tsx
// sidebar-layout.tsx (CC): children と nav を ReactNode として受け取る
"use client";
export function SidebarLayout({ children, nav }: { children: ReactNode; nav: ReactNode }) {
  const [isOpen, setIsOpen] = useState(true);
  return (
    <div className="flex">
      <aside className={isOpen ? "w-64" : "w-0"}>{nav}</aside>
      <main>{children}</main>
    </div>
  );
}
// layout.tsx (SC): <SidebarLayout nav={<NavMenu />}>{children}</SidebarLayout>
```

### 8. シリアライゼーション制約

SC -> CC のprops境界を越えられるのはシリアライズ可能な値のみ。詳細な型一覧は reference.md 参照。

コールバックが必要 -> CC内でハンドラを定義し、Server Action（`"use server"`）を呼ぶ。

### 9. Suspense と use() による非同期データ受け渡し

SCからPromiseをCCに渡し、`use()` hookで消費。ストリーミング描画を実現。

```tsx
// page.tsx (SC): Promiseをpropsとして渡す
export default function Page() {
  const dataPromise = fetchData(); // awaitしない
  return (
    <Suspense fallback={<Skeleton className="h-[200px]" />}>
      <DataView dataPromise={dataPromise} />
    </Suspense>
  );
}

// data-view.tsx (CC): use()でPromiseを消費
"use client";
import { use } from "react";
export function DataView({ dataPromise }: { dataPromise: Promise<Data> }) {
  const data = use(dataPromise); // Suspense境界内で使用
  return <div>{data.title}</div>;
}
```

---

## Part 3: CVA バリアントシステム [HIGH]

### 10. cva によるバリアント定義

class-variance-authority (CVA) + `cn()` で型安全なスタイルバリアント管理。

```tsx
import { cva, type VariantProps } from "class-variance-authority";

const buttonVariants = cva("inline-flex items-center justify-center rounded-md font-medium transition-colors ...", {
  variants: {
    variant: { default: "bg-primary ...", destructive: "bg-destructive ...", outline: "border ...", ghost: "hover:bg-accent ...", link: "underline ..." },
    size: { sm: "h-8 px-3 text-xs", default: "h-10 px-4 py-2 text-sm", lg: "h-12 px-6 text-base", icon: "h-10 w-10" },
  },
  defaultVariants: { variant: "default", size: "default" },
});
// 完全な Button コンポーネントは reference.md 参照
```

### 11. cn() と Shadcn/ui拡張

`cn()` = `twMerge(clsx(...))` でTailwindクラス競合を自動解決。実装は reference.md 参照。

Shadcnはコピー&オウン方式。`components/ui/`のコードを直接編集してプロジェクト固有のvariantを追加。compoundVariantsで組み合わせ条件付きスタイルを定義。

---

## Part 4: フォーム設計 [HIGH]

### 12. React Hook Form + Zod + Shadcn/ui

Zodスキーマをクライアント/サーバーで共有。二重バリデーションで安全性担保。

```tsx
// lib/validations/user.ts（共有）
export const userSchema = z.object({
  name: z.string().min(1, "名前は必須です").max(50),
  email: z.string().email("有効なメールアドレスを入力してください"),
  role: z.enum(["admin", "member", "viewer"]),
});
export type UserFormValues = z.infer<typeof userSchema>;
```

```tsx
// components/user-form.tsx (CC): useForm + zodResolver + Shadcn Form
const form = useForm<UserFormValues>({
  resolver: zodResolver(userSchema),
  defaultValues: { name: "", email: "", role: "member" },
});
// <Form {...form}> + <FormField> + <FormItem> + <FormLabel> + <FormControl> + <FormMessage>
```

```tsx
// app/actions/user.ts: Server Actionで同じスキーマ再検証
"use server";
export async function createUser(data: unknown) {
  const parsed = userSchema.safeParse(data);
  if (!parsed.success) return { error: parsed.error.flatten().fieldErrors };
  await db.user.create({ data: parsed.data });
  revalidatePath("/users");
  return { success: true };
}
```

### 13. マルチステップフォーム

各ステップが独立したuseFormインスタンス、共有stateで値を保持。

```tsx
export function SignupWizard() {
  const [step, setStep] = useState(0);
  const [data, setData] = useState<Partial<WizardData>>({});
  const updateData = <K extends keyof WizardData>(key: K, values: WizardData[K]) => {
    setData(prev => ({ ...prev, [key]: values }));
    setStep(s => s + 1);
  };
  return (
    <div>
      <StepIndicator current={step} total={3} />
      {step === 0 && <Step1Form onNext={v => updateData("step1", v)} defaults={data.step1} />}
      {step === 1 && <Step2Form onNext={v => updateData("step2", v)} onBack={() => setStep(0)} />}
      {step === 2 && <Step3Form onSubmit={v => finalSubmit({...data, step3: v})} onBack={() => setStep(1)} />}
    </div>
  );
}
```

### 14. useActionState（フォーム送信の状態管理）

Server Action の結果と pending 状態を一括管理。`useFormStatus` より上位のコンポーネントで使える。

```tsx
"use client";
import { useActionState } from "react";
import { createUser } from "@/app/actions/user";

export function CreateUserForm() {
  const [state, formAction, isPending] = useActionState(createUser, { error: null });
  return (
    <form action={formAction}>
      <input name="name" required />
      {state.error && <p role="alert" className="text-destructive text-sm">{state.error}</p>}
      <button disabled={isPending}>{isPending ? "送信中..." : "作成"}</button>
    </form>
  );
}
```

### 15. useOptimistic のコンポーネント設計

useOptimisticをコンポーネントに組み込む際の**設計判断**（UXフィードバックの実装詳細は micro-interaction-patterns 参照）。

```tsx
// コンポーネント設計のポイント: optimistic stateをpropsの初期値として受け取り、内部で管理
export function TodoItem({ todo }: { todo: Todo }) {
  const [optimistic, setOptimistic] = useOptimistic(todo);
  const [, startTransition] = useTransition();
  const handleToggle = () => {
    startTransition(async () => {
      setOptimistic({ ...todo, completed: !todo.completed });
      await toggleTodo(todo.id);
    });
  };
  return <button onClick={handleToggle} className={optimistic.completed ? "line-through" : ""}>{optimistic.title}</button>;
}
```

**設計原則**: optimistic stateを持つコンポーネントは表示層に閉じる。Server Action呼び出しを内包し、親はデータを渡すだけ。

### 15b. Controlled / Uncontrolled 両対応 [HIGH]

外部制御と内部state両方をサポートするコンポーネントAPI設計。

```tsx
function Toggle({ value: controlledValue, defaultValue = false, onChange }: ToggleProps) {
  const [internalValue, setInternalValue] = useState(defaultValue);
  const isControlled = controlledValue !== undefined;
  const value = isControlled ? controlledValue : internalValue;
  const handleChange = () => {
    const next = !value;
    if (!isControlled) setInternalValue(next);
    onChange?.(next);
  };
  return <button role="switch" aria-checked={value} onClick={handleChange}>...</button>;
}
```

**判断**: フォーム連携やテストでcontrolled必須。スタンドアロン利用ではuncontrolledが便利。両対応で汎用性を確保。

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
// ユーザー切替時にフォームを完全リセット
<UserProfileForm key={userId} userId={userId} />

// タブ切替時にスクロール位置をリセット
<ContentPanel key={activeTab} tab={activeTab} />
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
"use client";
export default function SectionError({ error, reset }: { error: Error & { digest?: string }; reset: () => void }) {
  useEffect(() => { reportError(error); }, [error]);
  return (
    <div className="flex flex-col items-center gap-4 p-8">
      <h2 className="text-xl font-semibold">問題が発生しました</h2>
      <p className="text-muted-foreground">{error.message}</p>
      <Button onClick={reset}>再試行</Button>
    </div>
  );
}
```

エラー種別ごとの対応方針・UIテンプレートは [reference.md](reference.md) 参照。

---

## Part 7: メモ化の判断 [MEDIUM]

### 21. React Compiler時代の方針

React Compiler（`babel-plugin-react-compiler`）が自動メモ化。手動メモ化の必要性は大幅低下。React 19自体の機能ではなく、別途導入するBabelプラグイン。

**手動が有効**: 巨大リスト(1000+)のアイテム、重い計算のuseMemo、サードパーティが参照等価性要求

**やめるべき**: 軽いコンポーネントへのReact.memo、プリミティブ値のuseMemo、単純ハンドラのuseCallback

### 22. コード分割

App Routerはルート単位で自動分割。追加は重いコンポーネントのみ。

```tsx
// next/dynamic: SSR制御付き
const HeavyEditor = dynamic(() => import("@/components/heavy-editor"), {
  loading: () => <Skeleton className="h-[400px]" />, ssr: false,
});
// React.lazy: CC内で使用
const Chart = lazy(() => import("./chart"));
// <Suspense fallback={<Skeleton />}><Chart /></Suspense>
```

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

## Reference

[reference.md](reference.md): パターン比較表、SC/CC境界図、CVAテンプレート、フォーム構成、State選択表、ARIAチェックリスト、レビューフォーマット、スニペット集。
