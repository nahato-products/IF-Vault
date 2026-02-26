---
name: react-component-patterns
description: "Design and implement reusable React components with compound component patterns, render props, custom hooks, context APIs, and accessibility best practices. Use when creating component libraries, designing component APIs, implementing compound UI patterns, managing component state, or building accessible interactive components. Do not trigger for Next.js-specific patterns (use nextjs-app-router-patterns), Tailwind CSS config (use tailwind-design-system), or TypeScript types (use typescript-best-practices)."
user-invocable: false
triggers:
  - Reactコンポーネントを設計
  - コンポーネントAPIを定義
  - カスタムフックを作る
  - Compound Componentパターン
  - コンポーネントライブラリを作る
---

# React Component Patterns

再利用可能な React コンポーネントの設計パターン。

## Compound Component

```tsx
// Usage: <Select><Select.Trigger /><Select.Options /></Select>
const SelectContext = createContext<SelectContextType>(null\!)

export function Select({ children, value, onChange }) {
  return (
    <SelectContext.Provider value={{ value, onChange }}>
      <div className="relative">{children}</div>
    </SelectContext.Provider>
  )
}
Select.Trigger = function Trigger({ children }) { ... }
Select.Options = function Options({ children }) { ... }
```

## Custom Hook Pattern

```tsx
function useDisclosure(defaultOpen = false) {
  const [isOpen, setIsOpen] = useState(defaultOpen)
  return {
    isOpen,
    open: () => setIsOpen(true),
    close: () => setIsOpen(false),
    toggle: () => setIsOpen(prev => \!prev),
  }
}
```

## Cross-references

- **typescript-best-practices**: コンポーネントの型安全設計
- **tailwind-design-system**: CVAを使ったスタイリング
- **_baseline-ui**: アクセシビリティ制約・プリミティブ選択
- **nextjs-app-router-patterns**: Server/Client Component境界設計
