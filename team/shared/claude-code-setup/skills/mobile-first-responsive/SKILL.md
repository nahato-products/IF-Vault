---
name: mobile-first-responsive
description: "LIFF/PWA/mobile web: safe-area insets, svh/dvh, touch targets 48dp, bottom sheet, mobile nav, Serwist, keyboard UX"
user-invocable: false
---

# Mobile-First Responsive Implementation

LIFF (LINE mini apps) + PWA + モバイルWeb向けの実装パターン集。Next.js App Router + Tailwind CSS v4 前提。

## When to Apply

- LIFF アプリの UI 実装・レイアウト調整
- モバイルファーストのレスポンシブ実装
- PWA のセットアップ（manifest, service worker, offline）
- タッチインタラクション・ジェスチャーの実装
- viewport / safe-area / キーボード関連の問題修正
- モバイルフォームの UX 改善

## When NOT to Apply

- 認知心理学に基づく UX 原則（Fitts's Law の根拠等） → ux-psychology
- WCAG / aria / セマンティック HTML / touch target 44px 基準 → web-design-guidelines
- デザイントークン / Tailwind `@theme` 全般設計 → design-token-system
- Tailwind v4 CSS-first 設定・CVA・ダークモード・Container Query の `@theme` 定義 → tailwind-design-system
- LINE Messaging API / Webhook / Flex Message / LIFF SDK 認証 → line-bot-dev
- Loading / skeleton / toast / empty state → micro-interaction-patterns

## Skill Boundaries

| Topic | This Skill | Other Skill |
|-------|-----------|-------------|
| Tailwind responsive classes | `sm:` `md:` でモバイルファーストレイアウト | design-token-system: トークン値の設計 |
| Tailwind `@theme` / custom utilities | `pb-safe`, `h-screen-safe` 等モバイル固有 | tailwind-design-system: 全般的な `@theme` / CVA 設計 |
| Container queries | モバイル向けカード等のコンポーネント幅レスポンシブ | tailwind-design-system: `@container` の CSS-first 設定 |
| Touch targets 48dp (LIFF/PWA) | 実装（`min-h-12 min-w-12`） | ux-psychology: なぜ48dp（Fitts's Law）、web-design-guidelines: WCAG 44px 基準 |
| LIFF API (`liff.init()`) | Viewport / layout / ナビゲーション制約 | line-bot-dev: SDK 初期化・認証・メッセージ送信 |
| Safe area / viewport | CSS 実装 (`env()`, `svh`) | web-design-guidelines: WCAG アクセシビリティ全般 |
| Loading / empty states | N/A (defer) | micro-interaction-patterns: skeleton, shimmer |
| 応答性 400ms 基準 | キーボード検出・UI即時反応の実装 | ux-psychology: Doherty 閾値の心理学的根拠 |

---

## Decision Tree

モバイル実装で困っている？ → LIFF レイアウト: Part 1 → viewport/safe-area/キーボード: Part 2 (ノッチ: 2.1-2.2, 100vh: 2.3, キーボード検出: Part 6.2) → レスポンシブ: Part 3 (breakpoint: 3.1-3.2, Container Query: 3.3) → タッチ/ジェスチャー: Part 4 (ターゲット: 4.1, Bottom Sheet: 4.2, Pull-to-refresh: 4.3) → ナビゲーション: Part 5 → フォームUX: Part 6 → PWA: Part 7

---

## Part 1: LIFF UI Constraints [CRITICAL]

### 1.1 LIFF Size Modes

| Mode | Height | Use Case |
|------|--------|----------|
| **Full** | 100% | メインアプリ、フォーム、ダッシュボード |
| **Tall** | ~75% | 設定画面、プロフィール編集 |
| **Compact** | ~50% | 確認ダイアログ、簡易入力 |

LIFF 環境の検出には `liff.isInClient()` と `liff.getOS()` を使う。`liff.init()` 後に判定し、レイアウト分岐に利用する。

> LIFF SDK 初期化・認証フローの詳細は line-bot-dev スキルを参照。

### 1.2 WebView 制約

| 制約 | 対策 |
|------|------|
| リロードボタンなし | 開発中は `location.reload()` ボタンを配置 |
| DevTools なし | `eruda` / `vconsole` を開発時に導入 |
| 戻るボタンが LINE を閉じる | アプリ内ナビゲーションを自前実装 |
| `liff.closeWindow()` | `liff.isInClient()` で分岐（外部ブラウザ非対応） |
| 積極的キャッシュ | meta タグ + クエリパラメータでバスト |

### 1.3 LIFF ナビゲーション

LIFF 内ではブラウザの戻るボタンが使えないため、ヘッダーに戻る/閉じるボタンを自前で実装する。`liff.isInClient()` で LIFF 内かどうかを判定し、閉じるボタンの表示を分岐する。

> LiffHeader の実装パターンは line-bot-dev スキルを参照（LIFF SDK 連携のため）。

---

