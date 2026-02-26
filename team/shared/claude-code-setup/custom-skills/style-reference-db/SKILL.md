---
name: style-reference-db
description: "Select design direction from curated style reference presets mapped to design-token-system 5-axis values. Provides Airbnb/Stripe/Apple/Duolingo/Notion style presets with concrete token values, visual characteristics, and use cases. Use when selecting a design direction, filling a design brief, or wanting inspiration for a new project. Do not trigger for implementation details (use design-token-system)."
user-invocable: false
triggers:
  - デザインスタイルを選ぶ
  - スタイルリファレンス
  - Stripe風デザイン
  - Airbnb風
  - デザインの方向性を決めたい
---

# Style Reference DB

実在するプロダクトのビジュアルスタイルを分析し、`design-token-system` の 5軸トークン値にマッピングしたプリセット集。デザインブリーフ作成時の「引き出し」として使う。

## When to Apply

- デザインブリーフの primary_reference 選択時
- 「参考サイトがない」と言われたとき → ここから提案
- プロジェクトのトーン&マナーを議論するとき
- 「〇〇っぽくして」と言われたとき → 該当プリセットのトークン値を適用

## When NOT to Apply

- トークン値の実装方法 → `design-token-system`
- UI 制約・アンチパターン → `baseline-ui`
- UX 設計の「なぜ」 → `ux-psychology`

---

## Part 1: Presets [CRITICAL]

### Minimal Trust（信頼 x ミニマル）

#### Stripe 風

```yaml
name: "stripe"
keywords: ["洗練", "信頼", "開発者向け", "モダン"]
best_for: ["SaaS", "BtoB", "API ドキュメント", "決済系"]

tokens:
  hue: 285              # パープル（実測: #635BFF → oklch Hue≈285）
  shape: 0.625          # やや丸め
  density: 0.5           # ゆったり
  type_scale: 1.25       # 標準
  motion: "relaxed"      # ゆったりホバーエフェクト

visual:
  background: "純白ベースにグラデーションアクセント"
  typography: "system-ui、見出し太め、本文軽め"
  spacing: "セクション間に大きな余白"
  accent: "ブルー〜パープルのグラデーション（LP限定。アプリ内では単色）"
  signature: "ホバー時の微妙な影の変化、インタラクティブなコードブロック"
```

#### Notion 風

```yaml
name: "notion"
keywords: ["シンプル", "機能的", "テキスト中心", "柔軟"]
best_for: ["ドキュメント", "ナレッジベース", "社内ツール", "エディタ"]

tokens:
  hue: 30               # ウォームグレー
  shape: 0.375          # 控えめな角丸
  density: 0.25          # コンパクト
  type_scale: 1.2        # 控えめ
  motion: "snappy"       # 即座のフィードバック

visual:
  background: "ウォームホワイト（#FFFFFF ではなく少し黄味）"
  typography: "serif 見出し + sans-serif 本文"
  spacing: "コンテンツ領域は狭め、サイドバーとのコントラスト"
  accent: "モノクロ + 1色だけの控えめなアクセント"
  signature: "スラッシュコマンド、ブロックベースUI、余白のドラッグハンドル"
```

### Clean Bold（クリーン x 大胆）

#### Airbnb 風

```yaml
name: "airbnb"
keywords: ["親しみ", "写真映え", "カード中心", "グローバル"]
best_for: ["マーケットプレイス", "CtoC", "旅行", "予約系"]

tokens:
  hue: 0                # コーラルレッド
  shape: 0.75           # 大きめの角丸
  density: 0.5           # ゆったり
  type_scale: 1.25       # 標準
  motion: "standard"     # 標準的なトランジション

visual:
  background: "純白ベースにカード配置"
  typography: "Cereal 風の丸ゴシック、太めのウェイト"
  spacing: "カード間にしっかり余白、写真に呼吸感"
  accent: "コーラルピンク 1色に絞る"
  signature: "横スクロールカード、水平フィルターバー、大きな写真カード"
```

#### Apple 風

