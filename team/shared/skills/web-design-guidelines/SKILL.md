---
name: web-design-guidelines
user-invocable: false
description: >-
  Use when building or reviewing raw HTML/CSS/JS without a framework. Covers
  semantic HTML, WCAG 2.2 AA accessibility, responsive CSS with fluid sizing
  and container queries, ARIA form validation, typography, Core Web Vitals
  performance, reduced-motion animation, dark mode theming, SEO meta tags and
  JSON-LD structured data, navigation state, touch interaction, i18n with
  logical properties, and print styles. Apply to enforce contrast, build
  accessible forms, optimize LCP/CLS/INP, configure fluid layouts, or handle
  RTL. Does NOT cover Tailwind (`tailwind-design-system`), LIFF
  (`mobile-first-responsive`), design tokens (`design-token-system`), or
  cognitive UX (`ux-psychology`).
---

# Web Platform Design Guidelines

Framework-agnostic rules for accessible, performant, responsive web interfaces based on WCAG 2.2 and the HTML Living Standard.

> Related skills: `mobile-first-responsive` (LIFF/PWA/Tailwind mobile SS2-3), `design-token-system` (token hierarchy SS1-4), `tailwind-design-system` (Tailwind v4 SS1-6), `micro-interaction-patterns` (animation/state SS2-5), `ux-psychology` (cognitive UX WHY SS1-3), `testing-strategy` (accessibility testing SS4), `security-review` (form security SS3).

---

## 1. Accessibility / WCAG [CRITICAL]

Accessibility is not optional. Every rule maps to WCAG 2.2 Level A or AA.

### 1.1 Semantic HTML

Use elements for their intended purpose. Semantic structure provides free accessibility, SEO, and reader-mode support.

Key elements: `<main>` (one per page), `<nav>`, `<header>`/`<footer>`, `<article>`, `<section>` (with heading), `<aside>`, `<figure>`/`<figcaption>`, `<details>`/`<summary>`, `<dialog>`, `<time>`, `<address>`, `<search>`.

**Anti-pattern**: `<div onclick>` instead of `<button>`. > Element table: reference.md SS1.1

### 1.2 ARIA Labels

Every interactive element must have an accessible name (SC 4.1.2). Prefer visible text; use `aria-label` only when insufficient. Icon-only buttons need `aria-label`. Use `aria-labelledby` to reference headings. **Rule**: Prefer native HTML over ARIA. > Roles: reference.md SS1.11

### 1.3 Keyboard Navigation

All interactive elements reachable via keyboard (SC 2.1.1). Use native elements (`<button>`, `<a href>`, `<input>`). Custom widgets: `tabindex="0"` + keydown. Never `tabindex` > 0. Trap focus in modals; return on close. > Focus trap: reference.md SS1.3

### 1.4 Focus Indicators

Never remove focus outlines without a visible replacement (SC 2.4.7, 2.4.11).

```css
:focus-visible { outline: 3px solid var(--focus-color, #4A90D9); outline-offset: 2px; }
```

WCAG 2.2: minimum area = perimeter x 2px, 3:1 contrast against adjacent colors.

### 1.5 Skip Navigation

Skip link to bypass repeated content (SC 2.4.1). > Example: reference.md SS1.5

### 1.6 Alt Text

Every `<img>` needs `alt` (SC 1.1.1). **Informative**: describe content. **Decorative**: `alt=""`. **Functional**: describe action. **Complex**: short `alt` + `<figcaption>`.

### 1.7 Color Contrast

Minimum ratios (SC 1.4.3, 1.4.11): normal text 4.5:1, large text (>=24px / >=18.66px bold) 3:1, UI components/graphics 3:1. Never rely on color alone (SC 1.4.1) -- pair with icons, text, or patterns.

### 1.8 Form Labels

Every input needs a programmatically associated label (SC 1.3.1, 3.3.2). Use `<label for="id">` (preferred) or implicit wrapping. Never placeholder as sole label.

### 1.9 Error Identification

Identify errors in text (SC 3.3.1). Link to inputs with `aria-describedby`. Use `aria-invalid="true"` and `role="alert"`.

### 1.10 Live Regions

Announce dynamic content (SC 4.1.3): `aria-live="polite"` (idle), `role="alert"` (time-sensitive), `role="status"` (polite status).

### 1.11 Table Accessibility

`<caption>`, `<th scope="col|row">`, `<thead>`/`<tbody>`/`<tfoot>`, `headers` for complex tables (SC 1.3.1). > Example: reference.md SS1.12

---

## 2. Responsive Design [CRITICAL]

> LIFF/PWA/Tailwind: `mobile-first-responsive` SS2-3.

