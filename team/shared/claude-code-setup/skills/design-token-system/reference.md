# Design Token System Reference

SKILL.md の補足: 完全なトークン値テーブル、コード例、チェックリスト集。

---

## A. OKLCH カラースケール生成例

### Blue Scale (H=250)

```css
:root {
  --blue-50:  oklch(0.97 0.01 250);
  --blue-100: oklch(0.93 0.03 250);
  --blue-200: oklch(0.87 0.06 250);
  --blue-300: oklch(0.79 0.10 250);
  --blue-400: oklch(0.70 0.14 250);
  --blue-500: oklch(0.62 0.18 250);  /* Base */
  --blue-600: oklch(0.54 0.18 250);
  --blue-700: oklch(0.46 0.16 250);
  --blue-800: oklch(0.38 0.13 250);
  --blue-900: oklch(0.30 0.10 250);
  --blue-950: oklch(0.22 0.07 250);
}
```

### Hue 参考値

| Color | Hue (H) | Base Chroma |
|-------|---------|-------------|
| Red | 25-30 | 0.20-0.25 |
| Orange | 55-65 | 0.18-0.22 |
| Yellow | 85-95 | 0.15-0.18 |
| Green | 140-150 | 0.15-0.18 |
| Teal | 180-190 | 0.10-0.14 |
| Blue | 245-255 | 0.16-0.20 |
| Purple | 290-300 | 0.15-0.20 |
| Pink | 340-350 | 0.18-0.22 |

### スケール生成ルール

1. 50 → 950 で L を 0.97 → 0.22 に段階的に下げる
2. 中間（500）を Base とし、C（彩度）を最大にする
3. 端に近づくほど C を下げる（50 は C≈0.01、950 は C≈0.07）
4. 同一スケール内で H は固定（微調整は ±2 程度）

---

## B. アクセシブルコントラスト計算

### L 値の差とコントラスト比の目安

| L 値の差 | 概算コントラスト比 | WCAG レベル |
|---------|-----------------|------------|
| 0.80+ | 10:1 以上 | AAA (通常テキスト) |
| 0.60-0.79 | 7:1 前後 | AAA (通常テキスト) |
| 0.40-0.59 | 4.5:1 前後 | AA (通常テキスト) |
| 0.30-0.39 | 3:1 前後 | AA (大テキスト/UI) |
| < 0.30 | 3:1 未満 | 不合格 |

> L値差はあくまで簡易指標。正式なWCAG AA準拠の判定には必ずコントラスト比計算ツール（Chrome DevTools, axe等）を使用すること。

### ライト/ダークモード L 値ペア例

```css
/* Light mode */
:root {
  --background: oklch(1 0 0);          /* L=1.0 */
  --foreground: oklch(0.145 0 0);      /* L=0.145, 差=0.855 */
  --muted-foreground: oklch(0.556 0 0); /* L=0.556, 差=0.444 */
}

/* Dark mode */
.dark {
  --background: oklch(0.145 0 0);      /* L=0.145 */
  --foreground: oklch(0.985 0 0);      /* L=0.985, 差=0.840 */
  --muted-foreground: oklch(0.708 0 0); /* L=0.708, 差=0.563 */
}
```

---

## C. セマンティックカラー完全定義

### Status Colors（light + dark）

```css
:root {
  --success: oklch(0.62 0.17 145);
  --success-foreground: oklch(0.985 0.01 145);
  --warning: oklch(0.80 0.15 85);
  --warning-foreground: oklch(0.25 0.05 85);
  --error: oklch(0.577 0.245 27);
  --error-foreground: oklch(0.985 0 0);
  --info: oklch(0.62 0.14 250);
  --info-foreground: oklch(0.985 0.01 250);
}

.dark {
  --success: oklch(0.52 0.14 145);
  --success-foreground: oklch(0.95 0.02 145);
  --warning: oklch(0.70 0.13 85);
  --warning-foreground: oklch(0.20 0.04 85);
  --error: oklch(0.45 0.18 27);
  --error-foreground: oklch(0.95 0 0);
  --info: oklch(0.52 0.12 250);
  --info-foreground: oklch(0.95 0.01 250);
}

@theme inline {
  --color-success: var(--success);
  --color-success-foreground: var(--success-foreground);
  --color-warning: var(--warning);
  --color-warning-foreground: var(--warning-foreground);
  --color-error: var(--error);
  --color-error-foreground: var(--error-foreground);
  --color-info: var(--info);
  --color-info-foreground: var(--info-foreground);
}
```

