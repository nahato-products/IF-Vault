# Baseline UI — Reference

SKILL.md 補足: アクセシブルプリミティブ、Tailwind デフォルト、アンチパターン詳細。

---

## Accessible Primitives

### ライブラリ選定基準

| ライブラリ | 特徴 | 使い分け |
|-----------|------|---------|
| **Radix UI** | unstyled、Tailwind と相性◎、豊富なコンポーネント | shadcn/ui ベースのプロジェクト |
| **Base UI** | MUI 系の unstyled 版、軽量 | MUI エコシステム内 |
| **React Aria** | Adobe 製、最も仕様準拠が厳密 | a11y 要件が厳しいプロジェクト |

### 鉄則

- 1つのサーフェスで複数のプリミティブシステムを混ぜない
- Icon-only ボタンには必ず `aria-label` を付与
- Dialog/Modal は `Dialog` コンポーネントを使い、手動 `div` + `role="dialog"` は避ける
- Focus trap は Radix/React Aria のビルトインを使う（自前実装しない）

---

## Tailwind Defaults

### レイアウト

| パターン | 正 | 誤 |
|---------|-----|-----|
| 全画面高さ | `h-dvh` | `h-screen`（iOS Safari で崩れる） |
| 正方形 | `size-12` | `w-12 h-12` |
| コンテナ | `mx-auto max-w-screen-xl px-4` | `container`（レスポンシブ制御しづらい） |

### タイポグラフィ

| パターン | 適用対象 |
|---------|---------|
| `text-balance` | 見出し（h1-h3） |
| `text-pretty` | 本文・段落 |
| `text-wrap` | デフォルト（短いテキスト） |

### タッチターゲット

- 最小 48x48dp（`min-h-12 min-w-12`）
- padding で拡張する場合は `p-3` 以上

---

## Compositor-Only Animations

### 安全なプロパティ（GPU 加速）

```css
/* OK: compositor-only */
transform: translateX() / translateY() / scale() / rotate()
opacity
filter  /* blur, brightness 等 */
```

### 避けるべきプロパティ（レイアウト再計算）

```css
/* NG: layout thrashing */
width / height / top / left / right / bottom
margin / padding
border-width
font-size
```

### `prefers-reduced-motion` 対応

```tsx
// Framer Motion での対応
<motion.div
  animate={{ opacity: 1, y: 0 }}
  transition={{ duration: 0.2 }}
  // reduced-motion 時は自動的にアニメーション無効化
  layout // layout animation も同様
/>
```

Tailwind: `motion-safe:animate-fade-in motion-reduce:animate-none`

---

## セマンティックトークン

### Z-Index レイヤー規約

| レイヤー | 値 | 用途 |
|---------|-----|------|
| `base` | 0 | 通常コンテンツ |
| `dropdown` | 10 | ドロップダウン、ポップオーバー |
| `sticky` | 20 | ヘッダー、サイドバー |
| `overlay` | 30 | オーバーレイ背景 |
| `modal` | 40 | モーダル、ダイアログ |
| `toast` | 50 | トースト通知 |

カスタム z-index（`z-[999]`）は原則禁止。上記スケール内で収める。

---

## AI 生成 UI アンチパターン

### よくある違反

| パターン | 問題 | 修正 |
|---------|------|------|
| グラデーション多用 | 明示的リクエストなしで装飾過多 | ソリッドカラーで統一 |
| グロー/シャドウ多用 | ダーク UI で安易に使いがち | `shadow-sm` 程度に抑制 |
| 角丸バラバラ | `rounded-lg` と `rounded-xl` が混在 | デザイントークンで統一 |
| ネスト深すぎ | div > div > div > ... | セマンティック HTML + Flex/Grid |
| アイコン乱用 | 全ボタンにアイコン | テキストラベル優先、アイコンは補助 |

### チェックリスト

- [ ] 装飾（グラデーション、グロー、影）はユーザーリクエストに基づくか
- [ ] z-index はレイヤー規約内か
- [ ] アニメーションは compositor-only プロパティのみか
- [ ] タッチターゲットは 48dp 以上か
- [ ] Icon-only ボタンに `aria-label` があるか
- [ ] `h-screen` ではなく `h-dvh` を使っているか

---

## Empty State Design

### 構成要素

1. **イラスト/アイコン**（オプション）: 状況を視覚的に伝える
2. **メッセージ**: 何が空なのか、なぜ空なのかを簡潔に
3. **CTA**: 次にやるべきアクションを1つ提示

### 良い例

```tsx
<div className="flex flex-col items-center gap-4 py-16 text-center">
  <InboxIcon className="size-12 text-muted-foreground" />
  <div>
    <h3 className="text-lg font-medium">メッセージはまだありません</h3>
    <p className="text-sm text-muted-foreground">
      新しい会話を始めてみましょう
    </p>
  </div>
  <Button>メッセージを作成</Button>
</div>
```

### 避けるべき例

- 「データがありません」だけの表示（CTAなし）
- 完全に空白の画面（ユーザーが壊れたと思う）
- 過度なイラストで画面を埋める
