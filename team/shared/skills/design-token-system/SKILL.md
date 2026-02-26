---
name: design-token-system
description: Design token architecture for Tailwind CSS v4 + Next.js + shadcn/ui. Covers 3-tier hierarchy (primitive/semantic/component), OKLCH color with accessible contrast (L-value diff >= 0.40), typography modular scale, spacing grid, shadow/z-index tokens, dark mode with FOUC prevention, animation tokens, border-radius/focus-ring tokens, and globals.css @theme inline structure. Use when defining color palettes, building theme systems, creating dark mode, setting up globals.css tokens, designing typography scales, configuring spacing, integrating tokens with shadcn/ui, customizing semantic CSS variables, or establishing OKLCH accessible contrast. Does NOT cover Tailwind utility usage (tailwind-design-system), component patterns (react-component-patterns), or WCAG accessibility (web-design-guidelines).
user-invocable: false
---

# Design Token System

Tailwind CSS v4 + Next.js + shadcn/ui 環境での**デザイントークンの定義・構造・値**に特化した実装ガイド。Tailwind ユーティリティの使い方やコンポーネント設計は扱わない（それらは tailwind-design-system / react-component-patterns を参照）。

## When to Apply

- カラーパレット/カラーシステムの設計（OKLCH、アクセシビリティ対応）
- globals.css のトークン構造設計（:root + @theme inline）
- ダークモード実装（FOUC 防止、system + manual ハイブリッド）
- タイポグラフィスケール設計（モジュラースケール、clamp()）
- スペーシング/サイジング/ボーダー半径トークンの設計
- アニメーション duration / easing / keyframe トークンの定義
- shadcn/ui テーマのカスタマイズ・拡張（セマンティックカラー追加）

## When NOT to Apply

- **Tailwind ユーティリティクラスの使い方・CVA バリアント** → tailwind-design-system
- **コンポーネント設計・合成パターン・CVA 統合** → react-component-patterns
- **WCAG 準拠・セマンティック HTML・aria 属性** → web-design-guidelines
- **アニメーション実装・Framer Motion・状態遷移** → micro-interaction-patterns
- **色彩心理学・認知バイアス・UX 原則** → ux-psychology

---

## Part 1: Token Architecture [CRITICAL]

### 3-Tier Token Hierarchy

```
Tier 1: Primitive Tokens（生値）
  色: oklch(0.65 0.18 250)  → --primitive-blue-500
  サイズ: 0.25rem           → --primitive-space-1

Tier 2: Semantic Tokens（意味付き）
  --color-primary            → var(--primitive-blue-500)
  --color-destructive        → var(--primitive-red-500)

Tier 3: Component Tokens（コンポーネント固有）
  --button-bg                → var(--color-primary)
  --card-border              → var(--color-border)
```

### Tailwind v4 での実装パターン

`:root` にセマンティック変数を定義し、`@theme inline` で Tailwind ユーティリティに接続する。

```css
/* globals.css - 構造の骨格 */
@import "tailwindcss";

@custom-variant dark (&:where(.dark, .dark *));

:root {
  --background: oklch(1 0 0);
  --foreground: oklch(0.145 0 0);
  --primary: oklch(0.205 0 0);
  --primary-foreground: oklch(0.985 0 0);
  /* ... 他のセマンティック変数 */
  --radius: 0.625rem;
}

.dark {
  --background: oklch(0.145 0 0);
  --foreground: oklch(0.985 0 0);
  --primary: oklch(0.985 0 0);
  --primary-foreground: oklch(0.205 0 0);
  /* ... ダークモード値 */
}

@theme inline {
  --color-background: var(--background);
  --color-foreground: var(--foreground);
  --color-primary: var(--primary);
  --color-primary-foreground: var(--primary-foreground);
  /* ... Tailwind ユーティリティへの橋渡し */
  --radius-lg: var(--radius);
}

@layer base {
  * { @apply border-border; }
  body { @apply bg-background text-foreground; }
}
```

> 完全な globals.css テンプレート（全変数・light/dark 両方）は [reference.md](reference.md) セクション H を参照。

### @theme vs :root の使い分け

| 定義場所 | 用途 | ユーティリティ生成 |
|---------|------|----------------|
| `@theme { }` | Tailwind と直結するトークン | される |
| `@theme inline { }` | 他の CSS 変数を参照するトークン | される（インライン展開） |
| `:root { }` | テーマ切替用の変数（light/dark） | されない |

**原則**: `:root` / `.dark` にセマンティック変数 → `@theme inline` で Tailwind に橋渡し。

---

## Part 2: Color System [CRITICAL]

### なぜ OKLCH か

- **知覚的均一性**: L（明度）の変化が人間の目に均一
- **コントラスト予測可能**: L 値の差でコントラスト比を予測できる
- **Wide Gamut 対応**: P3 ディスプレイの色域をフルに使える
- **HSL の問題**: 彩度や明度の知覚が不均一