### color-mix() アルファバリアント

```css
@theme {
  --color-primary-5: color-mix(in oklab, var(--primary) 5%, transparent);
  --color-primary-10: color-mix(in oklab, var(--primary) 10%, transparent);
  --color-primary-20: color-mix(in oklab, var(--primary) 20%, transparent);
  --color-primary-50: color-mix(in oklab, var(--primary) 50%, transparent);
}
```

### Chart カラー定義

```css
:root {
  --chart-1: oklch(0.646 0.222 41.116);
  --chart-2: oklch(0.6 0.118 184.714);
  --chart-3: oklch(0.398 0.07 227.392);
  --chart-4: oklch(0.828 0.189 84.429);
  --chart-5: oklch(0.769 0.188 70.08);
}

@theme inline {
  --color-chart-1: var(--chart-1);
  --color-chart-2: var(--chart-2);
  --color-chart-3: var(--chart-3);
  --color-chart-4: var(--chart-4);
  --color-chart-5: var(--chart-5);
}
```

---

## D. Typography 詳細

### Line-Height ペアリング

```css
@theme {
  --leading-xs: 1rem;       /* text-xs: 行間広め */
  --leading-sm: 1.25rem;
  --leading-base: 1.5rem;   /* 本文: 1.5 が基本 */
  --leading-lg: 1.75rem;
  --leading-xl: 2rem;
  --leading-2xl: 2.25rem;   /* 見出し: やや狭く */
  --leading-3xl: 2.5rem;
  --leading-4xl: 1;         /* 最大見出し: line-height: 1 */
}
```

### clamp() レスポンシブタイポグラフィ

```css
:root {
  /* clamp(最小値, 推奨値, 最大値) */
  --fluid-sm: clamp(0.8rem, 0.72rem + 0.25vw, 0.875rem);
  --fluid-base: clamp(1rem, 0.91rem + 0.3vw, 1.125rem);
  --fluid-lg: clamp(1.25rem, 1.09rem + 0.5vw, 1.5rem);
  --fluid-xl: clamp(1.563rem, 1.27rem + 0.9vw, 2rem);
  --fluid-2xl: clamp(1.953rem, 1.5rem + 1.4vw, 2.75rem);
  --fluid-3xl: clamp(2.441rem, 1.75rem + 2.1vw, 3.75rem);
  --fluid-display: clamp(3.052rem, 2rem + 3.3vw, 5rem);
}
```

### font-display + 日本語 Web フォント

```css
@font-face {
  font-family: 'Inter';
  src: url('/fonts/inter-var.woff2') format('woff2');
  font-weight: 100 900;
  font-display: swap;
}

@font-face {
  font-family: 'Noto Sans JP';
  src: url('/fonts/noto-sans-jp-var.woff2') format('woff2');
  font-weight: 100 900;
  font-display: swap;
  unicode-range: U+3000-9FFF, U+F900-FAFF;
}

@theme {
  --font-sans: 'Inter', 'Noto Sans JP', system-ui, sans-serif;
  --font-mono: 'JetBrains Mono', ui-monospace, monospace;
}
```

---

## E. Spacing & Sizing 詳細

### コンテナ幅トークン

```css
@theme {
  --container-xs: 20rem;   /* 320px */
  --container-sm: 24rem;   /* 384px */
  --container-md: 28rem;   /* 448px */
  --container-lg: 32rem;   /* 512px */
  --container-xl: 36rem;   /* 576px */
  --container-2xl: 42rem;  /* 672px */
  --container-3xl: 48rem;  /* 768px */
  --container-4xl: 56rem;  /* 896px */
  --container-5xl: 64rem;  /* 1024px */
  --container-6xl: 72rem;  /* 1152px */
  --container-7xl: 80rem;  /* 1280px */
  --container-prose: 65ch; /* 本文最適幅 */
}
```

### ブレークポイントトークン

