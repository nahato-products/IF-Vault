# Mobile-First Responsive Reference

SKILL.md の補足テーブル・チートシート集。

---

## 1. HTML Input Type & Virtual Keyboard Cheatsheet

| Input Purpose | `type` | `inputMode` | `autoComplete` | `enterKeyHint` | Keyboard |
|--------------|--------|-------------|----------------|----------------|----------|
| Name (full) | `text` | `text` | `name` | `next` | Standard |
| Email | `email` | `email` | `email` | `next` / `send` | @ key visible |
| Phone | `tel` | `tel` | `tel` | `next` | Numeric dialer |
| Amount / Price | `text` | `decimal` | `off` | `done` | Numeric + dot |
| Quantity (integer) | `text` | `numeric` | `off` | `done` | Numeric only |
| ZIP / Postal Code | `text` | `numeric` | `postal-code` | `next` | Numeric only |
| Credit Card | `text` | `numeric` | `cc-number` | `next` | Numeric only |
| Password | `password` | - | `current-password` | `done` | Standard |
| New Password | `password` | - | `new-password` | `done` | Standard |
| One-Time Code | `text` | `numeric` | `one-time-code` | `done` | Numeric + autofill |
| Search | `search` | `search` | `off` | `search` | Standard + search key |
| URL | `url` | `url` | `url` | `go` | / . key visible |
| Chat Message | `text` | `text` | `off` | `send` | Standard + send key |
| Date (native) | `date` | - | `bday` | - | Date picker |
| Time | `time` | - | - | - | Time picker |

### `enterKeyHint` Values

| Value | Key Label | Use Case |
|-------|----------|----------|
| `enter` | Enter / Return | Default text input |
| `done` | Done / Complete | Last field in form |
| `go` | Go | URL input, search action |
| `next` | Next | Multi-field form (move to next) |
| `previous` | Previous | Move to previous field |
| `search` | Search | Search input |
| `send` | Send | Chat / message input |

---

## 2. Viewport Units Comparison

| Unit | Full Name | Behavior | iOS Safari | Android Chrome | LIFF Browser |
|------|-----------|----------|------------|----------------|--------------|
| `vh` | Viewport Height | Static (initial viewport) | 100vh > visible area (URL bar) | 100vh > visible area | Same as vh |
| `svh` | Small Viewport Height | Toolbar visible (smallest VP) | Stable, recommended | Stable | Stable |
| `lvh` | Large Viewport Height | Toolbar hidden (largest VP) | Stable | Stable | Stable |
| `dvh` | Dynamic Viewport Height | Changes as toolbar animates | Buggy: gaps, stuttering | Works but jittery | Avoid |
| `-webkit-fill-available` | WebKit Fill | Fills available space | Good fallback | Not supported | iOS only |

### Recommendation Matrix

| Scenario | Recommended Unit | Reason |
|----------|-----------------|--------|
| Full-screen app shell | `100svh` | Consistent across toolbar states |
| Hero / splash screen | `100lvh` | Uses maximum available space |
| Fixed overlay / modal | `100svh` | Won't extend behind toolbar |
| Scroll container min-height | `100svh` | Content always reachable |
| Background decoration | `100lvh` | Covers full area when toolbar hides |

---

## 3. Safe Area Inset Values by Device

| Device | Top | Bottom | Left | Right |
|--------|-----|--------|------|-------|
| iPhone 15 Pro / 16 Pro | 59px | 34px | 0 | 0 |
| iPhone 15 / 16 | 59px | 34px | 0 | 0 |
| iPhone SE (3rd) | 20px | 0 | 0 | 0 |
| iPhone (landscape, notch) | 0 | 21px | 47px | 47px |
| Android (punch-hole) | varies | 0 | 0 | 0 |
| Android (nav gesture bar) | 0 | ~24px | 0 | 0 |

> These values are approximate. Always use `env()` for dynamic values.

---

## 4. LIFF Size Mode Reference

| Property | Full | Tall | Compact |
|----------|------|------|---------|
| Screen coverage | 100% | ~75% | ~50% |
| Top status bar visible | No (overlaid) | Yes | Yes |
| User can swipe to dismiss | No | Yes (drag down) | Yes (drag down) |
| Recommended for | Main app, complex forms | Settings, profiles | Quick actions, confirms |
| min-height CSS | `100svh` | N/A (auto) | N/A (auto) |
| Safe area top | Need padding | LINE header handles | LINE header handles |
| Safe area bottom | Need padding | Need padding | May not be needed |
| Keyboard behavior | Pushes content up | Pushes content up | May overlay sheet |
| Max items visible | Full scroll | ~6-8 items | ~3-4 items |
| Navigation | Full custom nav | Simple back/close | Close only |
| `liff.closeWindow()` | Closes -> chat | Closes -> chat | Closes -> chat |