### OKLCH 構造

```
oklch(L C H)
  L = Lightness  (0〜1)    0=黒, 1=白
  C = Chroma     (0〜0.4)  0=グレー, 高い=鮮やか
  H = Hue        (0〜360)  色相角度
```

### カラースケール生成の原則

**同一 Hue + Chroma で Lightness を変化**させ、知覚的に均一なスケールを作る。50→950 で L を 0.97→0.22 に段階的に下げ、中間（500）で C を最大にする。

> カラースケール生成例・Hue 参考値表は [reference.md](reference.md) セクション A を参照。

### アクセシブルコントラスト

WCAG AA 基準: テキスト 4.5:1、大テキスト 3:1。

**ルール: foreground と background の L 値の差を 0.40 以上にする。**

L 値の差とコントラスト比の対応表、ライト/ダークモードの L 値ペア例は [reference.md](reference.md) セクション B を参照。

### セマンティックカラー追加

shadcn/ui にない色（success, warning, info 等）の追加手順:

```css
/* 1. :root と .dark に変数追加 */
:root { --success: oklch(0.62 0.17 145); --success-foreground: oklch(0.985 0.01 145); }
.dark { --success: oklch(0.52 0.14 145); --success-foreground: oklch(0.95 0.02 145); }

/* 2. @theme inline で接続 → bg-success, text-success-foreground が使える */
@theme inline { --color-success: var(--success); --color-success-foreground: var(--success-foreground); }
```

> 全 Status Colors 定義・Chart カラー・color-mix() パターンは [reference.md](reference.md) セクション C を参照。

---

## Part 3: Typography Tokens [HIGH]

### モジュラースケール

比率ベース（Major Third = 1.25）でフォントサイズを決定し、一貫したリズムを作る。

```css
@theme {
  /* Base: 16px, Ratio: 1.25 (Major Third) */
  --text-xs: 0.64rem;      /* 10.24px */
  --text-sm: 0.8rem;       /* 12.8px */
  --text-base: 1rem;       /* 16px */
  --text-lg: 1.25rem;      /* 20px */
  --text-xl: 1.563rem;     /* 25px */
  --text-2xl: 1.953rem;    /* 31.25px */
  --text-3xl: 2.441rem;    /* 39.06px */
  --text-4xl: 3.052rem;    /* 48.83px */
}
```

**ルール**: フォントサイズが大きいほど行間を狭くする（本文 1.5 → 大見出し 1.0）。clamp() でビューポート幅に応じた流動サイズも設定可能。

> Line-Height ペアリング表・clamp() 定義・font-display 設定は [reference.md](reference.md) セクション D を参照。

---

## Part 4: Spacing, Sizing & Shape Tokens [MEDIUM]

### Tailwind v4 のスペーシングシステム

v4 では `--spacing: 0.25rem` がベース。数値 * 0.25rem で自動計算。

```css
@theme {
  --spacing: 0.25rem;  /* 4px base grid */
  /* p-1=4px, p-2=8px, p-4=16px, p-8=32px */
  /* v4 では p-21 のような任意の数値も使える */
}
```

8px ベースにしたい場合は `--spacing: 0.5rem` に変更。

### Border-Radius トークン

shadcn/ui は `--radius` をベースに全段階を `calc()` で導出する。値を 1 箇所変えるだけで全体のシェイプが統一される。

```css
:root { --radius: 0.625rem; }   /* 10px - デフォルト */
/* 角丸を強くしたいなら 0.75rem、角張らせるなら 0.375rem に変更 */

@theme inline {
  --radius-sm: calc(var(--radius) - 0.25rem);   /* 6px */
  --radius-md: calc(var(--radius) - 0.125rem);  /* 8px */
  --radius-lg: var(--radius);                    /* 10px */
  --radius-xl: calc(var(--radius) + 0.25rem);    /* 14px */
}
```

### Shadow, Z-Index & Focus Ring トークン

```css
@theme {
  --shadow-sm: 0 1px 2px oklch(0 0 0 / 0.05);
  --shadow-md: 0 4px 6px oklch(0 0 0 / 0.07);
  --shadow-lg: 0 10px 15px oklch(0 0 0 / 0.1);

  --z-dropdown: 50;
  --z-sticky: 100;
  --z-overlay: 200;
  --z-modal: 300;
  --z-toast: 400;
}
```

**Focus Ring**: `--ring` 変数でフォーカスリング色をテーマ連動させる。

```css
:root { --ring: oklch(0.708 0 0); }
.dark { --ring: oklch(0.556 0 0); }
@theme inline { --color-ring: var(--ring); }
/* 使用: focus-visible:ring-2 ring-ring ring-offset-2 */
```

> コンテナ幅トークン・ブレークポイントトークンの完全定義は [reference.md](reference.md) セクション E を参照。

---

## Part 5: Dark Mode Implementation [CRITICAL]

