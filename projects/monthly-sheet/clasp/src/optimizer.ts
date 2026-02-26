/**
 * 月別シート最適化 — 各Stepの実装
 *
 * 全6Stepをそれぞれ独立した関数として実装。
 * 各関数は dryRun モードを持ち、変更なしでプレビュー可能。
 */

// ─────────────────────────────────────────────
// ヘルパー
// ─────────────────────────────────────────────

/** セル名（例: "S2"）から Range を取得 */
function _getRange(sheet: GoogleAppsScript.Spreadsheet.Sheet, cellName: string) {
  return sheet.getRange(cellName);
}

/** 列文字を列番号に変換（A=1, B=2, ..., AA=27） */
function _colToNum(col: string): number {
  let num = 0;
  for (let i = 0; i < col.length; i++) {
    num = num * 26 + (col.charCodeAt(i) - 64);
  }
  return num;
}

/** ログ出力 */
function _log(step: string, msg: string) {
  Logger.log(`[${step}] ${msg}`);
}

// ─────────────────────────────────────────────
// Step 1: オープンレンジ閉鎖
// ─────────────────────────────────────────────

interface Step1Result {
  cell: string;
  before: string;
  after: string;
  changed: boolean;
}

function step1_closeOpenRanges(
  sheet: GoogleAppsScript.Spreadsheet.Sheet,
  dryRun: boolean = true
): Step1Result[] {
  const results: Step1Result[] = [];

  const allCells = [
    ...CONFIG.step1.sumCellsDataRange,
    ...CONFIG.step1.sumCellsSubRange,
  ];

  for (const item of allCells) {
    const range = _getRange(sheet, item.cell);
    const currentFormula = range.getFormula();

    if (!currentFormula) {
      _log('Step1', `${item.cell}: 数式なし、スキップ`);
      continue;
    }

    // SUM(X5:X) → SUM(X5:X169) のように末尾行を付加
    // パターン: SUM(COL + ROW + : + COL + `)` → SUM(COL + ROW + : + COL + END_ROW + `)`)
    const colMatch = currentFormula.match(/=SUM\(([A-Z]+)(\d+):([A-Z]+)\)/i);
    const closedMatch = currentFormula.match(/=SUM\(([A-Z]+)(\d+):([A-Z]+)(\d+)\)/i);

    let newFormula = currentFormula;

    if (colMatch) {
      // オープンレンジ: SUM(S5:S) → SUM(S5:S169)
      const col = colMatch[1];
      const startRow = colMatch[2];
      newFormula = `=SUM(${col}${startRow}:${col}${item.endRow})`;
    } else if (closedMatch) {
      // 既に閉鎖済みだが endRow が異なる場合は更新
      const col1 = closedMatch[1];
      const startRow = closedMatch[2];
      const col2 = closedMatch[3];
      const currentEnd = parseInt(closedMatch[4]);
      if (currentEnd !== item.endRow) {
        newFormula = `=SUM(${col1}${startRow}:${col2}${item.endRow})`;
      }
    }

    const changed = newFormula !== currentFormula;
    results.push({
      cell: item.cell,
      before: currentFormula,
      after: newFormula,
      changed,
    });

    if (changed) {
      _log('Step1', `${item.cell}: ${currentFormula} → ${newFormula}`);
      if (!dryRun) {
        range.setFormula(newFormula);
      }
    } else {
      _log('Step1', `${item.cell}: 変更不要`);
    }
  }

  return results;
}

// ─────────────────────────────────────────────
// Step 2: XLOOKUP集約（_cacheシート方式）
// ─────────────────────────────────────────────

interface Step2Result {
  cacheCreated: boolean;
  cellsUpdated: string[];
  errors: string[];
}

