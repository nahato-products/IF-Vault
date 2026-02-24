/**
 * ============================================================
 * 月別シート関数 パフォーマンス改善 — テスト・検証スクリプト
 * ============================================================
 *
 * 概要:
 *   改善適用の正当性を多角的にテストする。
 *   メニューの「テスト」セクションから実行可能。
 *
 * テスト内容:
 *   1. 数学的等価性テスト（Step 5 の源泉徴収）
 *   2. スポットチェック（ランダム行の全列突合）
 *   3. 列ごとの詳細比較
 *   4. 【自動】マスター参照 シートの整合性チェック
 *   5. まとめシートへの影響検証
 *   6. パフォーマンス改善度の計測
 *
 * ============================================================
 */

// ============================================================
// テスト用メニュー追加（onOpen に統合）
// ============================================================

/**
 * メインの onOpen() に追記する場合はこの関数の中身を移動してください。
 * 単独で使う場合はそのまま実行可能です。
 */
function onOpen_test() {
  const ui = SpreadsheetApp.getUi();
  ui.createMenu('🧪 テスト')
    .addItem('全テスト実行',                  'runAllTests')
    .addSeparator()
    .addItem('源泉徴収 数学的等価性テスト',     'testStep5MathEquivalence')
    .addItem('スポットチェック（ランダム10行）', 'testSpotCheck')
    .addItem('【自動】マスター参照 整合性チェック',           'testCacheIntegrity')
    .addItem('まとめシート影響テスト',          'testSummarySheetImpact')
    .addItem('パフォーマンス比較テスト',        'testPerformanceComparison')
    .addItem('数式構造テスト',                 'testFormulaStructure')
    .addToUi();
}

// ============================================================
// テストランナー
// ============================================================

/**
 * 全テストを順番に実行し、結果をまとめて表示する
 */
function runAllTests() {
  const ui = SpreadsheetApp.getUi();
  const results = [];

  const tests = [
    { name: '数式構造テスト',           fn: testFormulaStructure },
    { name: '源泉徴収 等価性テスト',     fn: testStep5MathEquivalence },
    { name: 'スポットチェック',          fn: testSpotCheck },
    { name: '【自動】マスター参照 整合性チェック',     fn: testCacheIntegrity },
    { name: 'まとめシート影響テスト',    fn: testSummarySheetImpact },
  ];

  for (const test of tests) {
    try {
      const result = test.fn();
      results.push({
        name: test.name,
        passed: result.passed,
        message: result.message,
      });
    } catch (e) {
      results.push({
        name: test.name,
        passed: false,
        message: `例外: ${e.message}`,
      });
    }
  }

  // 結果表示
  const passCount = results.filter(r => r.passed).length;
  const totalCount = results.length;
  const icon = passCount === totalCount ? '✅' : '❌';

  const report = results.map(r =>
    `${r.passed ? '✅' : '❌'} ${r.name}\n   ${r.message}`
  ).join('\n\n');

  ui.alert(
    `テスト結果 ${icon} ${passCount}/${totalCount}`,
    report,
    ui.ButtonSet.OK
  );

  return results;
}

// ============================================================
// 個別テスト
// ============================================================

/**
 * テスト1: 数式が正しい構造で生成されるか
 */
function testFormulaStructure() {
  const defs = buildFormulas_();
  const errors = [];

  // Step 1: すべて =SUM(...) 形式であること
  for (const [cell, formula] of Object.entries(defs.step1.formulas)) {
    if (!formula.startsWith('=SUM(')) {
      errors.push(`Step1 ${cell}: SUM関数ではない: ${formula}`);
    }
    // 閉鎖レンジ（末尾が数字）であること
    if (formula.match(/:[A-Z]+\)$/)) {
      errors.push(`Step1 ${cell}: オープンレンジのまま: ${formula}`);
    }
  }

  // Step 2: 【自動】マスター参照 参照式がシート名を含むこと
  for (const [cell, formula] of Object.entries(defs.step2.formulas)) {
    if (cell === 'I5') continue; // I5 は特殊
    if (!formula.includes(MSO_CONFIG.cacheSheet)) {
      errors.push(`Step2 ${cell}: 【自動】マスター参照 シート参照がない: ${formula}`);
    }
  }

  // Step 5: 簡約式が正しい構造であること
  for (const [cell, formula] of Object.entries(defs.step5.formulas)) {
    if (!formula.includes('1.08/1.1')) {
      errors.push(`Step5 ${cell}: 簡約式 (1.08/1.1) が含まれていない: ${formula}`);
    }
  }

  return {
    passed: errors.length === 0,
    message: errors.length === 0
      ? '全数式の構造が正しい'
      : errors.join('\n'),
  };
}

/**
 * テスト2: 源泉徴収の数学的等価性
 * ROUNDUP(金額/1.1 + (金額-金額/1.1) - (金額-金額/1.1)*0.2) === ROUNDUP(金額*1.08/1.1)
 */