```css
@theme {
  --breakpoint-sm: 40rem;   /* 640px - mobile landscape */
  --breakpoint-md: 48rem;   /* 768px - tablet */
  --breakpoint-lg: 64rem;   /* 1024px - small desktop */
  --breakpoint-xl: 80rem;   /* 1280px - desktop */
  --breakpoint-2xl: 96rem;  /* 1536px - large desktop */
}
```

### カスタムスペーシング（8px ベース）

```css
@theme {
  --spacing: 0.5rem;  /* 8px base grid */
  /* p-1 = 8px, p-2 = 16px, p-4 = 32px ... */
}
```

---

## F. Animation 詳細

### カスタムキーフレーム定義

```css
@theme {
  --animate-fade-in: fade-in 0.2s ease-out;
  --animate-fade-out: fade-out 0.15s ease-in;
  --animate-slide-up: slide-up 0.3s ease-out;
  --animate-slide-down: slide-down 0.3s ease-out;
  --animate-scale-in: scale-in 0.2s ease-out;

  @keyframes fade-in {
    from { opacity: 0; }
    to { opacity: 1; }
  }
  @keyframes fade-out {
    from { opacity: 1; }
    to { opacity: 0; }
  }
  @keyframes slide-up {
    from { transform: translateY(0.5rem); opacity: 0; }
    to { transform: translateY(0); opacity: 1; }
  }
  @keyframes slide-down {
    from { transform: translateY(-0.5rem); opacity: 0; }
    to { transform: translateY(0); opacity: 1; }
  }
  @keyframes scale-in {
    from { transform: scale(0.95); opacity: 0; }
    to { transform: scale(1); opacity: 1; }
  }
}
```

### テーマ切替トランジション

```css
@layer base {
  html {
    transition: color 0.2s ease, background-color 0.2s ease;
  }
  html[data-transitioning] * {
    transition: none !important;
  }
}
```

### Duration 用途ガイド

| Token | 値 | 用途 |
|-------|-----|------|
| `--duration-instant` | 0ms | 即時変更（色切替等） |
| `--duration-fast` | 100ms | hover/focus フィードバック |
| `--duration-normal` | 200ms | 標準トランジション |
| `--duration-slow` | 300ms | パネル開閉、アコーディオン |
| `--duration-slower` | 500ms | ページ遷移、モーダル |

### Easing 用途ガイド

| Token | 値 | 用途 |
|-------|-----|------|
| `--ease-default` | cubic-bezier(0.4, 0, 0.2, 1) | 汎用（Material Design 標準） |
| `--ease-in` | cubic-bezier(0.4, 0, 1, 1) | 退場アニメーション |
| `--ease-out` | cubic-bezier(0, 0, 0.2, 1) | 登場アニメーション |
| `--ease-in-out` | cubic-bezier(0.4, 0, 0.2, 1) | 移動（default と同値、意図的） |
| `--ease-bounce` | cubic-bezier(0.34, 1.56, 0.64, 1) | 弾むフィードバック |
| `--ease-spring` | cubic-bezier(0.22, 1.00, 0.36, 1) | スプリング効果 |

---

## G. shadcn/ui 統合

### components.json テンプレート

```json
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "new-york",
  "rsc": true,
  "tsx": true,
  "tailwind": {
    "config": "",
    "css": "app/globals.css",
    "baseColor": "neutral",
    "cssVariables": true,
    "prefix": ""
  },
  "aliases": {
    "components": "@/components",
    "utils": "@/lib/utils",
    "hooks": "@/hooks",
    "ui": "@/components/ui",
    "lib": "@/lib"
  },
  "iconLibrary": "lucide"
}
```

> Tailwind v4 では `config` を空文字にする（tailwind.config.ts は不要）。

### 新規セマンティックカラー追加手順

1. `:root` と `.dark` に CSS 変数を追加
2. `@theme inline` で `--color-{name}` にマッピング
3. `bg-{name}`, `text-{name}-foreground` 等のユーティリティが自動生成される

```css
/* Step 1-2 の例: brand カラーの追加 */
:root { --brand: oklch(0.55 0.20 260); --brand-foreground: oklch(0.985 0.01 260); }
.dark { --brand: oklch(0.65 0.18 260); --brand-foreground: oklch(0.15 0.02 260); }
@theme inline { --color-brand: var(--brand); --color-brand-foreground: var(--brand-foreground); }
/* → bg-brand, text-brand-foreground が使える */
```

