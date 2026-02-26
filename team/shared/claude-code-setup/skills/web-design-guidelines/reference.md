# Web Design Guidelines -- Reference

Detailed code examples for sections referenced from SKILL.md.

---

## SS1 Accessibility -- Code Examples

### SS1.1 Semantic HTML Elements

| Element | Purpose |
|---------|---------|
| `<main>` | Primary page content (one per page) |
| `<nav>` | Navigation blocks |
| `<header>` / `<footer>` | Introductory / footer content |
| `<article>` | Self-contained, independently distributable content |
| `<section>` | Thematic grouping with a heading |
| `<aside>` | Tangentially related content (sidebars, callouts) |
| `<figure>` / `<figcaption>` | Illustrations, diagrams, code listings |
| `<details>` / `<summary>` | Expandable/collapsible disclosure widget |
| `<dialog>` | Modal or non-modal dialog boxes |
| `<time>` | Machine-readable dates/times |
| `<mark>` | Highlighted/referenced text |
| `<address>` | Contact information |
| `<search>` | Search landmark (replaces `role="search"`) |

```html
<!-- Good -->
<main>
  <article>
    <h1>Article Title</h1>
    <p>Content...</p>
  </article>
  <aside>Related links</aside>
</main>

<!-- Search landmark -->
<search>
  <form action="/search">
    <label for="q">Search</label>
    <input id="q" type="search" name="q">
    <button type="submit">Search</button>
  </form>
</search>

<!-- Bad: div soup -->
<div class="main">
  <div class="article">
    <div class="title">Article Title</div>
    <div class="content">Content...</div>
  </div>
</div>
```

### SS1.2 ARIA Labels Examples

```html
<!-- Icon-only button: needs aria-label -->
<button aria-label="Close dialog">
  <svg aria-hidden="true">...</svg>
</button>

<!-- Linked by labelledby -->
<h2 id="section-title">Notifications</h2>
<ul aria-labelledby="section-title">...</ul>

<!-- Redundant: visible text is enough -->
<button>Save Changes</button> <!-- No aria-label needed -->
```

### SS1.3 Focus Trap for Modal

```js
dialog.addEventListener('keydown', (e) => {
  if (e.key === 'Tab') {
    const focusable = dialog.querySelectorAll(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    );
    const first = focusable[0];
    const last = focusable[focusable.length - 1];
    if (e.shiftKey && document.activeElement === first) {
      e.preventDefault();
      last.focus();
    } else if (!e.shiftKey && document.activeElement === last) {
      e.preventDefault();
      first.focus();
    }
  }
});
```

> **React/Next.js:** Radix Dialog / Headless UI Dialog が自動でfocus trapを提供。手動実装は非推奨。

### SS1.3b Native Dialog with Proper A11y

```tsx
// Native Dialog with proper a11y
'use client'
import { useId, useRef } from 'react'

export function NativeDialog({ children, trigger, title }: { children: React.ReactNode; trigger: string; title: string }) {
  const ref = useRef<HTMLDialogElement>(null)
  const titleId = useId()

  return (
    <>
      <button onClick={() => ref.current?.showModal()}>{trigger}</button>
      <dialog
        ref={ref}
        aria-labelledby={titleId}
        className="rounded-lg p-6 backdrop:bg-black/50"
        onClose={() => ref.current?.close()}
      >
        <h2 id={titleId}>{title}</h2>
        {children}
        <form method="dialog">
          <button className="mt-4">閉じる</button>
        </form>
      </dialog>
    </>
  )
}
```

> **ポイント:** `<dialog>` + `showModal()` はブラウザネイティブでfocus trap、Escキー閉じ、`backdrop` 擬似要素を提供する。外部ライブラリ不要で軽量。`<form method="dialog">` 内のボタンは自動的にダイアログを閉じる。

### SS1.4 Focus Indicator CSS

```css
:focus-visible {
  outline: 3px solid var(--focus-color, #4A90D9);
  outline-offset: 2px;
}
:focus:not(:focus-visible) {
  outline: none;
}
```

### SS1.5 Skip Navigation Link

```html
<body>
  <a href="#main-content" class="skip-link">Skip to main content</a>
  <nav>...</nav>
  <main id="main-content">...</main>
</body>
```

