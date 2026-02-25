# Style Reference DB — Reference

実測・公開情報ベースのプリセット詳細値。SKILL.md の推定値を実測で補強するためのデータ集。

---

## Section A: 実測データ（サイト別）

### Airbnb（実測値あり）

```yaml
measured:
  border_radius:
    tiny: "4px"       # --corner-radius-tiny4px
    small: "8px"      # --corner-radius-small8px
    medium: "12px"    # --corner-radius-medium12px
    large: "16px"     # --corner-radius-large16px
    xlarge: "24px"    # --corner-radius-xxlarge24px
    xxxlarge: "32px"  # --corner-radius-xxxlarge32px
    circle: "50%"     # アバター・アイコン

  colors:
    primary: "#FF385C"         # Rausch（ブランドピンク）
    text_primary: "#222222"    # 濃いグレー
    text_secondary: "#6A6A6A"  # セカンダリテキスト
    background: "#FFFFFF"      # 白
    background_alt: "#F7F7F7"  # 薄いグレー
    border: "#DDDDDD"         # ライトグレー
    error: "#C13515"          # 深い赤
    # OKLCH 変換
    primary_oklch: "oklch(0.63 0.22 12)"    # FF385C
    text_oklch: "oklch(0.20 0.00 0)"        # 222222

  font:
    family: "'Airbnb Cereal VF', 'Circular', -apple-system, 'BlinkMacSystemFont', 'Roboto', 'Helvetica Neue', sans-serif"
    variable_font: true

  animation:
    spring_fast: "451ms"
    spring_standard: "583ms"
    shimmer_skeleton: "1.3s loop"
    scale_active: "0.98"     # ボタンクリック時98%に縮小
    easing: "custom linear() 関数（自然な減衰）"

  spacing:
    micro: "2px-4px"
    standard: "12px-24px"
    section: "32px-64px"

updated_tokens:
  hue: 12               # 実測: #FF385C の Hue ≈ 12
  shape: 0.75            # 実測: 12-16px がメイン → 0.75rem
  density: 0.375         # 実測: 12-24px 標準パディング → 4px×3基準
  type_scale: 1.25       # 推定維持
  motion: "standard"     # 実測: 451-583ms → やや遅めだがspring系
```

### SmartHR（実測値あり）

```yaml
measured:
  border_radius:
    standard: "0.5rem"     # 8px — カード・ボタン
    button_pill: "4rem"    # ピル型ボタン
    fine: "0.125rem"       # リンク下線オフセット

  colors:
    primary: "aqua系（CSS変数管理）"
    text: "var(--service-text-primary)"
    accent: "var(--service-text-aqua-3), var(--service-text-aqua-4)"
    background: "var(--service-background-white)"
    border: "var(--service-separate-primary)"
    # SmartHR UI のブランドカラー
    brand_blue: "#0077C7"  # 推定
    brand_blue_oklch: "oklch(0.55 0.14 240)"

  font:
    weight_normal: 400
    weight_bold: 700
    line_height: "1.4-1.6"  # 日本語可読性確保

  animation:
    fast: "100ms"           # スライド
    standard: "250ms"       # cubic-bezier
    slow: "400-500ms"       # 展開・折畳

  spacing:
    gap_standard: "1.5rem"  # 24px
    gap_section: "2rem"     # 32px
    gap_mobile: "1rem"      # 16px

tokens:
  hue: 240               # ブルー系
  shape: 0.5             # 実測: 0.5rem = 8px
  density: 0.375         # 実測: 1.5rem gap ÷ 4 ≈ 6px基準
  type_scale: 1.2        # 控えめ（業務ツール）
  motion: "standard"     # 100-250ms がメイン
```

### freee（実測値あり）

