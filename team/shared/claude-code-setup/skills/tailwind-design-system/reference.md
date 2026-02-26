# Tailwind Design System - Reference

SKILL.md から参照される詳細コード例集。

---

## テーマ設定の完全例

```css
/* app.css - Tailwind v4 CSS-first configuration */
@import "tailwindcss";

@theme {
  /* Semantic color tokens (OKLCH) */
  --color-background: oklch(100% 0 0);
  --color-foreground: oklch(14.5% 0.025 264);
  --color-primary: oklch(14.5% 0.025 264);
  --color-primary-foreground: oklch(98% 0.01 264);
  --color-secondary: oklch(96% 0.01 264);
  --color-secondary-foreground: oklch(14.5% 0.025 264);
  --color-muted: oklch(96% 0.01 264);
  --color-muted-foreground: oklch(46% 0.02 264);
  --color-accent: oklch(96% 0.01 264);
  --color-accent-foreground: oklch(14.5% 0.025 264);
  --color-destructive: oklch(53% 0.22 27);
  --color-destructive-foreground: oklch(98% 0.01 264);
  --color-border: oklch(91% 0.01 264);
  --color-ring: oklch(14.5% 0.025 264);
  --color-card: oklch(100% 0 0);
  --color-card-foreground: oklch(14.5% 0.025 264);
  /* ring-offset-color ユーティリティ用。--color-* namespace だが
     Tailwind v4 は ring-offset-<color> として正しく解決する */
  --color-ring-offset: oklch(100% 0 0);

  /* Radius tokens */
  --radius-sm: 0.25rem;
  --radius-md: 0.375rem;
  --radius-lg: 0.5rem;
  --radius-xl: 0.75rem;

  /* Animation tokens */
  --animate-fade-in: fade-in 0.2s ease-out;
  --animate-fade-out: fade-out 0.2s ease-in;
  --animate-slide-in: slide-in 0.3s ease-out;
  --animate-slide-out: slide-out 0.3s ease-in;

  @keyframes fade-in {
    from { opacity: 0; }
    to { opacity: 1; }
  }
  @keyframes fade-out {
    from { opacity: 1; }
    to { opacity: 0; }
  }
  @keyframes slide-in {
    from { transform: translateY(-0.5rem); opacity: 0; }
    to { transform: translateY(0); opacity: 1; }
  }
  @keyframes slide-out {
    from { transform: translateY(0); opacity: 1; }
    to { transform: translateY(-0.5rem); opacity: 0; }
  }
}

/* Dark mode variant */
@custom-variant dark (&:where(.dark, .dark *));

/* Dark mode color overrides */
.dark {
  --color-background: oklch(14.5% 0.025 264);
  --color-foreground: oklch(98% 0.01 264);
  --color-primary: oklch(98% 0.01 264);
  --color-primary-foreground: oklch(14.5% 0.025 264);
  --color-secondary: oklch(22% 0.02 264);
  --color-secondary-foreground: oklch(98% 0.01 264);
  --color-muted: oklch(22% 0.02 264);
  --color-muted-foreground: oklch(65% 0.02 264);
  --color-accent: oklch(22% 0.02 264);
  --color-accent-foreground: oklch(98% 0.01 264);
  --color-destructive: oklch(42% 0.15 27);
  --color-destructive-foreground: oklch(98% 0.01 264);
  --color-border: oklch(22% 0.02 264);
  --color-ring: oklch(83% 0.02 264);
  --color-card: oklch(14.5% 0.025 264);
  --color-card-foreground: oklch(98% 0.01 264);
  --color-ring-offset: oklch(14.5% 0.025 264);
}

/* Base styles */
@layer base {
  * { @apply border-border; }
  body { @apply bg-background text-foreground antialiased; }
}
```

### @source — 追加スキャンパス & セーフリスト

```css
/* 追加のコンテンツパスをスキャン対象に含める */
@source "../components/**/*.tsx";
@source "../packages/ui/src/**/*.tsx";

/* インラインセーフリスト: 動的クラスで検出できないものを明示 */
@source inline("bg-blue-500 text-white p-4");
```

### @plugin — CSSネイティブプラグイン読み込み

```css
/* v3の require() の代わりにCSS内で直接プラグインを読み込む */
@plugin "@tailwindcss/typography";
@plugin "@tailwindcss/forms";
```

---

## CVAコンポーネント