### 2.1 Mobile-First

Base styles for smallest viewport. Layer with `min-width` media queries.

```css
.grid { display: grid; grid-template-columns: 1fr; gap: 1rem; }
@media (min-width: 48rem) { .grid { grid-template-columns: repeat(2, 1fr); } }
@media (min-width: 64rem) { .grid { grid-template-columns: repeat(3, 1fr); } }
```

### 2.2 Fluid Sizing

Use `clamp()`, `min()`, `max()` for fluid sizing without breakpoints.

```css
h1 { font-size: clamp(1.75rem, 1.2rem + 2vw, 3rem); }
.container { width: min(90%, 72rem); margin-inline: auto; }
```

### 2.3 Container Queries

Size components based on their container, not the viewport.

```css
.card-container { container-type: inline-size; container-name: card; }
@container card (min-width: 400px) {
  .card { display: grid; grid-template-columns: 200px 1fr; }
}
```

> More examples: reference.md SS2.3

### 2.4 Content-Based Breakpoints

Set breakpoints where content breaks, not at device widths: `30rem`, `48rem`, `64rem`, `80rem`.

### 2.5 Touch Targets

WCAG 2.2 SC 2.5.8 (AA): min 24x24 CSS px. SC 2.5.5 (AAA): 44x44. Use `::after` to enlarge tap area without changing visual size.

### 2.6 Viewport Meta

```html
<meta name="viewport" content="width=device-width, initial-scale=1">
```

Never `maximum-scale=1` or `user-scalable=no` -- breaks pinch-to-zoom (SC 1.4.4).

### 2.7 No Horizontal Scrolling

Reflow at 320px without horizontal scroll (SC 1.4.10): `max-width: 100%; height: auto` on media, `overflow-wrap: break-word`, scrollable wrappers for tables.

---

## 3. Forms [HIGH]

> Security: `security-review` SS3. Cognitive design: `ux-psychology` SS2.

### 3.1 Label Every Input

Use `<label for="id">` (preferred) or implicit wrapping. See SS1.8.

### 3.2 Autocomplete Attributes

Use `autocomplete` for common fields (SC 1.3.5): `name`, `email`, `tel`, `street-address`, `postal-code`, `cc-number`, `new-password`, `current-password`.

### 3.3 Correct Input Types

Use `email`, `tel`, `url`, `number` (not phone/zip/card), `search`, `date`/`time`/`datetime-local`. Use `text` + `inputmode="numeric"` for PINs/zip.

### 3.4 Inline Validation

Validate on `blur` (not keystroke). Use `aria-describedby`, `aria-invalid`, `role="alert"`.

```html
<label for="user">Username</label>
<input id="user" type="text" aria-describedby="user-err" aria-invalid="true">
<p id="user-err" role="alert">Must be at least 3 characters</p>
```

> Full CSS example: reference.md SS3.4

### 3.5 Fieldset and Legend

Group related inputs with `<fieldset>` + `<legend>`. Essential for radio/checkbox groups.

### 3.6 Required Fields

Use `required` + visible marker. If most fields required, indicate optional ones instead.

### 3.7 Submit Button

Never disable submit. Validate on submit and show errors -- disabled buttons fail to communicate why.

---

## 4. Typography [HIGH]

> For token-based scales, see `design-token-system` SS3.

### 4.1 Font Stacks

```css
body { font-family: system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif; }
code, pre { font-family: ui-monospace, "Cascadia Code", "Source Code Pro", Menlo, Consolas, monospace; }
```

Web fonts: `font-display: swap`, proper fallbacks, subset to used character ranges.

### 4.2 Relative Units

`rem` for sizes/spacing. `html { font-size: 100%; }` respects user preference. Never `px` for font-size. `em` for local scaling.

### 4.3 Line Height and Spacing

Body `line-height` >= 1.5 (SC 1.4.12). Headings: ~1.2. Paragraph spacing >= 2x font size. Letter-spacing adjustable to 0.12em, word-spacing to 0.16em.

### 4.4 Line Length

`.prose { max-width: 75ch; }` -- prevents eye fatigue.

### 4.5 Heading Hierarchy

`h1`-`h6` in order, never skip, one `h1` per page. CSS classes for visual overrides.

### 4.6 Typographic Details

`font-variant-numeric: tabular-nums` for tables. `<q>` for quotations. `<abbr title="">` for abbreviations.

> Typography code: reference.md SS4

---

## 5. Performance [HIGH]

### 5.1 Core Web Vitals

- **LCP** < 2.5s -- preload hero image/font, inline critical CSS
- **CLS** < 0.1 -- set `width`/`height` on media, avoid late-injected content
- **INP** < 200ms -- minimize main-thread work, `scheduler.yield()`