### LIFF Browser Differences from Regular Browser

| Feature | LIFF Browser | Regular Browser |
|---------|-------------|-----------------|
| `liff.closeWindow()` | Works | Not available |
| `liff.scanCode()` | Works | Not available |
| `liff.shareTargetPicker()` | Works | Not available |
| `history.back()` | May close LIFF | Normal back |
| Pull-to-refresh | Disabled by LINE | Browser default |
| DevTools | Not available | Available |
| `navigator.share()` | May conflict with LINE share | Native share UI |
| URL bar | Hidden | Visible |
| Cookie persistence | Session-based | Persistent |
| Cache behavior | Aggressive | Standard |

---

## 5. Tailwind Breakpoint Reference (Mobile-First)

### Default Breakpoints

| Prefix | Min-Width | Target Devices | CSS |
|--------|-----------|---------------|-----|
| *(none)* | 0px | All (mobile-first base) | `/* no media query */` |
| `xs:` | 375px | iPhone SE+, small phones | `@media (width >= 375px)` |
| `sm:` | 640px | Large phone landscape, small tablet | `@media (width >= 640px)` |
| `md:` | 768px | Tablet portrait | `@media (width >= 768px)` |
| `lg:` | 1024px | Tablet landscape, desktop | `@media (width >= 1024px)` |
| `xl:` | 1280px | Desktop | `@media (width >= 1280px)` |

### Container Query Breakpoints (Tailwind v4)

| Prefix | Min-Width | Typical Use |
|--------|-----------|-------------|
| `@xs:` | 20rem (320px) | Compact card layout |
| `@sm:` | 24rem (384px) | Card with side image |
| `@md:` | 28rem (448px) | Two-column card |
| `@lg:` | 32rem (512px) | Wide card layout |
| `@xl:` | 36rem (576px) | Full feature card |
| `@2xl:` | 42rem (672px) | Dashboard widget |

### Responsive Pattern Examples

```
Layout: vertical -> horizontal -> grid
flex flex-col sm:flex-row lg:grid lg:grid-cols-3

Font scaling: small -> medium -> large
text-sm sm:text-base lg:text-lg

Spacing: tight -> normal -> loose
p-3 sm:p-4 lg:p-6 gap-2 sm:gap-3 lg:gap-4

Visibility: show/hide by device
hidden sm:block          (hide on mobile, show on tablet+)
sm:hidden                (show on mobile only)
block md:hidden          (mobile + small tablet only)
```

---

## 6. Touch Interaction Reference

### Touch Target Sizes

| Standard | Minimum | Recommended | Comfortable |
|----------|---------|-------------|-------------|
| Material Design | 48x48dp | 48x48dp | 56x56dp |
| Apple HIG | 44x44pt | 44x44pt | 48x48pt |
| WCAG 2.2 (AAA) | 44x44 CSS px | 44x44 CSS px | 48x48 CSS px |
| **This project** | **48x48dp** | `min-h-12 min-w-12` | `min-h-14 min-w-14` |

### Touch Target Spacing

| Context | Minimum Gap | Tailwind Class |
|---------|-------------|----------------|
| Button row | 8px | `gap-2` |
| List items | 0px (with dividers) | `divide-y` |
| Icon buttons | 8px | `gap-2` |
| Form fields | 16px | `gap-4` / `space-y-4` |
| Bottom tab items | Equal distribute | `justify-around` |

### Gesture Reference

| Gesture | Use For | Accessibility Alt | LIFF Caveat |
|---------|---------|-------------------|-------------|
| Tap | Primary action | Keyboard Enter | - |
| Long press | Context menu | Button with menu | May conflict with text select |
| Swipe horizontal | Dismiss, navigate | Button/link | Conflicts in Compact/Tall dismiss |
| Swipe vertical | Scroll, pull-to-refresh | Native scroll | Conflicts with LIFF sheet dismiss |
| Pinch | Zoom | Zoom buttons | Usually disabled in LIFF |
| Double tap | Zoom / like | Button | May trigger zoom if not disabled |

---

## 7. PWA Manifest Configuration

### Required Fields