### Button（フル実装例）

```typescript
// components/ui/button.tsx
import { Slot } from '@radix-ui/react-slot'
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils'

const buttonVariants = cva(
  'inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50',
  {
    variants: {
      variant: {
        default: 'bg-primary text-primary-foreground hover:bg-primary/90',
        destructive: 'bg-destructive text-destructive-foreground hover:bg-destructive/90',
        outline: 'border border-border bg-background hover:bg-accent hover:text-accent-foreground',
        secondary: 'bg-secondary text-secondary-foreground hover:bg-secondary/80',
        ghost: 'hover:bg-accent hover:text-accent-foreground',
        link: 'text-primary underline-offset-4 hover:underline',
      },
      size: {
        default: 'h-10 px-4 py-2',
        sm: 'h-9 rounded-md px-3',
        lg: 'h-11 rounded-md px-8',
        icon: 'size-10',
      },
    },
    defaultVariants: { variant: 'default', size: 'default' },
  }
)

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  asChild?: boolean
}

// React 19: No forwardRef needed
export function Button({
  className, variant, size, asChild = false, ref, ...props
}: ButtonProps & { ref?: React.Ref<HTMLButtonElement> }) {
  const Comp = asChild ? Slot : 'button'
  return (
    <Comp
      className={cn(buttonVariants({ variant, size, className }))}
      ref={ref}
      {...props}
    />
  )
}
```

**使用例:**
```tsx
<Button variant="destructive" size="lg">Delete</Button>
<Button variant="outline">Cancel</Button>
<Button asChild><Link href="/home">Home</Link></Button>
```

---

## Compound Components

### Card（React 19版）

```typescript
// components/ui/card.tsx
import { cn } from '@/lib/utils'

export function Card({
  className, ref, ...props
}: React.HTMLAttributes<HTMLDivElement> & { ref?: React.Ref<HTMLDivElement> }) {
  return (
    <div
      ref={ref}
      className={cn('rounded-lg border border-border bg-card text-card-foreground shadow-sm', className)}
      {...props}
    />
  )
}

export function CardHeader({ className, ref, ...props }: React.HTMLAttributes<HTMLDivElement> & { ref?: React.Ref<HTMLDivElement> }) {
  return <div ref={ref} className={cn('flex flex-col space-y-1.5 p-6', className)} {...props} />
}

export function CardTitle({ className, ref, ...props }: React.HTMLAttributes<HTMLHeadingElement> & { ref?: React.Ref<HTMLHeadingElement> }) {
  return <h3 ref={ref} className={cn('text-2xl font-semibold leading-none tracking-tight', className)} {...props} />
}

export function CardDescription({ className, ref, ...props }: React.HTMLAttributes<HTMLParagraphElement> & { ref?: React.Ref<HTMLParagraphElement> }) {
  return <p ref={ref} className={cn('text-sm text-muted-foreground', className)} {...props} />
}

export function CardContent({ className, ref, ...props }: React.HTMLAttributes<HTMLDivElement> & { ref?: React.Ref<HTMLDivElement> }) {
  return <div ref={ref} className={cn('p-6 pt-0', className)} {...props} />
}

export function CardFooter({ className, ref, ...props }: React.HTMLAttributes<HTMLDivElement> & { ref?: React.Ref<HTMLDivElement> }) {
  return <div ref={ref} className={cn('flex items-center p-6 pt-0', className)} {...props} />
}
```

---

## Form Components

### Input + Label + バリデーション

```typescript
// components/ui/input.tsx
import { cn } from '@/lib/utils'

export interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  error?: string
  ref?: React.Ref<HTMLInputElement>
}

export function Input({ className, type, error, ref, ...props }: InputProps) {
  return (
    <div className="relative">
      <input
        type={type}
        className={cn(
          'flex h-10 w-full rounded-md border border-border bg-background px-3 py-2 text-sm ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50',
          error && 'border-destructive focus-visible:ring-destructive',
          className
        )}
        ref={ref}
        aria-invalid={!!error}
        aria-describedby={error ? `${props.id}-error` : undefined}
        {...props}
      />
      {error && (
        <p id={`${props.id}-error`} className="mt-1 text-sm text-destructive" role="alert">
          {error}
        </p>
      )}
    </div>
  )
}
```

### Label

