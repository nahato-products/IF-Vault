/**
 * 月別シート最適化 — エントリーポイント
 *
 * スプレッドシートのカスタムメニューから
 * dryRun / 実行 / 負荷テスト / ロールバック を選択可能。
 */

// ═══════════════════════════════════════════════
// メニュー追加
// ═══════════════════════════════════════════════

function onOpen() {
  SpreadsheetApp.getUi()
    .createMenu('🔧 最適化ツール')
    .addItem('① dryRun（変更プレビュー）', 'menuDryRun')
    .addItem('② 全Step最適化実行', 'menuOptimize')
    .addSeparator()
    .addItem('③ 負荷テスト実行', 'menuLoadTest')
    .addSeparator()
    .addItem('④ 【自動】マスター参照 シート削除（ロールバック）', 'menuDeleteCache')
    .addItem('⑤ 【自動】マスター参照 シート保護設定', 'menuProtectCache')
    .addToUi();
}

// ═══════════════════════════════════════════════
// メニューハンドラー
// ═══════════════════════════════════════════════

/**
 * ① dryRun: 変更内容をログに出力（実際の変更なし）
 */
function menuDryRun() {
  const ui = SpreadsheetApp.getUi();

  ui.alert(
    'dryRun モード',
    `対象シート: ${CONFIG.targetSheetName}\n` +
    `データ行: ${CONFIG.dataStartRow}〜${CONFIG.dataEndRow}\n\n` +
    '変更内容をログに出力します（実際の変更はしません）。\n' +
    '実行後に「表示 → 実行ログ」で結果を確認してください。',
    ui.ButtonSet.OK
  );

  const result = runAllSteps(true);

  // サマリーをアラート表示
  const step1Changed = result.step1.filter(r => r.changed).length;
  const step2Cells = result.step2.cellsUpdated.length;
  const step3Cells = result.step3.updatedCells.length + 1; // +1 for BQ key
  const step4Cells = result.step4.length;
  const step5Cells = result.step5.cells.length;

  ui.alert(
    'dryRun 完了',
    `Step 1（範囲閉鎖）: ${step1Changed}セル変更予定\n` +
    `Step 2（XLOOKUP集約）: ${step2Cells}セル + 【自動】マスター参照シート作成\n` +
    `Step 3（CV検索キー）: ${step3Cells}セル\n` +
    `Step 4（LETキャッシュ）: ${step4Cells}セル\n` +
    `Step 5（源泉簡約）: ${step5Cells}セル（⚠️要全行検算）\n` +
    `Step 6（エラーカウント）: 1セル\n\n` +
    '詳細は「表示 → 実行ログ」を確認してください。',
    ui.ButtonSet.OK
  );
}

/**
 * ② 全Step最適化実行
 */
function menuOptimize() {
  const ui = SpreadsheetApp.getUi();

  // 確認ダイアログ
  const confirm = ui.alert(
    '⚠️ 最適化実行',
    `対象シート: ${CONFIG.targetSheetName}\n\n` +
    '全6Stepの最適化を実行します。\n' +
    'before スナップショットを自動取得し、\n' +
    '適用後に値の一致を検証します。\n\n' +
    '続行しますか？',
    ui.ButtonSet.YES_NO
  );

  if (confirm !== ui.Button.YES) {
    ui.alert('キャンセルしました。');
    return;
  }

  try {
    const result = runAllSteps(false);

    ui.alert(
      '✅ 最適化完了',
      '全Stepの適用が完了しました。\n' +
      '詳細は「表示 → 実行ログ」を確認してください。\n\n' +
      '次のステップ:\n' +
      '1. 合計値（S2, T2等）が正しいか確認\n' +
      '2. 負荷テストで速度改善を確認\n' +
      '3. 問題があれば「【自動】マスター参照 シート削除」でロールバック',
      ui.ButtonSet.OK
    );
  } catch (e: any) {
    ui.alert('❌ エラー', `最適化中にエラーが発生しました:\n${e.message}`, ui.ButtonSet.OK);
    Logger.log(`エラー: ${e.message}\n${e.stack}`);
  }
}

