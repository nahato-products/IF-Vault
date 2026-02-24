/**
 * ============================================================
 * 月別シート関数 パフォーマンス改善 GAS
 * ============================================================
 *
 * 概要:
 *   月別シートの関数パフォーマンスを改善するスクリプト。
 *   バックアップ → スナップショット → 改善適用 → 検証 の流れで
 *   安全に最適化を適用する。
 *
 * 使い方:
 *   1. Google Sheets → 拡張機能 → Apps Script
 *   2. このコードを新規ファイルに貼り付け → 保存
 *   3. シートをリロード → メニュー「⚡ 月別最適化」が表示される
 *   4. まず「🔍 事前チェック」を実行
 *   5. 「📸 スナップショット取得」で現在値を保存
 *   6. Step 1〜6 を順番に実行（各Step後に自動検証）
 *   7. 「✅ 全体検証」で最終確認
 *
 * 注意:
 *   - CONFIG.cvKeyColumn を実際の ◆CV シートのキー列に変更すること
 *   - CONFIG.dryRun = true で変更を適用せずプレビューできる
 *
 * ============================================================
 */

// ============================================================
// 設定
// ============================================================

const CONFIG = {
  // --- シート名 ---
  monthlySheet:   '2026年01月',
  masterSheet:    'マスター原本',
  cacheSheet:     '【自動】マスター参照',
  cvSheet:        '◆CV',
  listSheet:      '◆list',
  snapshotSheet:  '_snapshot',
  summarySheet:   '2026年01月まとめ', // まとめシート（検証で使用）

  // --- データ範囲 ---
  dataStartRow:     5,
  dataEndRow:       169,
  aggregateEndRow:  200,   // 170行目〜末尾（AJ2等の集計範囲）
  totalColumns:     69,    // A〜BQ列

  // --- CV検索設定 ---
  cvKeyColumn:      'A',   // ⚠️ ◆CVシートの実際のキー列に変更すること
  searchKeyColumn:  'BQ',  // CV検索キー用の空き列

  // --- 検証設定 ---
  tolerance:        0.001, // 数値比較の許容誤差
  spotCheckCount:   10,    // ランダム検証する行数

  // --- 実行モード ---
  dryRun:           true,  // true: 変更を適用しない（ログのみ）
};

// ============================================================
// メニュー
// ============================================================

function onOpen() {
  const ui = SpreadsheetApp.getUi();
  ui.createMenu('⚡ 月別最適化')
    .addItem('🔍 事前チェック',            'preflight')
    .addItem('📸 スナップショット取得',     'takeSnapshot')
    .addSeparator()
    .addItem('Step 1: レンジ閉鎖',         'applyStep1')
    .addItem('Step 2: XLOOKUP集約',        'applyStep2')
    .addItem('Step 3: CV検索キー集約',      'applyStep3')
    .addItem('Step 4: LETキャッシュ化',     'applyStep4')
    .addItem('Step 5: 源泉徴収簡約',       'applyStep5')
    .addItem('Step 6: エラーカウント',      'applyStep6')
    .addItem('▶ 全Step一括適用',           'applyAll')
    .addSeparator()
    .addItem('✅ 全体検証',                'validateAll')
    .addItem('⏱ パフォーマンス計測',       'measurePerformance')
    .addItem('🔎 BN5 参照先自動検出',      'detectBN5Column')
    .addSeparator()
    .addItem('↩ ロールバック（最新Step）',  'rollbackLastStep')
    .addItem('🗑 作業用シート削除',         'cleanup')
    .addToUi();
}

// ============================================================
// 数式定義
// ============================================================