```typescript
// components/ui/label.tsx
import { cva } from 'class-variance-authority'
import { cn } from '@/lib/utils'

const labelVariants = cva(
  'text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70'
)

export function Label({
  className, ref, ...props
}: React.LabelHTMLAttributes<HTMLLabelElement> & { ref?: React.Ref<HTMLLabelElement> }) {
  return <label ref={ref} className={cn(labelVariants(), className)} {...props} />
}
```

### React Hook Form + Zod 連携

```typescript
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'

const schema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
})

function LoginForm() {
  const { register, handleSubmit, formState: { errors } } = useForm({
    resolver: zodResolver(schema),
  })

  const onSubmit = (data: z.infer<typeof schema>) => {
    // API call etc.
    console.log(data)
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
      <div className="space-y-2">
        <Label htmlFor="email">Email</Label>
        <Input id="email" type="email" {...register('email')} error={errors.email?.message} />
      </div>
      <div className="space-y-2">
        <Label htmlFor="password">Password</Label>
        <Input id="password" type="password" {...register('password')} error={errors.password?.message} />
      </div>
      <Button type="submit" className="w-full">Sign In</Button>
    </form>
  )
}
```

---

## Grid System

```typescript
// components/ui/grid.tsx
import { cn } from '@/lib/utils'
import { cva, type VariantProps } from 'class-variance-authority'

const gridVariants = cva('grid', {
  variants: {
    cols: {
      1: 'grid-cols-1',
      2: 'grid-cols-1 sm:grid-cols-2',
      3: 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3',
      4: 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-4',
      5: 'grid-cols-2 sm:grid-cols-3 lg:grid-cols-5',
      6: 'grid-cols-2 sm:grid-cols-3 lg:grid-cols-6',
    },
    gap: {
      none: 'gap-0', sm: 'gap-2', md: 'gap-4', lg: 'gap-6', xl: 'gap-8',
    },
  },
  defaultVariants: { cols: 3, gap: 'md' },
})

interface GridProps extends React.HTMLAttributes<HTMLDivElement>, VariantProps<typeof gridVariants> {}

export function Grid({ className, cols, gap, ...props }: GridProps) {
  return <div className={cn(gridVariants({ cols, gap, className }))} {...props} />
}

// Container component
const containerVariants = cva('mx-auto w-full px-4 sm:px-6 lg:px-8', {
  variants: {
    size: {
      sm: 'max-w-screen-sm', md: 'max-w-screen-md', lg: 'max-w-screen-lg',
      xl: 'max-w-screen-xl', '2xl': 'max-w-screen-2xl', full: 'max-w-full',
    },
  },
  defaultVariants: { size: 'xl' },
})

interface ContainerProps extends React.HTMLAttributes<HTMLDivElement>, VariantProps<typeof containerVariants> {}

export function Container({ className, size, ...props }: ContainerProps) {
  return <div className={cn(containerVariants({ size, className }))} {...props} />
}
```

**使用例:**
```tsx
<Container>
  <Grid cols={4} gap="lg">
    {products.map((p) => <ProductCard key={p.id} product={p} />)}
  </Grid>
</Container>
```

---

## CSS Animations

### Dialog アニメーション

```css
@theme {
  --animate-dialog-in: dialog-fade-in 0.2s ease-out;
  --animate-dialog-out: dialog-fade-out 0.15s ease-in;

  @keyframes dialog-fade-in {
    from { opacity: 0; transform: scale(0.95) translateY(-0.5rem); }
    to { opacity: 1; transform: scale(1) translateY(0); }
  }

  @keyframes dialog-fade-out {
    from { opacity: 1; transform: scale(1) translateY(0); }
    to { opacity: 0; transform: scale(0.95) translateY(-0.5rem); }
  }
}
```

### ネイティブ Popover アニメーション (`@starting-style`)

```css
[popover] {
  transition: opacity 0.2s, transform 0.2s, display 0.2s allow-discrete;
  opacity: 0;
  transform: scale(0.95);
}

[popover]:popover-open {
  opacity: 1;
  transform: scale(1);
}

@starting-style {
  [popover]:popover-open {
    opacity: 0;
    transform: scale(0.95);
  }
}
```

### Dialog コンポーネント (Radix)