```css
.skip-link {
  position: absolute;
  top: -100%;
  left: 0;
  z-index: 1000;
  padding: 0.75rem 1.5rem;
  background: var(--color-primary);
  color: var(--color-on-primary);
}
.skip-link:focus { top: 0; }
```

**Next.js App Router 向け（layout.tsx に配置）:**

```tsx
// Next.js App Router: layout.tsx に配置
<a href="#main" className="sr-only focus:not-sr-only focus:absolute focus:z-50 focus:p-4">
  Skip to main content
</a>
<main id="main">{children}</main>
```

### SS1.5b Media Accessibility

`<video>` には必ず `<track kind="captions">` を含めること（WCAG SC 1.2.1）。字幕がないと聴覚障害者がコンテンツにアクセスできない:
```html
<video controls>
  <source src="video.mp4" type="video/mp4">
  <track kind="captions" src="captions.vtt" srclang="ja" label="日本語" default>
</video>
```

### SS1.6 Alt Text Examples

```html
<img src="chart.png" alt="Revenue chart: Q1 $2M, Q2 $2.4M, Q3 $3.1M, Q4 $4.5M">
<img src="decorative-wave.svg" alt="">
```

### SS1.7 Contrast Token Example

```css
:root {
  --text-primary: #1a1a2e;    /* on white: ~16:1 */
  --text-secondary: #555770;  /* on white: ~6.5:1 */
  --text-disabled: #767693;   /* on white: ~4.5:1 */
}
```

### SS1.8 Form Label Examples

```html
<!-- Explicit label (preferred) -->
<label for="email">Email address</label>
<input id="email" type="email" autocomplete="email">

<!-- Implicit label (acceptable) -->
<label>
  Email address
  <input type="email" autocomplete="email">
</label>
```

### SS1.9 Error Identification

```html
<label for="email">Email</label>
<input id="email" type="email" aria-describedby="email-error" aria-invalid="true">
<p id="email-error" role="alert">Enter a valid email address, e.g. name@example.com</p>
```

### SS1.10 ARIA Live Regions

```html
<div aria-live="polite" aria-atomic="true">3 results found</div>
<div role="alert">Your session will expire in 2 minutes.</div>
<div role="status">File uploaded successfully.</div>
```

### SS1.11 ARIA Role Quick Reference

| Role | Purpose | Native Equivalent |
|------|---------|-------------------|
| `button` | Clickable action | `<button>` |
| `link` | Navigation | `<a href>` |
| `tab` / `tablist` / `tabpanel` | Tab interface | None |
| `dialog` | Modal | `<dialog>` |
| `alert` | Assertive live region | None |
| `status` | Polite live region | `<output>` |
| `navigation` / `main` / `complementary` | Landmarks | `<nav>` / `<main>` / `<aside>` |
| `search` | Search landmark | `<search>` |
| `img` | Image | `<img>` |
| `list` / `listitem` | List | `<ul>/<li>` |
| `heading` | Heading (with `aria-level`) | `<h1>`-`<h6>` |
| `menu` / `menuitem` | Menu widget | None |
| `tree` / `treeitem` | Tree view | None |
| `grid` / `row` / `gridcell` | Data grid | `<table>` |
| `progressbar` | Progress | `<progress>` |
| `slider` | Range input | `<input type="range">` |
| `switch` | Toggle | `<input type="checkbox">` |

### SS1.12 Table Accessibility

```html
<!-- Simple data table -->
<table>
  <caption>Monthly Sales by Region</caption>
  <thead>
    <tr>
      <th scope="col">Region</th>
      <th scope="col">Q1</th>
      <th scope="col">Q2</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th scope="row">East</th>
      <td>$1.2M</td>
      <td>$1.5M</td>
    </tr>
    <tr>
      <th scope="row">West</th>
      <td>$2.0M</td>
      <td>$2.3M</td>
    </tr>
  </tbody>
</table>

<!-- Complex table with multi-level headers -->
<table>
  <caption>Employee Schedule</caption>
  <thead>
    <tr>
      <td></td>
      <th id="mon" scope="col">Monday</th>
      <th id="tue" scope="col">Tuesday</th>
    </tr>
    <tr>
      <td></td>
      <th id="mon-am" headers="mon" scope="col">AM</th>
      <th id="mon-pm" headers="mon" scope="col">PM</th>
      <th id="tue-am" headers="tue" scope="col">AM</th>
      <th id="tue-pm" headers="tue" scope="col">PM</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th id="alice" scope="row">Alice</th>
      <td headers="alice mon mon-am">Office</td>
      <td headers="alice mon mon-pm">Remote</td>
      <td headers="alice tue tue-am">Office</td>
      <td headers="alice tue tue-pm">Off</td>
    </tr>
  </tbody>
</table>
```