## Part 2: Viewport & Safe Area [CRITICAL]

### 2.1 Viewport Meta Tag (Next.js App Router)

`app/layout.tsx` で `export const viewport: Viewport` を設定。必須プロパティ:

| Property | Value | 理由 |
|----------|-------|------|
| `viewportFit` | `'cover'` | ノッチ対応に必須 |
| `maximumScale` | `1` | ダブルタップズーム防止 |
| `userScalable` | `false` | LIFF/PWA では通常無効 |
| `interactiveWidget` | `'resizes-content'` | キーボード時に viewport リサイズ |

> 完全な viewport + metadata 設定コードは [reference.md](reference.md) セクション 12 を参照。

**`interactiveWidget` の値:**

| Value | 動作 | Use Case |
|-------|------|----------|
| `resizes-visual` (default) | Visual VP のみ縮小 | 通常のWebサイト |
| `resizes-content` | Layout + Visual VP 縮小 | チャットUI, フォーム |
| `overlays-content` | 変更なし | カスタムキーボード処理 |

### 2.2 Safe Area Insets

```css
/* app-shell: env(safe-area-inset-top/bottom) で padding */
/* 固定ボトムバー: padding-bottom: max(0.75rem, env(safe-area-inset-bottom)) */
/* 完全パターン → reference.md セクション 14 */
```

Tailwind v4 カスタムユーティリティ（`pb-safe`, `pt-safe`, `h-screen-safe` 等）の `@utility` 定義は [reference.md](reference.md) セクション 8 を参照。

### 2.3 Viewport Units

| Unit | 推奨度 | 動作 |
|------|--------|------|
| `svh` | *** 90%のケースで推奨 | ツールバー表示時（最小VP） |
| `lvh` | スプラッシュ画面向け | ツールバー非表示時（最大VP） |
| `dvh` | 避ける | ツールバーに連動（ガタつく） |
| `vh` | フォールバック用のみ | レガシー（100vh問題あり） |

```css
.full-screen-safe {
  height: 100vh;    /* fallback */
  height: 100svh;   /* modern */
}
```

> 各 viewport unit の詳細比較・デバイス別挙動は [reference.md](reference.md) セクション 2 を参照。

---

## Part 3: Tailwind Mobile-First Strategy [HIGH]

### 3.1 Base = Mobile (CRITICAL RULE)

Tailwind はモバイルファースト。**プレフィックスなし = モバイル**。

```tsx
// GOOD: flex flex-col gap-2 sm:flex-row sm:gap-4 md:grid md:grid-cols-3
// BAD:  grid grid-cols-3 sm:grid-cols-1（デスクトップファースト）
```

### 3.2 Breakpoint Strategy

```css
/* @theme { --breakpoint-xs:375px; sm:640px; md:768px; lg:1024px } */
/* 完全設定 → reference.md セクション 15 */
```

### 3.3 Container Queries (Mobile Layout)

Tailwind v4 ではコンテナクエリがビルトイン。**コンポーネント単位のモバイルレスポンシブ**に使う。`@theme` での Container Query 設定自体は tailwind-design-system を参照。

```tsx
// @container 内で @sm: でレスポンシブ切り替え（flex-col → flex-row）
// 完全パターン → reference.md セクション 16
```

> Breakpoint 一覧・Container Query breakpoint 一覧は [reference.md](reference.md) セクション 5 を参照。

### 3.4 Fluid Typography

```css
/* --font-size-fluid-base: clamp(1rem, 0.9rem + 0.5vw, 1.125rem) */
/* 完全設定 → reference.md セクション 17 */
```

---

## Part 4: Touch Interaction Patterns [HIGH]

### 4.1 Touch Targets (48x48dp Minimum)

LIFF/PWA では WCAG の 44px よりも厳しい **48dp** を採用する（Material Design / このプロジェクト標準）。WCAG 44px 基準の詳細は web-design-guidelines、48dp の心理学的根拠（Fitts's Law）は ux-psychology を参照。

```tsx
// GOOD: <button className="min-h-12 min-w-12 flex items-center justify-center p-3">
// BAD:  <button className="p-1"><Icon className="size-4" /></button>
```

### 4.2 Bottom Sheet

CSS + React で実装。Backdrop + Sheet + Drag handle + overscroll-contain のスクロール制御。

> BottomSheet コンポーネントの完全実装は [reference.md](reference.md) セクション 13 を参照。

### 4.3 Pull-to-Refresh Prevention & Tap Delay

```css
html, body { overscroll-behavior-y: none; }
body { touch-action: manipulation; } /* 300ms遅延解消 */
/* 完全パターン → reference.md セクション 18 */
```

### 4.4 Haptic Feedback

```tsx
// navigator.vibrate: iOS非対応、Android PWAのみ。light/medium/success パターン
// 完全実装 → reference.md セクション 19
```

---

## Part 5: Mobile Navigation [HIGH]

### 5.1 Bottom Tab Bar

