---
name: design-token-system
description: "Design tokens Tailwind v4 @theme: 3-tier hierarchy, OKLCH color, typography scale, dark mode FOUC fix, animation tokens"
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
Tier 1 Primitive: oklch(0.65 0.18 250) → --primitive-blue-500
Tier 2 Semantic:  --color-primary → var(--primitive-blue-500)
Tier 3 Component: --button-bg → var(--color-primary)
```

### Tailwind v4 での実装パターン

`:root` にセマンティック変数を定義し、`@theme inline` で Tailwind ユーティリティに接続する。

**globals.css の構成順序:**

```
1. @import "tailwindcss"  2. @import "tw-animate-css"  3. @custom-variant dark
4. :root { 変数 }  5. .dark { 変数 }  6. @theme inline { ブリッジ }
7. @theme { 直接トークン }  8. @layer base { グローバルスタイル }
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
oklch(L C H) — L=Lightness(0-1), C=Chroma(0-0.4), H=Hue(0-360)
```

### ブラウザサポート

OKLCH は主要ブラウザ（Chrome 111+, Safari 15.4+, Firefox 113+）で対応済み。古い WebView 向けフォールバック:
```css
@supports not (color: oklch(0 0 0)) {
  :root { --color-primary: hsl(220, 90%, 56%); }
}
```

### カラースケール生成の原則

**同一 Hue + Chroma で Lightness を変化**させ、知覚的に均一なスケールを作る。50→950 で L を 0.97→0.22 に段階的に下げ、中間（500）で C を最大にする。

> カラースケール生成例・Hue 参考値表は [reference.md](reference.md) セクション A を参照。

### アクセシブルコントラスト

WCAG AA 基準: テキスト 4.5:1、大テキスト 3:1。

**ルール: foreground と background の L 値の差を 0.40 以上にする。**

> **注意**: OKLCH の L 値の差はコントラスト比の近似指標であり、正確な WCAG 2.x コントラスト比（相対輝度ベース）とは計算方法が異なる。特に彩度が高い色や中間明度の色では乖離が生じるため、最終確認には必ずコントラスト比計算ツール（WebAIM Contrast Checker 等）を使用すること。

> L 値の差とコントラスト比の対応表、ライト/ダークモードの L 値ペア例は [reference.md](reference.md) セクション B を参照。

### セマンティックカラー追加

shadcn/ui にない色（success, warning, info 等）を追加する手順:

1. `:root` と `.dark` に CSS 変数を追加（OKLCH 値、L 値の差 >= 0.40）
2. `@theme inline` で `--color-{name}` / `--color-{name}-foreground` にマッピング
3. `bg-{name}`, `text-{name}-foreground` 等のユーティリティが自動生成される

> 全 Status Colors 定義・Chart カラー・color-mix() パターンは [reference.md](reference.md) セクション C を参照。

---

## Part 3: Typography Tokens [HIGH]

### モジュラースケール

比率ベース（Major Third = 1.25）でフォントサイズを決定し、一貫したリズムを作る。`@theme` ブロック内で `--text-xs` 〜 `--text-4xl` を定義する。

**ルール**: フォントサイズが大きいほど行間を狭くする（本文 1.5 → 大見出し 1.0）。clamp() でビューポート幅に応じた流動サイズも設定可能。

> モジュラースケール値・Line-Height ペアリング表・clamp() 定義・font-display 設定は [reference.md](reference.md) セクション D, H を参照。

---

## Part 4: Spacing, Sizing & Shape Tokens [MEDIUM]

### Tailwind v4 のスペーシングシステム

v4 では `--spacing` がベース。数値 * ベース値で自動計算される（デフォルト 0.25rem = 4px グリッド）。8px ベースにしたい場合は `--spacing: 0.5rem` に変更。

### Border-Radius トークン

shadcn/ui は `--radius` をベースに全段階を `calc()` で導出する。`:root` で `--radius` を 1 箇所変えるだけで全体のシェイプが統一される（角丸を強くしたいなら 0.75rem、角張らせるなら 0.375rem）。

### Shadow, Z-Index & Focus Ring トークン

- **Shadow**: sm / md / lg の 3 段階を `@theme` で定義。OKLCH の透明度で影色を指定
- **Z-Index**: dropdown(50) → sticky(100) → overlay(200) → modal(300) → toast(400) のレイヤー規約
- **Focus Ring**: `--ring` 変数でフォーカスリング色をテーマ連動（light/dark で L 値を切替）。使用: `focus-visible:ring-2 ring-ring ring-offset-2`

> 全トークン値・コンテナ幅・ブレークポイントは [reference.md](reference.md) セクション E, H を参照。

---

## Part 5: Dark Mode Implementation [CRITICAL]

### FOUC（Flash of Unstyled Content）防止

ダークモードで最も重要な課題。**ページ描画前にテーマを適用する**。

**next-themes 使用時（推奨）**: next-themes が自動で FOUC 防止スクリプトを挿入するため、手動スクリプトは不要。`suppressHydrationWarning` だけ付ける。

**next-themes 不使用時**: 手動でインラインスクリプトを `<head>` に挿入する。

```tsx
// app/layout.tsx - next-themes 使用時: <html suppressHydrationWarning>
// <body><ThemeProvider>{children}</ThemeProvider></body></html>
```

### next-themes 統合

```tsx
// providers/theme-provider.tsx — 'use client'
// <NextThemesProvider attribute="class" defaultTheme="system" enableSystem disableTransitionOnChange>
// {children}</NextThemesProvider>
```

### CSS 側の設定

`@custom-variant dark (&:where(.dark, .dark *));` — この 1 行で `dark:bg-background` 等の Tailwind v4 ダークモードユーティリティが有効になる。

> light/dark の全セマンティック変数値は [reference.md](reference.md) セクション H を参照。

---

## Part 6: Animation Tokens [MEDIUM]

### Duration & Easing 設計方針

- **Duration**: 用途別に 4〜5 段階（instant/fast/normal/slow/slower）を `@theme` で定義。hover=100ms、標準=200ms、パネル開閉=300ms、ページ遷移=500ms
- **Easing**: 汎用(Material Design 標準)、登場(ease-out)、退場(ease-in)、弾む(bounce)の 4 パターンを基本にする
- **prefers-reduced-motion**: `@layer base` 内でアニメーション/トランジションを 0.01ms に制限する。Tailwind: `motion-safe:animate-fade-in motion-reduce:opacity-100`

> 全 duration/easing 値・キーフレーム定義・用途ガイドは [reference.md](reference.md) セクション F, H を参照。

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

## Decision Tree

新しいスタイル値 → 既存トークンで表現可能？ → Yes → トークン参照（`var(--color-primary)` 等） / No → Primitive定義（OKLCH値） → Semantic mapping（`:root` + `.dark`） → Component token（`@theme inline` でブリッジ）

カラー追加 → shadcn/ui 既存色？ → Yes → そのまま利用 / No → `:root` にOKLCH変数追加 → L値の差 >= 0.40 確認 → `@theme inline` でマッピング → ユーティリティ自動生成

ダークモード → next-themes 使う？ → Yes → ThemeProvider + `suppressHydrationWarning` / No → 手動 `<head>` インラインスクリプト → FOUC防止

## Checklist

- [ ] 3-Tier構造（Primitive → Semantic → Component）に従っている
- [ ] OKLCH カラーの L値の差が foreground/background で 0.40 以上
- [ ] `:root` と `.dark` の両方にセマンティック変数を定義
- [ ] `@theme inline` で CSS変数を Tailwind ユーティリティにブリッジ
- [ ] globals.css の記述順序が正しい（@import → :root → .dark → @theme inline → @layer base）
- [ ] `@custom-variant dark` でダークモードユーティリティが有効
- [ ] フォントサイズにモジュラースケール比率を適用
- [ ] `prefers-reduced-motion` でアニメーションを制限
- [ ] shadcn/ui の `--radius` ベース値でシェイプ統一
- [ ] Z-Index レイヤー規約（dropdown→sticky→overlay→modal→toast）に準拠

## Cross-References [MEDIUM]

このスキルのトークン定義を、他スキルの知見と組み合わせると効果的な場面:

- **ux-psychology**: 色彩心理学（信頼=青 H:250、危険=赤 H:25）をトークンの Hue 選定に活用。警告色の L 値設計に認知バイアスの知見を適用
- **web-design-guidelines**: WCAG 2.2 のコントラスト比計算式でトークンの L 値の差を検証。トークンで定義した値が AA/AAA 基準を満たすか最終チェック
- **react-component-patterns**: CVA バリアントの `className` にトークンベースのユーティリティ（`bg-primary`, `text-destructive`）を使い、テーマ対応コンポーネントを実現
- **dashboard-data-viz**: Chart カラートークン（セクション C）を Recharts/Tremor のカラーパレットとして連携。データ可視化のアクセシビリティに L 値の差を適用
- **mobile-first-responsive**: clamp() fluid typography トークン（セクション D）をモバイルビューポートに適用。LIFF の制約下でも読みやすいサイズを維持
- **micro-interaction-patterns**: duration/easing トークン（Part 6）を Framer Motion の transition 設定に統一値として使用
