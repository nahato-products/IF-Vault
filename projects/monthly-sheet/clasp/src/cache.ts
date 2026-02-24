/**
 * 月別シート最適化 — _cache シート管理
 *
 * Step 2 で使用するキャッシュシートの作成・検証・削除。
 */

/**
 * _cache シートが存在するか確認
 */
function cacheSheetExists(): boolean {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  return ss.getSheetByName(CONFIG.cacheSheetName) !== null;
}

/**
 * _cache シートを作成し、XLOOKUP数式を配置
 */
function createCacheSheet(): GoogleAppsScript.Spreadsheet.Sheet {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const cacheName = CONFIG.cacheSheetName;
  const sheetName = CONFIG.targetSheetName;
  const masterName = CONFIG.masterSheetName;
  const startRow = CONFIG.dataStartRow;
  const endRow = CONFIG.dataEndRow;

  // 既存チェック
  let cacheSheet = ss.getSheetByName(cacheName);
  if (cacheSheet) {
    Logger.log(`_cache シートは既に存在します。再利用します。`);
    return cacheSheet;
  }

  // 新規作成
  cacheSheet = ss.insertSheet(cacheName);

  // XLOOKUP一括取得式を配置
  const formula =
    `=ArrayFormula(IFERROR(XLOOKUP(` +
    `'${sheetName}'!E${startRow}:E${endRow}&'${sheetName}'!BB${startRow}:BB${endRow},` +
    `'${masterName}'!B2:B&TEXT('${masterName}'!R2:R,"0000000"),` +
    `'${masterName}'!C2:S2)))`;

  cacheSheet.getRange(`A${startRow}`).setFormula(formula);
  SpreadsheetApp.flush();

  Logger.log(`_cache シート作成完了。A${startRow}に数式配置済み。`);
  return cacheSheet;
}

/**
 * _cache シートを非表示＋保護に設定
 */
function protectCacheSheet(): void {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const cacheSheet = ss.getSheetByName(CONFIG.cacheSheetName);

  if (!cacheSheet) {
    Logger.log('_cache シートが見つかりません。');
    return;
  }

  // 非表示
  cacheSheet.hideSheet();

  // シート保護
  const protection = cacheSheet.protect();
  protection.setDescription('自動生成キャッシュ — 編集不可');
  protection.setWarningOnly(true);

  Logger.log('_cache シートを非表示＋保護に設定しました。');
}

/**
 * _cache シートを削除（ロールバック用）
 */
function deleteCacheSheet(): boolean {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const cacheSheet = ss.getSheetByName(CONFIG.cacheSheetName);

  if (!cacheSheet) {
    Logger.log('_cache シートは存在しません。');
    return false;
  }

  // 非表示を解除してから削除
  if (cacheSheet.isSheetHidden()) {
    cacheSheet.showSheet();
  }
  ss.deleteSheet(cacheSheet);

  Logger.log('_cache シートを削除しました。');
  return true;
}

/**
 * _cache シートのデータ検証
 * マスター原本から正しくデータが取得できているか確認
 */
function validateCacheSheet(): { valid: boolean; errors: string[] } {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const cacheSheet = ss.getSheetByName(CONFIG.cacheSheetName);
  const targetSheet = ss.getSheetByName(CONFIG.targetSheetName);
  const errors: string[] = [];

  if (!cacheSheet) {
    return { valid: false, errors: ['_cache シートが存在しません'] };
  }
  if (!targetSheet) {
    return { valid: false, errors: [`${CONFIG.targetSheetName} シートが存在しません`] };
  }

  const startRow = CONFIG.dataStartRow;
  const endRow = CONFIG.dataEndRow;
  const dataRows = endRow - startRow + 1;

  // A列（IF名称 = マスター原本 C列）にデータがあるか確認
  const aValues = cacheSheet.getRange(`A${startRow}:A${endRow}`).getValues();
  let emptyCount = 0;
  for (const row of aValues) {
    if (row[0] === '' || row[0] === null) emptyCount++;
  }

  // E列にデータがある行で _cache が空なら問題
  const eValues = targetSheet.getRange(`E${startRow}:E${endRow}`).getValues();
  let eFilledCount = 0;
  for (const row of eValues) {
    if (row[0] !== '' && row[0] !== null) eFilledCount++;
  }

  if (emptyCount === dataRows) {
    errors.push('_cache のA列が全て空です。数式がエラーの可能性があります。');
  }

  Logger.log(`_cache 検証: データ${dataRows}行中、空セル${emptyCount}行, E列データ${eFilledCount}行`);

  return {
    valid: errors.length === 0,
    errors,
  };
}
