# Design Brief — Reference

完成ブリーフの実例集とエッジケース対応パターン。

---

## Section A: 完成ブリーフ実例

### 実例1: BtoB SaaS ダッシュボード

```yaml
# Design Brief: ProjectAlpha 管理画面
project_name: "ProjectAlpha Admin Dashboard"
target_user: "中小企業の経理担当者（30-50代、ITリテラシー中程度）"
brand_personality: "頼れる会計士の友人"
competitors: ["freee", "MoneyForward"]

primary_reference: "smarthr"       # style-reference-db プリセット
secondary_reference: "notion"      # テーブルUIの参考
avoid_reference: "duolingo"        # ゲーム的すぎる。業務ツールに不適
mood_keywords: ["安心感", "効率的", "迷わない"]

tokens:
  hue: 240                # ブルー（信頼）— SmartHR ベース
  shape: 0.5              # 8px 角丸 — 業務ツール標準
  density: 0.375          # やや詰め — テーブル情報密度重視
  type_scale: 1.2         # 控えめ — 数字中心の画面
  motion: "snappy"        # 150ms — 操作レスポンス重視

color:
  primary_hue: 240
  primary_chroma: 0.14    # やや控えめ（目に優しい）
  neutral_warmth: "cool"  # 青寄りグレー
  accent_strategy: "monochromatic"  # ブルーの濃淡だけ

app_type: "dashboard"
# → baseline-ui: tabular-nums 徹底、情報階層明確化
```

**選定理由**: ターゲットが「迷わない」を求めているので SmartHR の安定感をベースに。テーブルUIだけ Notion のシンプルさを参考にする。duolingo は信頼感と矛盾するので明示的に除外。

---

### 実例2: CtoC マーケットプレイス LP

```yaml
# Design Brief: HandmadeMarket LP
project_name: "HandmadeMarket ランディングページ"
target_user: "ハンドメイド作品を売りたい20-40代の女性クリエイター"
brand_personality: "おしゃれなマルシェのオーナー"
competitors: ["minne", "Creema"]

primary_reference: "airbnb"        # カード中心・写真映え
secondary_reference: "apple"       # ヒーローセクションの余白感
avoid_reference: "linear"          # 開発者ツール感は NG
mood_keywords: ["温かみ", "写真映え", "ワクワク"]

tokens:
  hue: 25                 # ウォームオレンジ — 温かみ
  shape: 0.75             # 大きめ角丸 — Airbnb ベース
  density: 0.5            # ゆったり — LP は余白多め
  type_scale: 1.333       # ダイナミック — Apple のヒーロー感
  motion: "relaxed"       # 300ms — スクロール連動

color:
  primary_hue: 25
  primary_chroma: 0.18    # 鮮やかめ（写真と調和）
  neutral_warmth: "warm"  # 黄味グレー
  accent_strategy: "analogous"  # オレンジ〜ピンクの類似色

app_type: "lp"
# → baseline-ui: グラデーション緩和OK、CWV(LCP<2.5s)厳守
```

**選定理由**: 写真カードが主役なので Airbnb のカード UI がベスト。ただし LP なのでヒーローの余白感だけ Apple を参考に。type_scale を 1.333 に上げてダイナミックな見出しにする。

---

### 実例3: LIFF ミニアプリ

```yaml
# Design Brief: ReservationBot LIFF
project_name: "美容室予約 LIFF アプリ"
target_user: "20-30代女性、LINE ヘビーユーザー"
brand_personality: "気さくな美容師さん"
competitors: ["ホットペッパービューティー", "minimo"]

primary_reference: "line"          # LIFF なので LINE ネイティブ感
secondary_reference: "airbnb"      # カレンダー/予約UIの参考
avoid_reference: "vercel"          # モノクロは冷たすぎる
mood_keywords: ["カジュアル", "サクサク", "LINE っぽい"]

tokens:
  hue: 330               # ローズピンク — 美容室のブランドカラー
  shape: 0.75            # 大きめ角丸 — LINE バブル感
  density: 0.25          # コンパクト — モバイルファースト
  type_scale: 1.15       # 小さめ — LINE 内で情報密度確保
  motion: "snappy"       # 150ms — タップ即反応

color:
  primary_hue: 330
  primary_chroma: 0.15
  neutral_warmth: "warm"
  accent_strategy: "monochromatic"

app_type: "consumer"
# → baseline-ui: タッチターゲット48dp厳守、safe-area必須
# → mobile-first-responsive: LIFF 固有の対応
```

