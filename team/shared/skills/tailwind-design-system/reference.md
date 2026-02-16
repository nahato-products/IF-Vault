# Tailwind Design System - Reference

SKILL.md から参照される詳細コード例集。ルール・パターンはSKILL.mdを参照。

---

## テーマ設定の完全例

```css
/* app.css - Tailwind v4 CSS-first configuration */
@import "tailwindcss";

/* Semantic variables: light/dark で切替 */
:root {
  --background: oklch(100% 0 0);
  --foreground: oklch(14.5% 0.025 264);
  --primary: oklch(14.5% 0.025 264);
  --primary-foreground: oklch(98% 0.01 264);
  --secondary: oklch(96% 0.01 264);
  --secondary-foreground: oklch(14.5% 0.025 264);
  --muted: oklch(96% 0.01 264);
  --muted-foreground: oklch(46% 0.02 264);
  --accent: oklch(96% 0.01 264);
  --accent-foreground: oklch(14.5% 0.025 264);
  --destructive: oklch(53% 0.22 27);
  --destructive-foreground: oklch(98% 0.01 264);
  --border: oklch(91% 0.01 264);
  --ring: oklch(14.5% 0.025 264);
  --card: oklch(100% 0 0);
  --card-foreground: oklch(14.5% 0.025 264);
  --ring-offset: oklch(100% 0 0);
  --radius-sm: 0.25rem;
  --radius-md: 0.375rem;
  --radius-lg: 0.5rem;
  --radius-xl: 0.75rem;
}

.dark {
  --background: oklch(14.5% 0.025 264);
  --foreground: oklch(98% 0.01 264);
  --primary: oklch(98% 0.01 264);
  --primary-foreground: oklch(14.5% 0.025 264);
  --secondary: oklch(22% 0.02 264);
  --secondary-foreground: oklch(98% 0.01 264);
  --muted: oklch(22% 0.02 264);
  --muted-foreground: oklch(65% 0.02 264);
  --accent: oklch(22% 0.02 264);
  --accent-foreground: oklch(98% 0.01 264);
  --destructive: oklch(42% 0.15 27);
  --destructive-foreground: oklch(98% 0.01 264);
  --border: oklch(22% 0.02 264);
  --ring: oklch(83% 0.02 264);
  --card: oklch(14.5% 0.025 264);
  --card-foreground: oklch(98% 0.01 264);
  --ring-offset: oklch(14.5% 0.025 264);
}

/* @theme inline で Tailwind ユーティリティに橋渡し */
@theme inline {
  --color-background: var(--background);
  --color-foreground: var(--foreground);
  --color-primary: var(--primary);
  --color-primary-foreground: var(--primary-foreground);
  --color-secondary: var(--secondary);
  --color-secondary-foreground: var(--secondary-foreground);
  --color-muted: var(--muted);
  --color-muted-foreground: var(--muted-foreground);
  --color-accent: var(--accent);
  --color-accent-foreground: var(--accent-foreground);
  --color-destructive: var(--destructive);
  --color-destructive-foreground: var(--destructive-foreground);
  --color-border: var(--border);
  --color-ring: var(--ring);
  --color-card: var(--card);
  --color-card-foreground: var(--card-foreground);
  --color-ring-offset: var(--ring-offset);
  --radius-sm: var(--radius-sm);
  --radius-md: var(--radius-md);
  --radius-lg: var(--radius-lg);
  --radius-xl: var(--radius-xl);
}

/* Animation tokens */
@theme {
  --animate-fade-in: fade-in 0.2s ease-out;
  --animate-fade-out: fade-out 0.2s ease-in;
  --animate-slide-in: slide-in 0.3s ease-out;
  --animate-slide-out: slide-out 0.3s ease-in;
  --animate-accordion-down: accordion-down 0.2s ease-out;
  --animate-accordion-up: accordion-up 0.2s ease-out;

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
  @keyframes accordion-down {
    from { height: 0; }
    to { height: var(--radix-accordion-content-height); }
  }
  @keyframes accordion-up {
    from { height: var(--radix-accordion-content-height); }
    to { height: 0; }
  }
}

/* Container query breakpoints */
@theme {
  --container-3xs: 16rem;
  --container-2xs: 18rem;
  --container-xs: 20rem;
  --container-sm: 24rem;
  --container-md: 28rem;
  --container-lg: 32rem;
}

/* Dark mode variant */
@custom-variant dark (&:where(.dark, .dark *));

/* Base styles */
@layer base {
  * { @apply border-border; }
  body { @apply bg-background text-foreground antialiased; }
}
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

export { buttonVariants }
```

**使用例:**
```tsx
<Button variant="destructive" size="lg">Delete</Button>
<Button variant="outline">Cancel</Button>
<Button asChild><Link href="/home">Home</Link></Button>
```

### Badge（フル実装例）

