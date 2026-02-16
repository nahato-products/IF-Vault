---
name: tailwind-design-system
description: "Use when building Tailwind CSS v4 design systems with CSS-first @theme configuration, CVA component variants, responsive grid patterns, dark mode via @custom-variant, custom @utility directives, container queries, CSS animations with @starting-style, or migrating from Tailwind v3 to v4. Also use when integrating shadcn/ui with Tailwind v4, composing container-query layouts, defining semantic color tokens in @theme inline, or standardizing component variant architecture with class-variance-authority. Does NOT cover: OKLCH color/spacing token values (design-token-system), React component design (react-component-patterns), LIFF/PWA responsive (mobile-first-responsive)."
user-invocable: false
---

# Tailwind Design System

[CRITICAL] Tailwind CSS v4のCSS-firstユーティリティ設計・コンポーネントバリアント・マイグレーションガイド。トークン値の定義・色設計は `design-token-system` が担当。本スキルはTailwindユーティリティの使い方とコンポーネント構築に特化。

> 関連スキル:
> - `design-token-system`「OKLCH色設計」「globals.css構造」「スペーシングスケール」
> - `react-component-patterns`「Compound Components」「asChild パターン」「Server/Client境界」
> - `mobile-first-responsive`「safe-area-inset」「LIFF WebView制約」「svh/dvh」
> - `micro-interaction-patterns`「Framer Motion連携」「状態遷移」「loading states」
> - `web-design-guidelines`「WCAG準拠」「セマンティックHTML」「aria属性」
> - `typescript-best-practices`「VariantProps型設計」「discriminated unions」「satisfies」
> - `nextjs-app-router-patterns`「app.css配置」「Server Componentスタイリング境界」
> - `dashboard-data-viz`「TanStack Table + Tailwindスタイリング」

## [CRITICAL] When to Use

- Tailwind v4のCSS-first設定（`@theme`, `@import "tailwindcss"`）
- CVAでバリアント付きコンポーネント構築
- v3からv4へのマイグレーション
- ダークモード実装（`@custom-variant` + `.dark` クラス）
- カスタムユーティリティ（`@utility`）作成
- レスポンシブグリッド / コンテナクエリ
- CSS animations（`@keyframes` + `@starting-style`）
- shadcn/ui コンポーネントのカスタマイズ

## [CRITICAL] When NOT to Apply

- トークン値の設計（OKLCH色、スペーシング、タイポグラフィスケール） → `design-token-system`「トークン値定義」
- globals.css の構造設計（:root / .dark / @theme inline の値定義） → `design-token-system`「globals.css構造」
- React コンポーネント設計全般（Tailwind非依存） → `react-component-patterns`「コンポーネント分類」
- LIFF/PWA特有のレスポンシブ対応 → `mobile-first-responsive`「WebView制約」
- WCAG準拠・セマンティックHTML・aria属性 → `web-design-guidelines`「アクセシビリティ」
- アニメーション/マイクロインタラクション中心 → `micro-interaction-patterns`「状態遷移」
- Tailwind v3プロジェクト（v4移行しない場合） → 公式v3ドキュメント参照

## [CRITICAL] v3 → v4 Migration Map

| v3 | v4 | 備考 |
|---|---|---|
| `tailwind.config.ts` | `@theme` in CSS | JS設定ファイル不要 |
| `@tailwind base/components/utilities` | `@import "tailwindcss"` | 1行インポート |
| `darkMode: "class"` | `@custom-variant dark (&:where(.dark, .dark *))` | CSS定義 |
| `theme.extend.colors` | `@theme { --color-*: value }` | CSS変数ベース |
| `require("tailwindcss-animate")` | ネイティブ `@keyframes` + `@starting-style` | プラグイン不要 |
| `h-10 w-10` | `size-10` | ショートハンド |
| `forwardRef` | React 19: `ref` is a prop | ラッパー不要 |
| Custom plugins | `@utility` directive | CSSネイティブ |
| `bg-opacity-50` | `bg-primary/50` | modifier構文 |
| `space-x-4` | `gap-4` (flex/grid内) | gap推奨 |

## [CRITICAL] CSS-First Configuration Rules

v4ではテーマ設定をCSSの `@theme` ブロックで行う。`tailwind.config.ts` は不要。

```css
@import "tailwindcss";

@theme {
  --color-primary: oklch(45% 0.2 260);
  --animate-fade-in: fade-in 0.2s ease-out;
  @keyframes fade-in {
    from { opacity: 0; }
    to { opacity: 1; }
  }
}

@custom-variant dark (&:where(.dark, .dark *));
```

### @theme Modifiers

| Modifier | 用途 | 使い分け |
|---|---|---|
| `@theme { }` | 直接値を定義 | 固定トークン（spacing, animation） |
| `@theme inline { }` | 他のCSS変数を参照 | `:root`/`.dark`で切替えるセマンティックトークン |
| `@theme static { }` | 未使用でもCSS変数を出力 | 外部JS参照が必要な場合 |