```css
/* Responsive table wrapper */
.table-wrapper {
  overflow-x: auto;
  -webkit-overflow-scrolling: touch;
}
.table-wrapper[role="region"][aria-labelledby] {
  /* Screen readers announce as scrollable region */
}
```

---

## SS2 Responsive Design -- Code Examples

### SS2.1 Mobile-First Grid

```css
.grid { display: grid; grid-template-columns: 1fr; gap: 1rem; }
@media (min-width: 48rem) { .grid { grid-template-columns: repeat(2, 1fr); } }
@media (min-width: 64rem) { .grid { grid-template-columns: repeat(3, 1fr); } }
```

### SS2.2 Fluid Sizing

```css
h1 { font-size: clamp(1.75rem, 1.2rem + 2vw, 3rem); }
.container { width: min(90%, 72rem); margin-inline: auto; }
.gap { gap: clamp(0.5rem, 1vw, 1.5rem); }
```

### SS2.3 Container Queries

```css
.card-container {
  container-type: inline-size;
  container-name: card;
}

@container card (min-width: 400px) {
  .card {
    display: grid;
    grid-template-columns: 200px 1fr;
  }
}

@container card (min-width: 700px) {
  .card {
    grid-template-columns: 300px 1fr;
    gap: 2rem;
  }
}
```

### SS2.5 Touch Target Enlargement

```css
button, a, input, select, textarea {
  min-height: 44px;
  min-width: 44px;
}

.icon-button {
  position: relative;
  width: 24px;
  height: 24px;
}
.icon-button::after {
  content: "";
  position: absolute;
  inset: -10px; /* expands clickable area */
}
```

### SS2.7 Preventing Horizontal Overflow

```css
img, video, iframe, svg {
  max-width: 100%;
  height: auto;
}
.prose { overflow-wrap: break-word; }
.table-wrapper {
  overflow-x: auto;
  -webkit-overflow-scrolling: touch;
}
```

---

## SS3 Forms -- Code Examples

### SS3.2 Autocomplete Attributes

```html
<input type="text" autocomplete="name" name="full-name">
<input type="email" autocomplete="email" name="email">
<input type="tel" autocomplete="tel" name="phone">
<input type="text" autocomplete="street-address" name="address">
<input type="text" autocomplete="postal-code" name="zip">
<input type="text" autocomplete="cc-name" name="card-name">
<input type="text" autocomplete="cc-number" name="card-number">
<input type="password" autocomplete="new-password" name="password">
<input type="password" autocomplete="current-password" name="current-pw">
```

### SS3.3 Input Type with inputmode

```html
<input type="tel" inputmode="numeric" pattern="[0-9]*" autocomplete="one-time-code">
```

### SS3.4 Inline Validation

```html
<div class="field" data-state="error">
  <label for="username">Username</label>
  <input id="username" type="text" aria-describedby="username-hint username-error" aria-invalid="true">
  <p id="username-hint" class="hint">3-20 characters, letters and numbers only</p>
  <p id="username-error" class="error" role="alert">Username must be at least 3 characters</p>
</div>
```

```css
.field[data-state="error"] input {
  border-color: var(--color-error);
  box-shadow: 0 0 0 1px var(--color-error);
}
.field[data-state="error"] .error { display: block; }
.field:not([data-state="error"]) .error { display: none; }
```

### SS3.5 Fieldset and Legend

```html
<fieldset>
  <legend>Shipping Address</legend>
  <label for="street">Street</label>
  <input id="street" type="text" autocomplete="street-address">
</fieldset>

<fieldset>
  <legend>Preferred contact method</legend>
  <label><input type="radio" name="contact" value="email"> Email</label>
  <label><input type="radio" name="contact" value="phone"> Phone</label>
</fieldset>
```

### SS3.6 Required Field Indication

```html
<label for="name">
  Full name <span aria-hidden="true">*</span>
  <span class="sr-only">(required)</span>
</label>
<input id="name" type="text" required autocomplete="name">
```

---

## SS4 Typography -- Code Examples