```yaml
name: "apple"
keywords: ["プレミアム", "ミニマル", "プロダクト映え", "没入"]
best_for: ["プロダクトLP", "ハードウェア", "ブランドサイト", "ポートフォリオ"]

tokens:
  hue: 0                # 無彩色ベース（アクセントでブルー）
  shape: 0.75           # 大きめの角丸
  density: 0.5           # ゆったり（余白贅沢）
  type_scale: 1.333      # ダイナミック（見出しが大きい）
  motion: "relaxed"      # ゆっくりしたスクロール連動

visual:
  background: "ダーク / ライト 大胆な切り替え"
  typography: "SF Pro 風、極太見出し + 極細本文"
  spacing: "フルスクリーンセクション、巨大な余白"
  accent: "ブルー（CTA のみ）、基本はモノクロ"
  signature: "スクロール連動アニメーション、高解像度プロダクト画像、動画ヒーロー"
```

### Playful Engaging（楽しい x エンゲージング）

#### Duolingo 風

```yaml
name: "duolingo"
keywords: ["楽しい", "ゲーミフィケーション", "カラフル", "親しみ"]
best_for: ["EdTech", "学習アプリ", "子ども向け", "ゲーム要素あり"]

tokens:
  hue: 140              # グリーン
  shape: 0.75           # 大きめの角丸
  density: 0.375         # やや詰め（情報密度高め）
  type_scale: 1.25       # 標準
  motion: "standard"     # 標準（ゲーム的フィードバック）

visual:
  background: "白ベースに鮮やかな差し色"
  typography: "丸ゴシック、太めのウェイト、大きめサイズ"
  spacing: "カード内はコンパクト、カード間はゆったり"
  accent: "グリーン + イエロー + ブルーの3色使い"
  signature: "キャラクターイラスト、進捗バー、バッジ/ストリーク、効果音的アニメーション"
```

#### Spotify 風

```yaml
name: "spotify"
keywords: ["ダーク", "鮮やか", "音楽的", "没入"]
best_for: ["メディア", "エンタメ", "ダークモード主体", "コンテンツ消費"]

tokens:
  hue: 140              # グリーン（Spotify Green）
  shape: 0.5            # 標準の角丸
  density: 0.25          # コンパクト（リスト密度高め）
  type_scale: 1.2        # 控えめ（コンテンツ優先）
  motion: "snappy"       # 素早い切り替え

visual:
  background: "ダークグレーベース（純黒ではない）"
  typography: "Circular 風のジオメトリック sans-serif"
  spacing: "リスト系は詰め気味、ヒーロー部分は余白たっぷり"
  accent: "ブライトグリーン 1色のみ"
  signature: "カラフルグラデーション背景（アルバムアート連動）、横スクロール棚"
```

### Data Dense（データ密度 x 効率）

#### Linear 風

```yaml
name: "linear"
keywords: ["効率", "開発者", "高密度", "モダンダーク"]
best_for: ["プロジェクト管理", "開発者ツール", "ダッシュボード", "BtoB SaaS"]

tokens:
  hue: 260              # バイオレット
  shape: 0.375          # 控えめな角丸
  density: 0.25          # コンパクト
  type_scale: 1.125      # 控えめ（密度優先）
  motion: "snappy"       # 即座のレスポンス

visual:
  background: "ダークモードデフォルト、ライトモード対応"
  typography: "Inter 風、均一なウェイト、小さめサイズ"
  spacing: "リスト・テーブルは詰め気味、パネル間に明確な境界"
  accent: "バイオレット + ステータスカラー（自動配色）"
  signature: "キーボードショートカット重視、コマンドパレット、高速トランジション"
```

#### Vercel 風

```yaml
name: "vercel"
keywords: ["モノクロ", "開発者", "テクニカル", "クリーン"]
best_for: ["開発者向けSaaS", "CLIツール", "デプロイ系", "インフラ"]

tokens:
  hue: 0                # 完全無彩色
  shape: 0.5            # 標準
  density: 0.375         # やや詰め
  type_scale: 1.2        # 控えめ
  motion: "snappy"       # 素早い

visual:
  background: "純白 or 純黒のハイコントラスト"
  typography: "Geist 風のモダン sans-serif、コードブロック多用"
  spacing: "情報はコンパクト、セクション間は広め"
  accent: "ほぼなし。ブルーの CTA のみ"
  signature: "モノクロ美学、グリッドシステム、三角形ロゴ的なシャープさ"
```

---

## Part 2: Preset 選定ガイド [HIGH]

### app_type 別の推奨

