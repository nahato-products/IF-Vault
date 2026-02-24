# 月別シート最適化 GAS 導入ガイド & 追加提案

## ファイル構成

```
gas/
├── monthly_sheet_optimizer.gs      # メインスクリプト
├── monthly_sheet_optimizer_test.gs # テスト・検証スクリプト
└── GAS導入ガイド_提案.md           # このファイル
```

---

## セットアップ手順

### 1. Apps Script にコードを配置

1. Google Sheets で対象のスプレッドシートを開く
2. **拡張機能 → Apps Script** を選択
3. 既存の `Code.gs` の内容を削除し、`monthly_sheet_optimizer.gs` の内容を貼り付け
4. **＋** ボタンで新規スクリプトファイルを追加 → `test` と命名
5. `monthly_sheet_optimizer_test.gs` の内容を貼り付け
6. **保存**（Ctrl+S）

### 2. 初回実行（権限の承認）

1. シートをリロード（F5）
2. メニューバーに「⚡ 月別最適化」が表示される
3. 「🔍 事前チェック」を実行 → Google の権限承認ダイアログが表示される
4. 「詳細を表示」→「（安全ではないページ）に移動」→「許可」

### 3. CONFIG の調整

| 設定 | デフォルト | 確認事項 |
|------|-----------|---------|
| `cvKeyColumn` | `'A'` | **◆CV シートの実際のキー列に変更すること** |
| `searchKeyColumn` | `'BQ'` | BQ列が空いていることを確認 |
| `dataEndRow` | `169` | 実際のデータ末尾行と一致しているか |
| `aggregateEndRow` | `200` | 170行目以降の集計セクション末尾 |
| `dryRun` | `true` | **初回は必ず true のまま実行** |

---

## 実行フロー

```
1. 事前チェック        CONFIG が正しいか、シートが揃っているか確認
      ↓
2. スナップショット     改善前の全セル値を _snapshot シートに保存
      ↓
3. パフォーマンス計測   改善前のベースラインを記録
      ↓
4. dryRun=true で確認   各 Step のプレビューで変更内容を確認
      ↓
5. dryRun=false に変更  実際の適用モードに切り替え
      ↓
6. Step 1〜6 を順番に   各 Step 後に自動検証（失敗時は自動ロールバック提案）
      ↓
7. 全体検証             _snapshot との完全照合
      ↓
8. まとめシート検証     「2026年02月まとめ」への影響がないことを確認
      ↓
9. パフォーマンス再計測  改善後の数値を記録、Before/After を比較
      ↓
10. クリーンアップ      作業用シート・プロパティの削除
```

---

## 自主提案

### 提案1: 月次テンプレート化（毎月の運用自動化）

現在の CONFIG は `2026年02月` にハードコードされているが、`monthlySheet` を変更するだけで他の月にも適用可能。

**さらに進めるなら:**

```javascript
// 月名を動的に取得する関数
function getActiveMonthSheet() {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  return `${year}年${month}月`;
}
```

毎月のシート作成時に GAS を1回実行するだけで最適化が完了する運用が可能。

### 提案2: 【自動】マスター参照 の自動更新トリガー

月替わりでシート名が変わると、【自動】マスター参照 の XLOOKUP 参照先も更新が必要。

**時限トリガーで自動化:**

```javascript
function setupMonthlyTrigger() {
  // 毎月1日 AM 9:00 に実行
  ScriptApp.newTrigger('refreshCache')
    .timeBased()
    .onMonthDay(1)
    .atHour(9)
    .create();
}

function refreshCache() {
  // 当月のシート名を取得し、【自動】マスター参照 を再作成
  const monthName = getActiveMonthSheet();
  CONFIG.monthlySheet = monthName;
  // Step 2 の 【自動】マスター参照 再作成ロジックを実行
  applyStep2();
}
```

### 提案3: エラー監視アラート

N2（エラーセル数）が増加したら Slack / メールで通知する。