function step2_consolidateXlookup(
  ss: GoogleAppsScript.Spreadsheet.Spreadsheet,
  sheet: GoogleAppsScript.Spreadsheet.Sheet,
  dryRun: boolean = true
): Step2Result {
  const result: Step2Result = {
    cacheCreated: false,
    cellsUpdated: [],
    errors: [],
  };

  const sheetName = CONFIG.targetSheetName;
  const startRow = CONFIG.dataStartRow;
  const endRow = CONFIG.dataEndRow;
  const masterName = CONFIG.masterSheetName;
  const cacheName = CONFIG.cacheSheetName;

  // 2-1. _cache シートの作成
  _log('Step2', '_cache シート作成');
  const cacheFormula =
    `=ArrayFormula(IFERROR(XLOOKUP(` +
    `'${sheetName}'!E${startRow}:E${endRow}&'${sheetName}'!BB${startRow}:BB${endRow},` +
    `'${masterName}'!B2:B&TEXT('${masterName}'!R2:R,"0000000"),` +
    `'${masterName}'!C2:S2)))`;

  _log('Step2', `_cache!A${startRow} = ${cacheFormula}`);

  if (!dryRun) {
    let cacheSheet = ss.getSheetByName(cacheName);
    if (!cacheSheet) {
      cacheSheet = ss.insertSheet(cacheName);
      result.cacheCreated = true;
    }
    cacheSheet.getRange(`A${startRow}`).setFormula(cacheFormula);
    SpreadsheetApp.flush();
  } else {
    result.cacheCreated = true;
  }

  // 2-3. 月別シートの各セルを _cache 参照に置換
  for (const mapping of CONFIG.step2.xlookupMappings) {
    const newFormula = `=ArrayFormula('${cacheName}'!${mapping.cacheCol}${startRow}:${mapping.cacheCol}${endRow})`;
    _log('Step2', `${mapping.targetCell}: → ${newFormula} (${mapping.description})`);

    if (!dryRun) {
      _getRange(sheet, mapping.targetCell).setFormula(newFormula);
    }
    result.cellsUpdated.push(mapping.targetCell);
  }

  // 2-4. I5: SNS分岐（LET最適化版）
  const sns = CONFIG.step2.snsCacheMapping;
  const i5Formula =
    `=ArrayFormula(LET(` +
    `g,G${startRow}:G${endRow},` +
    `ig,'${cacheName}'!${sns.instagram}${startRow}:${sns.instagram}${endRow},` +
    `yt,'${cacheName}'!${sns.youtube}${startRow}:${sns.youtube}${endRow},` +
    `tw,'${cacheName}'!${sns.twitter}${startRow}:${sns.twitter}${endRow},` +
    `tiktok,'${cacheName}'!${sns.tiktok}${startRow}:${sns.tiktok}${endRow},` +
    `other,'${cacheName}'!${sns.other}${startRow}:${sns.other}${endRow},` +
    `IFS(` +
    `(g="")+(g=0),ig,` +
    `g=2,other,` +
    `REGEXMATCH(LOWER(g),"instagram"),ig,` +
    `REGEXMATCH(LOWER(g),"youtube"),yt,` +
    `REGEXMATCH(LOWER(g),"twitter"),tw,` +
    `REGEXMATCH(LOWER(g),"tiktok"),tiktok,` +
    `TRUE,other)))`;

  _log('Step2', `I5: → SNS分岐LET版`);
  if (!dryRun) {
    _getRange(sheet, 'I5').setFormula(i5Formula);
  }
  result.cellsUpdated.push('I5');

  return result;
}

// ─────────────────────────────────────────────
// Step 3: CV検索キー集約
// ─────────────────────────────────────────────

interface Step3Result {
  keyCell: string;
  updatedCells: string[];
}