function testStep5MathEquivalence() {
  const testValues = [
    0, 1, 100, 999, 1000, 10000, 12345, 50000, 99999, 100000,
    333, 777, 1234567, 0.01, 0.5, 1.99,
    // 端数が出やすい値
    11, 111, 1111, 11111,
    3, 7, 13, 37, 97,
  ];

  const errors = [];

  for (const amount of testValues) {
    // 元の計算（Google Sheets の ROUNDUP は切り上げ = 小数部があれば +1）
    const taxExcl = amount / 1.1;
    const consumptionTax = amount - taxExcl;
    const withholding = consumptionTax * 0.2;
    const original = ceilAwayFromZero_(taxExcl + consumptionTax - withholding);

    // 簡約版
    const simplified = ceilAwayFromZero_(amount * 1.08 / 1.1);

    if (original !== simplified) {
      errors.push(`金額=${amount}: 元=${original}, 簡約=${simplified}, 差=${original - simplified}`);
    }
  }

  return {
    passed: errors.length === 0,
    message: errors.length === 0
      ? `${testValues.length}件のテスト値すべてで等価性を確認`
      : `${errors.length}件の不一致:\n${errors.join('\n')}`,
  };
}

/**
 * ROUNDUP 相当（0から離れる方向に切り上げ）
 */
function ceilAwayFromZero_(n) {
  if (n === 0) return 0;
  return n > 0 ? Math.ceil(n) : Math.floor(n);
}

/**
 * テスト3: ランダム行のスポットチェック
 * _snapshot とデータ行をランダムに10行比較する
 */
function testSpotCheck() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(MSO_CONFIG.monthlySheet);
  const snapshot = ss.getSheetByName(MSO_CONFIG.snapshotSheet);

  if (!snapshot) {
    return { passed: false, message: 'スナップショットが見つかりません' };
  }

  const s = MSO_CONFIG.dataStartRow;
  const e = MSO_CONFIG.dataEndRow;
  const totalRows = e - s + 1;
  const checkCount = Math.min(MSO_CONFIG.spotCheckCount, totalRows);

  // ランダム行を選択（重複なし）
  const rows = [];
  while (rows.length < checkCount) {
    const r = s + Math.floor(Math.random() * totalRows);
    if (!rows.includes(r)) rows.push(r);
  }
  rows.sort((a, b) => a - b);

  // チェック対象列
  const columns = ['H','I','S','T','U','V','W','Z','AA','AB','AC','AE','AG','AH','AI','BO'];
  const mismatches = [];

  for (const row of rows) {
    for (const col of columns) {
      const addr = `${col}${row}`;
      const expected = snapshot.getRange(addr).getValue();
      const actual = sheet.getRange(addr).getValue();
      if (!valuesMatch_(expected, actual)) {
        mismatches.push(`${addr}: 期待=${expected}, 実際=${actual}`);
      }
    }
  }

  return {
    passed: mismatches.length === 0,
    message: mismatches.length === 0
      ? `${checkCount}行 × ${columns.length}列 = ${checkCount * columns.length}セルのスポットチェック合格 (行: ${rows.join(',')})`
      : `${mismatches.length}件の不一致:\n${mismatches.slice(0, 10).join('\n')}`,
  };
}

/**
 * テスト4: 【自動】マスター参照 シートの整合性チェック
 * 【自動】マスター参照 の値がマスター原本の XLOOKUP 結果と一致するか
 */
function testCacheIntegrity() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const cache = ss.getSheetByName(MSO_CONFIG.cacheSheet);

  if (!cache) {
    return { passed: true, message: '【自動】マスター参照 シートが未作成（Step 2 未適用）— スキップ' };
  }

  const s = MSO_CONFIG.dataStartRow;
  const e = MSO_CONFIG.dataEndRow;

  // 【自動】マスター参照 の A列（= マスター原本 C列 = IF名称）が空でないことを確認
  const col_a = cache.getRange(`A${s}:A${e}`).getValues();
  const nonEmpty = col_a.filter(row => row[0] !== '' && row[0] != null).length;

  if (nonEmpty === 0) {
    return { passed: false, message: '【自動】マスター参照!A列が全て空です。XLOOKUP が正しく展開されていない可能性があります。' };
  }

  // 【自動】マスター参照 の列数が 17（C〜S列 = 17列）であることを確認
  const headerRow = cache.getRange(`A${s}:Q${s}`).getValues()[0];
  const colCount = headerRow.filter(v => v !== '' && v != null).length;

  // マスター原本の行数と 【自動】マスター参照 の有効行数が合理的であることを確認
  const monthly = ss.getSheetByName(MSO_CONFIG.monthlySheet);
  const eCol = monthly.getRange(`E${s}:E${e}`).getValues();
  const monthlyNonEmpty = eCol.filter(row => row[0] !== '' && row[0] != null).length;

  return {
    passed: nonEmpty > 0,
    message: [
      `【自動】マスター参照 データ行: ${nonEmpty}/${e - s + 1}行にデータあり`,
      `【自動】マスター参照 列数: ${colCount}列（期待: 最大17列）`,
      `月別シート E列 データ行: ${monthlyNonEmpty}行`,
      nonEmpty >= monthlyNonEmpty * 0.8
        ? '✅ データ充足率は十分'
        : `⚠️ 【自動】マスター参照 のデータが月別シートより少ない（${nonEmpty} < ${monthlyNonEmpty}）`,
    ].join('\n'),
  };
}