### SS4.1 Font Stacks

```css
/* System font stack */
body {
  font-family: system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
}
code, pre, kbd {
  font-family: ui-monospace, "Cascadia Code", "Source Code Pro", Menlo, Consolas, monospace;
}

/* Web font with fallbacks */
@font-face {
  font-family: "CustomFont";
  src: url("/fonts/custom.woff2") format("woff2");
  font-display: swap;
  font-weight: 100 900;
}
body { font-family: "CustomFont", system-ui, sans-serif; }
```

### SS4.2 Relative Units

```css
html { font-size: 100%; }
body { font-size: 1rem; }
h1 { font-size: 2.5rem; }
h2 { font-size: 2rem; }
h3 { font-size: 1.5rem; }
small { font-size: 0.875rem; }
```

### SS4.3 Line Height and Spacing

```css
body { line-height: 1.6; }
h1, h2, h3 { line-height: 1.2; }
p + p { margin-top: 1em; }
```

### SS4.4 Line Length

```css
.prose { max-width: 75ch; }
.content { max-width: 40rem; margin-inline: auto; }
```

### SS4.5 Typographic Details

```css
q { quotes: "\201C" "\201D" "\2018" "\2019"; }
.data-table td { font-variant-numeric: tabular-nums; }
```

### SS4.6 Heading Hierarchy

```html
<!-- Good -->
<h1>Page Title</h1>
  <h2>Section</h2>
    <h3>Subsection</h3>
  <h2>Another Section</h2>

<!-- Visual override without breaking hierarchy -->
<h2 class="text-lg">Visually smaller but semantically h2</h2>
```

---

## SS5 Performance -- Code Examples

### SS5.1 Image Loading

```html
<img src="hero.webp" alt="Hero image" fetchpriority="high" width="1200" height="600">
<img src="feature.webp" alt="Feature image" loading="lazy" width="600" height="400">
```

### SS5.2 Responsive Images

```css
img { max-width: 100%; height: auto; }
```

### SS5.3 Resource Hints

```html
<head>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://cdn.example.com" crossorigin>
  <link rel="preload" href="/fonts/main.woff2" as="font" type="font/woff2" crossorigin>
  <link rel="preload" href="/css/critical.css" as="style">
  <link rel="dns-prefetch" href="https://analytics.example.com">
</head>
```

### SS5.4 Code Splitting

```js
// Route-based splitting
const routes = {
  '/dashboard': () => import('./pages/dashboard.js'),
  '/settings':  () => import('./pages/settings.js'),
};

// Interaction-based splitting
button.addEventListener('click', async () => {
  const { openEditor } = await import('./editor.js');
  openEditor();
});
```

### SS5.5 Virtual Scrolling Concept

```js
const visibleStart = Math.floor(scrollTop / itemHeight);
const visibleEnd = visibleStart + Math.ceil(containerHeight / itemHeight);
const buffer = 5;
const renderStart = Math.max(0, visibleStart - buffer);
const renderEnd = Math.min(totalItems, visibleEnd + buffer);
```

### SS5.6 Avoiding Layout Thrashing

```js
// Bad: read-write-read-write
elements.forEach(el => {
  const height = el.offsetHeight;
  el.style.height = height + 10 + 'px';
});

// Good: batch reads, then batch writes
const heights = elements.map(el => el.offsetHeight);
elements.forEach((el, i) => {
  el.style.height = heights[i] + 10 + 'px';
});
```

### SS5.7 will-change Usage

```css
.card:hover { will-change: transform; }
.card.animating { will-change: transform, opacity; }
```

---

## SS6 Animation and Motion -- Full Section

### 6.1 Respect prefers-reduced-motion

```css
.fade-in {
  animation: fadeIn 300ms ease-out;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(8px); }
  to   { opacity: 1; transform: translateY(0); }
}

@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

```js
const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
```

### 6.2 Compositor-Friendly Animations

```css
/* Good: compositor-only */
.slide-in { transition: transform 200ms ease-out, opacity 200ms ease-out; }