function buildFormulas_() {
  const c = CONFIG;
  const s = c.dataStartRow;
  const e = c.dataEndRow;
  const ae = c.aggregateEndRow;

  return {
    step1: {
      name: 'レンジ閉鎖',
      formulas: {
        'S2':  `=SUM(S${s}:S${e})`,
        'T2':  `=SUM(T${s}:T${e})`,
        'Z2':  `=SUM(Z${s}:Z${e})`,
        'AA2': `=SUM(AA${s}:AA${e})`,
        'AH2': `=SUM(AH${s}:AH${e})`,
        'AI2': `=SUM(AI${s}:AI${e})`,
        'AJ2': `=SUM(AJ170:AJ${ae})`,
        'AL2': `=SUM(AL170:AL${ae})`,
        'AN2': `=SUM(AN170:AN${ae})`,
        'AP2': `=SUM(AP170:AP${ae})`,
        'BE2': `=SUM(BE170:BE${ae})`,
        'BF2': `=SUM(BF170:BF${ae})`,
      },
      validateCells: ['S2','T2','Z2','AA2','AH2','AI2','AJ2','AL2','AN2','AP2','BE2','BF2','BO2'],
    },

    step2: {
      name: 'XLOOKUP集約',
      cacheFormula: `=ArrayFormula(IFERROR(XLOOKUP('${c.monthlySheet}'!E${s}:E${e}&'${c.monthlySheet}'!BB${s}:BB${e},'${c.masterSheet}'!B2:B&TEXT('${c.masterSheet}'!R2:R,"0000000"),'${c.masterSheet}'!C2:S2)))`,
      formulas: {
        'H5':  `=ArrayFormula('${c.cacheSheet}'!A${s}:A${e})`,
        'AB5': `=ArrayFormula('${c.cacheSheet}'!G${s}:G${e})`,
        'AC5': `=ArrayFormula('${c.cacheSheet}'!H${s}:H${e})`,
        'AR5': `=ArrayFormula('${c.cacheSheet}'!I${s}:I${e})`,
        'AT5': `=ArrayFormula('${c.cacheSheet}'!J${s}:J${e})`,
        'AW5': `=ArrayFormula('${c.cacheSheet}'!K${s}:K${e})`,
        'AX5': `=ArrayFormula('${c.cacheSheet}'!L${s}:L${e})`,
        'AY5': `=ArrayFormula('${c.cacheSheet}'!M${s}:M${e})`,
        'AZ5': `=ArrayFormula('${c.cacheSheet}'!N${s}:N${e})`,
        'BA5': `=ArrayFormula('${c.cacheSheet}'!O${s}:O${e})`,
        'BC5': `=ArrayFormula('${c.cacheSheet}'!Q${s}:Q${e})`,
        'I5':  [
          `=ArrayFormula(LET(`,
          `g,G${s}:G${e},`,
          `ig,'${c.cacheSheet}'!B${s}:B${e},`,
          `yt,'${c.cacheSheet}'!C${s}:C${e},`,
          `tw,'${c.cacheSheet}'!D${s}:D${e},`,
          `tiktok,'${c.cacheSheet}'!E${s}:E${e},`,
          `other,'${c.cacheSheet}'!F${s}:F${e},`,
          `IFS((g="")+(g=0),ig,g=2,other,`,
          `REGEXMATCH(LOWER(g),"instagram"),ig,`,
          `REGEXMATCH(LOWER(g),"youtube"),yt,`,
          `REGEXMATCH(LOWER(g),"twitter"),tw,`,
          `REGEXMATCH(LOWER(g),"tiktok"),tiktok,`,
          `TRUE,other)))`,
        ].join(''),
      },
      validateColumns: ['H','I','AB','AC','AR','AT','AW','AX','AY','AZ','BA','BC'],
    },

    step3: {
      name: 'CV検索キー集約',
      formulas: {
        [`${c.searchKeyColumn}5`]: [
          `=ArrayFormula(LET(`,
          `ym,TEXT(B2,"YYMM"),`,
          `agent,XLOOKUP(MID(B${s}:B${e},5,10),'${c.listSheet}'!F:F,'${c.listSheet}'!E:E),`,
          `ym&M${s}:M${e}&L${s}:L${e}&agent&F${s}:F${e}))`,
        ].join(''),
        'U5': `=ArrayFormula(IFERROR(XLOOKUP(${c.searchKeyColumn}${s}:${c.searchKeyColumn}${e},'${c.cvSheet}'!${c.cvKeyColumn}:${c.cvKeyColumn},'${c.cvSheet}'!F:F)))`,
        'V5': `=ArrayFormula(IFERROR(XLOOKUP(${c.searchKeyColumn}${s}:${c.searchKeyColumn}${e},'${c.cvSheet}'!${c.cvKeyColumn}:${c.cvKeyColumn},'${c.cvSheet}'!G:G)))`,
        'W5': `=ArrayFormula(LET(cv_h,IFERROR(XLOOKUP(${c.searchKeyColumn}${s}:${c.searchKeyColumn}${e},'${c.cvSheet}'!${c.cvKeyColumn}:${c.cvKeyColumn},'${c.cvSheet}'!H:H)),x,X${s}:X${e},IF(x<>"",x,cv_h)))`,
      },
      validateColumns: ['U','V','W'],
    },

    step4: {
      name: 'LETキャッシュ化',
      formulas: {
        'T5':  `=ArrayFormula(LET(s,S${s}:S${e},r,R${s}:R${e},af,AF${s}:AF${e},bf,BF${s}:BF${e},bg,BG${s}:BG${e},IF(bg="成果",s-(r*af),s-bf)))`,
        'Z5':  `=ArrayFormula(LET(q,Q${s}:Q${e},d,D${s}:D${e},n,N${s}:N${e},x,X${s}:X${e},IF(q=TRUE,IF(d="予算/ボーナス",n,n*x),0)))`,
        'AA5': `=ArrayFormula(LET(q,Q${s}:Q${e},z,Z${s}:Z${e},bf,BF${s}:BF${e},IF(q=TRUE,z-bf,z)))`,
      },
      validateColumns: ['T','Z','AA'],
      validateCells: ['T2','Z2','AA2'],
    },

    step5: {
      name: '源泉徴収簡約',
      formulas: {
        'AE5': `=ArrayFormula(ROUNDUP(AD${s}:AD${e}*1.08/1.1))`,
        'AG5': `=ArrayFormula(ROUNDUP(AF${s}:AF${e}*1.08/1.1))`,
      },
      validateColumns: ['AE','AG'],
      // Step 5 は全行一致が必須。1件でも不一致なら即ロールバック
      strictValidation: true,
    },

    step6: {
      name: 'エラーカウント',
      formulas: {
        'N2': `=SUMPRODUCT(ISERROR(B3:BD3)*1)+SUMPRODUCT(ISERROR(B${s}:BD${e})*1)`,
      },
      validateCells: ['N2'],
    },
  };
}

