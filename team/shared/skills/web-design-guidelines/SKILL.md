---
name: web-design-guidelines
description: Framework-agnostic web platform standards for semantic HTML, WCAG 2.2 AA accessibility, responsive CSS, forms, typography, performance, animation, dark mode, i18n, and print styles. Use when building, reviewing, auditing, refactoring, or debugging raw HTML/CSS/JS without a CSS framework. Apply to implement semantic landmarks and accessible tables, enforce color contrast and keyboard navigation, construct form validation with ARIA error messaging, configure fluid layouts with clamp and container queries, optimize Core Web Vitals, set up dark mode theming, handle RTL with logical properties, or diagnose accessibility issues. Does not cover Tailwind, React, LIFF, design tokens, or cognitive UX psychology.
user-invocable: false
---

# Web Platform Design Guidelines

Framework-agnostic rules for accessible, performant, responsive web interfaces based on WCAG 2.2 and the HTML Living Standard.

> Code examples are in `reference.md`. Related skills: `mobile-first-responsive` (LIFF/PWA/Tailwind mobile), `design-token-system` (token hierarchy), `tailwind-design-system` (Tailwind v4), `micro-interaction-patterns` (animation/state), `ux-psychology` (cognitive UX WHY), `testing-strategy` (accessibility testing), `security-review` (form security).

---

## 1. Accessibility / WCAG [CRITICAL]

Accessibility is not optional. Every rule maps to WCAG 2.2 Level A or AA. Details and code examples: see reference.md SS1.

### 1.1 Semantic HTML

Use elements for their intended purpose (`<main>`, `<nav>`, `<article>`, `<dialog>`, `<search>`, etc.). Anti-pattern: `<div onclick>` instead of `<button>`.

### 1.2 ARIA Labels

Every interactive element must have an accessible name (SC 4.1.2). Prefer visible text over `aria-label`. Use ARIA only when no native element exists.

### 1.3 Keyboard Navigation

All interactive elements reachable via keyboard (SC 2.1.1). Use native elements; `tabindex="0"` for custom widgets; never `tabindex` > 0. Trap focus in modals.

### 1.4 Focus Indicators

Never remove outlines without visible replacement (SC 2.4.7, 2.4.11). Use `:focus-visible`; min area = perimeter x 2px, 3:1 contrast.

### 1.5 Skip Navigation

Provide skip link to bypass repeated content (SC 2.4.1).

### 1.6 Alt Text

Every `<img>` needs `alt` (SC 1.1.1). Informative: describe content. Decorative: `alt=""`. Functional: describe action. Complex: short alt + `<figcaption>`.

### 1.7 Color Contrast

Normal text 4.5:1, large text 3:1, UI components 3:1 (SC 1.4.3, 1.4.11). Never rely on color alone (SC 1.4.1).

### 1.8 Form Labels

Every input needs a programmatic label (SC 1.3.1, 3.3.2). Use `<label for="id">`. Never placeholder as sole label.

### 1.9 Error Identification

Identify errors in text (SC 3.3.1). Use `aria-describedby`, `aria-invalid="true"`, `role="alert"`.

### 1.10 Live Regions

`aria-live="polite"` for non-urgent updates, `role="alert"` for time-sensitive, `role="status"` for status messages (SC 4.1.3).

### 1.11 Table Accessibility

`<caption>` for title, `<th scope>` for headers, `<thead>`/`<tbody>`/`<tfoot>` for grouping (SC 1.3.1). Complex tables: `headers` attribute.

---

## 2. Responsive Design [CRITICAL]

> For LIFF/PWA/Tailwind-specific responsive patterns, see `mobile-first-responsive`.

### 2.1 Mobile-First

Base styles for smallest viewport. Layer with `min-width` media queries.

> Grid example: reference.md SS2.1

### 2.2 Fluid Sizing

Use `clamp()`, `min()`, `max()` for fluid sizing without breakpoints.

> Fluid sizing examples: reference.md SS2.2