function step3_cvKeyConsolidation(
  sheet: GoogleAppsScript.Spreadsheet.Sheet,
  dryRun: boolean = true
): Step3Result {
  const startRow = CONFIG.dataStartRow;
  const endRow = CONFIG.dataEndRow;

  // 3-1. BQ5: 検索キー生成
  const bqFormula =
    `=ArrayFormula(LET(` +
    `ym,TEXT(B2,"YYMM"),` +
    `agent,XLOOKUP(MID(B${startRow}:B${endRow},5,10),'◆list'!F:F,'◆list'!E:E),` +
    `ym&M${startRow}:M${endRow}&L${startRow}:L${endRow}&agent&F${startRow}:F${endRow}))`;

  _log('Step3', `BQ${startRow}: 検索キー生成式`);

  // 3-2〜3-4. U5, V5, W5
  // ※ '◆CV'のキー列は実際のシートで要確認（仮でA列）
  const cvKeyCol = 'A'; // ◆CV のキー列（実シートで確認必要）

  const u5Formula =
    `=ArrayFormula(IFERROR(XLOOKUP(BQ${startRow}:BQ${endRow},'◆CV'!${cvKeyCol}:${cvKeyCol},'◆CV'!F:F)))`;

  const v5Formula =
    `=ArrayFormula(IFERROR(XLOOKUP(BQ${startRow}:BQ${endRow},'◆CV'!${cvKeyCol}:${cvKeyCol},'◆CV'!G:G)))`;

  const w5Formula =
    `=ArrayFormula(LET(` +
    `cv_h,IFERROR(XLOOKUP(BQ${startRow}:BQ${endRow},'◆CV'!${cvKeyCol}:${cvKeyCol},'◆CV'!H:H)),` +
    `x,X${startRow}:X${endRow},` +
    `IF(x<>"",x,cv_h)))`;

  _log('Step3', `U5: CV参照（F列）`);
  _log('Step3', `V5: CV参照（G列）`);
  _log('Step3', `W5: CV参照（H列）+ 手動上書き`);

  if (!dryRun) {
    _getRange(sheet, `BQ${startRow}`).setFormula(bqFormula);
    _getRange(sheet, 'U5').setFormula(u5Formula);
    _getRange(sheet, 'V5').setFormula(v5Formula);
    _getRange(sheet, 'W5').setFormula(w5Formula);
  }

  return {
    keyCell: `BQ${startRow}`,
    updatedCells: ['U5', 'V5', 'W5'],
  };
}

// ─────────────────────────────────────────────
// Step 4: LETキャッシュ化
// ─────────────────────────────────────────────

function step4_letCaching(
  sheet: GoogleAppsScript.Spreadsheet.Sheet,
  dryRun: boolean = true
): string[] {
  const s = CONFIG.dataStartRow;
  const e = CONFIG.dataEndRow;
  const updated: string[] = [];

  // 4-1. T5: 利益計算
  const t5Formula =
    `=ArrayFormula(LET(` +
    `s,S${s}:S${e},r,R${s}:R${e},af,AF${s}:AF${e},bf,BF${s}:BF${e},bg,BG${s}:BG${e},` +
    `IF(bg="成果",s-(r*af),s-bf)))`;

  // 4-2. Z5: 確定売上
  const z5Formula =
    `=ArrayFormula(LET(` +
    `q,Q${s}:Q${e},d,D${s}:D${e},n,N${s}:N${e},x,X${s}:X${e},` +
    `IF(q=TRUE,IF(d="予算/ボーナス",n,n*x),0)))`;

  // 4-3. AA5: 確定利益
  const aa5Formula =
    `=ArrayFormula(LET(` +
    `q,Q${s}:Q${e},z,Z${s}:Z${e},bf,BF${s}:BF${e},` +
    `IF(q=TRUE,z-bf,z)))`;

  const formulas: [string, string][] = [
    ['T5', t5Formula],
    ['Z5', z5Formula],
    ['AA5', aa5Formula],
  ];

  for (const [cell, formula] of formulas) {
    _log('Step4', `${cell}: LETキャッシュ化`);
    if (!dryRun) {
      _getRange(sheet, cell).setFormula(formula);
    }
    updated.push(cell);
  }

  return updated;
}