// ============================================================
// 事前チェック
// ============================================================

function preflight() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const ui = SpreadsheetApp.getUi();
  const issues = [];

  // 必要なシートの存在確認
  const requiredSheets = [
    CONFIG.monthlySheet,
    CONFIG.masterSheet,
    CONFIG.cvSheet,
    CONFIG.listSheet,
  ];
  for (const name of requiredSheets) {
    if (!ss.getSheetByName(name)) {
      issues.push(`❌ シート「${name}」が見つかりません`);
    }
  }

  // 月別シートの構造チェック
  const monthly = ss.getSheetByName(CONFIG.monthlySheet);
  if (monthly) {
    const lastRow = monthly.getLastRow();
    if (lastRow < CONFIG.dataEndRow) {
      issues.push(`⚠️ データ行が想定より少ない（最終行: ${lastRow}、想定: ${CONFIG.dataEndRow}）`);
    }

    // ArrayFormula セルの存在確認
    const checkCells = ['H5','S5','T5','U5','AB5','AE5','N2'];
    for (const addr of checkCells) {
      const formula = monthly.getRange(addr).getFormula();
      if (!formula) {
        issues.push(`⚠️ ${addr} に数式がありません`);
      }
    }

    // BQ列（検索キー用）が空いているか
    const bqValues = monthly.getRange(`${CONFIG.searchKeyColumn}${CONFIG.dataStartRow}:${CONFIG.searchKeyColumn}${CONFIG.dataEndRow}`).getValues();
    const hasData = bqValues.some(row => row[0] !== '');
    if (hasData) {
      issues.push(`⚠️ ${CONFIG.searchKeyColumn}列にデータがあります（CV検索キー用に使う予定）`);
    }
  }

  // 【自動】マスター参照 シートの重複チェック
  if (ss.getSheetByName(CONFIG.cacheSheet)) {
    issues.push(`⚠️ シート「${CONFIG.cacheSheet}」が既に存在します（Step 2 で上書きされます）`);
  }

  // 結果表示
  if (issues.length === 0) {
    ui.alert('事前チェック結果', '✅ すべてのチェックをパスしました。\n\n次に「📸 スナップショット取得」を実行してください。', ui.ButtonSet.OK);
  } else {
    ui.alert('事前チェック結果', '以下の問題が検出されました:\n\n' + issues.join('\n'), ui.ButtonSet.OK);
  }

  return issues;
}

// ============================================================
// バックアップ & スナップショット
// ============================================================

/**
 * スナップショットを取得（現在値を _snapshot シートに保存）
 * 改善適用前に必ず実行すること。
 */