**原則**: `:root`/`.dark` にセマンティック変数を定義 → `@theme inline` で Tailwind ユーティリティに橋渡し。値の設計は `design-token-system`「トークン値定義」を参照。

### @theme inline パターン

```css
:root {
  --background: oklch(100% 0 0);
  --foreground: oklch(14.5% 0.025 264);
}
.dark {
  --background: oklch(14.5% 0.025 264);
  --foreground: oklch(98% 0.01 264);
}

@theme inline {
  --color-background: var(--background);
  --color-foreground: var(--foreground);
}
```

### Namespace Override（デフォルトリセット）

```css
@theme {
  --color-*: initial;  /* デフォルトカラーをクリア */
  --color-primary: oklch(45% 0.2 260);
  --color-secondary: oklch(96% 0.01 264);
}
```

`initial` でTailwindのデフォルトパレットをリセットし、プロジェクト固有のカラーだけ定義する。

## [CRITICAL] CVA Component Rules

### Pattern Selection

| コンポーネント種別 | パターン | 例 |
|---|---|---|
| バリアント付き | CVA + `cn()` | Button, Badge, Alert |
| 複合コンポーネント | Compound Components | Card, Dialog, Tabs |
| フォーム入力 | CVA + aria + error state | Input, Label, Select |
| レイアウト | Grid/Container CVA | Grid, Container |

### CVA Build Flow

```
Base styles → Variants → Sizes → States → Overrides
                                           ↑ cn() でマージ
```

### CVA 必須ルール

1. **`cn()` で必ずマージ**: `cn(variants({ variant, size, className }))` — 文字列結合禁止
2. **`defaultVariants` を必ず設定**: 未指定時のフォールバック
3. **`VariantProps<typeof xxxVariants>` を型に含める**: 型安全バリアント
4. **React 19: `forwardRef` 不要**: `ref` はpropsで直接受け取る
5. **`asChild` + Radix `Slot`**: ポリモーフィックレンダリング用

### CVA Button パターン（構造）

```typescript
const buttonVariants = cva(
  // base: 共通スタイル（layout, typography, focus, disabled）
  'inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50',
  {
    variants: {
      variant: {
        default: 'bg-primary text-primary-foreground hover:bg-primary/90',
        destructive: 'bg-destructive text-destructive-foreground hover:bg-destructive/90',
        outline: 'border border-border bg-background hover:bg-accent',
        ghost: 'hover:bg-accent hover:text-accent-foreground',
        link: 'text-primary underline-offset-4 hover:underline',
      },
      size: {
        default: 'h-10 px-4 py-2',
        sm: 'h-9 px-3',
        lg: 'h-11 px-8',
        icon: 'size-10',
      },
    },
    defaultVariants: { variant: 'default', size: 'default' },
  }
)
```

### CVA Badge パターン（構造）

```typescript
const badgeVariants = cva(
  'inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors',
  {
    variants: {
      variant: {
        default: 'border-transparent bg-primary text-primary-foreground',
        secondary: 'border-transparent bg-secondary text-secondary-foreground',
        destructive: 'border-transparent bg-destructive text-destructive-foreground',
        outline: 'text-foreground',
      },
    },
    defaultVariants: { variant: 'default' },
  }
)
```

→ reference.md「CVAコンポーネント」にフル実装例あり

### Compound Component ルール

- 各サブコンポーネントは独立した関数でexport
- `cn()` で `className` を受け取り、デフォルトスタイルとマージ
- 名前規則: `Card`, `CardHeader`, `CardTitle`, `CardContent`, `CardFooter`

→ reference.md「Compound Components」にCard完全実装あり

## [CRITICAL] CSS Animations Rules

### @keyframes 配置ルール

- `@keyframes` は `@theme {}` ブロック **内** に配置する
- `--animate-*` カスタムプロパティで参照名を定義
- v3の `tailwindcss-animate` は不要 — ネイティブCSS animation で代替

### Radix data属性との連携

```css
/* Radix の state 属性で出入りを制御 */
.data-[state=open]:animate-fade-in
.data-[state=closed]:animate-fade-out
.data-[state=open]:animate-dialog-in
.data-[state=closed]:animate-dialog-out
```

### @starting-style によるエントリーアニメーション

`@starting-style` はネイティブCSSのエントリーアニメーション。`display: none` → 表示時のトランジションに使用。

```css
[popover] {
  transition: opacity 0.2s, transform 0.2s, display 0.2s allow-discrete;
  opacity: 1; transform: scale(1);
}
[popover]:not(:popover-open) {
  opacity: 0; transform: scale(0.95);
}
@starting-style {
  [popover]:popover-open {
    opacity: 0; transform: scale(0.95);
  }
}
```