// ─────────────────────────────────────────────
// Step 5: 源泉徴収簡約化
// ─────────────────────────────────────────────

interface Step5Result {
  applied: boolean;
  mismatches: number;
  cells: string[];
}

function step5_taxSimplification(
  sheet: GoogleAppsScript.Spreadsheet.Sheet,
  dryRun: boolean = true
): Step5Result {
  const s = CONFIG.dataStartRow;
  const e = CONFIG.dataEndRow;
  const result: Step5Result = { applied: false, mismatches: 0, cells: [] };

  const taxCells = CONFIG.step5.taxCells;

  // AE5: ROUNDUP(AD * 1.08 / 1.1)
  const ae5Formula = `=ArrayFormula(ROUNDUP(${taxCells.fixed.sourceCol}${s}:${taxCells.fixed.sourceCol}${e}*1.08/1.1))`;
  // AG5: ROUNDUP(AF * 1.08 / 1.1)
  const ag5Formula = `=ArrayFormula(ROUNDUP(${taxCells.result.sourceCol}${s}:${taxCells.result.sourceCol}${e}*1.08/1.1))`;

  _log('Step5', `⚠️ 源泉徴収簡約化 — 全行検算が必要`);

  if (!dryRun) {
    // before の値をスナップショット
    const aeRange = sheet.getRange(`AE${s}:AE${e}`);
    const agRange = sheet.getRange(`AG${s}:AG${e}`);
    const aeBefore = aeRange.getValues();
    const agBefore = agRange.getValues();

    // 数式を適用
    _getRange(sheet, 'AE5').setFormula(ae5Formula);
    SpreadsheetApp.flush();

    // after の値と比較
    const aeAfter = aeRange.getValues();
    let aeMismatches = 0;
    for (let i = 0; i < aeBefore.length; i++) {
      if (aeBefore[i][0] !== aeAfter[i][0] && aeBefore[i][0] !== '' && aeAfter[i][0] !== '') {
        aeMismatches++;
        _log('Step5', `AE${s + i}: 不一致 ${aeBefore[i][0]} → ${aeAfter[i][0]}`);
      }
    }

    if (aeMismatches > 0) {
      // ロールバック: 元の数式に戻す
      _log('Step5', `❌ AE列で${aeMismatches}件の不一致。ロールバック`);
      // 元の数式をセットし直す（元の冗長版）
      const aeOriginal = `=ArrayFormula(ROUNDUP((${taxCells.fixed.sourceCol}${s}:${taxCells.fixed.sourceCol}${e}/1.1)+(${taxCells.fixed.sourceCol}${s}:${taxCells.fixed.sourceCol}${e}-${taxCells.fixed.sourceCol}${s}:${taxCells.fixed.sourceCol}${e}/1.1)-(${taxCells.fixed.sourceCol}${s}:${taxCells.fixed.sourceCol}${e}-${taxCells.fixed.sourceCol}${s}:${taxCells.fixed.sourceCol}${e}/1.1)*0.2))`;
      _getRange(sheet, 'AE5').setFormula(aeOriginal);
      result.mismatches = aeMismatches;
      return result;
    }

    // AE OK → AG も適用
    _getRange(sheet, 'AG5').setFormula(ag5Formula);
    SpreadsheetApp.flush();

    const agAfter = agRange.getValues();
    let agMismatches = 0;
    for (let i = 0; i < agBefore.length; i++) {
      if (agBefore[i][0] !== agAfter[i][0] && agBefore[i][0] !== '' && agAfter[i][0] !== '') {
        agMismatches++;
      }
    }

    if (agMismatches > 0) {
      _log('Step5', `❌ AG列で${agMismatches}件の不一致。ロールバック`);
      const agOriginal = `=ArrayFormula(ROUNDUP((${taxCells.result.sourceCol}${s}:${taxCells.result.sourceCol}${e}/1.1)+(${taxCells.result.sourceCol}${s}:${taxCells.result.sourceCol}${e}-${taxCells.result.sourceCol}${s}:${taxCells.result.sourceCol}${e}/1.1)-(${taxCells.result.sourceCol}${s}:${taxCells.result.sourceCol}${e}-${taxCells.result.sourceCol}${s}:${taxCells.result.sourceCol}${e}/1.1)*0.2))`;
      _getRange(sheet, 'AG5').setFormula(agOriginal);
      result.mismatches = agMismatches;
      return result;
    }

    result.applied = true;
    result.cells = ['AE5', 'AG5'];
  } else {
    _log('Step5', `AE5: → ${ae5Formula}`);
    _log('Step5', `AG5: → ${ag5Formula}`);
    result.cells = ['AE5', 'AG5'];
  }

  return result;
}