### 5.2 Image Optimization

```html
<img src="hero.webp" alt="Hero" fetchpriority="high" width="1200" height="600">
<img src="card.webp" alt="Card" loading="lazy" width="600" height="400"
     srcset="card-400.webp 400w, card-800.webp 800w" sizes="(min-width: 48rem) 50vw, 100vw">
```

Use `<picture>` for format fallbacks (AVIF > WebP > JPEG). Always set dimensions.

### 5.3 Resource Hints

`<link rel="preconnect">` critical origins. `<link rel="preload">` fonts/above-fold CSS. `<link rel="dns-prefetch">` non-critical. > Examples: reference.md SS5.3

### 5.4 Code Splitting

Dynamic `import()` for route/interaction splitting. `<script defer>` or `<script type="module">` for non-critical JS.

### 5.5 Long Lists

Virtualize lists > a few hundred items -- render only visible rows + buffer.

### 5.6 Layout Thrashing

Batch DOM reads then writes. Never interleave in loops.

```js
const heights = elements.map(el => el.offsetHeight);
elements.forEach((el, i) => { el.style.height = heights[i] + 10 + 'px'; });
```

### 5.7 will-change

Only on elements that animate. Remove after. Never `* { will-change: transform; }`.

### 5.8 Critical CSS

Inline above-fold CSS in `<head>`. Load rest: `<link rel="preload" href="full.css" as="style" onload="this.rel='stylesheet'">`.

> Performance code: reference.md SS5

---

## 6. SEO [HIGH]

### 6.1 Meta Tags

Every page needs unique `<title>` (50-60 chars) and `<meta name="description">` (150-160 chars). Set `<link rel="canonical">`.

```html
<title>Page Title -- Site Name</title>
<meta name="description" content="Unique 150-160 char page summary">
<link rel="canonical" href="https://example.com/page">
```

### 6.2 Open Graph and Social

```html
<meta property="og:title" content="Page Title">
<meta property="og:description" content="Social sharing summary">
<meta property="og:image" content="https://example.com/og.jpg">
<meta property="og:url" content="https://example.com/page">
<meta name="twitter:card" content="summary_large_image">
```

OG images: 1200x630px min. Always absolute URLs. > Full examples: reference.md SS12.2

### 6.3 Structured Data (JSON-LD)

`<script type="application/ld+json">` for rich results. Schemas: `Article`, `BreadcrumbList`, `FAQPage`, `Product`, `Organization`.

```html
<script type="application/ld+json">
{"@context":"https://schema.org","@type":"BreadcrumbList","itemListElement":[
  {"@type":"ListItem","position":1,"name":"Home","item":"https://example.com/"},
  {"@type":"ListItem","position":2,"name":"Products","item":"https://example.com/products"}
]}
</script>
```

> More schemas: reference.md SS12.3

### 6.4 Sitemap and Robots

`sitemap.xml` with canonical URLs and `<lastmod>`. Configure `robots.txt`. `<link rel="sitemap">` in head. > Examples: reference.md SS12.4-5

### 6.5 Semantic HTML for SEO

Landmarks help crawlers. One `<h1>` per page, heading hierarchy. `<time datetime="">` for dates. Descriptive anchor text. > Patterns: reference.md SS12.6

---

## 7. Animation and Motion [MEDIUM]

> For Framer Motion / Next.js, see `micro-interaction-patterns` SS2-5.

### 7.1 Reduced Motion

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

### 7.2 Compositor-Friendly

Animate only `transform` and `opacity` (compositor thread). Never `width`, `height`, `top`, `left`, `margin`, `padding`.

### 7.3 Flash Safety

Never > 3 flashes/sec (SC 2.3.1). Can trigger seizures.

### 7.4 Purposeful Motion

Communicate state, guide attention, show spatial relationships. 150-300ms micro, 300-500ms page transitions.

> Full animation examples: reference.md SS6

---

## 8. Dark Mode and Theming [MEDIUM]

> For token architecture, see `design-token-system` SS2-4.

### 8.1 System Detection

```css
:root { color-scheme: light dark; }
@media (prefers-color-scheme: dark) {
  :root { --color-bg: #0f0f17; --color-text: #e4e4ef; --color-surface: #1c1c2e; }
}
```

`<meta name="color-scheme" content="light dark">`. CSS custom properties for all theme values.

### 8.2 Dark Mode Contrast

Verify contrast in both modes. Avoid pure `#fff` on dark -- use `#e4e4ef`. Dark surfaces need extra text legibility attention.