```yaml
measured:
  border_radius:
    button: "8px"
    modal: "16px"
    mobile_sheet: "16px 16px 0 0"

  colors:
    primary: "#2964F0"        # プライマリブルー
    primary_oklch: "oklch(0.52 0.20 265)"
    background: "#FFFFFF"
    hover: "#EBF3FF99"        # 半透明ライトブルー
    overlay: "rgba(0,0,0,0.5)"

  font:
    family: "システムフォント（日本語対応）"

  animation:
    fade: "0.2s cubic-bezier"
    slide: "0.5s ease-in-out"
    modal: "0.5s ease-in-out"
    carousel_delay: "5000ms"

  spacing:
    standard: "24px 60px"     # KVラップ
    section: "30px"           # セクション間
    modal: "40px 80px"        # モーダル内

tokens:
  hue: 265               # 実測: #2964F0 のHue ≈ 265
  shape: 0.5             # 実測: 8px → 0.5rem
  density: 0.375         # 実測: 24px 基準
  type_scale: 1.2        # 控えめ（業務ツール）
  motion: "standard"     # 0.2-0.5s 混在
```

---

## Section B: 日本市場向け追加プリセット

### SmartHR 風

```yaml
name: "smarthr"
keywords: ["業務効率", "HR Tech", "日本語最適", "安心感"]
best_for: ["HR SaaS", "業務管理", "BtoB（日本市場）", "管理画面"]

tokens:
  hue: 240              # ブルー（信頼・安心）
  shape: 0.5            # 実測: 8px
  density: 0.375        # やや詰め（業務効率）
  type_scale: 1.2       # 控えめ（情報密度重視）
  motion: "standard"    # 100-250ms

visual:
  background: "純白ベース、セクション分離にライトグレー"
  typography: "system-ui 日本語、line-height 1.5-1.6 で可読性重視"
  spacing: "カード間 1.5-2rem、モバイルで 1rem に圧縮"
  accent: "アクア〜ブルーの1色。ホバー時に色変化"
  signature: "アコーディオンFAQ、ホバーカード、グラデーション省略表示"
```

### freee 風

```yaml
name: "freee"
keywords: ["わかりやすい", "親しみ", "日本のSaaS", "会計"]
best_for: ["会計・経理SaaS", "中小企業向け", "BtoB（親しみ路線）", "フォーム重視"]

tokens:
  hue: 265              # 実測: #2964F0
  shape: 0.5            # 実測: 8px ボタン、16px モーダル
  density: 0.375        # 実測: 24px 基準
  type_scale: 1.2       # 控えめ
  motion: "relaxed"     # 実測: 0.5s のスライドが多い

visual:
  background: "白ベース + 半透明ブルーのホバー(#EBF3FF)"
  typography: "システムフォント、改行位置に配慮した日本語組版"
  spacing: "フォーム領域はゆったり（40-80px padding）"
  accent: "ブルー1色（#2964F0）。CTAは目立つサイズ"
  signature: "モバイルボトムシート、自動カルーセル(5s)、モーダルフォーム"
```

### LINE 風（追加）

```yaml
name: "line"
keywords: ["チャット", "カジュアル", "日本標準", "コミュニケーション"]
best_for: ["LIFF アプリ", "チャットUI", "日本向けCtoC", "メッセージング"]

tokens:
  hue: 140              # LINE Green
  shape: 0.75           # バブル・カード大きめ角丸
  density: 0.25         # チャットUIはコンパクト
  type_scale: 1.15      # 小さめ（チャット密度）
  motion: "snappy"      # メッセージ送信は即座

visual:
  background: "ライトグレー背景 + 白カード"
  typography: "ヒラギノ角ゴ / system-ui、本文14-16px"
  spacing: "メッセージバブル間は小さめ、セクション間は広め"
  accent: "LINE Green (#06C755) 1色"
  signature: "チャットバブル、リッチメニュー、Flex Message カード"
```

---

## Section C: 相性マトリクス拡張版

日本市場プリセットを含めた拡張版。

### ミックス推奨パターン