> success / warning / error / info の定義済み値はセクション C を参照。

---

## H. globals.css 完全テンプレート

```css
/* ===== 1. Imports ===== */
@import "tailwindcss";
@import "tw-animate-css";

/* ===== 2. Dark Mode Variant ===== */
@custom-variant dark (&:where(.dark, .dark *));

/* ===== 3. Semantic Tokens (light) ===== */
:root {
  /* Surfaces */
  --background: oklch(1 0 0);
  --foreground: oklch(0.145 0 0);
  --card: oklch(1 0 0);
  --card-foreground: oklch(0.145 0 0);
  --popover: oklch(1 0 0);
  --popover-foreground: oklch(0.145 0 0);

  /* Brand */
  --primary: oklch(0.205 0 0);
  --primary-foreground: oklch(0.985 0 0);
  --secondary: oklch(0.97 0 0);
  --secondary-foreground: oklch(0.205 0 0);

  /* State */
  --accent: oklch(0.97 0 0);
  --accent-foreground: oklch(0.205 0 0);
  --destructive: oklch(0.577 0.245 27.325);
  --muted: oklch(0.97 0 0);
  --muted-foreground: oklch(0.556 0 0);

  /* UI Chrome */
  --border: oklch(0.922 0 0);
  --input: oklch(0.922 0 0);
  --ring: oklch(0.708 0 0);

  /* Radius */
  --radius: 0.625rem;

  /* Sidebar */
  --sidebar: oklch(0.985 0 0);
  --sidebar-foreground: oklch(0.145 0 0);
  --sidebar-primary: oklch(0.205 0 0);
  --sidebar-primary-foreground: oklch(0.985 0 0);
  --sidebar-accent: oklch(0.97 0 0);
  --sidebar-accent-foreground: oklch(0.205 0 0);
  --sidebar-border: oklch(0.922 0 0);
  --sidebar-ring: oklch(0.708 0 0);
}

/* ===== 4. Semantic Tokens (dark) ===== */
.dark {
  --background: oklch(0.145 0 0);
  --foreground: oklch(0.985 0 0);
  --card: oklch(0.145 0 0);
  --card-foreground: oklch(0.985 0 0);
  --popover: oklch(0.145 0 0);
  --popover-foreground: oklch(0.985 0 0);

  --primary: oklch(0.985 0 0);
  --primary-foreground: oklch(0.205 0 0);
  --secondary: oklch(0.269 0 0);
  --secondary-foreground: oklch(0.985 0 0);

  --accent: oklch(0.269 0 0);
  --accent-foreground: oklch(0.985 0 0);
  --destructive: oklch(0.396 0.141 25.723);
  --muted: oklch(0.269 0 0);
  --muted-foreground: oklch(0.708 0 0);

  --border: oklch(0.269 0 0);
  --input: oklch(0.269 0 0);
  --ring: oklch(0.556 0 0);

  --sidebar: oklch(0.205 0 0);
  --sidebar-foreground: oklch(0.985 0 0);
  --sidebar-primary: oklch(0.488 0.243 264.376);
  --sidebar-primary-foreground: oklch(0.985 0 0);
  --sidebar-accent: oklch(0.269 0 0);
  --sidebar-accent-foreground: oklch(0.985 0 0);
  --sidebar-border: oklch(0.269 0 0);
  --sidebar-ring: oklch(0.556 0 0);
}

/* ===== 5. Tailwind Utility Bridge ===== */
@theme inline {
  --color-background: var(--background);
  --color-foreground: var(--foreground);
  --color-card: var(--card);
  --color-card-foreground: var(--card-foreground);
  --color-popover: var(--popover);
  --color-popover-foreground: var(--popover-foreground);
  --color-primary: var(--primary);
  --color-primary-foreground: var(--primary-foreground);
  --color-secondary: var(--secondary);
  --color-secondary-foreground: var(--secondary-foreground);
  --color-accent: var(--accent);
  --color-accent-foreground: var(--accent-foreground);
  --color-destructive: var(--destructive);
  --color-muted: var(--muted);
  --color-muted-foreground: var(--muted-foreground);
  --color-border: var(--border);
  --color-input: var(--input);
  --color-ring: var(--ring);
  --color-sidebar: var(--sidebar);
  --color-sidebar-foreground: var(--sidebar-foreground);
  --color-sidebar-primary: var(--sidebar-primary);
  --color-sidebar-primary-foreground: var(--sidebar-primary-foreground);
  --color-sidebar-accent: var(--sidebar-accent);
  --color-sidebar-accent-foreground: var(--sidebar-accent-foreground);
  --color-sidebar-border: var(--sidebar-border);
  --color-sidebar-ring: var(--sidebar-ring);
  --radius-sm: calc(var(--radius) - 0.25rem);
  --radius-md: calc(var(--radius) - 0.125rem);
  --radius-lg: var(--radius);
  --radius-xl: calc(var(--radius) + 0.25rem);
}

/* ===== 6. Direct Tokens ===== */
@theme {
  /* Typography Scale */
  --text-xs: 0.64rem;
  --text-sm: 0.8rem;
  --text-base: 1rem;
  --text-lg: 1.25rem;
  --text-xl: 1.563rem;
  --text-2xl: 1.953rem;
  --text-3xl: 2.441rem;
  --text-4xl: 3.052rem;

  /* Spacing */
  --spacing: 0.25rem;

  /* Duration */
  --duration-instant: 0ms;
  --duration-fast: 100ms;
  --duration-normal: 200ms;
  --duration-slow: 300ms;
  --duration-slower: 500ms;

  /* Easing */
  --ease-default: cubic-bezier(0.4, 0, 0.2, 1);
  --ease-in: cubic-bezier(0.4, 0, 1, 1);
  --ease-out: cubic-bezier(0, 0, 0.2, 1);
  --ease-in-out: cubic-bezier(0.4, 0, 0.2, 1);
  --ease-bounce: cubic-bezier(0.34, 1.56, 0.64, 1);
  --ease-spring: cubic-bezier(0.22, 1.00, 0.36, 1);
}

/* ===== 7. Base Styles ===== */
@layer base {
  * { @apply border-border; }
  body { @apply bg-background text-foreground; }

  @media (prefers-reduced-motion: reduce) {
    *, *::before, *::after {
      animation-duration: 0.01ms !important;
      animation-iteration-count: 1 !important;
      transition-duration: 0.01ms !important;
      scroll-behavior: auto !important;
    }
  }
}
```

