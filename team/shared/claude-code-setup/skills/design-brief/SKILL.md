---
name: design-brief
description: "Force a design brief before UI implementation. Defines brand tone, style reference, 5-axis token values (Hue/Shape/Density/TypeScale/Motion), and target persona. Use when starting a new UI project, creating a new page/screen, or when no design brief exists yet. Do not trigger for existing projects with established tokens."
user-invocable: false
---

# Design Brief

UI 実装に入る前に**デザインブリーフ**を必ず作成させるゲートスキル。ブリーフなしの実装はデフォルト値依存になり、プロジェクト間で似たり寄ったりの見た目になる。

## When to Apply

- 新規プロジェクト・新規ページの UI 実装開始時
- `globals.css` のトークン定義がまだないとき
- 「とりあえずいい感じに」と言われたとき（← 最も危険）
- 既存プロジェクトでもデザインの方向転換時

## When NOT to Apply

- 既に `globals.css` にトークンが定義済みのプロジェクト
- コンポーネントのロジック修正のみ（見た目変更なし）
- バグ修正・リファクタリング

---

## Part 1: Brief Template [CRITICAL]

UI 実装を始める前に、以下を guchi と一緒に埋める。**全項目が埋まるまで実装に入らない**。

### 1. プロジェクト概要

```yaml
project_name: ""           # プロジェクト名
target_user: ""            # ターゲットユーザー（1文で）
brand_personality: ""      # ブランドの人格（例: "信頼できる先輩", "洗練されたプロ"）
competitors: []            # 競合・似たくないサイト
```

### 2. スタイルリファレンス

```yaml
primary_reference: ""      # メインで参考にするサイト/ブランド（style-reference-db から選択 or URL指定）
secondary_reference: ""    # サブ参考（部分的に取り入れたい要素）
avoid_reference: ""        # 「これにはしたくない」の明示
mood_keywords: []          # 3-5個のキーワード（例: ["ミニマル", "信頼感", "余白多め"]）
```

### 3. 5軸トークン値

`design-token-system` Part 8 の Identity 5軸を確定する:

```yaml
tokens:
  hue: 0                  # OKLCH Hue 値（0-360）。style-reference-db のプリセット参照
                           # ※ プリセットの hue を初期値に。ブランド固有色がある場合は
                           #   color.primary_hue で上書き。hue はニュートラル色の色温度にも影響
  shape: 0.5              # --radius 値（rem）。0.25=シャープ, 0.5=標準, 0.75=ラウンド
  density: 0.25           # --spacing ベース値（rem）。0.25=コンパクト, 0.5=ゆったり
  type_scale: 1.25        # モジュラースケール比率。1.125=控えめ, 1.25=標準, 1.333=ダイナミック
  motion: "standard"      # standard(200ms) / snappy(150ms) / relaxed(300ms)
```

### 4. カラー方針

```yaml
color:
  primary_hue: 0          # メインカラーの Hue
  primary_chroma: 0.15    # 彩度（0.05=控えめ, 0.15=標準, 0.25=鮮やか）
  neutral_warmth: "cool"  # neutral の色温度: cool(青寄り) / warm(黄寄り) / pure(無彩色)
  accent_strategy: "complementary"  # complementary / analogous / triadic / monochromatic
```

### 5. App-Type

```yaml
app_type: ""              # consumer / dashboard / lp / internal-tool
# baseline-ui の App-Type Adaptation に連動
```

---

## Part 2: Brief 作成フロー [CRITICAL]

### Step 1: ヒアリング

guchi に以下を聞く（全部一度に聞かず、段階的に）:

1. **「何を作る？誰が使う？」** → project_name, target_user, app_type
2. **「参考にしたいサイトある？」** → primary_reference（なければ `style-reference-db` から提案）
3. **「こういうのは嫌ってのある？」** → avoid_reference
4. **「雰囲気のキーワード3つ」** → mood_keywords

### Step 2: トークン提案

ヒアリング結果から 5軸トークン値を提案する:

```
[提案] mood_keywords: ["ミニマル", "信頼感", "余白多め"] の場合

  hue: 220        # ブルー系（信頼感）
  shape: 0.5rem   # 標準の角丸
  density: 0.5rem  # ゆったり（余白多め）
  type_scale: 1.25 # 標準
  motion: relaxed  # ゆったり

→ これで進める？調整したいところある？
```

### Step 3: 確定 & 保存

確定したブリーフを以下に保存:

- **保存先**: プロジェクトルートの `docs/design-brief.yaml` or `CLAUDE.md` のデザインセクション
- **フォーマット**: YAML（上記テンプレート形式）

---

## Part 3: ブリーフ未作成時の振る舞い [CRITICAL]

UI 実装の指示を受けたとき、以下をチェック:

1. プロジェクトに `docs/design-brief.yaml` or `CLAUDE.md` 内のデザインセクションがあるか
2. `globals.css` に Identity 5軸のトークンが定義されているか

**どちらもない場合**:

```
デザインブリーフがまだないね。
似たり寄ったりにならないように、先にスタイルの方向性を決めておきたいんだけど、
2-3分で終わるから一緒に埋めてもいい？

1. 何を作る？誰が使う？
2. 参考にしたいサイトある？（なければこっちから提案するよ）
3. 雰囲気のキーワード3つ教えて
```

**急ぎの場合**: 「とりあえず作って」と言われたら、`style-reference-db` からプロジェクトに最も近いプリセットを自動選択し、ブリーフを仮作成して提示する。確認が取れたら実装開始。

---

## Checklist

- [ ] project_name と target_user が定義されている
- [ ] primary_reference が指定されている（URL or style-reference-db プリセット名）
- [ ] mood_keywords が 3-5 個ある
- [ ] 5軸トークン値が全て確定している
- [ ] app_type が指定されている（baseline-ui の適応ルールに連動）
- [ ] avoid_reference で「やりたくないスタイル」が明示されている
- [ ] ブリーフが `docs/design-brief.yaml` or `CLAUDE.md` に保存されている

## Cross-References

- **style-reference-db**: リファレンス選択時のプリセット集
- **design-token-system**: 5軸トークンの実装（Part 8: Project Identity Profiles）
- **baseline-ui**: app_type による制約の緩和/強化ルール
- **ux-psychology**: brand_personality からの UX 設計指針

### Referenced by

- **style-reference-db**: プリセットからスタイル方向を選択
- **design-token-system**: ブリーフで確定した5軸値をトークンに実装
- **react-component-patterns**: ブリーフに基づくコンポーネント設計