function takeSnapshot() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const monthly = ss.getSheetByName(CONFIG.monthlySheet);
  if (!monthly) throw new Error(`シート「${CONFIG.monthlySheet}」が見つかりません`);

  // 既存の _snapshot を削除
  const existing = ss.getSheetByName(CONFIG.snapshotSheet);
  if (existing) ss.deleteSheet(existing);

  // 月別シートの全値をコピー（数式ではなく値として）
  const snapshot = ss.insertSheet(CONFIG.snapshotSheet);

  // Row 2（集計行）
  const row2Range = monthly.getRange('A2:BQ2');
  snapshot.getRange('A2:BQ2').setValues(row2Range.getValues());

  // Row 3（ヘッダ行 — N2 の ISERROR 対象）
  const row3Range = monthly.getRange('A3:BD3');
  snapshot.getRange('A3:BD3').setValues(row3Range.getValues());

  // Rows 5-169（データ行）
  const s = CONFIG.dataStartRow;
  const e = CONFIG.dataEndRow;
  const dataRange = monthly.getRange(`A${s}:BQ${e}`);
  snapshot.getRange(`A${s}:BQ${e}`).setValues(dataRange.getValues());

  // Rows 170-200（集計セクション）
  const aggRange = monthly.getRange('A170:BQ' + CONFIG.aggregateEndRow);
  snapshot.getRange('A170:BQ' + CONFIG.aggregateEndRow).setValues(aggRange.getValues());

  // 非表示にする
  snapshot.hideSheet();

  // タイムスタンプを記録
  PropertiesService.getScriptProperties().setProperty(
    'snapshot_time',
    new Date().toISOString()
  );

  SpreadsheetApp.getUi().alert(
    'スナップショット完了',
    `✅ 月別シートの現在値を保存しました。\n\nタイムスタンプ: ${new Date().toLocaleString('ja-JP')}\n\n次に Step 1 から適用を開始してください。`,
    SpreadsheetApp.getUi().ButtonSet.OK
  );
}

// ============================================================
// 汎用 適用エンジン
// ============================================================

/**
 * 指定された数式群をシートに適用する汎用関数。
 * ロールバック用に旧数式を保存し、適用後に自動検証を行う。
 *
 * @param {string} stepKey - ステップ識別子（例: 'step1'）
 * @param {Object} stepDef - buildFormulas_() で定義されたステップ定義
 * @param {Function} [preAction] - 数式適用前に実行するフック（例: 【自動】マスター参照 シート作成）
 * @return {boolean} 成功なら true
 */
function applyStep_(stepKey, stepDef, preAction) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(CONFIG.monthlySheet);
  const ui = SpreadsheetApp.getUi();
  const props = PropertiesService.getScriptProperties();

  // スナップショット存在確認
  if (!ss.getSheetByName(CONFIG.snapshotSheet)) {
    ui.alert('エラー', '❌ スナップショットが見つかりません。\n先に「📸 スナップショット取得」を実行してください。', ui.ButtonSet.OK);
    return false;
  }

  // ドライラン確認
  if (CONFIG.dryRun) {
    const preview = Object.entries(stepDef.formulas)
      .map(([cell, formula]) => {
        const current = sheet.getRange(cell).getFormula() || '(値のみ)';
        const shortened = String(formula).substring(0, 80);
        return `${cell}:\n  現在: ${current.substring(0, 80)}\n  変更: ${shortened}...`;
      })
      .join('\n\n');
    ui.alert(
      `[DRY RUN] ${stepDef.name}`,
      `以下の変更をプレビューします（実際には適用されません）:\n\n${preview}\n\n※ CONFIG.dryRun = false に変更して再実行すると適用されます。`,
      ui.ButtonSet.OK
    );
    return true;
  }

  // 旧数式をバックアップ
  const oldFormulas = {};
  for (const cell of Object.keys(stepDef.formulas)) {
    oldFormulas[cell] = sheet.getRange(cell).getFormula();
  }
  props.setProperty(`backup_${stepKey}`, JSON.stringify(oldFormulas));

  // フック実行（Step 2 の 【自動】マスター参照 作成など）
  if (preAction) preAction(ss);

  // 数式適用
  for (const [cell, formula] of Object.entries(stepDef.formulas)) {
    sheet.getRange(cell).setFormula(formula);
  }

  // 再計算を強制
  SpreadsheetApp.flush();
  Utilities.sleep(3000); // ArrayFormula の展開を待つ

  // ロールバック順序を記録
  const rollbackStack = JSON.parse(props.getProperty('rollback_stack') || '[]');
  rollbackStack.push(stepKey);
  props.setProperty('rollback_stack', JSON.stringify(rollbackStack));

  // 自動検証
  const result = validateStep_(stepKey, stepDef);

  if (result.success) {
    ui.alert(
      `${stepDef.name} — 完了`,
      `✅ ${stepDef.name}を適用し、検証に成功しました。\n\n変更セル数: ${Object.keys(stepDef.formulas).length}\n不一致: 0`,
      ui.ButtonSet.OK
    );
    return true;
  } else {
    // 検証失敗 → 自動ロールバック（Step 5 の strict モード含む）
    const doRollback = ui.alert(
      `${stepDef.name} — 検証失敗`,
      `❌ ${result.mismatches.length}件の不一致が検出されました。\n\n` +
      result.mismatches.slice(0, 10).map(m =>
        `${m.cell}: 期待=${m.expected}, 実際=${m.actual}`
      ).join('\n') +
      (result.mismatches.length > 10 ? `\n...他${result.mismatches.length - 10}件` : '') +
      `\n\nロールバックしますか？`,
      ui.ButtonSet.YES_NO
    );

    if (doRollback === ui.Button.YES) {
      rollbackStep_(stepKey);
      ui.alert('ロールバック完了', `↩ ${stepDef.name}をロールバックしました。`, ui.ButtonSet.OK);
    }
    return false;
  }
}

