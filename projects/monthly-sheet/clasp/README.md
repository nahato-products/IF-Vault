# monthly-sheet-optimizer

月別スプレッドシートの数式パフォーマンス最適化ツール。

## 関連
- Issue: [#3 月別スプレッドシート改修](https://github.com/nahato-Inc/IF-Vault/issues/3)
- 改善案: `team/ikuta/月別シート関数_パフォーマンス改善案.md`

## セットアップ

```bash
cd projects/monthly-sheet-optimizer
npm install
```

### clasp 設定
`.clasp.json` の `scriptId` をテストコピーSSのスクリプトIDに設定:

```json
{
  "scriptId": "YOUR_SCRIPT_ID_HERE",
  "rootDir": "src",
  "fileExtension": "ts"
}
```

スクリプトIDは Apps Script エディタの URL から取得:
`https://script.google.com/.../projects/SCRIPT_ID/edit`

## 使い方

### デプロイ
```bash
npm run push    # clasp push
```

### スプレッドシートから実行
1. スプレッドシートを開く
2. メニュー「🔧 最適化ツール」が表示される
3. `① dryRun` → 変更プレビュー（安全）
4. `② 全Step最適化実行` → 実際に適用

### 対象シート変更
`src/config.ts` の `TARGET_SHEET_NAME` を変更:
```typescript
const TARGET_SHEET_NAME = '2026年03月';  // ← ここを変えるだけ
```

## 最適化Step一覧

| Step | 内容 | 効果 |
|------|------|------|
| 1 | オープンレンジ閉鎖 | ★★★ |
| 2 | XLOOKUP集約（_cacheシート） | ★★★ |
| 3 | CV検索キー集約 | ★★☆ |
| 4 | LETキャッシュ化 | ★★☆ |
| 5 | 源泉徴収簡約化 | ★☆☆ |
| 6 | エラーカウント範囲限定 | ★☆☆ |

## 実績
- 3月タブ: 中央値 **37%改善**（871ms → 553ms）