### FOUC（Flash of Unstyled Content）防止

ダークモードで最も重要な課題。**ページ描画前にテーマを適用する**。

**next-themes 使用時（推奨）**: next-themes が自動で FOUC 防止スクリプトを挿入するため、手動スクリプトは不要。`suppressHydrationWarning` だけ付ける。

**next-themes 不使用時**: 手動でインラインスクリプトを `<head>` に挿入する。

```tsx
// app/layout.tsx - next-themes 使用時
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ja" suppressHydrationWarning>
      <body>
        <ThemeProvider>{children}</ThemeProvider>
      </body>
    </html>
  );
}
```

### next-themes 統合

```tsx
// providers/theme-provider.tsx
'use client';
import { ThemeProvider as NextThemesProvider } from 'next-themes';

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  return (
    <NextThemesProvider
      attribute="class"         // .dark クラスを html に付与
      defaultTheme="system"     // 初期値はシステム設定
      enableSystem              // prefers-color-scheme を監視
      disableTransitionOnChange // テーマ切替時のちらつき防止
    >
      {children}
    </NextThemesProvider>
  );
}
```

### CSS 側の設定

```css
@custom-variant dark (&:where(.dark, .dark *));
```

この 1 行で `dark:bg-background` 等の Tailwind v4 ダークモードユーティリティが有効になる。

---

## Part 6: Animation Tokens [MEDIUM]

### Duration & Easing スケール

```css
@theme {
  /* Duration */
  --duration-fast: 100ms;     /* hover/focus */
  --duration-normal: 200ms;   /* 標準 */
  --duration-slow: 300ms;     /* パネル開閉 */
  --duration-slower: 500ms;   /* ページ遷移 */

  /* Easing */
  --ease-default: cubic-bezier(0.4, 0, 0.2, 1);   /* 汎用 */
  --ease-out: cubic-bezier(0, 0, 0.2, 1);          /* 登場 */
  --ease-in: cubic-bezier(0.4, 0, 1, 1);           /* 退場 */
  --ease-bounce: cubic-bezier(0.34, 1.56, 0.64, 1); /* 弾む */
}
```

### prefers-reduced-motion 対応

```css
@layer base {
  @media (prefers-reduced-motion: reduce) {
    *, *::before, *::after {
      animation-duration: 0.01ms !important;
      transition-duration: 0.01ms !important;
    }
  }
}
```

Tailwind: `motion-safe:animate-fade-in motion-reduce:opacity-100`

> カスタムキーフレーム定義・用途ガイドは [reference.md](reference.md) セクション F を参照。

---

## Part 7: shadcn/ui テーマ統合 [HIGH]

### カラー追加の 2 ステップ

1. `:root` / `.dark` に CSS 変数を追加
2. `@theme inline` で `--color-{name}` にマッピング → ユーティリティ自動生成

### components.json（Tailwind v4）

- `"config": ""` （空文字 - tailwind.config.ts 不要）
- `"style": "new-york"` が推奨（shadcn/ui 最新デフォルト）
- `"rsc": true` で React Server Components 対応

> components.json テンプレート・Chart カラー定義は [reference.md](reference.md) セクション G を参照。

---

## Quick Reference: globals.css 構成順序 [HIGH]

```
1. @import "tailwindcss"
2. @import "tw-animate-css"              (optional)
3. @custom-variant dark (...)
4. :root { セマンティック変数 }
5. .dark { ダークモード変数 }
6. @theme inline { Tailwind ブリッジ }
7. @theme { 直接定義トークン }           (spacing, font, animation)
8. @layer base { グローバルスタイル }
```

> 完全な globals.css テンプレート・チェックリスト・アンチパターン集は [reference.md](reference.md) セクション H, I を参照。

---

## Cross-References [MEDIUM]

このスキルのトークン定義を、他スキルの知見と組み合わせると効果的な場面:

- **ux-psychology**: 色彩心理学（信頼=青 H:250、危険=赤 H:25）をトークンの Hue 選定に活用。警告色の L 値設計に認知バイアスの知見を適用
- **web-design-guidelines**: WCAG 2.2 のコントラスト比計算式でトークンの L 値の差を検証。トークンで定義した値が AA/AAA 基準を満たすか最終チェック
- **react-component-patterns**: CVA バリアントの `className` にトークンベースのユーティリティ（`bg-primary`, `text-destructive`）を使い、テーマ対応コンポーネントを実現
- **dashboard-data-viz**: Chart カラートークン（セクション C）を Recharts/Tremor のカラーパレットとして連携。データ可視化のアクセシビリティに L 値の差を適用
- **mobile-first-responsive**: clamp() fluid typography トークン（セクション D）をモバイルビューポートに適用。LIFF の制約下でも読みやすいサイズを維持
- **micro-interaction-patterns**: duration/easing トークン（Part 6）を Framer Motion の transition 設定に統一値として使用