// ============================================================
// 検証エンジン
// ============================================================

/**
 * ステップ適用後の値を _snapshot と比較する
 */
function validateStep_(stepKey, stepDef) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(CONFIG.monthlySheet);
  const snapshot = ss.getSheetByName(CONFIG.snapshotSheet);
  const mismatches = [];

  // 1. 個別セルの検証（Row 2 集計セル等）
  if (stepDef.validateCells) {
    for (const cell of stepDef.validateCells) {
      const expected = snapshot.getRange(cell).getValue();
      const actual = sheet.getRange(cell).getValue();
      if (!valuesMatch_(expected, actual)) {
        mismatches.push({ cell, expected, actual });
      }
    }
  }

  // 2. 列全体の検証（ArrayFormula のデータ行）
  if (stepDef.validateColumns) {
    const s = CONFIG.dataStartRow;
    const e = CONFIG.dataEndRow;
    for (const col of stepDef.validateColumns) {
      const expectedVals = snapshot.getRange(`${col}${s}:${col}${e}`).getValues();
      const actualVals = sheet.getRange(`${col}${s}:${col}${e}`).getValues();
      for (let i = 0; i < expectedVals.length; i++) {
        if (!valuesMatch_(expectedVals[i][0], actualVals[i][0])) {
          mismatches.push({
            cell: `${col}${s + i}`,
            expected: expectedVals[i][0],
            actual: actualVals[i][0],
          });
          // strict モード（Step 5）: 1件でも不一致なら即終了
          if (stepDef.strictValidation) {
            return { success: false, mismatches };
          }
        }
      }
    }
  }

  return {
    success: mismatches.length === 0,
    mismatches,
  };
}

/**
 * 2つの値が一致するか判定（数値は許容誤差付き）
 */
function valuesMatch_(a, b) {
  // 両方空
  if ((a === '' || a == null) && (b === '' || b == null)) return true;
  // 両方数値
  if (typeof a === 'number' && typeof b === 'number') {
    if (a === 0 && b === 0) return true;
    return Math.abs(a - b) <= CONFIG.tolerance;
  }
  // 日付
  if (a instanceof Date && b instanceof Date) {
    return a.getTime() === b.getTime();
  }
  // エラー値（#N/A 等）はどちらも文字列化して比較
  return String(a) === String(b);
}

// ============================================================
// ロールバック
// ============================================================

/**
 * 指定ステップの数式をバックアップから復元する
 */
function rollbackStep_(stepKey) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(CONFIG.monthlySheet);
  const props = PropertiesService.getScriptProperties();

  const backupJson = props.getProperty(`backup_${stepKey}`);
  if (!backupJson) throw new Error(`ステップ ${stepKey} のバックアップが見つかりません`);

  const oldFormulas = JSON.parse(backupJson);
  for (const [cell, formula] of Object.entries(oldFormulas)) {
    if (formula) {
      sheet.getRange(cell).setFormula(formula);
    } else {
      sheet.getRange(cell).clearContent();
    }
  }

  // Step 2 の場合は 【自動】マスター参照 シートも削除
  if (stepKey === 'step2') {
    const cache = ss.getSheetByName(CONFIG.cacheSheet);
    if (cache) ss.deleteSheet(cache);
  }

  // Step 3 の場合は BQ 列もクリア
  if (stepKey === 'step3') {
    const bqAddr = `${CONFIG.searchKeyColumn}5`;
    if (!oldFormulas[bqAddr]) {
      sheet.getRange(`${CONFIG.searchKeyColumn}${CONFIG.dataStartRow}:${CONFIG.searchKeyColumn}${CONFIG.dataEndRow}`).clearContent();
    }
  }

  SpreadsheetApp.flush();

  // ロールバックスタックから除去
  const stack = JSON.parse(props.getProperty('rollback_stack') || '[]');
  const idx = stack.indexOf(stepKey);
  if (idx !== -1) stack.splice(idx, 1);
  props.setProperty('rollback_stack', JSON.stringify(stack));
}

/**
 * 最後に適用したステップをロールバック
 */
