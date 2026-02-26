---
name: micro-interaction-patterns
description: "Design and implement micro-interactions covering button feedback, loading states, transitions, hover effects, form validation animations, and gesture responses using CSS animations and Framer Motion. Use when adding tactile feedback to UI actions, implementing loading skeletons, designing state transition animations, or creating gesture-responsive interfaces. Do not trigger for complex video animations (use video-motion-graphics), motion performance optimization (use fixing-motion-performance), or full-page transitions."
user-invocable: false
triggers:
  - マイクロインタラクションを追加
  - ボタンのフィードバックを改善
  - ローディング状態のアニメーション
  - ホバーエフェクトを作る
  - フォームのバリデーションアニメーション
---

# Micro-Interaction Patterns

UI の小さなインタラクションアニメーションパターン集。

## Button Feedback

```tsx
// Satisfying click feedback
<button className="
  active:scale-95 active:brightness-90
  transition-all duration-75
  hover:shadow-md hover:-translate-y-0.5
">
```

## Loading Skeleton

```tsx
function Skeleton({ className }) {
  return (
    <div className={cn(
      "animate-pulse rounded-md bg-muted",
      className
    )} />
  )
}
// Usage
<Skeleton className="h-4 w-[200px]" />
```

## Form Field Validation (Framer Motion)

```tsx
<motion.p
  initial={{ opacity: 0, y: -4 }}
  animate={{ opacity: 1, y: 0 }}
  exit={{ opacity: 0 }}
  className="text-red-500 text-sm"
>
  {error}
</motion.p>
```

## Cross-references

- **motion-designer**: 大規模モーションデザインとの連携
- **tailwind-design-system**: Tailwind アニメーションユーティリティ
- **_baseline-ui**: compositor-only アニメーション制約
