---
name: baseline-ui
description: "Enforce opinionated UI constraints to prevent AI-generated interface antipatterns. Covers Tailwind defaults, accessible primitives (Radix/Base UI), compositor-only animations, touch targets, semantic tokens, and empty state design. Use when reviewing AI-generated UI for antipatterns, enforcing design system constraints, or selecting accessible component primitives. Do not trigger for general UI building (use web-design-guidelines) or animation implementation (use micro-interaction-patterns)."
---

# Baseline UI

Enforces an opinionated UI baseline to prevent AI-generated interface slop.

> **前提**: `web-design-guidelines`（WCAG 2.2・セマンティックHTML・a11y監査）を満たした上で、本スキルの制約を適用する。

## How to use

- `/baseline-ui`
  Apply these constraints to any UI work in this conversation.

- `/baseline-ui <file>`
  Review the file against all constraints below and output:
  - violations (quote the exact line/snippet)
  - why it matters (1 short sentence)
  - a concrete fix (code-level suggestion)

## Stack

- MUST use Tailwind CSS defaults unless custom values already exist or are explicitly requested
- MUST use `motion/react` (formerly `framer-motion`) when JavaScript animation is required
- SHOULD use `tw-animate-css` for entrance and micro-animations in Tailwind CSS
- MUST use `cn` utility (`clsx` + `tailwind-merge`) for class logic

## Components

- MUST use accessible component primitives for anything with keyboard or focus behavior (`Base UI`, `React Aria`, `Radix`)
- MUST use the project's existing component primitives first
- NEVER mix primitive systems within the same interaction surface
- SHOULD prefer [`Base UI`](https://base-ui.com/react/components) for new primitives if compatible with the stack
- MUST add an `aria-label` to icon-only buttons
- NEVER rebuild keyboard or focus behavior by hand unless explicitly requested

## Interaction

- MUST use an `AlertDialog` for destructive or irreversible actions
- SHOULD use structural skeletons for loading states
- NEVER use `h-screen`, use `h-dvh`
- MUST respect `safe-area-inset` for fixed elements
- MUST show errors next to where the action happens
- NEVER block paste in `input` or `textarea` elements

## Animation

- NEVER add animation unless it is explicitly requested
- MUST animate only compositor props (`transform`, `opacity`)
- NEVER animate layout properties (`width`, `height`, `top`, `left`, `margin`, `padding`)
- SHOULD avoid animating paint properties (`background`, `color`) except for small, local UI (text, icons)
- SHOULD use `ease-out` on entrance
- NEVER exceed `200ms` for interaction feedback
- MUST pause looping animations when off-screen
- SHOULD respect `prefers-reduced-motion`
- NEVER introduce custom easing curves unless explicitly requested
- SHOULD avoid animating large images or full-screen surfaces

## Typography

- MUST use `text-balance` for headings and `text-pretty` for body/paragraphs
- MUST use `tabular-nums` for data
- SHOULD use `truncate` or `line-clamp` for dense UI
- NEVER modify `letter-spacing` (`tracking-*`) unless explicitly requested

## Layout

- MUST use a fixed `z-index` scale (no arbitrary `z-*`)
- SHOULD use `size-*` for square elements instead of `w-*` + `h-*`

## Performance

- NEVER animate large `blur()` or `backdrop-filter` surfaces
- NEVER apply `will-change` outside an active animation
- NEVER use `useEffect` for anything that can be expressed as render logic

## Design

- NEVER use gradients unless explicitly requested
- NEVER use purple or multicolor gradients
- NEVER use glow effects as primary affordances
- SHOULD use Tailwind CSS default shadow scale unless explicitly requested
- MUST give empty states one clear next action
- SHOULD limit accent color usage to one per view
- SHOULD use existing theme or Tailwind CSS color tokens before introducing new ones

## App-Type Adaptation

上記ベースラインは全プロジェクト共通。以下のコンテキストで**緩和・強化**する:

| Context | 緩和 | 強化 |
|---------|------|------|
| **消費者向けアプリ** (LIFF/PWA) | アニメーション許可範囲を広げてよい（ブランド表現） | タッチターゲット48dp厳守、safe-area必須 |
| **管理画面/ダッシュボード** | — | データ密度優先、`tabular-nums` 徹底、情報階層の明確化 |
| **LP/マーケティング** | グラデーション・装飾の制約を緩和してよい | CWV（LCP < 2.5s）厳守、画像最適化必須 |
| **社内ツール** | 装飾を最小限に | キーボード操作・ショートカット充実 |

**差別化のポイント**: ベースラインを守った上で、プロジェクトの個性は以下で出す:
- **カラーパレット**: `design-token-system` で Hue・Chroma を変えるだけで印象が変わる
- **タイポグラフィ**: フォント選択と `--text-*` スケール比率で個性を出す
- **スペーシングリズム**: `--spacing` ベース値（4px vs 8px）で密度感を調整
- **角丸**: `--radius` 1箇所で全体のシェイプ印象を統一
- **空白の使い方**: 余白の多寡がプロダクトの「呼吸感」を決める

装飾で差別化するのではなく、**トークン値とレイアウトリズム**で差別化する。

## Cross-references

- `web-design-guidelines` — WCAG 2.2 準拠・セマンティック HTML（本スキルの前提）
- `web-design-guidelines` — a11y 監査・WCAG 2.2 準拠チェック（Accessibility Audit セクション）
- `design-token-system` — カラー・タイポ・スペーシングトークンでブランド差別化
- `micro-interaction-patterns` — アニメーション実装パターン（本スキルの制約内で実装）
- `ux-psychology` — 認知心理学の「なぜ」（本スキルは「制約」を定義）
- `_design-brief` — ブランドトーン・ペルソナ定義（App-Type Adaptation の制約緩和・強化の入力源）