**選定理由**: LIFF なので LINE プラットフォームの UX に馴染む必要がある。ベースは LINE 風でタップ即反応。予約カレンダーだけ Airbnb の日付選択 UI を参考にする。

---

## Section B: エッジケース対応

### 「とりあえず作って」パターン

guchi が「細かいことはいいからとりあえず」と言った場合:

```
了解！最低限これだけ教えて:
1. 何を作る？（一言で）
2. 誰が使う？（一言で）

→ それだけで仮ブリーフ作るよ
```

**自動選定ロジック**:

| 回答パターン | 自動選定プリセット |
|------------|------------------|
| 「管理画面」「ダッシュボード」 | smarthr (日本 BtoB) or linear (海外風) |
| 「LP」「ランディングページ」 | airbnb (サービス) or apple (プロダクト) |
| 「LIFF」「LINE」 | line |
| 「社内ツール」 | notion |
| 「SaaS」 | stripe (海外風) or freee (日本市場) |
| 「EC」「マーケットプレイス」 | airbnb |
| 「学習」「EdTech」 | duolingo |

**市場判定基準**:
- target_user が日本語話者 or 日本企業 → 日本市場プリセット優先
- target_user が英語圏 or グローバル → 海外風プリセット優先
- 不明な場合 → 日本市場プリセットをデフォルト（guchi のメイン市場）

**mood_keywords 自動生成ルール**（急ぎパターンでは聞かないため自動生成）:

```yaml
auto_mood_keywords:
  source: "プリセットの keywords フィールドから先頭3つを選択"
  fallback:
    dashboard: ["効率的", "安心感", "迷わない"]
    consumer: ["親しみ", "サクサク", "わかりやすい"]
    lp: ["インパクト", "信頼感", "ワクワク"]
    internal-tool: ["シンプル", "効率", "迷わない"]
```

仮ブリーフを提示 → guchi が OK なら実装開始。修正あれば調整。

---

### 「参考サイトないけど雰囲気はある」パターン

```
OK、雰囲気のキーワード3つ教えて。
それで style-reference-db から一番近いプリセットを提案するよ。

例:
- 「シンプル・信頼・余白」→ stripe or notion
- 「楽しい・カラフル・親しみ」→ duolingo or airbnb
- 「効率・高密度・ダーク」→ linear or spotify
```

---

### 「既存デザインを引き継ぐ」パターン

既にデザインがある場合はブリーフ不要。代わりに:

```yaml
# 既存デザイン引き継ぎ
inherit_from: "globals.css"  # or Figma URL
override_tokens: []          # 変更したいトークンだけ指定
```

globals.css が既にあれば、そこからトークン値を読み取って「現在のブリーフ」として解釈する。

---

### 「プロトタイプだから適当でいい」パターン

```
プロト用のデフォルト:
  primary_reference: "notion"  # 最もニュートラル
  tokens:
    hue: 0         # 無彩色
    shape: 0.5     # 標準
    density: 0.25  # コンパクト
    type_scale: 1.2
    motion: "snappy"

→ 後で本番用ブリーフに差し替えれば、トークン値の変更だけでブランド化できるよ
```

---

## Section C: ブリーフ → 実装チェーン

ブリーフ確定後の実装手順（他スキルとの連携）:

```
1. [_design-brief] ブリーフ確定
   ↓ tokens 値を持って
2. [style-reference-db] プリセットのOKLCH値を取得（reference.md Section D,E）
   ↓ 具体的な CSS 変数値を持って
3. [design-token-system] globals.css にトークン定義
   ↓ @theme inline でブリッジ
4. [tailwind-design-system] Tailwind v4 設定
   ↓ CVA バリアント定義
5. [react-component-patterns] コンポーネント実装
   ↓ baseline-ui の制約チェック
6. [_baseline-ui] アンチパターン最終チェック
   ↓ UX 心理学の観点で検証
7. [_ux-psychology] 認知負荷・ヒューリスティクス検証
   ↓ スコアリング
8. [lazy-user-ux-review] 100点満点スコア
```