```typescript
// components/ui/dialog.tsx
import * as DialogPrimitive from '@radix-ui/react-dialog'
import { cn } from '@/lib/utils'

export function DialogOverlay({
  className, ref, ...props
}: React.ComponentPropsWithoutRef<typeof DialogPrimitive.Overlay> & { ref?: React.Ref<HTMLDivElement> }) {
  return (
    <DialogPrimitive.Overlay
      ref={ref}
      className={cn(
        'fixed inset-0 z-50 bg-black/80',
        'data-[state=open]:animate-fade-in data-[state=closed]:animate-fade-out',
        className
      )}
      {...props}
    />
  )
}

export function DialogContent({
  className, children, ref, ...props
}: React.ComponentPropsWithoutRef<typeof DialogPrimitive.Content> & { ref?: React.Ref<HTMLDivElement> }) {
  return (
    <DialogPrimitive.Portal>
      <DialogOverlay />
      <DialogPrimitive.Content
        ref={ref}
        className={cn(
          'fixed left-1/2 top-1/2 z-50 grid w-full max-w-lg -translate-x-1/2 -translate-y-1/2 gap-4 border border-border bg-background p-6 shadow-lg sm:rounded-lg',
          'data-[state=open]:animate-dialog-in data-[state=closed]:animate-dialog-out',
          className
        )}
        {...props}
      >
        {children}
      </DialogPrimitive.Content>
    </DialogPrimitive.Portal>
  )
}
```

---

## Dark Mode

### ThemeProvider (React 19)

```typescript
// providers/ThemeProvider.tsx
'use client'

import { createContext, useContext, useEffect, useState } from 'react'

type Theme = 'dark' | 'light' | 'system'

interface ThemeContextType {
  theme: Theme
  setTheme: (theme: Theme) => void
  resolvedTheme: 'dark' | 'light'
}

const ThemeContext = createContext<ThemeContextType | undefined>(undefined)

export function ThemeProvider({
  children, defaultTheme = 'system', storageKey = 'theme',
}: {
  children: React.ReactNode; defaultTheme?: Theme; storageKey?: string
}) {
  const [theme, setTheme] = useState<Theme>(defaultTheme)
  const [resolvedTheme, setResolvedTheme] = useState<'dark' | 'light'>('light')

  useEffect(() => {
    const stored = localStorage.getItem(storageKey) as Theme | null
    if (stored) setTheme(stored)
  }, [storageKey])

  useEffect(() => {
    const root = document.documentElement
    root.classList.remove('light', 'dark')
    const resolved = theme === 'system'
      ? (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light')
      : theme
    root.classList.add(resolved)
    setResolvedTheme(resolved)

    const metaThemeColor = document.querySelector('meta[name="theme-color"]')
    if (metaThemeColor) {
      metaThemeColor.setAttribute('content', resolved === 'dark' ? '#09090b' : '#ffffff')
    }
  }, [theme])

  return (
    <ThemeContext.Provider value={{
      theme,
      setTheme: (newTheme) => { localStorage.setItem(storageKey, newTheme); setTheme(newTheme) },
      resolvedTheme,
    }}>
      {children}
    </ThemeContext.Provider>
  )
}

export const useTheme = () => {
  const context = useContext(ThemeContext)
  if (!context) throw new Error('useTheme must be used within ThemeProvider')
  return context
}
```

### ThemeToggle

```typescript
// components/ThemeToggle.tsx
import { Moon, Sun } from 'lucide-react'
import { useTheme } from '@/providers/ThemeProvider'

export function ThemeToggle() {
  const { resolvedTheme, setTheme } = useTheme()
  return (
    <Button
      variant="ghost" size="icon"
      onClick={() => setTheme(resolvedTheme === 'dark' ? 'light' : 'dark')}
    >
      <Sun className="size-5 rotate-0 scale-100 transition-all dark:-rotate-90 dark:scale-0" />
      <Moon className="absolute size-5 rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100" />
      <span className="sr-only">Toggle theme</span>
    </Button>
  )
}
```

---

## Utility Functions

```typescript
// lib/utils.ts
import { type ClassValue, clsx } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

// Focus ring utility
export const focusRing = cn(
  "focus-visible:outline-none focus-visible:ring-2",
  "focus-visible:ring-ring focus-visible:ring-offset-2",
);

// Disabled utility
export const disabled = "disabled:pointer-events-none disabled:opacity-50";
```

---

## Troubleshooting

### v4 CSS-first 設定の問題