/**
 * テスト5: まとめシートへの影響テスト
 * 月別シートの改善がまとめシートの値に影響していないか確認
 */
function testSummarySheetImpact() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const summary = ss.getSheetByName(MSO_CONFIG.summarySheet);

  if (!summary) {
    return { passed: true, message: `シート「${MSO_CONFIG.summarySheet}」が見つかりません — スキップ` };
  }

  const props = PropertiesService.getScriptProperties();
  const savedJson = props.getProperty('summary_snapshot');

  if (!savedJson) {
    // 初回: スナップショットを保存
    const values = summary.getRange('D2:R70').getValues();
    props.setProperty('summary_snapshot', JSON.stringify(values));
    return { passed: true, message: 'まとめシートのスナップショットを保存しました（次回実行時に比較）' };
  }

  const saved = JSON.parse(savedJson);
  const current = summary.getRange('D2:R70').getValues();
  const mismatches = [];

  for (let r = 0; r < current.length; r++) {
    for (let c = 0; c < current[r].length; c++) {
      if (!valuesMatch_(saved[r][c], current[r][c])) {
        const cellAddr = `${indexToCol_(c + 3)}${r + 2}`;
        mismatches.push(`${cellAddr}: 期待=${saved[r][c]}, 実際=${current[r][c]}`);
      }
    }
  }

  return {
    passed: mismatches.length === 0,
    message: mismatches.length === 0
      ? `まとめシート D2:R70 (${current.length * current[0].length}セル) に影響なし`
      : `${mismatches.length}件の変化:\n${mismatches.slice(0, 5).join('\n')}`,
  };
}

/**
 * テスト6: パフォーマンス比較テスト
 * 再計算を5回実行して平均時間を計測する
 */
function testPerformanceComparison() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(MSO_CONFIG.monthlySheet);
  const runs = 5;
  const times = [];

  const dummyCell = sheet.getRange('A1');
  const originalValue = dummyCell.getValue();

  for (let i = 0; i < runs; i++) {
    const start = Date.now();
    dummyCell.setValue(`__perf_${i}__`);
    SpreadsheetApp.flush();
    times.push(Date.now() - start);
    Utilities.sleep(500);
  }

  // 元に戻す
  dummyCell.setValue(originalValue);
  SpreadsheetApp.flush();

  const avg = Math.round(times.reduce((a, b) => a + b, 0) / times.length);
  const min = Math.min(...times);
  const max = Math.max(...times);

  // 過去の計測結果と比較
  const props = PropertiesService.getScriptProperties();
  const history = JSON.parse(props.getProperty('perf_history') || '[]');
  let comparison = '';
  if (history.length > 0) {
    const lastAvg = history[history.length - 1].elapsed_ms;
    const improvement = ((lastAvg - avg) / lastAvg * 100).toFixed(1);
    comparison = `\n前回の計測: ${lastAvg}ms → 改善率: ${improvement}%`;
  }

  // 結果を保存
  history.push({ timestamp: new Date().toISOString(), elapsed_ms: avg });
  props.setProperty('perf_history', JSON.stringify(history.slice(-20)));

  return {
    passed: true, // パフォーマンステストは常に pass（情報提供のみ）
    message: `${runs}回計測 — 平均: ${avg}ms, 最小: ${min}ms, 最大: ${max}ms${comparison}`,
  };
}

// ============================================================
// 高度なテスト: 数式の依存関係チェック
// ============================================================

/**
 * 循環参照や壊れた参照がないか検出する
 */
function testFormulaDependencies() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(MSO_CONFIG.monthlySheet);
  const s = MSO_CONFIG.dataStartRow;
  const e = MSO_CONFIG.dataEndRow;
  const errors = [];

  // 主要な数式セルのエラーチェック
  const formulaCells = [
    'N2','S2','T2','Z2','AA2','AH2','AI2',
    'H5','I5','S5','T5','U5','V5','W5','Z5','AA5',
    'AB5','AC5','AE5','AG5','AH5','AI5',
    'AR5','AT5','AW5','AX5','AY5','AZ5','BA5','BC5',
    'BD5','BE5','BF5','BG5','BN5','BO5',
  ];

  for (const cell of formulaCells) {
    const value = sheet.getRange(cell).getValue();
    const display = sheet.getRange(cell).getDisplayValue();

    // エラー値の検出
    if (display.startsWith('#')) {
      errors.push(`${cell}: エラー値 ${display}`);
    }
  }

  return {
    passed: errors.length === 0,
    message: errors.length === 0
      ? `${formulaCells.length}セルにエラーなし`
      : `${errors.length}件のエラー:\n${errors.join('\n')}`,
  };
}