function rollbackLastStep() {
  const ui = SpreadsheetApp.getUi();
  const props = PropertiesService.getScriptProperties();
  const stack = JSON.parse(props.getProperty('rollback_stack') || '[]');

  if (stack.length === 0) {
    ui.alert('ロールバック', 'ロールバック対象のステップがありません。', ui.ButtonSet.OK);
    return;
  }

  const lastStep = stack[stack.length - 1];
  const confirm = ui.alert(
    'ロールバック確認',
    `最後に適用した「${lastStep}」をロールバックしますか？`,
    ui.ButtonSet.YES_NO
  );

  if (confirm === ui.Button.YES) {
    rollbackStep_(lastStep);
    ui.alert('完了', `↩ ${lastStep} をロールバックしました。`, ui.ButtonSet.OK);
  }
}

// ============================================================
// Step 1〜6 個別関数
// ============================================================

function applyStep1() {
  const defs = buildFormulas_();
  applyStep_('step1', defs.step1);
}

function applyStep2() {
  const defs = buildFormulas_();
  applyStep_('step2', defs.step2, function createCacheSheet(ss) {
    // 既存の 【自動】マスター参照 を削除
    const existing = ss.getSheetByName(CONFIG.cacheSheet);
    if (existing) ss.deleteSheet(existing);

    // 【自動】マスター参照 シート作成
    const cache = ss.insertSheet(CONFIG.cacheSheet);
    cache.getRange('A5').setFormula(defs.step2.cacheFormula);

    // 再計算を待つ（XLOOKUP の展開に時間がかかる）
    SpreadsheetApp.flush();
    Utilities.sleep(5000);

    // 非表示 + 保護
    cache.hideSheet();
    const protection = cache.protect().setDescription('自動生成: XLOOKUP キャッシュ');
    protection.setWarningOnly(true);
  });
}

function applyStep3() {
  const defs = buildFormulas_();
  applyStep_('step3', defs.step3);
}

function applyStep4() {
  const defs = buildFormulas_();
  applyStep_('step4', defs.step4);
}

function applyStep5() {
  const defs = buildFormulas_();
  applyStep_('step5', defs.step5);
}

function applyStep6() {
  const defs = buildFormulas_();
  applyStep_('step6', defs.step6);
}

/**
 * 全ステップを一括適用（Step 1 → 6 の順）
 * 途中で検証に失敗したら停止する
 */
function applyAll() {
  const ui = SpreadsheetApp.getUi();
  const confirm = ui.alert(
    '全Step一括適用',
    'Step 1〜6 を順番に適用します。\n各Stepの後に自動検証を行い、失敗時はそのStepをロールバックして停止します。\n\n続行しますか？',
    ui.ButtonSet.YES_NO
  );
  if (confirm !== ui.Button.YES) return;

  const steps = [
    { fn: applyStep1, name: 'Step 1' },
    { fn: applyStep2, name: 'Step 2' },
    { fn: applyStep3, name: 'Step 3' },
    { fn: applyStep4, name: 'Step 4' },
    { fn: applyStep5, name: 'Step 5' },
    { fn: applyStep6, name: 'Step 6' },
  ];

  for (const step of steps) {
    const success = step.fn();
    if (!success && !CONFIG.dryRun) {
      ui.alert('一括適用 中断', `${step.name} で検証に失敗したため停止しました。`, ui.ButtonSet.OK);
      return;
    }
  }

  ui.alert('一括適用 完了', '✅ 全ステップの適用と検証が完了しました。\n\n「✅ 全体検証」で最終確認を行ってください。', ui.ButtonSet.OK);
}

// ============================================================
// 全体検証
// ============================================================

/**
 * 全セルの値を _snapshot と照合する最終検証
 */
function validateAll() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(CONFIG.monthlySheet);
  const snapshot = ss.getSheetByName(CONFIG.snapshotSheet);
  const ui = SpreadsheetApp.getUi();

  if (!snapshot) {
    ui.alert('エラー', '❌ スナップショットが見つかりません。', ui.ButtonSet.OK);
    return;
  }

  const s = CONFIG.dataStartRow;
  const e = CONFIG.dataEndRow;
  const mismatches = [];

  // 1. Row 2 全集計セル
  const row2Cells = ['N2','S2','T2','Z2','AA2','AH2','AI2','AJ2','AL2','AN2','AP2','BE2','BF2','BO2'];
  for (const cell of row2Cells) {
    const expected = snapshot.getRange(cell).getValue();
    const actual = sheet.getRange(cell).getValue();
    if (!valuesMatch_(expected, actual)) {
      mismatches.push({ cell, expected, actual });
    }
  }

  // 2. 全数式列（ランダム行抽出 + 全行チェック対象列）
  const allColumns = ['H','I','S','T','U','V','W','Z','AA','AB','AC','AE','AG','AH','AI','AR','AT','AW','AX','AY','AZ','BA','BC','BE','BF','BG','BN','BO'];
  for (const col of allColumns) {
    const expectedVals = snapshot.getRange(`${col}${s}:${col}${e}`).getValues();
    const actualVals = sheet.getRange(`${col}${s}:${col}${e}`).getValues();
    for (let i = 0; i < expectedVals.length; i++) {
      if (!valuesMatch_(expectedVals[i][0], actualVals[i][0])) {
        mismatches.push({
          cell: `${col}${s + i}`,
          expected: expectedVals[i][0],
          actual: actualVals[i][0],
        });
      }
    }
  }

  // 3. 結果レポート
  if (mismatches.length === 0) {
    ui.alert(
      '全体検証 結果',
      `✅ 全 ${row2Cells.length + allColumns.length * (e - s + 1)} セルの検証に成功しました。\n\n計算結果は改善前と完全に一致しています。`,
      ui.ButtonSet.OK
    );
  } else {
    const report = mismatches.slice(0, 20).map(m =>
      `${m.cell}: 期待=${m.expected}, 実際=${m.actual}`
    ).join('\n');

    ui.alert(
      '全体検証 結果',
      `❌ ${mismatches.length}件の不一致が検出されました。\n\n${report}` +
      (mismatches.length > 20 ? `\n...他${mismatches.length - 20}件` : ''),
      ui.ButtonSet.OK
    );
  }

  return mismatches;
}

