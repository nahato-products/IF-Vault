# React Component Patterns -- Reference

SKILL.md の補足資料。パターン比較表、チートシート、テンプレート、チェックリスト。

---

## コンポーネント合成パターン比較表

| パターン | 適用場面 | メリット | デメリット | 代表例 |
|---------|---------|---------|-----------|--------|
| **Compound Components** | 関連UI群（Tabs, Accordion, Menu） | 柔軟なAPI、順序自由 | Context依存、型が複雑 | Radix Tabs, Select |
| **asChild / Slot** | 要素の差し替え（Button -> Link） | DOM層が増えない、型シンプル | 子が1つに限定 | Shadcn Button, Radix全般 |
| **Render Props** | 描画ロジックの委譲 | 最大の柔軟性 | ネスト地獄、可読性低下 | Downshift, React Aria |
| **HOC** | 横断的関心事の注入 | ロジック再利用 | レガシー感、デバッグ困難 | withAuth (非推奨寄り) |
| **Custom Hooks** | ステートフルロジックの共有 | テスト容易、合成可能 | UIを含まない | useForm, useMediaQuery |
| **Polymorphic `as`** | HTML要素の切り替え | 型安全に要素変更 | TS推論が重い | Text, Heading |
| **children slot** | SC inside CC | SC/CC境界を越える | 暗黙的で発見しにくい | Layout, Modal |

### パターン選択フロー

```
関連する子コンポーネントが暗黙的に状態共有?
  Yes -> Compound Components
  No -> 描画要素を消費者が差し替えたい?
    Yes -> asChild/Slot (Radixエコシステム) or as prop (プリミティブ要素限定)
    No -> ロジックだけ共有したい?
      Yes -> Custom Hook
      No -> 描画ロジックを消費者に委ねたい?
        Yes -> Render Props (最終手段)
        No -> 通常のprops
```

---

## Server Component / Client Component 判断表

### props境界で渡せるもの・渡せないもの

| 型 | SC -> CC に渡せるか | 備考 |
|---|---|---|
| `string`, `number`, `boolean`, `null` | OK | |
| `Date` | OK | JSON文字列化される |
| `undefined` | OK | |
| プレーンオブジェクト / 配列 | OK | ネストもOK（中身がシリアライズ可能なら） |
| `ReactNode` (JSX) | OK | children, slotパターンで活用 |
| `Promise` | OK | `use()` hookで消費（React 19） |
| 関数 / コールバック | NG | Server Actionは例外（`"use server"`付き） |
| クラスインスタンス | NG | プレーンオブジェクトに変換して渡す |
| `Map`, `Set`, `Symbol` | NG | Array / Objectに変換 |
| DOM Ref | NG | CCで作成して使う |
| `RegExp` | NG | パターン文字列として渡す |

### SC / CC 配置パターン

```
推奨: SC -> CC (データ取得 -> インタラクション)
┌─────────────────────────────┐
│ Server Component (page.tsx) │  データ取得、レイアウト
│  ┌────────────────────┐     │
│  │ Client Component   │     │  useState, onClick
│  │  (serializable     │     │
│  │   props only)      │     │
│  └────────────────────┘     │
└─────────────────────────────┘

推奨: CC children slot (CC -> SC を含む)
┌─────────────────────────────┐
│ Server Component (layout)   │
│  ┌────────────────────────┐ │
│  │ Client Component       │ │  トグル、アニメーション
│  │  ┌──────────────────┐  │ │
│  │  │ {children} = SC  │  │ │  サーバーで描画済みJSX
│  │  └──────────────────┘  │ │
│  └────────────────────────┘ │
└─────────────────────────────┘

非推奨: CC内でSCを直接import
// これはSCをCCに変換してしまう
"use client";
import { ServerThing } from "./server-thing"; // 全体がCC化
```

---

## CVA バリアント設計テンプレート

### 基本テンプレート

```tsx
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

const componentVariants = cva(
  "base-classes-here",
  {
    variants: {
      variant: {
        default: "...",
        secondary: "...",
      },
      size: {
        sm: "...",
        default: "...",
        lg: "...",
      },
    },
    compoundVariants: [
      { variant: "default", size: "lg", className: "..." },
    ],
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
);

type ComponentProps = React.HTMLAttributes<HTMLDivElement> &
  VariantProps<typeof componentVariants>;

function Component({ className, variant, size, ...props }: ComponentProps) {
  return <div className={cn(componentVariants({ variant, size }), className)} {...props} />;
}
```

### よく使うバリアント設計