```typescript
// components/ui/badge.tsx
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils'

const badgeVariants = cva(
  'inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2',
  {
    variants: {
      variant: {
        default: 'border-transparent bg-primary text-primary-foreground hover:bg-primary/80',
        secondary: 'border-transparent bg-secondary text-secondary-foreground hover:bg-secondary/80',
        destructive: 'border-transparent bg-destructive text-destructive-foreground hover:bg-destructive/80',
        outline: 'text-foreground',
      },
    },
    defaultVariants: { variant: 'default' },
  }
)

export interface BadgeProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof badgeVariants> {}

export function Badge({ className, variant, ...props }: BadgeProps) {
  return <div className={cn(badgeVariants({ variant }), className)} {...props} />
}

export { badgeVariants }
```

**使用例:**
```tsx
<Badge>Default</Badge>
<Badge variant="secondary">Draft</Badge>
<Badge variant="destructive">Expired</Badge>
<Badge variant="outline">v4.0</Badge>
```

### Alert（フル実装例）

```typescript
// components/ui/alert.tsx
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils'

const alertVariants = cva(
  'relative w-full rounded-lg border p-4 [&>svg~*]:pl-7 [&>svg+div]:translate-y-[-3px] [&>svg]:absolute [&>svg]:left-4 [&>svg]:top-4 [&>svg]:text-foreground',
  {
    variants: {
      variant: {
        default: 'bg-background text-foreground',
        destructive: 'border-destructive/50 text-destructive dark:border-destructive [&>svg]:text-destructive',
      },
    },
    defaultVariants: { variant: 'default' },
  }
)

export function Alert({
  className, variant, ref, ...props
}: React.HTMLAttributes<HTMLDivElement> & VariantProps<typeof alertVariants> & { ref?: React.Ref<HTMLDivElement> }) {
  return <div ref={ref} role="alert" className={cn(alertVariants({ variant }), className)} {...props} />
}

export function AlertTitle({ className, ref, ...props }: React.HTMLAttributes<HTMLHeadingElement> & { ref?: React.Ref<HTMLHeadingElement> }) {
  return <h5 ref={ref} className={cn('mb-1 font-medium leading-none tracking-tight', className)} {...props} />
}

export function AlertDescription({ className, ref, ...props }: React.HTMLAttributes<HTMLParagraphElement> & { ref?: React.Ref<HTMLParagraphElement> }) {
  return <div ref={ref} className={cn('text-sm [&_p]:leading-relaxed', className)} {...props} />
}
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

**使用例:**
```tsx
<Card>
  <CardHeader>
    <CardTitle>Notifications</CardTitle>
    <CardDescription>You have 3 unread messages.</CardDescription>
  </CardHeader>
  <CardContent>
    <p>Card content goes here.</p>
  </CardContent>
  <CardFooter>
    <Button>Mark all as read</Button>
  </CardFooter>
</Card>
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

type LoginFormData = z.infer<typeof schema>

