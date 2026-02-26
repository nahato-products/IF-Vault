---
name: design-token-system
description: "Design and implement a token-based design system covering color palettes, typography scales, spacing systems, shadow levels, and border radii using CSS custom properties and Tailwind CSS v4. Use when establishing design foundations, creating consistent visual language, implementing dark/light mode via tokens, syncing design tools to code, or building a scalable component library. Do not trigger for specific component implementation (use react-component-patterns), Tailwind config only (use tailwind-design-system), or design direction selection (use style-reference-db)."
user-invocable: false
triggers:
  - デザイントークンを設計
  - カラーパレットを定義
  - タイポグラフィスケールを作る
  - デザインシステムを構築
  - トークンを実装したい
---

# Design Token System

CSS カスタムプロパティと Tailwind CSS v4 を使ったデザイントークン実装。

## 5-Axis Token Model

| 軸 | 例 | 用途 |
|----|-----|------|
| **Hue** | `--color-primary: oklch(60% 0.2 220)` | ブランドカラー |
| **Shape** | `--radius: 0.5rem` | 角丸・形状 |
| **Density** | `--spacing-1: 4px` | 余白密度 |
| **TypeScale** | `--text-base: 1rem` | フォントサイズ比 |
| **Motion** | `--duration-fast: 100ms` | アニメーション速度 |

## Tailwind v4 Implementation

```css
/* app/globals.css */
@theme {
  --color-primary: oklch(60% 0.2 220);
  --color-primary-foreground: oklch(98% 0 0);
  --radius: 0.5rem;
  --font-sans: 'Inter', sans-serif;
}
```

## Dark Mode Tokens

```css
.dark {
  --color-background: oklch(15% 0 0);
  --color-foreground: oklch(95% 0 0);
}
```

## Cross-references

- **tailwind-design-system**: トークンをTailwind設定に反映
- **style-reference-db**: スタイルプリセットからトークン値を選択
- **_design-brief**: ブリーフで確定した方向性をトークンに実装