| コンポーネント | variant軸 | size軸 | その他の軸 |
|---|---|---|---|
| Button | default, destructive, outline, ghost, link | sm, default, lg, icon | loading (boolean) |
| Badge | default, secondary, destructive, outline | sm, default | - |
| Alert | default, destructive, warning, success | - | - |
| Input | default, error | sm, default, lg | - |
| Card | default, outlined, elevated | - | interactive (boolean) |
| Avatar | - | sm, default, lg, xl | status: online/offline/away |

### compoundVariants の活用例

```tsx
compoundVariants: [
  // destructive + outlineの組み合わせ
  {
    variant: "destructive",
    outline: true,
    className: "border-destructive text-destructive bg-transparent hover:bg-destructive/10",
  },
  // small + iconの組み合わせ
  {
    size: "sm",
    icon: true,
    className: "h-7 w-7 p-0",
  },
],
```

---

## フォームパターン集

### React Hook Form + Shadcn/ui 構成

```
lib/validations/          -- Zodスキーマ（クライアント/サーバー共有）
  user.ts
  project.ts
components/
  forms/
    user-form.tsx         -- フォームUI（Client Component）
    project-form.tsx
app/actions/
  user.ts                 -- Server Action（サーバー側バリデーション）
  project.ts
```

### フォームフィールド早見表（Shadcn/ui）

| 入力タイプ | Shadcnコンポーネント | Zodスキーマ |
|---|---|---|
| テキスト | `<Input />` | `z.string().min(1).max(100)` |
| メール | `<Input type="email" />` | `z.string().email()` |
| パスワード | `<Input type="password" />` | `z.string().min(8).regex(...)` |
| 数値 | `<Input type="number" />` | `z.coerce.number().min(0)` |
| テキストエリア | `<Textarea />` | `z.string().max(1000)` |
| セレクト | `<Select />` | `z.enum(["a", "b", "c"])` |
| チェックボックス | `<Checkbox />` | `z.boolean()` |
| ラジオ | `<RadioGroup />` | `z.enum(["opt1", "opt2"])` |
| 日付 | `<Calendar />` + `<Popover />` | `z.date()` or `z.coerce.date()` |
| ファイル | `<Input type="file" />` | `z.instanceof(File).refine(...)` |
| スイッチ | `<Switch />` | `z.boolean().default(false)` |
| スライダー | `<Slider />` | `z.number().min(0).max(100)` |
| コンボボックス | `<Command />` + `<Popover />` | `z.string()` |

### useActionState パターン（React 19）

```tsx
"use client";
import { useActionState } from "react";
import { useFormStatus } from "react-dom";
import { createUser } from "@/app/actions/user";

function SubmitButton() {
  const { pending } = useFormStatus();
  return (
    <Button type="submit" disabled={pending}>
      {pending ? "送信中..." : "作成"}
    </Button>
  );
}

export function UserForm() {
  const [state, formAction] = useActionState(createUser, { errors: {} });

  return (
    <form action={formAction}>
      <div>
        <Label htmlFor="name">名前</Label>
        <Input id="name" name="name" />
        {state.errors?.name && <p className="text-sm text-destructive">{state.errors.name}</p>}
      </div>
      <SubmitButton />
    </form>
  );
}
```

### マルチステップフォーム設計パターン

| アプローチ | 状態管理 | メリット | デメリット |
|---|---|---|---|
| 単一form + 表示切替 | 1つのuseForm | バリデーションが統一 | 巨大フォームは重い |
| ステップ毎のform + 共有state | useState + 複数useForm | ステップ独立、軽量 | state同期が必要 |
| URL driven steps | searchParams + useForm | ブックマーク・共有可能 | 複雑なstate管理 |
| Zustand + useForm | Zustand store | 永続化容易、DevTools | 外部依存増 |

**推奨**: ステップ毎のform + 共有state（`useState`で十分な場合が多い）。永続化が必要ならZustand + `persist`ミドルウェア。

---

## State管理 判断チートシート

| state の性質 | 推奨 | 理由 |
|---|---|---|
| ボタンの開閉、入力値 | `useState` | 単純、ローカル |
| フォームの複数フィールド | `useReducer` or React Hook Form | 相互依存するstate |
| テーマ、言語、認証 | Context | アプリ全体、低頻度更新 |
| フィルター、ソート、ページ | `useSearchParams` (URL) | 共有可能、戻るボタン対応 |
| DBデータ | SC fetch / Server Action | サーバーが正 |
| 楽観的更新 | `useOptimistic` | 即時フィードバック |
| グローバル複雑state | Zustand / Jotai | Context再レンダリング回避 |
| サーバーキャッシュ | TanStack Query / SWR | キャッシュ、再検証、ポーリング |