| Field | Value | Note |
|-------|-------|------|
| `id` | `"/app"` | Unique identifier |
| `name` | Full app name | Install dialog, splash screen |
| `short_name` | Max 12 chars | Home screen label |
| `start_url` | `"/"` | Entry point when launched |
| `display` | `"standalone"` | App-like (no browser chrome) |
| `icons` | 192px + 512px | Both required for install |

### Display Modes

| Mode | Browser Chrome | Status Bar | Best For |
|------|---------------|------------|----------|
| `fullscreen` | None | None | Games, immersive |
| `standalone` | None | System | Most PWAs |
| `minimal-ui` | Minimal | System | Content apps |
| `browser` | Full | System | Not PWA-like |

### Icon Requirements

| Size | Purpose | Required |
|------|---------|----------|
| 192x192 | General icon | Yes |
| 512x512 | Splash screen | Yes |
| 512x512 maskable | Adaptive icon (Android) | Strongly recommended |
| 180x180 | Apple touch icon | For iOS home screen |

---

## 8. CSS Utility Patterns for Mobile

### Safe Area Utilities (Tailwind v4 Custom)

```css
/* globals.css — 主要ユーティリティのみ（必要に応じて pl-safe, pr-safe, p-safe 等を追加） */
@utility pb-safe { padding-bottom: env(safe-area-inset-bottom); }
@utility pt-safe { padding-top: env(safe-area-inset-top); }
@utility h-screen-safe {
  height: calc(100svh - env(safe-area-inset-top) - env(safe-area-inset-bottom));
}
@utility min-h-screen-safe {
  min-height: calc(100svh - env(safe-area-inset-top) - env(safe-area-inset-bottom));
}
```

### Common Mobile Layout Patterns

```
/* Full-screen app shell */
.app-shell {
  @apply flex min-h-screen-safe flex-col pt-safe;
}

/* Scrollable main content with fixed header + bottom bar */
.main-content {
  @apply flex-1 overflow-y-auto pb-20; /* pb-20 for bottom tab bar */
}

/* Fixed bottom bar */
.bottom-bar {
  @apply fixed inset-x-0 bottom-0 border-t bg-white/95 pb-safe backdrop-blur-sm;
}

/* Fixed bottom action button (LINE-style) */
.bottom-action {
  @apply fixed inset-x-0 bottom-0 p-4 pb-safe bg-white border-t;
}
```

---

## 9. iOS Safari Specific Quirks & Fixes

| Issue | Description | Fix |
|-------|-------------|-----|
| 100vh overflow | URL bar not accounted for | Use `100svh` or `-webkit-fill-available` |
| Fixed position + keyboard | Fixed elements hidden behind keyboard | Use `visualViewport` API to detect |
| Tap 300ms delay | Delay on double-tap-to-zoom | `touch-action: manipulation` on body |
| Overscroll bounce | Rubber-band effect on edges | `overscroll-behavior: none` on html/body |
| Input zoom on focus | Auto-zoom when font < 16px | Set input `font-size: 16px` minimum |
| `position: fixed` in scroll | Fixed elements jitter during scroll | Use `position: sticky` when possible |
| `dvh` gaps | Gap between overlay and URL bar | Use `svh` instead of `dvh` |
| Safe area in landscape | Insets change in landscape | Always use `env()`, never hardcode |
| `backdrop-filter` performance | Blur causes jank on older devices | Limit to small areas, test on device |
| Smooth scroll + fixed | `scroll-behavior: smooth` conflicts with fixed | Disable smooth scroll on fixed containers |

### iOS Safari Input Zoom Prevention

```css
/* 16px未満 → 自動ズーム。text-base (16px) = safe, text-sm (14px) = NG */
input, select, textarea { font-size: 16px; }
```

---

## 10. Performance Budget for Mobile

| Metric | Budget | Measurement |
|--------|--------|-------------|
| First Contentful Paint | < 1.8s (3G) | Lighthouse |
| Largest Contentful Paint | < 2.5s | Core Web Vitals |
| Total Blocking Time | < 200ms | Lighthouse |
| Cumulative Layout Shift | < 0.1 | Core Web Vitals |
| Interaction to Next Paint | < 200ms | Core Web Vitals |
| JS Bundle (initial) | < 100KB gzip | Build output |
| Image (hero) | < 100KB | next/image auto |
| Font files | < 50KB total | Subset + swap |

### Image Format Priority