### 2.3 Container Queries

Size components based on their container, not the viewport.

> Full example: reference.md SS2.3

### 2.4 Content-Based Breakpoints

Set breakpoints where content breaks, not at device widths: `30rem` (~480px), `48rem` (~768px), `64rem` (~1024px), `80rem` (~1280px).

### 2.5 Touch Targets

WCAG 2.2 SC 2.5.8 (Level AA): minimum 24x24 CSS pixels with sufficient spacing. SC 2.5.5 (Level AAA): minimum 44x44 CSS pixels. Target 44x44 for best usability. Use `::after` pseudo-element to enlarge tap area without changing visual size.

### 2.6 Viewport Meta

```html
<meta name="viewport" content="width=device-width, initial-scale=1">
```

Never use `maximum-scale=1` or `user-scalable=no` -- breaks pinch-to-zoom (SC 1.4.4).

### 2.7 No Horizontal Scrolling

Content must reflow at 320px without horizontal scroll (SC 1.4.10): `img, video { max-width: 100%; height: auto; }`, `overflow-wrap: break-word`, scrollable containers for tables.

---

## 3. Forms [HIGH]

> For form security (CSRF, injection prevention), see `security-review`. For cognitive form design (progressive disclosure, validation psychology), see `ux-psychology`.

### 3.1 Label Every Input

See SS1.8.

### 3.2 Autocomplete Attributes

Use `autocomplete` for common fields (SC 1.3.5): `name`, `email`, `tel`, `street-address`, `postal-code`, `cc-number`, `new-password`, `current-password`.

### 3.3 Correct Input Types

Use `email`, `tel`, `url`, `number` (not for phone/zip/card), `search`, `date`/`time`/`datetime-local`, `password`. Use `text` + `inputmode="numeric"` for numeric data without spinners (PINs, zip).

### 3.4 Inline Validation

Validate on `blur` (not every keystroke). Use `aria-describedby`, `aria-invalid`, `role="alert"`.

> Full example: reference.md SS3.4

### 3.5 Fieldset and Legend

Group related inputs with `<fieldset>` + `<legend>`. Essential for radio/checkbox groups.

### 3.6 Required Fields

Use `required` attribute + visible marker. If most fields required, indicate optional ones instead.

### 3.7 Submit Button

Do not disable submit button. Validate on submit and show errors -- disabled buttons fail to communicate why the user cannot proceed.

---

## 4. Typography [HIGH]

> For design-token-based typography scales, see `design-token-system`.

### 4.1 Font Stacks

System: `system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif`
Mono: `ui-monospace, "Cascadia Code", "Source Code Pro", Menlo, Consolas, monospace`
Web fonts: use `font-display: swap` with proper fallbacks.

### 4.2 Relative Units

Use `rem` for font sizes/spacing. `html { font-size: 100%; }` respects user preference. Never `px` for font-size.

### 4.3 Line Height and Spacing

Body `line-height` >= 1.5 (SC 1.4.12). Headings: ~1.2. Paragraph spacing >= 2x font size.

### 4.4 Line Length

Limit to ~75 characters: `.prose { max-width: 75ch; }`

### 4.5 Heading Hierarchy

`h1`-`h6` in order, never skip levels, one `h1` per page. Use CSS classes for visual overrides.

> Typography code examples: reference.md SS4

---

## 5. Performance [HIGH]

### 5.1 Image Loading

`loading="lazy"` for below-fold. `fetchpriority="high"` for hero images. Always set `width` and `height` to prevent CLS.

### 5.2 Resource Hints

- `<link rel="preconnect">` for critical third-party origins
- `<link rel="preload">` for critical resources (fonts, CSS)
- `<link rel="dns-prefetch">` for non-critical origins

### 5.3 Code Splitting

Dynamic `import()` for route-based and interaction-based splitting.

### 5.4 Long Lists

Virtualize lists > a few hundred items -- render only visible rows + buffer.

### 5.5 Layout Thrashing