LIFF/PWA のメインナビゲーションには Bottom Tab Bar を推奨（3-5項目）。safe-area padding を含めた固定配置で、`aria-current="page"` でアクティブ状態を示す。

> BottomTabBar コンポーネントの完全実装は [reference.md](reference.md) セクション 13 を参照。

### 5.2 Navigation Pattern Selection

| Pattern | Best For | LIFF Compat |
|---------|----------|-------------|
| Bottom Tab Bar | メインナビ（3-5項目） | Excellent |
| Stack Navigation | 詳細画面への遷移 | Excellent |
| Hamburger Drawer | 多階層メニュー（6+項目） | Good |
| Top Tab / Segment | 同カテゴリの切り替え | Good |
| Swipe Navigation | カルーセル / ギャラリー | Fair (dismiss競合) |

---

## Part 6: Mobile Form UX [HIGH]

### 6.1 Input Types & Virtual Keyboard

正しい input type を指定するだけでモバイルキーボードが最適化される。

```tsx
// type="tel" inputMode="tel" → 電話キーボード
// type="text" inputMode="decimal" → 数値キーボード
// 全組み合わせ表 → reference.md セクション 1, 20
```

> 全 input type/inputMode/autoComplete/enterKeyHint の組み合わせ表は [reference.md](reference.md) セクション 1 を参照。

### 6.2 Keyboard-Aware Layout

`visualViewport` API でキーボード表示を検出し、BottomTabBar を非表示にする。

```tsx
// visualViewport API でキーボード検出（innerHeight - vp.height > 150）
// 完全実装 → reference.md セクション 21
```

### 6.3 Floating Label

Tailwind の `peer` を使った CSS-only Floating Label。`placeholder=" "` と `peer-placeholder-shown` / `peer-focus` で状態管理。

> FloatingInput コンポーネントの完全実装は [reference.md](reference.md) セクション 13 を参照。

---

## Part 7: PWA Setup (Next.js) [MEDIUM]

### 7.1 Web App Manifest

`app/manifest.ts` で `MetadataRoute.Manifest` を返す。必須: `id`, `name`, `short_name`(12文字以内), `start_url`, `display: 'standalone'`, アイコン(192px + 512px + maskable)。

> manifest コード例・display mode 比較・アイコン要件は [reference.md](reference.md) セクション 7 を参照。

### 7.2 Service Worker (Serwist)

Serwist で precache + runtime cache + offline fallback を設定。`next.config.ts` で `withSerwist` を適用し、`app/sw.ts` に Serwist インスタンスを定義する。

> Service Worker・Install Prompt の完全実装は [reference.md](reference.md) セクション 13 を参照。

---

## Part 8: Mobile Performance [MEDIUM]

### 8.1 Image Optimization (Mobile Focus)

`next/image` の `sizes` 属性でモバイル向けに最適化。モバイルファーストで記述:

```tsx
sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 800px"
```

- Hero 画像: `priority` + `placeholder="blur"` で LCP 改善
- Below the fold: デフォルトの lazy loading に任せる
- フォーマット: Next.js が自動で AVIF > WebP > JPEG を選択

### 8.2 reduce-motion & Dynamic Import

```tsx
// アニメーション: motion-safe / motion-reduce で分岐
<div className="motion-safe:hover:scale-105 motion-reduce:transition-none">

// 重いモバイルUI は dynamic import
const BottomSheet = dynamic(() => import('@/components/BottomSheet'), { ssr: false });
```

> パフォーマンスバジェット・画像フォーマット優先度は [reference.md](reference.md) セクション 10 を参照。

---

## Quick Reference: LIFF + Mobile Checklist

- [ ] viewport meta: `viewport-fit=cover`, `interactive-widget=resizes-content`
- [ ] safe-area padding on app shell (`env(safe-area-inset-*)`)
- [ ] `svh` units for full-screen layouts
- [ ] `overscroll-behavior-y: none` on html/body
- [ ] `touch-action: manipulation` on body（300ms タップ遅延解消）
- [ ] Touch targets >= 48x48dp (`min-h-12 min-w-12`)
- [ ] Correct input types + `enterKeyHint`
- [ ] Input `font-size: 16px` minimum（iOS 自動ズーム防止）
- [ ] Hide bottom bar when virtual keyboard visible
- [ ] PWA manifest with maskable icons
- [ ] `prefers-reduced-motion` respected
- [ ] Test on actual LIFF browser (not just Chrome DevTools)

> 詳細テーブル集は [reference.md](reference.md) を参照。

---

## Cross-references [MEDIUM]

- `tailwind-design-system` — Tailwind v4 CSS-first `@theme` 設定、CVA バリアント、Container Query の `@container` 定義
- `ux-psychology` — Fitts's Law（48dp の根拠）、Doherty 閾値（400ms）、認知心理学に基づく UX 原則
- `web-design-guidelines` — WCAG 2.2 AA アクセシビリティ基準、タッチターゲット 44px、セマンティック HTML
