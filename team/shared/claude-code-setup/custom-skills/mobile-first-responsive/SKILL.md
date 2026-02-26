---
name: mobile-first-responsive
description: "Implement mobile-first responsive layouts using Tailwind CSS breakpoints, container queries, fluid typography, and touch-friendly UX patterns. Use when building responsive web interfaces, optimizing for mobile viewports, implementing touch gestures, ensuring minimum touch target sizes, or adapting layouts for different screen sizes. Do not trigger for iOS/Android native app design (use ios-design-guidelines or android-design-guidelines) or accessibility only (use fixing-accessibility)."
user-invocable: false
triggers:
  - モバイルファーストで設計
  - レスポンシブレイアウトを作る
  - スマホ対応
  - タッチ操作のUI
  - 画面サイズに適応させたい
---

# Mobile-First Responsive Design

Tailwind CSS を使ったモバイルファースト・レスポンシブ実装パターン。

## Breakpoint Strategy

```tsx
// Mobile first: base styles apply to mobile, extend upward
<div className="
  flex flex-col        // mobile: stack vertically
  md:flex-row          // tablet: side by side
  lg:max-w-6xl         // desktop: constrained width
  mx-auto px-4 sm:px-6 lg:px-8
">
```

## Touch Targets

```tsx
// Minimum 44×44px touch target (iOS HIG)
<button className="min-h-[44px] min-w-[44px] p-3">
  Tap me
</button>
```

## Safe Area (iPhone notch / home indicator)

```css
.safe-bottom { padding-bottom: env(safe-area-inset-bottom); }
```

## Cross-references

- **tailwind-design-system**: Tailwind CSS v4 の詳細設定
- **_web-design-guidelines**: Webアクセシビリティ・タッチターゲット
- **_baseline-ui**: UI制約ルール（タッチターゲット最小サイズ）
