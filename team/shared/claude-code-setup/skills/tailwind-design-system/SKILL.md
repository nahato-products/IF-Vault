---
name: tailwind-design-system
description: "Tailwind v4 @theme CSS-first, CVA, v3→v4 migration, dark mode @custom-variant, @utility, container queries, shadcn/ui"
user-invocable: false
---

# Tailwind Design System

[CRITICAL] Tailwind CSS v4のCSS-firstユーティリティ設計・コンポーネントバリアント・マイグレーションガイド。トークン値の定義・色設計は `design-token-system` が担当。本スキルはTailwindユーティリティの使い方とコンポーネント構築に特化。

> 関連スキル: `design-token-system`（トークン値・OKLCH色設計・globals.css構造）、`react-component-patterns`（コンポーネント設計全般）。他の関連スキルは reference.md クロスリファレンスセクション参照。

## [CRITICAL] When to Use

- Tailwind v4のCSS-first設定（`@theme`, `@import "tailwindcss"`）
- CVAでバリアント付きコンポーネント構築
- v3からv4へのマイグレーション
- ダークモード実装（`@custom-variant` + `.dark` クラス）
- カスタムユーティリティ（`@utility`）作成
- レスポンシブグリッド / コンテナクエリ

## [HIGH] When NOT to Apply

- トークン値の設計（OKLCH色、スペーシング、タイポグラフィスケール） → `design-token-system`
- globals.css の構造設計（:root / .dark / @theme inline の値定義） → `design-token-system`
- React コンポーネント設計全般（Tailwind非依存） → `react-component-patterns`
- LIFF/PWA特有のレスポンシブ対応 → `mobile-first-responsive`
- WCAG準拠・セマンティックHTML・aria属性 → `web-design-guidelines`
- アニメーション/マイクロインタラクション中心 → `micro-interaction-patterns`
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

## Decision Tree [HIGH]

```
テーマ値設計 → design-token-system | ユーティリティ橋渡し → @theme(本スキル)
コンポーネント → CVA+cn() / Compound / Form+Zod
ダークモード → @custom-variant | カスタムUtility → @utility
レスポンシブ → sm:/md:/lg: or @container | v3移行 → Migration Map
```

## [CRITICAL] CSS-First Configuration

v4ではテーマ設定をCSSの `@theme` ブロックで行う。`tailwind.config.ts` は不要。

```css
@import "tailwindcss";
@theme { --color-primary: oklch(...); --animate-*: ...; @keyframes ... }
@custom-variant dark (&:where(.dark, .dark *));
```
Full theme example: see reference.md「テーマ設定の完全例」

### @theme Modifiers

| Modifier | 用途 | 使い分け |
|---|---|---|
| `@theme { }` | 直接値を定義 | 固定トークン（spacing, animation） |
| `@theme inline { }` | 他のCSS変数を参照 | `:root`/`.dark`で切替えるトークン |
| `@theme static { }` | 未使用でもCSS変数を出力 | 外部JS参照が必要な場合 |

**原則**: `:root`/`.dark` にセマンティック変数を定義 → `@theme inline` で Tailwind ユーティリティに橋渡し。トークン値の設計は `design-token-system` を参照。

## [CRITICAL] CVA Component Patterns

### Pattern Selection

| コンポーネント種別 | パターン | 例 |
|---|---|---|
| バリアント付き | CVA + `cn()` | Button, Badge, Alert |
| 複合コンポーネント | Compound Components | Card, Dialog, Tabs |
| フォーム入力 | Form Components | Input, Label, Select |
| レイアウト | Grid/Container CVA | Grid, Container |

### CVA Build Flow

```
Base styles → Variants → Sizes → States → Overrides
                                            ↑ cn() でマージ
```

- `cva()` でバリアント定義、`cn()` で安全にクラスマージ
- `cn()` = `twMerge(clsx(...))` → reference.md「Utility Functions」参照
- React 19: `forwardRef` 不要、`ref` はpropsで直接受け取る
- `asChild` + Radix `Slot` でポリモーフィックレンダリング

→ reference.md「CVAコンポーネント」「Compound Components」「Form Components」参照

### Animation with Radix

- `@keyframes` を `@theme` 内に定義、`--animate-*` で参照
- `@starting-style` でエントリーアニメーション
- Radix data属性と連携: `data-[state=open]:animate-*`

→ reference.md「CSS Animations」参照