```javascript
function monitorErrors() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet()
    .getSheetByName(CONFIG.monthlySheet);
  const errorCount = sheet.getRange('N2').getValue();

  if (errorCount > 0) {
    MailApp.sendEmail(
      'team@example.com',
      `⚠️ 月別シート エラー検出: ${errorCount}件`,
      `シート「${CONFIG.monthlySheet}」で ${errorCount} 件のエラーセルが検出されました。\n確認してください。`
    );
  }
}

// 毎日 AM 10:00 にチェック
function setupErrorMonitor() {
  ScriptApp.newTrigger('monitorErrors')
    .timeBased()
    .everyDays(1)
    .atHour(10)
    .create();
}
```

### 提案4: まとめシートとの整合性自動テスト

「2026年02月まとめ」シートは月別シートの値を参照している可能性が高い。改善後にまとめシートの値が変わっていないことをテストスクリプトで自動確認できるようにした（`testSummarySheetImpact`）。

**追加で検討すべき点:**
- まとめシートの D2:R70 が月別シートのどのセルを参照しているか確認
- 参照先が変わった場合（例: XLOOKUP → 【自動】マスター参照参照）にまとめシート側にも影響がないか
- まとめシートにも XLOOKUP があれば同様の最適化が可能

### 提案5: ダッシュボード付き実行ログ

GAS 実行ログを `_log` シートに書き出し、いつ・誰が・何を適用したか追跡可能にする。

```javascript
function logAction(action, details) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let log = ss.getSheetByName('_log');
  if (!log) {
    log = ss.insertSheet('_log');
    log.getRange('A1:D1').setValues([['タイムスタンプ', '実行者', 'アクション', '詳細']]);
    log.hideSheet();
  }
  log.appendRow([
    new Date(),
    Session.getActiveUser().getEmail(),
    action,
    details,
  ]);
}
```

### 提案6: 段階的レンジ閉鎖の動的化

現在のレンジ閉鎖は `169行` / `200行` にハードコードしている。データ行が増えた場合に備えて、COUNTA で動的に末尾行を検出する方式も検討可能:

```
=SUM(INDIRECT("S5:S" & COUNTA(S:S) + 4))
```

ただし INDIRECT は再計算トリガーが異なるため、パフォーマンスとのトレードオフがある。データ行が固定的なら現状のハードコードの方が高速。

### 提案7: 手動適用との使い分け

| 手段 | メリット | デメリット |
|------|---------|-----------|
| GAS 一括適用 | 高速・正確・自動検証 | Apps Script の権限設定が必要 |
| 手動（コピペ） | すぐ始められる | ミスしやすい・検証が手間 |
| ハイブリッド | GAS で検証のみ利用 | 柔軟だが手順が増える |

**推奨: まず手動で Step 1（レンジ閉鎖）だけ試し、効果を確認してから GAS で残りを一括適用。**

---

## 既存スプレッドシートとの仕様一致チェックリスト

GAS 適用後に以下を確認すること:

| チェック項目 | 確認方法 | 状態 |
|-------------|---------|------|
| Row 2 集計値が全て一致 | 全体検証（validateAll） | ☐ |
| H列（IF名称）が全行一致 | スポットチェック | ☐ |
| I列（SNSアカウント）が全行一致 | I5 のLET分岐ロジック確認 | ☐ |
| AB列（支払区分）が全行一致 | 【自動】マスター参照 G列との照合 | ☐ |
| U/V/W列（CV値）が全行一致 | BQ列の検索キーが正しいか | ☐ |
| AE/AG列（源泉徴収）が全行一致 | Step 5 strict モードで自動検証 | ☐ |
| N2（エラーセル数）が一致 | 直接比較 | ☐ |
| BD列（口座バリデーション）が全行一致 | 変更なし（影響なしを確認） | ☐ |
| まとめシートの値が不変 | testSummarySheetImpact | ☐ |
| 他シート（◆CV, ◆list 等）への影響なし | 変更なし（参照のみ） | ☐ |

---

## 注意事項

- `dryRun = true` のままでは変更は適用されない（プレビューのみ）
- Step 2 の 【自動】マスター参照 作成には XLOOKUP の展開に数秒かかる（`Utilities.sleep(5000)` で待機）
- Apps Script の実行時間制限は 6分（通常は十分だが、巨大スプレッドシートでは注意）
- `◆CV` のキー列（`cvKeyColumn`）は実シートで確認してから設定すること
- BN5 の参照先は「🔎 BN5 参照先自動検出」で特定できる