| 症状 | 原因 | 解決策 |
|---|---|---|
| `@theme` の変数がユーティリティに反映されない | `@import "tailwindcss"` が欠落 | ファイル先頭に `@import "tailwindcss"` を追加 |
| ダークモードが切り替わらない | `@custom-variant` 未定義 or `.dark` クラス未付与 | `@custom-variant dark (&:where(.dark, .dark *));` を追加、`<html class="dark">` を確認 |
| `bg-primary` が無効 | `--color-primary` が `@theme` にない | `@theme { --color-primary: oklch(...); }` を定義 |
| `animate-fade-in` が動かない | `@keyframes` が `@theme` 外に定義されている | `@keyframes` を `@theme {}` ブロック内に移動 |
| v3プラグインが読み込めない | v4では `require()` ベースのプラグインは非対応 | `@utility` ディレクティブで書き直す |
| `tailwind.config.ts` が無視される | v4ではCSS-first がデフォルト | `@theme` ブロックへ移行、設定ファイルを削除 |

### CVA の問題

| 症状 | 原因 | 解決策 |
|---|---|---|
| バリアントのクラスが競合する | `className` をそのまま結合 | `cn(buttonVariants({ variant, size, className }))` で `twMerge` 経由にする |
| TypeScript型エラー: `variant` が `string` | `VariantProps` 未使用 | `VariantProps<typeof buttonVariants>` を interface に追加 |
| `defaultVariants` が効かない | `cva()` の第2引数に `defaultVariants` がない | `defaultVariants: { variant: 'default', size: 'default' }` を追加 |

### cn() / tailwind-merge の問題

| 症状 | 原因 | 解決策 |
|---|---|---|
| カスタムクラスが `twMerge` で消される | `twMerge` が認識しないユーティリティ | `extendTailwindMerge` でカスタムクラスを登録 |
| `clsx` の条件分岐が動かない | falsy値の扱い | `clsx({ 'bg-red-500': hasError })` の形式を使用 |

---

## v3 → v4 Migration 詳細手順

### Step 1: エントリーポイント変更

```css
/* Before (v3) */
@tailwind base;
@tailwind components;
@tailwind utilities;

/* After (v4) */
@import "tailwindcss";
```

### Step 2: テーマ移行

```javascript
// Before: tailwind.config.ts (v3)
export default {
  theme: {
    extend: {
      colors: {
        primary: '#3b82f6',
      },
      borderRadius: {
        lg: '0.5rem',
      },
    },
  },
}
```

```css
/* After: app.css (v4) */
@theme {
  --color-primary: oklch(58.8% 0.216 264);
  --radius-lg: 0.5rem;
}
```

### Step 3: ユーティリティ変更マップ

| v3 | v4 | 自動移行 |
|---|---|---|
| `h-10 w-10` | `size-10` | `npx @tailwindcss/upgrade` |
| `bg-black bg-opacity-50` | `bg-black/50` | 手動 (opacity修飾子がカラークラスに統合) |
| `text-black text-opacity-75` | `text-black/75` | 手動 (同上) |
| `ring-offset-2` | `ring-offset-2` (v4でも同名で利用可能) | 不要 |
| `space-x-4` | `gap-4` (flex/gridの場合) | 推奨 (※`space-x-*` はv4でも有効。flexbox/gridでは `gap` 推奨) |

---

## Cross-reference ガイド

| シナリオ | 参照先スキル | 理由 |
|---|---|---|
| CVAの型パターン設計 | `typescript-best-practices` | VariantProps, discriminated unions, satisfies の適用 |
| app.cssの配置と読み込み | `nextjs-app-router-patterns` | App Routerのレイアウト階層でのCSS読み込み順序 |
| データテーブルのスタイリング | `dashboard-data-viz` | TanStack Table + Tailwind のスタイリングパターン |
| コンポーネントの分割設計 | `react-component-patterns` | Compound Components, asChild, Server/Client境界 |
| ボタン・フォームの心理学 | `ux-psychology` | CTA配置、フォームの認知負荷、Fittの法則 |
| トークン値の決定 | `design-token-system` | OKLCH色設計、スペーシングスケール、コントラスト比 |
| LIFF内レスポンシブ | `mobile-first-responsive` | safe-area-inset、WebView制約、svh/dvh |
| アニメーション設計 | `micro-interaction-patterns` | Framer Motion連携、状態遷移、loading states |
| セマンティックHTML | `web-design-guidelines` | aria属性、ランドマーク、フォーカス管理 |