// ─────────────────────────────────────────────
// Step 6: エラーカウント範囲限定
// ─────────────────────────────────────────────

function step6_errorCountOptimization(
  sheet: GoogleAppsScript.Spreadsheet.Sheet,
  dryRun: boolean = true
): string {
  const e = CONFIG.dataEndRow;

  // XLOOKUP系列のみに限定（エラーが発生しうる列）
  const n2Formula =
    `=SUMPRODUCT(ISERROR(B3:BD3)*1)` +
    `+SUMPRODUCT(ISERROR(H5:I${e})*1)` +
    `+SUMPRODUCT(ISERROR(U5:W${e})*1)` +
    `+SUMPRODUCT(ISERROR(AB5:AC${e})*1)`;

  _log('Step6', `N2: エラーカウント最適化版`);
  _log('Step6', `N2: → ${n2Formula}`);

  if (!dryRun) {
    _getRange(sheet, 'N2').setFormula(n2Formula);
  }

  return n2Formula;
}

// ─────────────────────────────────────────────
// 全Step統合実行
// ─────────────────────────────────────────────

interface OptimizeResult {
  step1: Step1Result[];
  step2: Step2Result;
  step3: Step3Result;
  step4: string[];
  step5: Step5Result;
  step6: string;
  dryRun: boolean;
}

function runAllSteps(dryRun: boolean = true): OptimizeResult {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(CONFIG.targetSheetName);

  if (!sheet) {
    throw new Error(`シート "${CONFIG.targetSheetName}" が見つかりません`);
  }

  _log('Main', `=== 最適化${dryRun ? '(dryRun)' : '(実行)'} 開始 ===`);
  _log('Main', `対象: ${CONFIG.targetSheetName} (行${CONFIG.dataStartRow}〜${CONFIG.dataEndRow})`);

  // before スナップショット
  let snapshot: CellSnapshot[] | null = null;
  if (!dryRun) {
    snapshot = takeSnapshot(sheet);
    _log('Main', `スナップショット取得: ${snapshot.length}セル`);
  }

  const result: OptimizeResult = {
    step1: step1_closeOpenRanges(sheet, dryRun),
    step2: step2_consolidateXlookup(ss, sheet, dryRun),
    step3: step3_cvKeyConsolidation(sheet, dryRun),
    step4: step4_letCaching(sheet, dryRun),
    step5: step5_taxSimplification(sheet, dryRun),
    step6: step6_errorCountOptimization(sheet, dryRun),
    dryRun,
  };

  // after 検証
  if (!dryRun && snapshot) {
    SpreadsheetApp.flush();
    const afterSnapshot = takeSnapshot(sheet);
    const validation = compareSnapshots(snapshot, afterSnapshot);
    _log('Main', `検証結果: ${validation.passed ? '✅ 全一致' : '❌ 不一致あり'}`);
    if (!validation.passed) {
      for (const m of validation.mismatches) {
        _log('Main', `  不一致: ${m.cell} ${m.before} → ${m.after}`);
      }
    }
  }

  _log('Main', `=== 最適化完了 ===`);
  return result;
}