| Format | Compression | Browser Support | Next.js |
|--------|------------|-----------------|---------|
| AVIF | Best (50%+ smaller) | 93%+ | Default in next/image |
| WebP | Great (25-35% smaller) | 97%+ | Fallback |
| JPEG | Good (baseline) | 100% | Last fallback |
| PNG | Lossless | 100% | Icons, screenshots |
| SVG | Vector | 100% | Icons, illustrations |

---

## 11. LIFF Testing Checklist

```
Environments: LIFF(iOS/Android), External(Safari/Chrome), Desktop, PWA
Devices:      iPhone SE, iPhone 15/16 Pro, Android mid-range/budget
Scenarios:    Keyboard open, Landscape, Slow 3G, Offline, Deep link, Cache
```

> デバッグツール: `eruda`, Chrome Remote Debug (`chrome://inspect`), Safari Web Inspector

---

## 12. Next.js App Router Mobile Patterns

### Viewport & Root Layout

```tsx
// app/layout.tsx
import type { Viewport, Metadata } from 'next';

export const viewport: Viewport = {
  width: 'device-width', initialScale: 1, maximumScale: 1,
  userScalable: false, viewportFit: 'cover',
  interactiveWidget: 'resizes-content',
  themeColor: [
    { media: '(prefers-color-scheme: light)', color: '#ffffff' },
    { media: '(prefers-color-scheme: dark)', color: '#0a0a0a' },
  ],
};

export const metadata: Metadata = {
  title: 'My App',
  appleWebApp: { capable: true, statusBarStyle: 'black-translucent', title: 'My App' },
  formatDetection: { telephone: false },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ja" className="antialiased">
      <body className="flex min-h-svh flex-col bg-white text-gray-900 overscroll-none"
        style={{
          paddingTop: 'env(safe-area-inset-top)',
          paddingLeft: 'env(safe-area-inset-left)',
          paddingRight: 'env(safe-area-inset-right)',
        }}>
        {children}
      </body>
    </html>
  );
}
```

---

## 13. Full Component Implementations

> LIFF UIコンポーネント（LiffHeader等）の実装例は **line-bot-dev** 参照

### BottomSheet

```tsx
'use client';
import { useRef, type ReactNode } from 'react';

type BottomSheetProps = {
  children: ReactNode;
  open: boolean;
  onClose: () => void;
  snapPoints?: number[];
};

export function BottomSheet({ children, open, onClose, snapPoints = [0.5, 0.9] }: BottomSheetProps) {
  const sheetRef = useRef<HTMLDivElement>(null);
  if (!open) return null;

  return (
    <>
      <div className="fixed inset-0 z-40 bg-black/40" onClick={onClose} aria-hidden="true" />
      <div
        ref={sheetRef}
        role="dialog"
        aria-modal="true"
        className="fixed inset-x-0 bottom-0 z-50 flex flex-col rounded-t-2xl bg-white shadow-2xl"
        style={{ maxHeight: `${snapPoints[snapPoints.length - 1] * 100}svh` }}
      >
        <div className="flex justify-center py-3">
          <div className="h-1 w-10 rounded-full bg-gray-300" />
        </div>
        <div className="flex-1 overflow-y-auto overscroll-contain px-4 pb-safe">
          {children}
        </div>
      </div>
    </>
  );
}
```

### BottomTabBar

```tsx
// Key patterns:
// - fixed inset-x-0 bottom-0 z-50 + backdrop-blur-sm
// - paddingBottom: 'max(0.5rem, env(safe-area-inset-bottom))'
// - Each tab: min-h-12 min-w-12 (48dp touch target)
// - Active state: aria-current="page" + color change
// - Main content needs: pb-20 to avoid overlap
'use client';
import { usePathname } from 'next/navigation';
import Link from 'next/link';

const tabs = [
  { href: '/', icon: Home, label: 'Home' },
  { href: '/search', icon: Search, label: 'Search' },
  // ...
] as const;

export function BottomTabBar() {
  const pathname = usePathname();
  return (
    <nav className="fixed inset-x-0 bottom-0 z-50 border-t bg-white/95 backdrop-blur-sm"
      style={{ paddingBottom: 'max(0.5rem, env(safe-area-inset-bottom))' }}>
      <ul className="flex items-center justify-around px-2 pt-2">
        {tabs.map(({ href, icon: Icon, label }) => (
          <li key={href}>
            <Link href={href}
              className={`flex min-h-12 min-w-12 flex-col items-center justify-center gap-0.5 ${
                pathname === href ? 'text-blue-600' : 'text-gray-500 active:bg-gray-100'
              }`}
              aria-current={pathname === href ? 'page' : undefined}>
              <Icon className="size-5" />
              <span className="text-[10px] font-medium">{label}</span>
            </Link>
          </li>
        ))}
      </ul>
    </nav>
  );
}
```