// ============================================================
// パフォーマンス計測
// ============================================================

/**
 * シートの再計算時間を計測する。
 * 改善前/後で比較するために使用。
 */
function measurePerformance() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(CONFIG.monthlySheet);
  const ui = SpreadsheetApp.getUi();

  // 再計算を強制するため、ダミーの値変更 → 元に戻す
  const dummyCell = sheet.getRange('A1');
  const originalValue = dummyCell.getValue();

  const startTime = Date.now();

  // 再計算トリガー: セルを変更して flush
  dummyCell.setValue('__perf_test__');
  SpreadsheetApp.flush();
  dummyCell.setValue(originalValue);
  SpreadsheetApp.flush();

  const elapsed = Date.now() - startTime;

  // 結果を Script Properties に記録
  const props = PropertiesService.getScriptProperties();
  const history = JSON.parse(props.getProperty('perf_history') || '[]');
  history.push({
    timestamp: new Date().toISOString(),
    elapsed_ms: elapsed,
  });
  props.setProperty('perf_history', JSON.stringify(history.slice(-10)));

  // 直近の比較
  let comparison = '';
  if (history.length >= 2) {
    const prev = history[history.length - 2].elapsed_ms;
    const diff = elapsed - prev;
    const pct = ((diff / prev) * 100).toFixed(1);
    comparison = `\n\n前回: ${prev}ms → 今回: ${elapsed}ms（${diff > 0 ? '+' : ''}${pct}%）`;
  }

  ui.alert(
    'パフォーマンス計測',
    `⏱ 再計算時間: ${elapsed}ms${comparison}\n\n※ ネットワーク状況やサーバー負荷により変動します。\n※ 複数回計測して平均を取ることを推奨します。`,
    ui.ButtonSet.OK
  );

  return elapsed;
}

// ============================================================
// BN5 参照先自動検出
// ============================================================

/**
 * BN5 の XLOOKUP 数式を解析し、マスター原本のどの列を参照しているか特定する。
 * → 【自動】マスター参照 のどの列に対応するかを表示する。
 */