### Context 分割の指針

```tsx
// BAD: 1つの巨大Context
const AppContext = createContext({ theme, user, locale, notifications, ... });

// GOOD: 責務ごとに分割
const ThemeContext = createContext<Theme>("light");          // ほぼ不変
const AuthContext = createContext<AuthState | null>(null);   // ログイン時のみ変化
const LocaleContext = createContext<Locale>("ja");           // ほぼ不変

// GOOD: 値とdispatchを分離（再レンダリング最適化）
const TodoStateContext = createContext<TodoState>(initialState);
const TodoDispatchContext = createContext<Dispatch<TodoAction>>(() => {});

// 読み取り専用コンポーネントはStateだけ購読
function TodoCount() {
  const { todos } = useContext(TodoStateContext); // dispatchの変更では再レンダリングしない
  return <span>{todos.length}</span>;
}
```

---

## エラーバウンダリ設計表

ファイル配置とキャッチ範囲は SKILL.md #19 参照。以下はUI設計テンプレートとエラー種別対応方針。

### エラーUI設計テンプレート

```tsx
// セクションエラー（リカバリ可能）
function SectionError({ error, reset }) {
  return (
    <Card className="p-6 text-center">
      <AlertCircle className="mx-auto h-8 w-8 text-destructive" />
      <p className="mt-2 font-medium">データの読み込みに失敗しました</p>
      <p className="text-sm text-muted-foreground">{error.message}</p>
      <Button onClick={reset} className="mt-4">再試行</Button>
    </Card>
  );
}

// インラインエラー（フォームフィールド等）
<FormMessage className="text-sm text-destructive" role="alert" />

// トーストエラー（非同期操作の失敗）
toast.error("保存に失敗しました。再度お試しください。");
```

### エラー種別と対応方針

| エラー種別 | UI | ユーザーアクション |
|---|---|---|
| ネットワーク | トースト or インライン | 「再試行」ボタン |
| 認証切れ | リダイレクト | ログイン画面へ |
| バリデーション | フィールド横エラー | 入力修正 |
| 権限不足 | 専用ページ/カード | 管理者に依頼 |
| サーバー500 | error.tsx | 「再試行」+「サポートに連絡」 |
| 404 | not-found.tsx | ホームへ戻る |

---

## アクセシビリティ実装チェックリスト

### コンポーネント実装時

- [ ] インタラクティブ要素は全てキーボードでアクセス可能か
- [ ] アイコンボタンに `aria-label` または `sr-only` テキストがあるか
- [ ] フォームフィールドに関連付けられた `<label>` があるか
- [ ] 動的コンテンツ変更時に `aria-live` で通知しているか
- [ ] モーダル/ダイアログにフォーカストラップがあるか
- [ ] モーダル/ダイアログを閉じた後、元のトリガーにフォーカスが戻るか
- [ ] エラーメッセージは `role="alert"` で通知しているか
- [ ] カスタムコンポーネントに適切な `role` が設定されているか
- [ ] `tabIndex` は `0`（自然順序）か `-1`（プログラム的フォーカス）のみ使用しているか（正の値は禁止）
- [ ] 色だけに頼らず、アイコン・テキスト・パターンでも情報伝達しているか

### Radix/Shadcn利用時の追加確認

- [ ] `DialogTitle` と `DialogDescription` が設定されているか
- [ ] `DropdownMenu` のトリガーに適切なラベルがあるか
- [ ] `Select` のプレースホルダーが説明的か
- [ ] `Toast` に `aria-live` の適切な優先度が設定されているか（polite/assertive）
- [ ] `Tooltip` のトリガーがキーボードフォーカス可能か（button/link）

### ARIA ロール早見表（カスタムUI用）

| UIパターン | role | 必須aria属性 |
|---|---|---|
| タブ | `tablist`, `tab`, `tabpanel` | `aria-selected`, `aria-controls` |
| ドロップダウン | `listbox`, `option` | `aria-expanded`, `aria-selected` |
| ツリービュー | `tree`, `treeitem` | `aria-expanded`, `aria-level` |
| ツールバー | `toolbar` | `aria-label` |
| アラート | `alert` | - (暗黙的にlive) |
| ステータス | `status` | - (暗黙的にlive=polite) |
| プログレス | `progressbar` | `aria-valuenow`, `aria-valuemin`, `aria-valuemax` |
| スイッチ | `switch` | `aria-checked` |
| フィードバック | `log` | `aria-live="polite"` |