### FloatingInput

```tsx
'use client';
import { forwardRef, type InputHTMLAttributes } from 'react';

type FloatingInputProps = InputHTMLAttributes<HTMLInputElement> & { label: string };

export const FloatingInput = forwardRef<HTMLInputElement, FloatingInputProps>(
  ({ label, id, className = '', ...props }, ref) => {
    const inputId = id ?? label.toLowerCase().replace(/\s+/g, '-');
    return (
      <div className="relative">
        <input
          ref={ref}
          id={inputId}
          placeholder=" "
          className={`peer w-full rounded-lg border border-gray-300 bg-white px-4 pb-2 pt-5 text-base
            focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500 ${className}`}
          {...props}
        />
        <label
          htmlFor={inputId}
          className="pointer-events-none absolute left-4 top-4 origin-top-left text-gray-500 transition-all
            peer-focus:top-2 peer-focus:scale-75 peer-focus:text-blue-500
            peer-[:not(:placeholder-shown)]:top-2 peer-[:not(:placeholder-shown)]:scale-75"
        >
          {label}
        </label>
      </div>
    );
  }
);
FloatingInput.displayName = 'FloatingInput';
```

Key points:
- `text-base` (16px) で iOS 自動ズーム防止
- `placeholder=" "` で `:placeholder-shown` の CSS 状態管理
- `peer` + `peer-focus` / `peer-[:not(:placeholder-shown)]` で label 位置を切り替え

### Service Worker (Serwist)

```ts
// next.config.ts
import withSerwistInit from '@serwist/next';
const withSerwist = withSerwistInit({ swSrc: 'app/sw.ts', swDest: 'public/sw.js' });
export default withSerwist({ /* Next.js config */ });
```

```ts
// app/sw.ts — key config options:
// precacheEntries: self.__SW_MANIFEST, skipWaiting: true, clientsClaim: true,
// navigationPreload: true, runtimeCaching: defaultCache,
// fallbacks: { entries: [{ url: '/offline', matcher: req => req.destination === 'document' }] }
import { defaultCache } from '@serwist/next/worker';
import { Serwist } from 'serwist';

const serwist = new Serwist({
  precacheEntries: self.__SW_MANIFEST,
  skipWaiting: true, clientsClaim: true,
  navigationPreload: true, runtimeCaching: defaultCache,
  fallbacks: { entries: [{ url: '/offline', matcher: ({ request }) => request.destination === 'document' }] },
});
serwist.addEventListeners();
```

### Install Prompt Hook

```tsx
'use client';
import { useEffect, useState } from 'react';

interface BeforeInstallPromptEvent extends Event {
  prompt(): Promise<void>;
  userChoice: Promise<{ outcome: 'accepted' | 'dismissed' }>;
}

export function useInstallPrompt() {
  const [deferredPrompt, setDeferredPrompt] = useState<BeforeInstallPromptEvent | null>(null);
  const [isInstalled, setIsInstalled] = useState(false);

  useEffect(() => {
    // Check if already installed
    if (window.matchMedia('(display-mode: standalone)').matches) {
      setIsInstalled(true);
      return;
    }

    const handler = (e: Event) => {
      e.preventDefault();
      setDeferredPrompt(e as BeforeInstallPromptEvent);
    };
    window.addEventListener('beforeinstallprompt', handler);

    const installedHandler = () => setIsInstalled(true);
    window.addEventListener('appinstalled', installedHandler);

    return () => {
      window.removeEventListener('beforeinstallprompt', handler);
      window.removeEventListener('appinstalled', installedHandler);
    };
  }, []);

  const install = async () => {
    if (!deferredPrompt) return false;
    await deferredPrompt.prompt();
    const { outcome } = await deferredPrompt.userChoice;
    setDeferredPrompt(null);
    return outcome === 'accepted';
  };

  return { canInstall: !!deferredPrompt && !isInstalled, isInstalled, install };
}
```

Usage: ボタンに `canInstall` で表示制御、`install()` で prompt 呼び出し。iOS Safari は `beforeinstallprompt` 非対応のため、手動で「ホーム画面に追加」を案内する UI が別途必要。