## [HIGH] Custom Variants (`@variant`)

`@variant` でカスタムバリアントを定義できる（`@custom-variant` のエイリアス）: `@variant mobile (&:where(.mobile, .mobile *));` — dark mode以外のカスタム状態にも対応。

## [HIGH] Custom Utilities (`@utility`)

```css
@utility line-t {
  @apply relative before:absolute before:top-0 before:-left-[100vw]
         before:h-px before:w-[200vw] before:bg-gray-950/5
         dark:before:bg-white/10;
}
```

`@utility` はv3のカスタムプラグインの代替。CSSファイル内に直接定義でき、Tailwindのツリーシェイクの対象になる。

## [HIGH] Namespace Overrides

```css
@theme {
  --color-*: initial;  /* デフォルトカラーをクリア */
  --color-primary: oklch(45% 0.2 260);
}
```

`initial` でTailwindのデフォルトパレットをリセットし、プロジェクト固有のカラーだけ定義できる。

## [HIGH] Container Queries

```css
@theme {
  --container-xs: 20rem;
  --container-sm: 24rem;
}
```

`@container` でコンポーネントの親コンテナサイズに応じたレスポンシブを実現。ビューポートではなくコンテナ幅で判断する。

### 使用例

```tsx
{/* 親要素を @container にする */}
<div className="@container">
  {/* コンテナ幅に応じてレイアウト変更 */}
  <div className="grid grid-cols-1 @sm:grid-cols-2 @md:grid-cols-3 gap-4">
    <Card />
    <Card />
    <Card />
  </div>
</div>
```

→ reference.md「Grid System」参照

## [HIGH] Semi-transparent Variants

```css
@theme {
  --color-primary-50: color-mix(in oklab, var(--color-primary) 5%, transparent);
}
```

`color-mix()` でベースカラーからアルファバリアントを動的生成。ホバー状態やオーバーレイに便利。

> 基本的にはアルファ修飾子 `bg-primary/50` を使用。`color-mix()` は異なるカラー同士のブレンドが必要な場合のみ。

## [HIGH] v3 → v4 Migration Checklist

- [ ] `tailwind.config.ts` → CSS `@theme` ブロックへ
- [ ] `@tailwind base/components/utilities` → `@import "tailwindcss"`
- [ ] カラー定義を `@theme { --color-*: value }` へ
- [ ] `darkMode: "class"` → `@custom-variant dark`
- [ ] `@keyframes` を `@theme` 内へ
- [ ] `tailwindcss-animate` → ネイティブCSS animations
- [ ] `h-10 w-10` → `size-10`
- [ ] `forwardRef` 削除（React 19）
- [ ] カスタムプラグイン → `@utility`

## [MEDIUM] Best Practices

### Do

- `@theme` ブロックでCSS-first設定
- CVA + TypeScript で型安全バリアント
- セマンティックトークン（`bg-primary` > `bg-blue-500`）
- `size-*` ショートハンド
- ARIA属性・フォーカス管理
- `cn()` でクラスの安全なマージ

### Don't

- `tailwind.config.ts` を使う（→ `@theme`）
- `@tailwind` ディレクティブを使う（→ `@import "tailwindcss"`）
- `forwardRef` を使う（React 19ではrefはprop）
- arbitrary values多用（→ `@theme` 拡張）
- ハードコードカラー（→ セマンティックトークン）
- `className` の文字列結合（→ `cn()` を使う）

## Cross-references [MEDIUM]

- **design-token-system**: トークン値定義（OKLCH色、spacing、typography）— 本スキルは定義済みトークンのTailwindユーティリティ橋渡し
- **react-component-patterns**: CVAバリアントのコンポーネント設計・Compound Components・asChild/Slot
- **mobile-first-responsive**: LIFF/PWA向けレスポンシブ — 本スキルのContainer Queryとの使い分け

## [MEDIUM] ThemeProvider

本番のダークモード切替には [`next-themes`](https://github.com/pacocoursey/next-themes) を推奨。`@custom-variant dark` と組み合わせて使う。カスタム実装よりSSR/hydration不整合の対処が堅牢。

## [MEDIUM] Resources

- [Tailwind CSS v4 Docs](https://tailwindcss.com/docs)
- [CVA](https://cva.style/docs)
- [shadcn/ui](https://ui.shadcn.com/)
- [Radix Primitives](https://www.radix-ui.com/primitives)
