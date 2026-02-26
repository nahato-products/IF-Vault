/**
 * 月別シート最適化 — before/after 検証
 *
 * 最適化の前後でセル値が変わっていないことを自動検証する。
 * 前回の手動作業で before 計測漏れが起きた問題を根本的に防止。
 */

interface CellSnapshot {
  cell: string;
  value: any;
  formula: string;
}

interface MismatchDetail {
  cell: string;
  before: any;
  after: any;
}

interface ValidationResult {
  passed: boolean;
  totalChecked: number;
  mismatches: MismatchDetail[];
}

/**
 * 指定シートのスナップショットを取得
 * - 合計行（S2, T2等）の値
 * - ランダム行のデータセル値
 */
function takeSnapshot(sheet: GoogleAppsScript.Spreadsheet.Sheet): CellSnapshot[] {
  const snapshots: CellSnapshot[] = [];

  // 1. 合計行セルのスナップショット
  for (const cellName of CONFIG.validation.summaryCells) {
    const range = sheet.getRange(cellName);
    snapshots.push({
      cell: cellName,
      value: range.getValue(),
      formula: range.getFormula(),
    });
  }

  // 2. ランダム行の詳細セルスナップショット
  const dataRows = CONFIG.dataEndRow - CONFIG.dataStartRow + 1;
  const randomRows = new Set<number>();

  // 固定で最初・最後・中間の行を含める
  randomRows.add(CONFIG.dataStartRow);
  randomRows.add(CONFIG.dataEndRow);
  randomRows.add(Math.floor((CONFIG.dataStartRow + CONFIG.dataEndRow) / 2));

  // 残りはランダム
  while (randomRows.size < CONFIG.validation.randomRows + 3) {
    const row = CONFIG.dataStartRow + Math.floor(Math.random() * dataRows);
    randomRows.add(row);
  }

  for (const row of randomRows) {
    for (const col of CONFIG.validation.detailCols) {
      const cellName = `${col}${row}`;
      const range = sheet.getRange(cellName);
      snapshots.push({
        cell: cellName,
        value: range.getValue(),
        formula: range.getFormula(),
      });
    }
  }

  return snapshots;
}

/**
 * before/after スナップショットを比較
 * 数値は小数点以下の丸め誤差を考慮（±0.01以内なら一致とみなす）
 */
function compareSnapshots(
  before: CellSnapshot[],
  after: CellSnapshot[]
): ValidationResult {
  const mismatches: MismatchDetail[] = [];
  let totalChecked = 0;

  const afterMap = new Map<string, CellSnapshot>();
  for (const s of after) {
    afterMap.set(s.cell, s);
  }

  for (const b of before) {
    const a = afterMap.get(b.cell);
    if (!a) continue;

    totalChecked++;

    // 空セル同士は一致
    if ((b.value === '' || b.value === null) && (a.value === '' || a.value === null)) {
      continue;
    }

    // 数値比較（丸め誤差考慮）
    if (typeof b.value === 'number' && typeof a.value === 'number') {
      if (Math.abs(b.value - a.value) > 0.01) {
        mismatches.push({ cell: b.cell, before: b.value, after: a.value });
      }
      continue;
    }

    // 文字列・その他の比較
    if (String(b.value) !== String(a.value)) {
      mismatches.push({ cell: b.cell, before: b.value, after: a.value });
    }
  }

  return {
    passed: mismatches.length === 0,
    totalChecked,
    mismatches,
  };
}

/**
 * 全行の特定列を完全検証（Step 5 の源泉徴収用）
 */
function fullColumnValidation(
  sheet: GoogleAppsScript.Spreadsheet.Sheet,
  col: string,
  beforeValues: any[][]
): MismatchDetail[] {
  const startRow = CONFIG.dataStartRow;
  const endRow = CONFIG.dataEndRow;
  const afterValues = sheet.getRange(`${col}${startRow}:${col}${endRow}`).getValues();
  const mismatches: MismatchDetail[] = [];

  for (let i = 0; i < beforeValues.length; i++) {
    const bVal = beforeValues[i][0];
    const aVal = afterValues[i][0];

    if (bVal === '' && aVal === '') continue;

    if (typeof bVal === 'number' && typeof aVal === 'number') {
      if (Math.abs(bVal - aVal) > 0.001) {
        mismatches.push({
          cell: `${col}${startRow + i}`,
          before: bVal,
          after: aVal,
        });
      }
    } else if (String(bVal) !== String(aVal)) {
      mismatches.push({
        cell: `${col}${startRow + i}`,
        before: bVal,
        after: aVal,
      });
    }
  }

  return mismatches;
}