---

## I. トークン設計チェックリスト

### 必須

- [ ] OKLCH カラースペースを使用
- [ ] `:root` / `.dark` でセマンティック変数を定義
- [ ] `@theme inline` で Tailwind ユーティリティに接続
- [ ] foreground と background の L 値の差が 0.40 以上
- [ ] FOUC 防止対策あり（next-themes 使用 or 手動インラインスクリプト）
- [ ] `@custom-variant dark` が定義されている
- [ ] `prefers-reduced-motion` への対応がある
- [ ] モジュラースケールでタイポグラフィを定義
- [ ] `font-display: swap` を使用

### 推奨

- [ ] Status colors（success/warning/error/info）を定義
- [ ] `color-mix()` でアルファバリアントを生成
- [ ] `clamp()` でレスポンシブタイポグラフィ
- [ ] 日本語フォントに `unicode-range` を指定
- [ ] アニメーション duration/easing トークンを定義
- [ ] Chart カラーを定義（ダッシュボード使用時）

### アンチパターン

| NG | OK | 理由 |
|----|-----|------|
| HSL でカラー定義 | OKLCH | 知覚均一性なし |
| `:root` に直接 Tailwind 用変数 | `@theme inline` で橋渡し | テーマ切替が効かない |
| `@theme { }` にテーマ変数 | `:root` / `.dark` に配置 | ダークモードで上書き不可 |
| `color: var(--blue-500)` | `color: var(--primary)` | Primitive を直接使うな |
| px でフォントサイズ定義 | rem / clamp() | アクセシビリティ配慮 |
| `transition: all` | 個別プロパティ指定 | パフォーマンス |
| ハードコードの色値 | セマンティックトークン | テーマ対応不可 |