| ベース | よくあるオーバーライド | ユースケース |
|--------|----------------------|-------------|
| smarthr + shape(stripe) | 角丸をやや大きく | HR SaaS のモダン化 |
| freee + density(notion) | よりコンパクトに | 経理ダッシュボード |
| line + hue(airbnb) | グリーン→コーラル | LIFF EC アプリ |
| stripe + motion(smarthr) | アニメーション控えめ | 日本向け BtoB SaaS |
| stripe + shape(airbnb) | 角丸を大きく | 洗練 SaaS + 親しみやすさ |
| linear + hue(freee) | バイオレット→ブルー | 日本向け開発者ツール |

### NG パターン（追加）

| 組み合わせ | 理由 |
|-----------|------|
| smarthr + duolingo | 業務ツール × ゲーミフィケーション = 信頼感崩壊 |
| freee + spotify | 会計 × ダークモード = 視認性不安 |
| line + apple | カジュアル × プレミアム = トーン矛盾 |
| smarthr + apple | 効率 × 余白贅沢 = 密度矛盾 |

---

## Section D: OKLCH 変換早見表

プリセットの主要カラーを OKLCH に変換済み。`design-token-system` で `:root` に入れる値。

| プリセット | HEX | OKLCH | 用途 |
|-----------|-----|-------|------|
| Airbnb | #FF385C | oklch(0.63 0.22 12) | primary |
| Stripe | #635BFF | oklch(0.52 0.24 285) | primary |
| Duolingo | #58CC02 | oklch(0.75 0.22 140) | primary |
| Spotify | #1DB954 | oklch(0.66 0.19 155) | primary |
| Linear | #5E6AD2 | oklch(0.53 0.15 275) | primary |
| Notion | #000000 | oklch(0.00 0.00 0) | primary（ロゴ） |
| Vercel | #000000 | oklch(0.00 0.00 0) | primary |
| Apple | #0071E3 | oklch(0.55 0.18 255) | CTA blue |
| SmartHR | #0077C7 | oklch(0.55 0.14 240) | primary |
| freee | #2964F0 | oklch(0.52 0.20 265) | primary |
| LINE | #06C755 | oklch(0.72 0.20 155) | primary |

---

## Section E: プリセット → globals.css 変換例

Airbnb プリセットを `design-token-system` の形式に変換した例:

```css
/* --- Airbnb Preset → globals.css --- */

:root {
  /* Primitive: Airbnb Rausch */
  --primitive-hue: 12;
  --primitive-chroma: 0.22;

  /* Semantic: Light mode */
  --primary: oklch(0.63 0.22 12);          /* #FF385C */
  --primary-foreground: oklch(0.98 0.01 12);
  --background: oklch(1.00 0.00 0);        /* #FFFFFF */
  --foreground: oklch(0.20 0.00 0);        /* #222222 */
  --muted: oklch(0.97 0.00 0);            /* #F7F7F7 */
  --muted-foreground: oklch(0.50 0.00 0);  /* #6A6A6A */
  --border: oklch(0.89 0.00 0);           /* #DDDDDD */
  --destructive: oklch(0.48 0.18 25);     /* #C13515 */
}

.dark {
  --primary: oklch(0.70 0.20 12);
  --primary-foreground: oklch(0.15 0.01 12);
  --background: oklch(0.15 0.00 0);
  --foreground: oklch(0.93 0.00 0);
  --muted: oklch(0.22 0.00 0);
  --muted-foreground: oklch(0.65 0.00 0);
  --border: oklch(0.30 0.00 0);
}

@theme inline {
  --color-primary: var(--primary);
  --color-primary-foreground: var(--primary-foreground);
  --radius: 0.75rem;        /* Airbnb: 大きめ角丸 */
  --spacing: 0.375rem;      /* Airbnb: 12-24px → 6px基準 */
}

@theme {
  /* Typography: Airbnb Cereal 風 */
  --font-sans: 'Airbnb Cereal VF', 'Circular', -apple-system, BlinkMacSystemFont, 'Roboto', 'Helvetica Neue', sans-serif;
  --text-base: 1rem;
  --text-base--line-height: 1.5;
}
```