/* Bad: triggers layout/paint */
.slide-in-bad { transition: left 200ms, width 200ms, height 200ms; }
```

### 6.3 No Flashing Content

Never flash content more than 3 times per second (SC 2.3.1). This can trigger seizures.

### 6.4 Transitions for State Changes

```css
.dropdown {
  opacity: 0;
  transform: translateY(-4px);
  transition: opacity 150ms ease-out, transform 150ms ease-out;
  pointer-events: none;
}
.dropdown.open {
  opacity: 1;
  transform: translateY(0);
  pointer-events: auto;
}
```

### 6.5 Meaningful Motion Only

Animation should communicate state, guide attention, or show spatial relationships. Never animate for decoration alone.

---

## SS7 Dark Mode and Theming -- Full Section

### 7.1 System Preference Detection

```css
@media (prefers-color-scheme: dark) {
  :root {
    --bg: #0f0f17;
    --text: #e4e4ef;
    --surface: #1c1c2e;
    --border: #2e2e44;
  }
}
```

### 7.2 CSS Custom Properties for Theming

```css
:root {
  color-scheme: light dark;
  --color-bg: #ffffff;
  --color-surface: #f5f5f7;
  --color-text-primary: #1a1a2e;
  --color-text-secondary: #555770;
  --color-border: #d1d1e0;
  --color-primary: #2563eb;
  --color-primary-text: #ffffff;
  --color-error: #dc2626;
  --color-success: #16a34a;
}

@media (prefers-color-scheme: dark) {
  :root {
    --color-bg: #0f0f17;
    --color-surface: #1c1c2e;
    --color-text-primary: #e4e4ef;
    --color-text-secondary: #a0a0b8;
    --color-border: #2e2e44;
    --color-primary: #60a5fa;
    --color-primary-text: #0f0f17;
    --color-error: #f87171;
    --color-success: #4ade80;
  }
}
```

### 7.3 Color-Scheme Meta Tag

```html
<meta name="color-scheme" content="light dark">
```

### 7.4 Maintain Contrast in Both Modes

Verify contrast ratios in both light and dark modes. Dark mode often suffers from low-contrast text on dark surfaces.

### 7.5 Adaptive Images

```html
<picture>
  <source srcset="logo-dark.svg" media="(prefers-color-scheme: dark)">
  <img src="logo-light.svg" alt="Company logo">
</picture>
```

```css
@media (prefers-color-scheme: dark) {
  .decorative-img { filter: brightness(0.9) contrast(1.1); }
}
```

---

## SS8 Navigation and State -- Full Section

### 8.1 URL Reflects State

```js
function updateFilters(filters) {
  const params = new URLSearchParams(filters);
  history.pushState(null, '', `?${params}`);
  renderResults(filters);
}
const params = new URLSearchParams(location.search);
const initialFilters = Object.fromEntries(params);
```

### 8.2 Browser Back/Forward

```js
window.addEventListener('popstate', () => {
  const params = new URLSearchParams(location.search);
  renderResults(Object.fromEntries(params));
});
```

### 8.3 Active Navigation States

```html
<nav aria-label="Main">
  <a href="/" aria-current="page">Home</a>
  <a href="/products">Products</a>
  <a href="/about">About</a>
</nav>
```

```css
[aria-current="page"] {
  font-weight: 700;
  border-bottom: 2px solid var(--color-primary);
}
```

### 8.4 Breadcrumbs

```html
<nav aria-label="Breadcrumb">
  <ol>
    <li><a href="/">Home</a></li>
    <li><a href="/products">Products</a></li>
    <li><a href="/products/widgets" aria-current="page">Widgets</a></li>
  </ol>
</nav>
```

### 8.5 Scroll Restoration

```js
if ('scrollRestoration' in history) {
  history.scrollRestoration = 'manual';
}
function saveScrollPosition() {
  sessionStorage.setItem(`scroll-${location.pathname}`, window.scrollY);
}
window.addEventListener('popstate', () => {
  const saved = sessionStorage.getItem(`scroll-${location.pathname}`);
  if (saved) {
    requestAnimationFrame(() => window.scrollTo(0, parseInt(saved)));
  }
});
```

---

## SS9 Touch and Interaction -- Full Section

### 9.1 Touch-Action for Scroll Control

```css
.vertical-scroll { touch-action: pan-y; }
.carousel { touch-action: pan-x; }
.canvas { touch-action: none; }
```

### 9.2 Tap Highlight

```css
button, a { -webkit-tap-highlight-color: transparent; }
```

### 9.3 Hover and Focus Parity

```css
.card:hover,
.card:focus-visible {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  transform: translateY(-2px);
}
```

### 9.4 No Hover-Only Interactions

```css
/* Good: works with focus and click too */
.trigger:hover .tooltip,
.trigger:focus-within .tooltip,
.tooltip:focus-within {
  display: block;
}
```

### 9.5 Scroll Snap for Carousels

```css
.carousel {
  display: flex;
  overflow-x: auto;
  scroll-snap-type: x mandatory;
  gap: 1rem;
  scroll-padding: 1rem;
}
.carousel > .slide {
  scroll-snap-align: start;
  flex: 0 0 min(85%, 400px);
}
```

---

## SS10 Internationalization -- Full Section

### 10.1 dir and lang Attributes

```html
<html lang="en" dir="ltr">
<p dir="auto">User-submitted text here</p>
<blockquote lang="ar" dir="rtl">...</blockquote>
```

### 10.2 Intl APIs for Formatting

```js
// Dates
new Intl.DateTimeFormat('en-US', { dateStyle: 'long' }).format(date);