/**
 * ③ 負荷テスト実行
 */
function menuLoadTest() {
  const ui = SpreadsheetApp.getUi();

  ui.alert(
    '負荷テスト',
    `対象シート: ${CONFIG.targetSheetName}\n` +
    `ラウンド数: ${CONFIG.loadTest.rounds}\n` +
    `書き込み/ラウンド: ${CONFIG.loadTest.writesPerRound}\n\n` +
    'テスト後に値は自動復元されます。',
    ui.ButtonSet.OK
  );

  try {
    const result = runLoadTest();

    ui.alert(
      '負荷テスト結果',
      `シート: ${result.sheetName}\n\n` +
      `平均: ${result.stats.avgMs}ms\n` +
      `中央値: ${result.stats.medianMs}ms\n` +
      `最小: ${result.stats.minMs}ms\n` +
      `最大: ${result.stats.maxMs}ms\n` +
      `標準偏差: ${result.stats.stddevMs}ms\n\n` +
      `復元セル: ${result.cellsRestored}`,
      ui.ButtonSet.OK
    );
  } catch (e: any) {
    ui.alert('❌ エラー', `負荷テスト中にエラー:\n${e.message}`, ui.ButtonSet.OK);
  }
}

/**
 * ④ 【自動】マスター参照 シート削除（ロールバック）
 */
function menuDeleteCache() {
  const ui = SpreadsheetApp.getUi();

  if (!cacheSheetExists()) {
    ui.alert('【自動】マスター参照 シートは存在しません。');
    return;
  }

  const confirm = ui.alert(
    '⚠️ 【自動】マスター参照 シート削除',
    '【自動】マスター参照 シートを削除します。\n' +
    'Step 2 の最適化が無効になります。\n\n' +
    '※ 月別シートの参照式（H5, AB5等）は\n' +
    '  手動で元のXLOOKUP式に戻す必要があります。\n\n' +
    '続行しますか？',
    ui.ButtonSet.YES_NO
  );

  if (confirm === ui.Button.YES) {
    deleteCacheSheet();
    ui.alert('【自動】マスター参照 シートを削除しました。');
  }
}

/**
 * ⑤ 【自動】マスター参照 シート保護設定
 */
function menuProtectCache() {
  if (!cacheSheetExists()) {
    SpreadsheetApp.getUi().alert('【自動】マスター参照 シートが存在しません。先に最適化を実行してください。');
    return;
  }

  protectCacheSheet();
  SpreadsheetApp.getUi().alert('【自動】マスター参照 シートを非表示＋保護に設定しました。');
}

// ═══════════════════════════════════════════════
// 個別Step実行（デバッグ・テスト用）
// ═══════════════════════════════════════════════

function runStep1Only() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(CONFIG.targetSheetName)!;
  const result = step1_closeOpenRanges(sheet, false);
  Logger.log(`Step 1 完了: ${result.filter(r => r.changed).length}セル変更`);
}

function runStep2Only() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(CONFIG.targetSheetName)!;
  const result = step2_consolidateXlookup(ss, sheet, false);
  Logger.log(`Step 2 完了: ${result.cellsUpdated.length}セル変更`);
}

function runStep3Only() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(CONFIG.targetSheetName)!;
  const result = step3_cvKeyConsolidation(sheet, false);
  Logger.log(`Step 3 完了: ${result.updatedCells.length + 1}セル変更`);
}

function runStep4Only() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(CONFIG.targetSheetName)!;
  const result = step4_letCaching(sheet, false);
  Logger.log(`Step 4 完了: ${result.length}セル変更`);
}

function runStep5Only() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(CONFIG.targetSheetName)!;
  const result = step5_taxSimplification(sheet, false);
  Logger.log(`Step 5: ${result.applied ? '適用済み' : 'スキップ（不一致' + result.mismatches + '件）'}`);
}

function runStep6Only() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(CONFIG.targetSheetName)!;
  step6_errorCountOptimization(sheet, false);
  Logger.log('Step 6 完了');
}