### Animation 命名規則

| 名前 | 用途 | duration |
|---|---|---|
| `fade-in` / `fade-out` | オーバーレイ、汎用 | 0.2s |
| `slide-in` / `slide-out` | ドロップダウン、通知 | 0.3s |
| `dialog-fade-in` / `dialog-fade-out` | モーダル | 0.2s / 0.15s |
| `accordion-down` / `accordion-up` | アコーディオン | 0.2s |
| `spin` | ローディング | 1s linear infinite |

→ reference.md「CSS Animations」に完全CSS例あり

## [HIGH] Custom Utilities (`@utility`)

`@utility` はv3のカスタムプラグインの代替。CSSファイル内に直接定義でき、Tailwindのツリーシェイクの対象になる。

### @utility 定義ルール

1. 名前はkebab-case: `@utility my-utility { }`
2. `@apply` で既存ユーティリティを組み合わせ可能
3. 疑似要素、メディアクエリも使用可能
4. 自動的にツリーシェイクされる（未使用クラスはビルドに含まれない）

### 実用 @utility 例

```css
/* 区切り線ユーティリティ */
@utility line-t {
  @apply relative before:absolute before:top-0 before:-left-[100vw]
         before:h-px before:w-[200vw] before:bg-gray-950/5
         dark:before:bg-white/10;
}

/* テキスト省略（1行） */
@utility truncate-line {
  @apply overflow-hidden text-ellipsis whitespace-nowrap;
}

/* テキスト省略（複数行 - CSS clamp） */
@utility line-clamp-3 {
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* スクロールバー非表示 */
@utility scrollbar-hide {
  -ms-overflow-style: none;
  scrollbar-width: none;
  &::-webkit-scrollbar { display: none; }
}

/* グラスモーフィズム */
@utility glass {
  @apply bg-white/10 backdrop-blur-md border border-white/20;
}
```

→ reference.md「@utility Collection」に追加例あり

## [HIGH] Container Queries

### 基本設定

```css
@theme {
  --container-3xs: 16rem;
  --container-2xs: 18rem;
  --container-xs: 20rem;
  --container-sm: 24rem;
  --container-md: 28rem;
  --container-lg: 32rem;
}
```

### Container Query ルール

1. 親要素に `@container` を指定: HTMLで `class="@container"` を付与
2. 子要素で `@sm:`, `@md:` 等のコンテナブレークポイントを使用
3. ビューポートではなくコンテナ幅で判断するため、再利用可能なコンポーネント向き
4. Named container: `@container/sidebar` で名前付きコンテナ

### Container Query 使用パターン

```tsx
{/* 親: コンテナ定義 */}
<div className="@container">
  {/* 子: コンテナ幅に応じたレスポンシブ */}
  <div className="grid grid-cols-1 @sm:grid-cols-2 @lg:grid-cols-3 gap-4">
    {items.map(item => <Card key={item.id} {...item} />)}
  </div>
</div>

{/* Named container */}
<aside className="@container/sidebar">
  <nav className="flex flex-col @sm/sidebar:flex-row gap-2">
    {links.map(link => <NavLink key={link.href} {...link} />)}
  </nav>
</aside>
```

### Container vs Viewport

| 判断基準 | Container Query | Viewport Query |
|---|---|---|
| コンポーネント再利用 | `@container` + `@sm:` | - |
| ページレイアウト | - | `sm:` `md:` `lg:` |
| サイドバー内コンテンツ | `@container` | - |
| トップレベルGrid | - | `sm:grid-cols-2` |

## [HIGH] Semi-transparent Variants

```css
@theme {
  --color-primary-50: color-mix(in oklab, var(--color-primary) 5%, transparent);
  --color-primary-100: color-mix(in oklab, var(--color-primary) 10%, transparent);
  --color-primary-200: color-mix(in oklab, var(--color-primary) 20%, transparent);
}
```

`color-mix()` でベースカラーからアルファバリアントを動的生成。ホバー状態やオーバーレイに活用。なお、Tailwindの `bg-primary/50` modifier構文でも同様の効果が得られる。

## [HIGH] Dark Mode Rules

### CSS設定

```css
@custom-variant dark (&:where(.dark, .dark *));
```

### 実装ルール

1. **`@custom-variant` を app.css に1回だけ定義**
2. **`<html>` に `.dark` クラスをトグル** — `ThemeProvider` で管理
3. **セマンティックトークンを使う**: `bg-background` > `bg-white dark:bg-gray-900`
4. **`@theme inline` + `:root`/`.dark` パターンで自動切替え**
5. **meta[name="theme-color"] も同期** — モバイルブラウザのステータスバー対応

→ reference.md「Dark Mode」にThemeProvider完全実装あり

## [HIGH] cn() Utility Rules

```typescript
import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}
```