### 8.3 Adaptive Images

`<picture media="(prefers-color-scheme: dark)">` for theme images. `filter: brightness(0.9)` on decorative dark-mode images.

> Full theming: reference.md SS7

---

## 9. Navigation and State [MEDIUM]

### 9.1 URL Reflects State

`pushState` + `URLSearchParams` for meaningful state. Every shareable view needs a unique URL.

### 9.2 Back/Forward and Scroll

Handle `popstate`. Restore filters, scroll, UI state. `history.scrollRestoration = 'manual'` in SPAs.

### 9.3 Active Navigation

`aria-current="page"` on active nav. Breadcrumbs: `<nav aria-label="Breadcrumb">` + `<ol>` for deep hierarchies.

> Full navigation: reference.md SS8

---

## 10. Touch and Interaction [MEDIUM]

### 10.1 Touch Action

`touch-action`: `pan-y` (vertical), `pan-x` (carousels), `none` (canvas).

### 10.2 Hover/Focus Parity

Pair `:hover` with `:focus-visible`. Never hover-only. `:focus-within` for revealed content.

```css
.card:hover, .card:focus-visible {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  transform: translateY(-2px);
}
```

### 10.3 Scroll Snap

`scroll-snap-type: x mandatory` on container, `scroll-snap-align: start` on items. > Full: reference.md SS9

---

## 11. Internationalization [MEDIUM]

### 11.1 Language and Direction

`lang` on `<html>`. `dir="auto"` for user content. `lang` on inline language switches.

### 11.2 Formatting

`Intl` APIs (`DateTimeFormat`, `NumberFormat`, `RelativeTimeFormat`, `ListFormat`). Never hard-code formats.

### 11.3 CSS Logical Properties

| Physical | Logical |
|----------|---------|
| `margin-left` | `margin-inline-start` |
| `padding-right` | `padding-inline-end` |
| `text-align: left` | `text-align: start` |
| `width` / `height` | `inline-size` / `block-size` |

### 11.4 No Text in Images

Cannot be translated, resized, or read by screen readers. > Full i18n: reference.md SS10

---

## 12. Print Styles [MEDIUM]

```css
@media print {
  nav, footer, .sidebar, button, .no-print { display: none !important; }
  body { background: #fff !important; color: #000 !important; font-size: 12pt; }
  a[href^="http"]::after { content: " (" attr(href) ")"; font-size: 0.8em; }
  h1, h2, h3 { break-after: avoid; }
  table, figure, img { break-inside: avoid; }
  p, li { orphans: 3; widows: 3; }
}
@page { margin: 2cm; size: A4; }
```

Expand collapsed `<details>`. `filter: none` on images. > Full stylesheet: reference.md SS11

---

## Quick Review Checklist [HIGH]

- **Accessibility**: alt text, contrast (4.5:1 / 3:1), keyboard, focus indicators, skip nav, labels, error linking, live regions, no flashing, heading hierarchy, landmarks, table headers
- **Responsive**: no h-scroll at 320px, touch targets >= 24px (AA) / 44px (AAA), viewport meta, container queries
- **Forms**: labels, autocomplete, input types, clear errors, required markers, submit never disabled
- **Performance**: LCP < 2.5s, CLS < 0.1, INP < 200ms, lazy load, dimensions + srcset, preload/preconnect, code split, critical CSS
- **SEO**: unique title + description, canonical, Open Graph, JSON-LD, sitemap, semantic landmarks, h1 hierarchy
- **Motion/Theme**: reduced-motion, transform/opacity only, dark contrast, color-scheme meta
- **i18n**: lang, logical properties, Intl APIs, no image text, RTL tested
- **Print**: @media print, hidden nav, link URLs shown, page breaks

---

## Common Anti-Patterns [HIGH]

| Anti-Pattern | Fix |
|---|---|
| `<div onclick>` | `<button>` |
| `outline: none` | `:focus-visible` custom outline |
| `placeholder` as label | `<label>` |
| `tabindex="5"` | `tabindex="0"` or natural order |
| `user-scalable=no` | Remove it |
| `font-size: 12px` | `font-size: 0.75rem` |
| Animating `width`/`height`/`left` | `transform` + `opacity` |
| Disabled submit | Validate on submit |
| Color alone for status | Icon, text, or pattern |
| `margin-left` | `margin-inline-start` |
| `<img>` without dimensions | `width`/`height` |
| Hover-only disclosure | `:focus-within` + click |
| `<table>` without `<th scope>` | Proper header cells |
| Missing `<title>` / description | Unique per page |
| No `canonical` | `<link rel="canonical">` |
| Inline theme styles | CSS custom properties |