---

## コンポーネントレビュー出力フォーマット

コンポーネントコードをレビューする際は以下の形式で出力する:

```
### コンポーネント設計レビュー

**サマリー**: [1文で全体評価]

#### 構造上の問題
1. **[CRITICAL/HIGH/MEDIUM]** [問題の説明]
   - 該当パターン: #N [パターン名]
   - 修正案: [具体的なコード変更]

#### 良い設計
- [パターンに沿った良い実装のフィードバック]

#### チェック結果
- [x] SC/CC境界は適切か
- [x] シリアライゼーション制約を守っているか
- [ ] バリアントは型安全か (CVA使用) -> 修正推奨
- [x] エラーバウンダリがあるか
- [ ] アクセシビリティ (aria-label, role等) -> 修正推奨
```

---

## よく使うパターンスニペット

### cn() ユーティリティ

```tsx
// lib/utils.ts
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

### 型安全なContext + Provider

```tsx
function createSafeContext<T>(displayName: string) {
  const Context = createContext<T | null>(null);

  function useContext_() {
    const ctx = useContext(Context);
    if (ctx === null) {
      throw new Error(`use${displayName} must be used within <${displayName}Provider>`);
    }
    return ctx;
  }

  return [Context, useContext_] as const;
}

// 使用
const [ThemeContext, useTheme] = createSafeContext<ThemeContextType>("Theme");
```

### Controlled/Uncontrolled 両対応コンポーネント

```tsx
type ToggleProps = {
  value?: boolean;           // controlled
  defaultValue?: boolean;    // uncontrolled
  onChange?: (value: boolean) => void;
};

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

### レスポンシブコンポーネント（メディアクエリhook）

```tsx
// 注意: SSRでは window が存在しないため初期値は false。
// hydration mismatch を避けるには useEffect 内でのみ使用するか、
// suppressHydrationWarning を検討。
function useMediaQuery(query: string): boolean {
  const [matches, setMatches] = useState(false);

  useEffect(() => {
    const media = window.matchMedia(query);
    setMatches(media.matches);
    const listener = (e: MediaQueryListEvent) => setMatches(e.matches);
    media.addEventListener("change", listener);
    return () => media.removeEventListener("change", listener);
  }, [query]);

  return matches;
}

// 使用
const isMobile = useMediaQuery("(max-width: 768px)");
```

---

## Compound Components 完全例

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
    // React 19+: <Context value={}> で直接使用可能（.Provider 不要）
    <AccordionContext value={{ openItem, toggle: (id) => setOpenItem(p => p === id ? null : id) }}>
      <div>{children}</div>
    </AccordionContext>
  );
}
function AccordionItem({ id, children }: { id: string; children: ReactNode }) {
  return <div data-accordion-item={id}>{children}</div>;
}

function AccordionTrigger({ id, children }: { id: string; children: ReactNode }) {
  const { openItem, toggle } = useAccordion();
  return (
    <button onClick={() => toggle(id)} aria-expanded={openItem === id}>
      {children}
    </button>
  );
}

function AccordionContent({ id, children }: { id: string; children: ReactNode }) {
  const { openItem } = useAccordion();
  if (openItem !== id) return null;
  return <div role="region">{children}</div>;
}

// dot-access パターンでサブコンポーネントを公開
const AccordionRoot = Accordion;
const AccordionCompound = Object.assign(AccordionRoot, {
  Item: AccordionItem,
  Trigger: AccordionTrigger,
  Content: AccordionContent,
});
// 使用: <Accordion><Accordion.Item id="1"><Accordion.Trigger id="1">...</Accordion.Trigger><Accordion.Content id="1">...</Accordion.Content></Accordion.Item></Accordion>
```

---

## CC children slot パターン 完全例

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

---

## Suspense + use() 完全例

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

## マルチステップフォーム 完全例

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

---

## useOptimistic コンポーネント設計 完全例

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

---

## error.tsx 完全例

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

---

## コード分割パターン 完全例

```tsx
// next/dynamic: SSR制御付き
const HeavyEditor = dynamic(() => import("@/components/heavy-editor"), {
  loading: () => <Skeleton className="h-[400px]" />, ssr: false,
});
// React.lazy: CC内で使用
const Chart = lazy(() => import("./chart"));
// <Suspense fallback={<Skeleton />}><Chart /></Suspense>
```