function detectBN5Column() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(CONFIG.monthlySheet);
  const ui = SpreadsheetApp.getUi();

  const formula = sheet.getRange('BN5').getFormula();
  if (!formula) {
    ui.alert('BN5 検出', '❌ BN5 に数式がありません。', ui.ButtonSet.OK);
    return;
  }

  // マスター原本の列参照を抽出（例: マスター原本!T:T, マスター原本!T2:T）
  const patterns = [
    /マスター原本[!']*!([A-Z]+):/,
    /マスター原本[!']*!([A-Z]+)\d/,
  ];

  let masterCol = null;
  for (const pattern of patterns) {
    const match = formula.match(pattern);
    if (match) {
      masterCol = match[1];
      break;
    }
  }

  if (!masterCol) {
    ui.alert('BN5 検出', `⚠️ マスター原本の列を特定できませんでした。\n\n数式: ${formula}`, ui.ButtonSet.OK);
    return;
  }

  // C列を起点として 【自動】マスター参照 列を計算
  const masterOffset = colToIndex_(masterCol) - colToIndex_('C');
  const cacheCol = indexToCol_(masterOffset);

  const cacheMapping = `BN5 → マスター原本!${masterCol}列 → 【自動】マスター参照!${cacheCol}列`;
  const referenceFormula = `=ArrayFormula('${CONFIG.cacheSheet}'!${cacheCol}${CONFIG.dataStartRow}:${cacheCol}${CONFIG.dataEndRow})`;

  ui.alert(
    'BN5 検出結果',
    `✅ BN5 の参照先を特定しました。\n\n${cacheMapping}\n\n【自動】マスター参照 参照式:\n${referenceFormula}\n\n※ この式を BN5 に設定すると 【自動】マスター参照 経由の参照に切り替わります。`,
    ui.ButtonSet.OK
  );

  return { masterCol, cacheCol, referenceFormula };
}

// ============================================================
// まとめシート検証（追加提案）
// ============================================================

/**
 * 「2026年02月まとめ」シートの値が月別シートと整合しているか検証する。
 * まとめシートの実売上・実利鞘等が月別シートの合計値と一致するかチェック。
 */
function validateSummarySheet() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const monthly = ss.getSheetByName(CONFIG.monthlySheet);
  const summary = ss.getSheetByName(CONFIG.summarySheet);
  const ui = SpreadsheetApp.getUi();

  if (!summary) {
    ui.alert('まとめシート検証', `シート「${CONFIG.summarySheet}」が見つかりません。`, ui.ButtonSet.OK);
    return;
  }

  // まとめシートが月別シートを参照している場合、
  // 月別シートの改善後もまとめシートの値が変わっていないことを確認する。
  // D2:R70 の全セルの値を記録して比較

  const range = summary.getRange('D2:R70');
  const values = range.getValues();

  // スナップショットに保存済みのまとめシート値と比較
  const props = PropertiesService.getScriptProperties();
  const savedJson = props.getProperty('summary_snapshot');

  if (!savedJson) {
    // 初回: スナップショットを保存
    props.setProperty('summary_snapshot', JSON.stringify(values));
    ui.alert(
      'まとめシート検証',
      '📸 まとめシートのスナップショットを保存しました。\n改善適用後にもう一度実行すると、値の比較ができます。',
      ui.ButtonSet.OK
    );
    return;
  }

  // 比較
  const saved = JSON.parse(savedJson);
  const mismatches = [];
  for (let r = 0; r < values.length; r++) {
    for (let c = 0; c < values[r].length; c++) {
      if (!valuesMatch_(saved[r][c], values[r][c])) {
        const cellAddr = `${indexToCol_(c + 3)}${r + 2}`; // D列 = index 3
        mismatches.push({
          cell: cellAddr,
          expected: saved[r][c],
          actual: values[r][c],
        });
      }
    }
  }

  if (mismatches.length === 0) {
    ui.alert('まとめシート検証', '✅ まとめシートの全セルが改善前と一致しています。', ui.ButtonSet.OK);
  } else {
    const report = mismatches.slice(0, 10).map(m =>
      `${m.cell}: 期待=${m.expected}, 実際=${m.actual}`
    ).join('\n');
    ui.alert('まとめシート検証', `❌ ${mismatches.length}件の不一致:\n\n${report}`, ui.ButtonSet.OK);
  }
}

// ============================================================
// クリーンアップ
// ============================================================

function cleanup() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const ui = SpreadsheetApp.getUi();

  const confirm = ui.alert(
    'クリーンアップ',
    '以下のシートを削除します:\n- _snapshot\n- _log\n\n※ 【自動】マスター参照 は残ります（本番で使用中）\n※ Script Properties のバックアップも削除されます\n\n続行しますか？',
    ui.ButtonSet.YES_NO
  );
  if (confirm !== ui.Button.YES) return;

  // シート削除
  for (const name of [CONFIG.snapshotSheet]) {
    const s = ss.getSheetByName(name);
    if (s) ss.deleteSheet(s);
  }

  // Script Properties クリア
  const props = PropertiesService.getScriptProperties();
  const keys = props.getKeys().filter(k =>
    k.startsWith('backup_') || k.startsWith('rollback_') || k === 'snapshot_time' || k === 'summary_snapshot'
  );
  keys.forEach(k => props.deleteProperty(k));

  ui.alert('完了', '🗑 作業用データを削除しました。', ui.ButtonSet.OK);
}

// ============================================================
// ユーティリティ
// ============================================================

/**
 * 列文字 → 0-based インデックス（A=0, B=1, ..., AA=26）
 */
function colToIndex_(col) {
  let index = 0;
  for (let i = 0; i < col.length; i++) {
    index = index * 26 + (col.charCodeAt(i) - 64);
  }
  return index - 1;
}

/**
 * 0-based インデックス → 列文字
 */
function indexToCol_(index) {
  let col = '';
  let n = index + 1;
  while (n > 0) {
    n--;
    col = String.fromCharCode(65 + (n % 26)) + col;
    n = Math.floor(n / 26);
  }
  return col;
}