### cn() 使用ルール

1. **コンポーネントの `className` は必ず `cn()` 経由でマージ**
2. **条件付きクラス**: `cn('base', isActive && 'bg-primary', className)`
3. **オブジェクト形式**: `cn('base', { 'bg-red-500': hasError })`
4. **カスタムクラスが消える場合**: `extendTailwindMerge` で登録

→ reference.md「Utility Functions」に `extendTailwindMerge` 例あり

## [HIGH] Form Component Rules

### 必須パターン

1. **`aria-invalid`**: エラー時に `aria-invalid={!!error}` を設定
2. **`aria-describedby`**: エラーメッセージとinputを紐付け
3. **`role="alert"`**: エラーメッセージに設定
4. **disabled state**: `disabled:cursor-not-allowed disabled:opacity-50`
5. **focus ring**: `focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring`

### エラー状態のクラス切替

```typescript
cn(
  'border border-border bg-background ...',
  error && 'border-destructive focus-visible:ring-destructive',
  className
)
```

→ reference.md「Form Components」にInput/Label/RHF連携の完全実装あり

## [HIGH] v3 → v4 Migration Checklist

- [ ] `tailwind.config.ts` → CSS `@theme` ブロックへ
- [ ] `@tailwind base/components/utilities` → `@import "tailwindcss"`
- [ ] カラー定義を `@theme { --color-*: value }` へ
- [ ] `darkMode: "class"` → `@custom-variant dark`
- [ ] `@keyframes` を `@theme` 内へ
- [ ] `tailwindcss-animate` → ネイティブCSS animations
- [ ] `h-10 w-10` → `size-10`
- [ ] `bg-opacity-50` → `bg-primary/50`
- [ ] `space-x-4` → `gap-4` (flex/grid内)
- [ ] `forwardRef` 削除（React 19）
- [ ] カスタムプラグイン → `@utility`
- [ ] `npx @tailwindcss/upgrade` で自動移行を実行

→ reference.md「v3 → v4 Migration 詳細手順」にBefore/After対比あり

## [MEDIUM] Grid / Layout CVA Rules

### Grid CVA パターン

- `cols` バリアント: レスポンシブブレークポイント付きの列数
- `gap` バリアント: spacing scale に対応
- `Container` + `Grid` の組み合わせでページレイアウト

```tsx
<Container size="xl">
  <Grid cols={4} gap="lg">
    {items.map(item => <ItemCard key={item.id} {...item} />)}
  </Grid>
</Container>
```

→ reference.md「Grid System」にGrid/Container CVA完全実装あり

## [MEDIUM] Best Practices

### Do

- `@theme` ブロックでCSS-first設定
- CVA + TypeScript で型安全バリアント
- セマンティックトークン（`bg-primary` > `bg-blue-500`）
- `size-*` ショートハンド（`size-10` > `h-10 w-10`）
- ARIA属性・フォーカス管理（`web-design-guidelines`「アクセシビリティ」参照）
- `cn()` でクラスの安全なマージ
- コンテナクエリで再利用可能なコンポーネント

### Don't

- `tailwind.config.ts` を使う（→ `@theme`）
- `@tailwind` ディレクティブを使う（→ `@import "tailwindcss"`）
- `forwardRef` を使う（React 19ではrefはprop）
- arbitrary values多用（→ `@theme` にトークン追加）
- ハードコードカラー（→ セマンティックトークン）
- `className` の文字列結合（→ `cn()` を使う）
- `tailwindcss-animate` を入れる（→ ネイティブ `@keyframes`）
- ビューポートクエリで再利用コンポーネント（→ `@container`）

## [MEDIUM] Troubleshooting Quick Reference

| 症状 | 原因 | 解決策 |
|---|---|---|
| `@theme` 変数が効かない | `@import "tailwindcss"` 欠落 | ファイル先頭に追加 |
| ダークモード切替不可 | `@custom-variant` 未定義 | `@custom-variant dark (...)` 追加 |
| `animate-*` 動かない | `@keyframes` が `@theme` 外 | `@theme {}` 内へ移動 |
| v3プラグイン読込不可 | `require()` 非対応 | `@utility` で書き直す |
| CVAクラス競合 | 文字列結合 | `cn(variants({...}))` で解決 |
| カスタムクラス消失 | `twMerge` 未認識 | `extendTailwindMerge` で登録 |

→ reference.md「Troubleshooting」に詳細な原因・解決策テーブルあり

## [MEDIUM] Resources

- [Tailwind CSS v4 Docs](https://tailwindcss.com/docs)
- [CVA (class-variance-authority)](https://cva.style/docs)
- [shadcn/ui](https://ui.shadcn.com/)
- [Radix Primitives](https://www.radix-ui.com/primitives)
- [Tailwind Merge](https://github.com/dcastil/tailwind-merge)
