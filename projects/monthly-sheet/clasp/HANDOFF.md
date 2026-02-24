# 月別シート最適化ツール — CLI Claude Code 引き継ぎ

## プロジェクト概要

月別スプレッドシートの数式パフォーマンスを最適化する clasp + TypeScript の GAS プロジェクト。
手動で行っていた最適化作業を自動化・再利用可能にしたもの。

- **対象スプレッドシート**: `[コピー]【8期】固定Unit_月別詳細 のコピー`
  - URL: https://docs.google.com/spreadsheets/d/1yUcDj3-OGfym6C8dWG0A6jeeDzkxMUoLz5A53Bui984/edit
  - テスト用コピーで作業。本番適用前に検証する
- **GitHub Issue**: https://github.com/nahato-Inc/IF-Vault/issues/3
- **GitHubリポ**: `nahato-Inc/IF-Vault`
- **配置先**: `team/ikuta/gas/monthly-sheet-optimizer/`

## 仕様ドキュメント（リポ内）

これらが最適化ロジックの原典。コードはこの2つを忠実に実装している：

- `team/ikuta/月別シートの関数洗い出し.md` — 45セルの数式分析
- `team/ikuta/月別シート関数_パフォーマンス改善案.md` — 6ステップの改善案（before/after数式付き）

## ファイル構成

```
monthly-sheet-optimizer/
├── .clasp.json          # scriptId を設定する必要あり（現在placeholder）
├── .gitignore           # node_modules/ と .clasp.json を除外
├── package.json         # clasp, @types/google-apps-script, typescript
├── tsconfig.json        # ES2019, module: None（GAS用）
├── README.md
├── HANDOFF.md           # ← このファイル
└── src/
    ├── appsscript.json  # GASマニフェスト（Asia/Tokyo, V8 runtime）
    ├── config.ts        # 全設定値を一元管理（シート名、行範囲、マッピング等）
    ├── optimizer.ts     # 6つの最適化ステップ（step1〜step6）
    ├── validator.ts     # before/afterスナップショット比較
    ├── cache.ts         # _cacheシートの作成・保護・削除
    ├── loadTest.ts      # 負荷テスト実行・比較レポート生成
    └── main.ts          # onOpen()メニュー + 各ステップのランナー関数
```

## 6つの最適化ステップ

| Step | 内容 | 関数 |
|------|------|------|
| 1 | SUM範囲クローズ（開放範囲→固定範囲） | `step1_closeOpenRanges()` |
| 2 | XLOOKUP統合（14本→_cacheシート経由で1本） | `step2_consolidateXlookup()` |
| 3 | ◆CVサーチキー統合（BQ5で生成→U/V/W参照） | `step3_cvKeyConsolidation()` |
| 4 | LETキャッシュ（T5/Z5/AA5の重複計算排除） | `step4_letCaching()` |
| 5 | 税計算簡略化（AE5/AG5）※ズレたら自動ロールバック | `step5_taxSimplification()` |
| 6 | エラーカウント最適化（N2のXLOOKUP列のみ対象） | `step6_errorCountOptimization()` |

## 残タスク（優先度順）

### 必須（pushまでに必要）
1. **IF-Vaultリポにpush** — ユーザー許可済み
   - `team/ikuta/gas/monthly-sheet-optimizer/` に配置
   - ブランチ名: `ikuta/monthly-sheet-optimizer`
   - この環境からはGitHub認証が通らなかったので未push
   - ローカルでclone済みのコミットは作成済み（ただしpushできず）

### 要確認
2. **`.clasp.json` のscriptId設定** — 現在 `YOUR_SCRIPT_ID_HERE`
   - スプレッドシートの「拡張機能 > Apps Script」からスクリプトIDを取得して設定
3. **◆CVキー列の確認** — `config.ts` の Step 3 で `CV_KEY_COLUMN: 'A'` とハードコードしている
   - 実際の ◆CV シートのキー列が A列かどうか確認が必要

### 将来
4. **2月タブのBQ5 #REF!エラー修正**
5. **2月タブのBR1 一時数式クリーンアップ**
6. **2月タブの_snapshotシート削除**
7. **本番スプレッドシートへの適用**（テストコピーで検証完了後）

## 前回の実績

手動最適化（3月タブ）の結果：
- 平均再計算時間: 871ms → 621ms（**29%改善**）
- 中央値: 878ms → 553ms（**37%改善**）

## 使い方（セットアップ後）

```bash
cd monthly-sheet-optimizer
npm install
# .clasp.json にスクリプトIDを設定してから：
npx clasp push
# スプレッドシートを開くと「🔧 最適化ツール」メニューが出る
# 「ドライラン（プレビュー）」→「全Step実行」の順で使う
```

## 注意点

- `config.ts` の `TARGET_SHEET_NAME` を変えれば別の月タブにも適用可能
- dryRun=trueで実行すると変更せずログだけ出る
- Step 5（税計算）は値がズレたら自動でロールバックする
- _cacheシートは非表示+保護で作成される