Batch DOM reads then writes. Never interleave read-write.

### 5.6 will-change

Only on elements that will animate. Remove after animation completes. Never `* { will-change: transform; }`.

> Performance code examples: reference.md SS5

---

## 6. Animation and Motion [MEDIUM]

> For Framer Motion / Next.js animation patterns, see `micro-interaction-patterns`.

Respect `prefers-reduced-motion` (SC 2.3.3). Animate only `transform` and `opacity` (compositor-friendly). Never flash > 3 times/sec (SC 2.3.1). Animation should communicate state, not decorate.

> Full section with examples: reference.md SS6

---

## 7. Dark Mode and Theming [MEDIUM]

> For CSS custom property token architecture, see `design-token-system`.

Detect with `prefers-color-scheme: dark`. Use CSS custom properties for all theme values. Add `<meta name="color-scheme" content="light dark">`. Verify contrast in both modes.

> Full section with examples: reference.md SS7

---

## 8. Navigation and State [MEDIUM]

URL must reflect meaningful state (`pushState` + `URLSearchParams`). Handle `popstate` for back/forward. Use `aria-current="page"` for active nav. Breadcrumbs for deep hierarchies. Manage scroll restoration in SPAs.

> Full section with examples: reference.md SS8

---

## 9. Touch and Interaction [MEDIUM]

Use `touch-action` CSS for scroll control. Pair every `:hover` with `:focus-visible`. Never hide functionality behind hover-only. Use CSS scroll snap for carousels.

> Full section with examples: reference.md SS9

---

## 10. Internationalization [MEDIUM]

Set `lang` on `<html>`. Use `dir="auto"` for user content. Format with `Intl` APIs (never hard-code formats). Avoid text in images. Use CSS logical properties (`margin-inline-start`, `padding-block-end`, etc.) instead of physical ones.

> Logical property mapping and examples: reference.md SS10

---

## 11. Print Styles [MEDIUM]

Apply `@media print` styles to ensure pages print correctly. Hide non-essential UI (nav, footer, ads). Expand collapsed content. Show URLs after links. Use `page-break-inside: avoid` on critical blocks.

> Full print stylesheet: reference.md SS11

---

## Quick Review Checklist [HIGH]

**Accessibility**: alt text, contrast (4.5:1 text / 3:1 UI), keyboard access, focus indicators (3:1, 2px perimeter), skip nav, labels, error linking, live regions, no flashing, heading hierarchy, landmarks, table headers.

**Responsive**: no horizontal scroll at 320px, touch targets >= 24x24px (AA) / 44x44px (AAA), viewport meta (no user-scalable=no), works across breakpoints.

**Forms**: visible labels, autocomplete, correct input types, clear errors, required indication, submit not disabled.

**Performance**: lazy loading, image dimensions, font preload, preconnect, code splitting.

**Motion/Theme**: prefers-reduced-motion, transform/opacity only, dark mode contrast, color-scheme meta.

**i18n**: lang attribute, logical properties, Intl APIs, no image text, RTL tested.

**Print**: @media print tested, nav/footer hidden, links show URLs, page breaks respected.

---

## Common Anti-Patterns [HIGH]

| Anti-Pattern | Fix |
|---|---|
| `<div onclick>` | `<button>` |
| `outline: none` without replacement | `:focus-visible` with custom outline |
| `placeholder` as label | Add `<label>` |
| `tabindex="5"` | `tabindex="0"` or natural order |
| `user-scalable=no` | Remove it |
| `font-size: 12px` | `font-size: 0.75rem` |
| Animating `width`/`height`/`left` | `transform` and `opacity` |
| Disabled submit button | Validate on submit |
| Color alone for status | Add icon, text, or pattern |
| `margin-left` | `margin-inline-start` |
| `<img>` without dimensions | Add `width`/`height` |
| Hover-only disclosure | Add `:focus-within` and click |
| `<table>` without `<th scope>` | Add proper header cells |
