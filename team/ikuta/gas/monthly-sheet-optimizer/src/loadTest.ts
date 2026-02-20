/**
 * 月別シート最適化 — 負荷テスト
 *
 * ランダムなセル書き込み → flush() → 再計算時間計測
 * 前回の runLoadTest() を TypeScript 化＋改良。
 */

interface LoadTestRound {
  round: number;
  durationMs: number;
  rows: number[];
}

interface LoadTestResult {
  sheetName: string;
  rounds: LoadTestRound[];
  stats: {
    avgMs: number;
    medianMs: number;
    minMs: number;
    maxMs: number;
    stddevMs: number;
  };
  timestamp: string;
  cellsRestored: number;
}

function runLoadTest(sheetNameOverride?: string): LoadTestResult {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheetName = sheetNameOverride || CONFIG.targetSheetName;
  const sheet = ss.getSheetByName(sheetName);

  if (!sheet) {
    throw new Error(`シート "${sheetName}" が見つかりません`);
  }

  const cfg = CONFIG.loadTest;
  const startRow = CONFIG.dataStartRow;
  const endRow = CONFIG.dataEndRow;
  const writeColNum = _colToNum(cfg.writeColumn);

  Logger.log(`=== 負荷テスト開始: ${sheetName} ===`);
  Logger.log(`設定: ${cfg.rounds}ラウンド, 各${cfg.writesPerRound}書込, 列${cfg.writeColumn}`);

  // バックアップ（復元用）
  const backups: { row: number; value: any }[] = [];
  const rounds: LoadTestRound[] = [];

  for (let r = 1; r <= cfg.rounds; r++) {
    const writeRows: number[] = [];
    const roundBackups: { row: number; value: any }[] = [];

    // ランダム行に書き込み
    for (let w = 0; w < cfg.writesPerRound; w++) {
      const row = startRow + Math.floor(Math.random() * (endRow - startRow + 1));
      const cell = sheet.getRange(row, writeColNum);

      // 現在値をバックアップ
      roundBackups.push({ row, value: cell.getValue() });

      // ランダム値を書き込み
      cell.setValue(`TEST_${Date.now()}_${w}`);
      writeRows.push(row);
    }

    // flush() で再計算 → 時間計測
    const t0 = Date.now();
    SpreadsheetApp.flush();
    const elapsed = Date.now() - t0;

    rounds.push({
      round: r,
      durationMs: elapsed,
      rows: writeRows,
    });

    Logger.log(`  Round ${r}/${cfg.rounds}: ${elapsed}ms (行: ${writeRows.join(',')})`);

    // 元の値に復元
    if (cfg.restoreValues) {
      for (const b of roundBackups) {
        sheet.getRange(b.row, writeColNum).setValue(b.value);
        backups.push(b);
      }
      SpreadsheetApp.flush();
    }

    // クールダウン
    if (r < cfg.rounds) {
      Utilities.sleep(cfg.coolDownMs);
    }
  }

  // 統計計算
  const times = rounds.map(r => r.durationMs);
  const sorted = [...times].sort((a, b) => a - b);
  const avg = times.reduce((a, b) => a + b, 0) / times.length;
  const median = sorted[Math.floor(sorted.length / 2)];
  const min = sorted[0];
  const max = sorted[sorted.length - 1];
  const variance = times.reduce((acc, t) => acc + Math.pow(t - avg, 2), 0) / times.length;
  const stddev = Math.sqrt(variance);

  const result: LoadTestResult = {
    sheetName,
    rounds,
    stats: {
      avgMs: Math.round(avg),
      medianMs: median,
      minMs: min,
      maxMs: max,
      stddevMs: Math.round(stddev),
    },
    timestamp: new Date().toISOString(),
    cellsRestored: cfg.restoreValues ? backups.length : 0,
  };

  Logger.log(`--- 統計 ---`);
  Logger.log(`  平均: ${result.stats.avgMs}ms`);
  Logger.log(`  中央値: ${result.stats.medianMs}ms`);
  Logger.log(`  最小: ${result.stats.minMs}ms`);
  Logger.log(`  最大: ${result.stats.maxMs}ms`);
  Logger.log(`  標準偏差: ${result.stats.stddevMs}ms`);
  Logger.log(`  復元セル: ${result.cellsRestored}`);
  Logger.log(`=== 負荷テスト完了 ===`);

  return result;
}

/**
 * before/after の負荷テスト結果を比較レポートとして出力
 */
function compareLoadTests(
  before: LoadTestResult,
  after: LoadTestResult
): string {
  const pctChange = (b: number, a: number) => {
    if (b === 0) return 'N/A';
    const pct = ((a - b) / b * 100).toFixed(1);
    return `${Number(pct) < 0 ? '' : '+'}${pct}%`;
  };

  const lines = [
    `=== Before/After 比較レポート ===`,
    ``,
    `Before: ${before.sheetName} (${before.timestamp})`,
    `After:  ${after.sheetName} (${after.timestamp})`,
    ``,
    `| 指標 | Before | After | 改善率 |`,
    `|------|--------|-------|--------|`,
    `| 平均 | ${before.stats.avgMs}ms | ${after.stats.avgMs}ms | ${pctChange(before.stats.avgMs, after.stats.avgMs)} |`,
    `| 中央値 | ${before.stats.medianMs}ms | ${after.stats.medianMs}ms | ${pctChange(before.stats.medianMs, after.stats.medianMs)} |`,
    `| 最小 | ${before.stats.minMs}ms | ${after.stats.minMs}ms | ${pctChange(before.stats.minMs, after.stats.minMs)} |`,
    `| 最大 | ${before.stats.maxMs}ms | ${after.stats.maxMs}ms | ${pctChange(before.stats.maxMs, after.stats.maxMs)} |`,
    `| 標準偏差 | ${before.stats.stddevMs}ms | ${after.stats.stddevMs}ms | — |`,
  ];

  return lines.join('\n');
}
