# TokenGuardian Quick Reference

## Tools Summary

### read_smart
```
path: string       — ファイルパス
force_full: bool   — true で全文強制（デフォルト: false）
```
- 1500トークン以下 → 全文返却
- 1500トークン超 → skeleton mode（定義行のみ）

### read_fragment
```
path: string       — ファイルパス
start_line: number — 開始行（1-indexed）
end_line: number   — 終了行（1-indexed, inclusive）
```
- 指定行範囲のみ返却、最小トークンコスト

### map_dir_cost
```
path: string — ディレクトリパス
```
- ツリー表示 + 各ファイルのトークン概算
- マーク: 1500トークン超のファイル

### grep_surgical
```
query: string — 正規表現パターン
path: string  — 検索対象のファイル/ディレクトリ
```
- 1ファイルあたり最大3マッチ
- 各マッチ前後3行のコンテキスト

## Token Cost 推定方法

トークン数の概算には以下の換算を使う（あくまで目安）:

| コンテンツ種別 | 換算目安 | 例 |
|--------------|---------|-----|
| 英語テキスト / コード | 約4文字 ≈ 1トークン | 500行 x 40文字 = 20,000文字 ≈ 5,000 tok |
| 日本語テキスト | 約1.5文字 ≈ 1トークン | 日本語コメント100文字 ≈ 67 tok |
| 画像 / スクリーンショット | 解像度依存 | 一般的なスクリーンショット ≈ 1,000〜2,000 tok |
| JSON / YAML（構造化データ） | 約3文字 ≈ 1トークン | ブラケット・コロン等の記号が多いため |

**注意:** 画像はテキストよりも大幅にトークンを消費する。Read ツールでスクリーンショットを読む場合、1枚で1,000トークン以上消費することがあるため、本当に必要な場合にのみ使用すること。

## Skeleton Mode 対応言語

| 言語 | 抽出する行 |
|------|-----------|
| TypeScript/JS | import, export, class, interface, type, function, const, enum |
| Python | import, from, def, class, デコレータ |
| CSS/SCSS | @import, @media, @keyframes, セレクタ, CSS変数 |
| その他 | インデント0の行（トップレベル定義） |

## モード別ワークフロー詳細

### Scout Mode（偵察モード）ワークフロー

新しいプロジェクトやディレクトリを効率的に探索する。

```
Step 1: map_dir_cost("./")
   → プロジェクト全体のファイル構成とトークンコストを把握
   → 1500tok超のファイルに注意マークがつく

Step 2: read_smart("src/index.ts")
   → エントリポイントのskeleton取得（import/export/関数シグネチャ）
   → 全体のモジュール構成を理解

Step 3: grep_surgical("export", "src/")
   → 公開APIの一覧を取得（各ファイル最大3マッチ、前後3行）
   → どのモジュールが何を公開しているか把握

Step 4: read_fragment("src/core/handler.ts", 45, 80)
   → 気になった関数の実装だけをピンポイントで読む
```

**Fallback（TokenGuardian なし）:**
```
Step 1: Glob ツール: pattern="src/**/*.{ts,tsx}" でファイル一覧
Step 2: Read ツール: limit=30 でエントリポイントの先頭だけ確認
Step 3: Grep ツール: pattern="export", head_limit=15, output_mode="content"
Step 4: Read ツール: offset=45, limit=35 で必要箇所だけ読む
```

### Session Mode（セッション管理）ワークフロー

長時間作業でコンテキストを温存する。

```
Phase 1: 通常作業（序盤）
   → offset/limit 付きの Read、head_limit 付きの Grep を常に使う
   → 不要な全文 Read を避ける

Phase 2: 外部化トリガー発動（中盤）
   トリガー条件（いずれか）:
   - 10ファイル以上を Read した
   - 長い出力を3回以上受け取った
   - 同じ情報を再Read した
   - 会話ターン20回超
   → status.md に現在状態を書き出す

Phase 3: 継続 or リセット（終盤）
   → status.md を読んで作業再開
   → キーファイルの再読み込みは limit 付きで最小限に
```

### Audit Mode（診断）ワークフロー

現在セッションのトークン効率を振り返り改善する。

```
Step 1: セッション中の Read 操作を振り返る
   → 500行以上のファイルを全文Readしていないか確認
   → 確認方法: map_dir_cost でトークン数チェック

Step 2: 重複 Read を確認
   → 同一ファイルへの Read が2回以上ないか
   → 重複があれば Knowledge Externalization を適用

Step 3: Grep 結果量を確認
   → head_limit なしで大量マッチが返っていないか
   → 改善: output_mode="count" で事前確認する習慣

Step 4: 改善レポート
   → 検出した非効率パターンと改善策をリスト化
```

## 経済パターンを使わないべき場面

トークン節約にもオーバーヘッドがある。以下の場合は素直に通常の Read/Grep を使う方が効率的:

| 場面 | 理由 |
|------|------|
| 50行以下の小さいファイル | offset/limit 指定のオーバーヘッド > 節約量 |
| 全文が確実に必要な設定ファイル（tsconfig.json 等） | skeleton mode でも結局 force_full が必要になる |
| 1回しか読まないファイル | 最適化の判断コスト自体が無駄 |
| デバッグ中で文脈全体が必要 | 部分読みだとバグの原因を見落とす可能性 |
| ファイル内容が不明で構造把握が最優先 | まず read_smart でskeletonを取り、必要なら追加読み |

**判断基準:** 「Read 1回 + 数秒の判断」と「offset/limit の試行錯誤で2〜3回 Read」を比較して、前者の方が安いなら素直に読む。

## よくあるワークフロー

### 新プロジェクト探索
```
map_dir_cost("./") → read_smart("src/index.ts") → grep_surgical("export", "src/")
```

### バグ調査
```
grep_surgical("errorPattern", "src/") → read_fragment で該当箇所確認
```

### リファクタリング前の調査
```
map_dir_cost("src/") → 高コストファイル特定 → read_smart で構造確認
```

### 大規模横断調査
```
Task ツールで Explore エージェントに委譲 → 返り値のサマリだけ受け取る
```