| app_type | 第一推奨 | 代替候補 |
|----------|---------|---------|
| **LIFF** | line | airbnb |
| **consumer（PWA）** | airbnb / duolingo | spotify |
| **dashboard（日本市場）** | smarthr / freee | notion |
| **dashboard（グローバル）** | linear / vercel | notion |
| **lp（プロダクト）** | apple / stripe | airbnb |
| **lp（サービス）** | airbnb / stripe | notion |
| **internal-tool** | notion / linear | vercel |
| **BtoB SaaS（日本市場）** | smarthr / freee | stripe |
| **BtoB SaaS（グローバル）** | stripe / linear | vercel |
| **EdTech** | duolingo | airbnb |
| **メディア/コンテンツ** | spotify | apple |

### mood_keywords からの逆引き

| キーワード | 候補 |
|-----------|------|
| ミニマル / シンプル | notion, vercel, apple |
| 信頼 / プロフェッショナル | stripe, vercel, linear, smarthr |
| 親しみ / カジュアル | airbnb, duolingo, line |
| 楽しい / ゲーム的 | duolingo, spotify |
| 高級 / プレミアム | apple, stripe |
| 効率 / 高密度 | linear, notion, smarthr |
| ダーク / 没入 | spotify, linear, apple |
| テクニカル / 開発者 | vercel, linear, stripe |
| 日本的 / 安心感 | smarthr, freee, line |
| わかりやすい / 業務 | freee, smarthr, notion |

> **注意**: SKILL.md の `tokens.hue` は OKLCH の H 値。HSL の H とは異なる。正確な HEX → OKLCH 変換は reference.md Section D を参照。

---

## Part 3: ミックス & カスタマイズ [MEDIUM]

プリセットはそのまま使うだけでなく、**ミックス**できる:

```
例: 「Stripe の洗練さ + Airbnb のカード UI」

base: stripe           # ベーストークン値
override:
  shape: 0.75          # Airbnb の大きめ角丸を適用
  accent_strategy: "monochromatic"  # Stripe のグラデーションではなく単色に
```

### ミックスのルール

1. **ベースは1つ**。2つ以上のプリセットを均等にミックスしない（方向性がブレる）
2. **オーバーライドは2軸まで**。3つ以上変えるなら別のプリセットをベースにすべき
3. **motion と density は連動**。コンパクト(density小) + relaxed(motion遅) は違和感が出る

### 相性マトリクス

| | stripe | notion | airbnb | apple | duolingo | spotify | linear | vercel |
|--|--------|--------|--------|-------|----------|---------|--------|--------|
| **stripe** | - | shape | shape,hue | motion | NG | NG | density | hue |
| **notion** | shape | - | hue | NG | NG | NG | density | density |
| **airbnb** | shape,hue | hue | - | type_scale | motion | NG | NG | NG |
| **apple** | motion | NG | type_scale | - | NG | motion | NG | hue |
| **duolingo** | NG | NG | motion | NG | - | hue | NG | NG |
| **spotify** | NG | NG | NG | motion | hue | - | density | NG |
| **linear** | density | density | NG | NG | NG | density | - | hue |
| **vercel** | hue | density | NG | hue | NG | NG | hue | - |

NG = ミックス非推奨（世界観が矛盾する）

---

## Part 4: プリセット拡張 [LOW]

新しいプリセットを追加するときのテンプレート:

```yaml
name: ""
keywords: []           # 4つ
best_for: []           # 4つ
tokens:
  hue: 0
  shape: 0.5
  density: 0.25
  type_scale: 1.25
  motion: "standard"
visual:
  background: ""
  typography: ""
  spacing: ""
  accent: ""
  signature: ""        # そのプロダクト固有の特徴的 UI パターン
```

---

## Checklist

- [ ] プリセットを1つベースとして選定している
- [ ] オーバーライドは2軸以内に収まっている
- [ ] 相性マトリクスで NG の組み合わせを避けている
- [ ] motion と density の相性が取れている
- [ ] 選定理由が mood_keywords / target_user と整合している

## Cross-References

- **_design-brief**: ブリーフ作成時にプリセットを選択
- **design-token-system**: プリセットのトークン値を実装（Part 8）
- **baseline-ui**: app_type による制約適用（App-Type Adaptation）
- **ux-psychology**: ブランドパーソナリティと認知心理学の接続

### Referenced by

- **design-brief**: 5軸トークン値の入力ソース
- **design-token-system**: プリセットからトークン値への変換
- **tailwind-design-system**: スタイルプリセットからTailwind設定への反映

## Cross-references

- **design-brief**: スタイル選定前にブリーフで方向性を決める
- **design-token-system**: 選定スタイルをトークン値に変換
- **tailwind-design-system**: Tailwind v4での実装に接続