function LoginForm() {
  const { register, handleSubmit, formState: { errors } } = useForm<LoginFormData>({
    resolver: zodResolver(schema),
  })

  const onSubmit = (data: LoginFormData) => {
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

## Container Query Examples

### 基本パターン: レスポンシブカードグリッド

```tsx
// コンテナクエリによるカードレイアウト
function ProductSection({ products }: { products: Product[] }) {
  return (
    <section className="@container">
      <div className="grid grid-cols-1 @sm:grid-cols-2 @lg:grid-cols-3 @xl:grid-cols-4 gap-4">
        {products.map(product => (
          <ProductCard key={product.id} product={product} />
        ))}
      </div>
    </section>
  )
}

// コンテナ幅に応じてレイアウトが変わるカード
function ProductCard({ product }: { product: Product }) {
  return (
    <div className="@container/card">
      <div className="flex flex-col @xs/card:flex-row gap-3 rounded-lg border border-border p-4">
        <img
          src={product.image}
          alt={product.name}
          className="size-full @xs/card:size-20 rounded-md object-cover"
        />
        <div className="flex flex-col gap-1">
          <h3 className="text-sm @sm/card:text-base font-semibold">{product.name}</h3>
          <p className="text-xs @sm/card:text-sm text-muted-foreground hidden @xs/card:block">
            {product.description}
          </p>
          <span className="text-sm font-bold text-primary">{product.price}</span>
        </div>
      </div>
    </div>
  )
}
```

### Named Container: サイドバー

```tsx
function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-screen">
      <aside className="@container/sidebar w-64 border-r border-border p-4">
        <nav className="flex flex-col gap-1">
          <SidebarLink icon={Home} label="Home" href="/" />
          <SidebarLink icon={Settings} label="Settings" href="/settings" />
        </nav>
        {/* サイドバー幅に応じてレイアウト変更 */}
        <div className="mt-4 hidden @md/sidebar:block">
          <QuickStats />
        </div>
      </aside>
      <main className="@container flex-1 p-6">
        {children}
      </main>
    </div>
  )
}
```

---

## @utility Collection

### レイアウト系

```css
/* 全画面中央配置 */
@utility center-screen {
  @apply flex min-h-svh items-center justify-center;
}

/* セクション間スペーシング */
@utility section-gap {
  @apply space-y-8 sm:space-y-12 lg:space-y-16;
}

/* Sticky ヘッダー */
@utility sticky-header {
  @apply sticky top-0 z-40 w-full border-b border-border bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60;
}
```

### テキスト系

```css
/* グラデーションテキスト */
@utility text-gradient {
  @apply bg-gradient-to-r from-primary to-accent bg-clip-text text-transparent;
}

/* リンクスタイル（underline on hover） */
@utility link-hover {
  @apply underline-offset-4 hover:underline text-primary transition-colors;
}
```

### ビジュアル系

```css
/* 区切り線（上部） */
@utility line-t {
  @apply relative before:absolute before:top-0 before:-left-[100vw]
         before:h-px before:w-[200vw] before:bg-gray-950/5
         dark:before:bg-white/10;
}

/* 区切り線（下部） */
@utility line-b {
  @apply relative after:absolute after:bottom-0 after:-left-[100vw]
         after:h-px after:w-[200vw] after:bg-gray-950/5
         dark:after:bg-white/10;
}

/* グラスモーフィズム */
@utility glass {
  @apply bg-white/10 backdrop-blur-md border border-white/20 shadow-lg;
}

/* スクロールバー非表示 */
@utility scrollbar-hide {
  -ms-overflow-style: none;
  scrollbar-width: none;
  &::-webkit-scrollbar { display: none; }
}

/* テキスト省略（複数行 clamp） */
@utility line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

@utility line-clamp-3 {
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
```

### インタラクション系

```css
/* プレスエフェクト */
@utility press {
  @apply transition-transform active:scale-[0.98];
}

/* フォーカスリング（共通） */
@utility focus-ring {
  @apply focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2;
}

/* ホバーカードエフェクト */
@utility hover-lift {
  @apply transition-all duration-200 hover:-translate-y-1 hover:shadow-md;
}
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

### Sheet（スライドイン）アニメーション

```css
@theme {
  --animate-sheet-in-right: sheet-slide-in-right 0.3s ease-out;
  --animate-sheet-out-right: sheet-slide-out-right 0.2s ease-in;

  @keyframes sheet-slide-in-right {
    from { transform: translateX(100%); }
    to { transform: translateX(0); }
  }
  @keyframes sheet-slide-out-right {
    from { transform: translateX(0); }
    to { transform: translateX(100%); }
  }
}
```

### Toast 通知アニメーション

```css
@theme {
  --animate-toast-in: toast-slide-in 0.3s ease-out;
  --animate-toast-out: toast-slide-out 0.2s ease-in;

  @keyframes toast-slide-in {
    from { transform: translateX(100%); opacity: 0; }
    to { transform: translateX(0); opacity: 1; }
  }
  @keyframes toast-slide-out {
    from { transform: translateX(0); opacity: 1; }
    to { transform: translateX(100%); opacity: 0; }
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

### Skeleton ローディングアニメーション

```css
@theme {
  --animate-pulse: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;

  @keyframes pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.5; }
  }
}
```

```typescript
// components/ui/skeleton.tsx
import { cn } from '@/lib/utils'

export function Skeleton({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return <div className={cn('animate-pulse rounded-md bg-muted', className)} {...props} />
}
```

### Dialog コンポーネント (Radix)

```typescript
// components/ui/dialog.tsx
import * as DialogPrimitive from '@radix-ui/react-dialog'
import { X } from 'lucide-react'
import { cn } from '@/lib/utils'

export const Dialog = DialogPrimitive.Root
export const DialogTrigger = DialogPrimitive.Trigger
export const DialogClose = DialogPrimitive.Close

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
        <DialogPrimitive.Close className="absolute right-4 top-4 rounded-sm opacity-70 ring-offset-background transition-opacity hover:opacity-100 focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2">
          <X className="size-4" />
          <span className="sr-only">Close</span>
        </DialogPrimitive.Close>
      </DialogPrimitive.Content>
    </DialogPrimitive.Portal>
  )
}

export function DialogHeader({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return <div className={cn('flex flex-col space-y-1.5 text-center sm:text-left', className)} {...props} />
}

export function DialogTitle({
  className, ref, ...props
}: React.ComponentPropsWithoutRef<typeof DialogPrimitive.Title> & { ref?: React.Ref<HTMLHeadingElement> }) {
  return <DialogPrimitive.Title ref={ref} className={cn('text-lg font-semibold leading-none tracking-tight', className)} {...props} />
}

export function DialogDescription({
  className, ref, ...props
}: React.ComponentPropsWithoutRef<typeof DialogPrimitive.Description> & { ref?: React.Ref<HTMLParagraphElement> }) {
  return <DialogPrimitive.Description ref={ref} className={cn('text-sm text-muted-foreground', className)} {...props} />
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
      aria-label="Toggle theme"
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
import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

// Focus ring utility
export const focusRing = cn(
  "focus-visible:outline-none focus-visible:ring-2",
  "focus-visible:ring-ring focus-visible:ring-offset-2",
)

// Disabled utility
export const disabled = "disabled:pointer-events-none disabled:opacity-50"
```

### extendTailwindMerge でカスタムクラスを登録

```typescript
// lib/utils.ts (extended version)
import { type ClassValue, clsx } from "clsx"
import { extendTailwindMerge } from "tailwind-merge"

const twMerge = extendTailwindMerge({
  extend: {
    classGroups: {
      // カスタム @utility のクラスグループを登録
      'custom-line': ['line-t', 'line-b'],
      'custom-glass': ['glass'],
      'custom-text': ['text-gradient'],
      // カスタムアニメーションを登録
      animate: [
        'animate-fade-in', 'animate-fade-out',
        'animate-slide-in', 'animate-slide-out',
        'animate-dialog-in', 'animate-dialog-out',
      ],
    },
  },
})

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}
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
| `@theme inline` が効かない | CSS変数が `:root` に未定義 | `:root { --var: value }` と `@theme inline { --color-var: var(--var) }` のペアを確認 |

### CVA の問題

| 症状 | 原因 | 解決策 |
|---|---|---|
| バリアントのクラスが競合する | `className` をそのまま結合 | `cn(buttonVariants({ variant, size, className }))` で `twMerge` 経由にする |
| TypeScript型エラー: `variant` が `string` | `VariantProps` 未使用 | `VariantProps<typeof buttonVariants>` を interface に追加 |
| `defaultVariants` が効かない | `cva()` の第2引数に `defaultVariants` がない | `defaultVariants: { variant: 'default', size: 'default' }` を追加 |
| compoundVariants が効かない | 条件の指定ミス | `compoundVariants: [{ variant: 'destructive', size: 'lg', class: '...' }]` を確認 |

### cn() / tailwind-merge の問題

| 症状 | 原因 | 解決策 |
|---|---|---|
| カスタムクラスが `twMerge` で消される | `twMerge` が認識しないユーティリティ | `extendTailwindMerge` でカスタムクラスを登録（上記「Utility Functions」参照） |
| `clsx` の条件分岐が動かない | falsy値の扱い | `clsx({ 'bg-red-500': hasError })` の形式を使用 |
| アニメーションクラスが消される | `animate-*` の競合 | `extendTailwindMerge` の `classGroups.animate` に登録 |

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
| `bg-opacity-50` | `bg-primary/50` | 手動 |
| `text-opacity-75` | `text-primary/75` | 手動 |
| `ring-offset-2` | `ring-offset-ring-offset/2` | 手動 |
| `space-x-4` | `gap-4` (flex/gridの場合) | 手動 |

### Step 4: 自動移行ツール

```bash
npx @tailwindcss/upgrade
```

このコマンドで自動変換されるもの:
- `@tailwind` → `@import`
- `h-X w-X` → `size-X`
- `tailwind.config.ts` の一部設定 → `@theme`

手動対応が必要なもの:
- `darkMode: "class"` → `@custom-variant dark`
- opacity modifier への変換
- カスタムプラグイン → `@utility`

---

## Cross-reference ガイド

| シナリオ | 参照先スキル | 具体的セクション |
|---|---|---|
| CVAの型パターン設計 | `typescript-best-practices` | 「VariantProps」「discriminated unions」「satisfies」 |
| app.cssの配置と読み込み | `nextjs-app-router-patterns` | 「app.css配置」「Server Componentスタイリング境界」 |
| データテーブルのスタイリング | `dashboard-data-viz` | 「TanStack Table + Tailwindスタイリング」 |
| コンポーネントの分割設計 | `react-component-patterns` | 「Compound Components」「asChildパターン」 |
| ボタン・フォームの心理学 | `ux-psychology` | 「CTA配置」「フォームの認知負荷」 |
| トークン値の決定 | `design-token-system` | 「OKLCH色設計」「スペーシングスケール」「コントラスト比」 |
| LIFF内レスポンシブ | `mobile-first-responsive` | 「safe-area-inset」「WebView制約」「svh/dvh」 |
| アニメーション設計 | `micro-interaction-patterns` | 「Framer Motion連携」「状態遷移」「loading states」 |
| セマンティックHTML | `web-design-guidelines` | 「aria属性」「ランドマーク」「フォーカス管理」 |