// Numbers
new Intl.NumberFormat('de-DE', { style: 'currency', currency: 'EUR' }).format(1234.56);

// Relative time
new Intl.RelativeTimeFormat('en', { numeric: 'auto' }).format(-1, 'day');

// Lists
new Intl.ListFormat('en', { style: 'long', type: 'conjunction' }).format(['a', 'b', 'c']);

// Plurals / Ordinals
const pr = new Intl.PluralRules('en');
const suffixes = { one: 'st', two: 'nd', few: 'rd', other: 'th' };
function ordinal(n) { return `${n}${suffixes[pr.select(n)]}`; }
```

### 10.3 Avoid Text in Images

Text in images cannot be translated, resized, or read by screen readers.

### 10.4 CSS Logical Properties

```css
.sidebar {
  margin-inline-start: 1rem;
  padding-inline-end: 2rem;
  border-inline-start: 1px solid var(--color-border);
}
.stack > * + * { margin-block-start: 1rem; }
.box {
  margin-inline: auto;
  padding-block: 2rem;
  inset-inline-start: 0;
  border-start-start-radius: 8px;
}
```

| Physical | Logical |
|----------|---------|
| `left` / `right` | `inline-start` / `inline-end` |
| `top` / `bottom` | `block-start` / `block-end` |
| `margin-left` | `margin-inline-start` |
| `padding-right` | `padding-inline-end` |
| `border-top-left-radius` | `border-start-start-radius` |
| `width` | `inline-size` |
| `height` | `block-size` |
| `text-align: left` | `text-align: start` |

### 10.5 RTL Layout Support

```css
.layout { display: flex; gap: 1rem; }
[dir="rtl"] .arrow-icon { transform: scaleX(-1); }
```

---

## SS11 Print Styles -- Full Section

### 11.1 Base Print Stylesheet

```css
@media print {
  /* Hide non-essential UI */
  nav, footer, .sidebar, .no-print,
  button, .ad, .cookie-banner {
    display: none !important;
  }

  /* Reset backgrounds and colors for ink savings */
  body {
    background: #fff !important;
    color: #000 !important;
    font-size: 12pt;
    line-height: 1.5;
  }

  /* Show URLs after links */
  a[href^="http"]::after {
    content: " (" attr(href) ")";
    font-size: 0.8em;
    font-weight: normal;
    word-break: break-all;
  }
  a[href^="#"]::after,
  a[href^="javascript"]::after {
    content: "";
  }

  /* Expand abbreviations */
  abbr[title]::after {
    content: " (" attr(title) ")";
  }

  /* Page break control */
  h1, h2, h3 {
    page-break-after: avoid;
    break-after: avoid;
  }
  table, figure, img, pre, blockquote {
    page-break-inside: avoid;
    break-inside: avoid;
  }
  p, li {
    orphans: 3;
    widows: 3;
  }

  /* Ensure images are visible */
  img {
    max-width: 100% !important;
    filter: none !important;
  }

  /* details要素の展開はCSSだけでは不可（open属性はHTML属性）。 */
  /* JS: document.querySelectorAll('details').forEach(d => d.open = true); */
  /* CSS代替: details内容を常時表示し、summaryを非表示にする */
  details > summary { display: none; }
  details > *:not(summary) { display: block !important; }
}
```

### 11.2 Page Margins

```css
@page {
  margin: 2cm;
  size: A4;
}
@page :first {
  margin-top: 3cm;
}
```
