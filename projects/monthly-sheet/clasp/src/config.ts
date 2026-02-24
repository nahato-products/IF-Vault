/**
 * 月別シート最適化 — 設定ファイル
 *
 * このファイルを変更するだけで、対象シート・行範囲・マッピングを
 * 全Stepに一括反映できる。
 */

// ═══════════════════════════════════════════════
// 1. 基本設定
// ═══════════════════════════════════════════════

/** 対象シート名（毎月変更） */
const TARGET_SHEET_NAME = '2026年02月';

/** データ行の範囲 */
const DATA_START_ROW = 5;
const DATA_END_ROW = 169;

/** サブセクション（170行目以降の集計エリア） */
const SUB_SECTION_START = 170;
const SUB_SECTION_END = 200;

/** マスター原本シート名 */
const MASTER_SHEET_NAME = 'マスター原本';

/** キャッシュシート名（Step 2で作成） */
const CACHE_SHEET_NAME = '【自動】マスター参照';

// ═══════════════════════════════════════════════
// 2. Step 1: オープンレンジ閉鎖
// ═══════════════════════════════════════════════

interface SumCellConfig {
  cell: string;
  startRow: number;
  endRow: number;
}

/** SUM関数を閉鎖する対象セル */
const SUM_CELLS_DATA_RANGE: SumCellConfig[] = [
  { cell: 'S2',  startRow: DATA_START_ROW, endRow: DATA_END_ROW },
  { cell: 'T2',  startRow: DATA_START_ROW, endRow: DATA_END_ROW },
  { cell: 'Z2',  startRow: DATA_START_ROW, endRow: DATA_END_ROW },
  { cell: 'AA2', startRow: DATA_START_ROW, endRow: DATA_END_ROW },
  { cell: 'AH2', startRow: DATA_START_ROW, endRow: DATA_END_ROW },
  { cell: 'AI2', startRow: DATA_START_ROW, endRow: DATA_END_ROW },
];

const SUM_CELLS_SUB_RANGE: SumCellConfig[] = [
  { cell: 'AJ2', startRow: SUB_SECTION_START, endRow: SUB_SECTION_END },
  { cell: 'AL2', startRow: SUB_SECTION_START, endRow: SUB_SECTION_END },
  { cell: 'AN2', startRow: SUB_SECTION_START, endRow: SUB_SECTION_END },
  { cell: 'AP2', startRow: SUB_SECTION_START, endRow: SUB_SECTION_END },
  { cell: 'BE2', startRow: SUB_SECTION_START, endRow: SUB_SECTION_END },
  { cell: 'BF2', startRow: SUB_SECTION_START, endRow: SUB_SECTION_END },
];

/** 変更不要（既に閉鎖済み） */
const SUM_CELLS_CLOSED: string[] = ['BO2'];

// ═══════════════════════════════════════════════
// 3. Step 2: XLOOKUP集約マッピング
// ═══════════════════════════════════════════════

interface XlookupMapping {
  /** 【自動】マスター参照 シート上の列（A, B, C...） */
  cacheCol: string;
  /** 月別シート上のセル（H5, AB5...） */
  targetCell: string;
  /** マスター原本の列（C, I, J...） */
  masterCol: string;
  /** 用途メモ */
  description: string;
}

const XLOOKUP_MAPPINGS: XlookupMapping[] = [
  { cacheCol: 'A', targetCell: 'H5',  masterCol: 'C', description: 'IF名称' },
  // B〜F列は I5 のSNS分岐で使用（特殊処理）
  { cacheCol: 'G', targetCell: 'AB5', masterCol: 'I', description: '支払区分' },
  { cacheCol: 'H', targetCell: 'AC5', masterCol: 'J', description: '支払関連' },
  { cacheCol: 'I', targetCell: 'AR5', masterCol: 'K', description: '要確認' },
  { cacheCol: 'J', targetCell: 'AT5', masterCol: 'L', description: '要確認' },
  { cacheCol: 'K', targetCell: 'AW5', masterCol: 'M', description: '要確認' },
  { cacheCol: 'L', targetCell: 'AX5', masterCol: 'N', description: '要確認' },
  { cacheCol: 'M', targetCell: 'AY5', masterCol: 'O', description: '金融機関名' },
  { cacheCol: 'N', targetCell: 'AZ5', masterCol: 'P', description: '支店名' },
  { cacheCol: 'O', targetCell: 'BA5', masterCol: 'Q', description: '口座種別' },
  // P列 = R列（検索キー用、直接参照なし）
  { cacheCol: 'Q', targetCell: 'BC5', masterCol: 'S', description: '口座番号' },
];

/** I5用 SNS分岐マッピング（【自動】マスター参照 B〜F列 = マスター原本 D〜H列） */
const SNS_CACHE_MAPPING = {
  instagram: 'B',  // マスター原本 D列
  youtube:   'C',  // マスター原本 E列
  twitter:   'D',  // マスター原本 F列
  tiktok:    'E',  // マスター原本 G列
  other:     'F',  // マスター原本 H列（デフォルト）
};

// ═══════════════════════════════════════════════
// 4. Step 5: 源泉徴収簡約化
// ═══════════════════════════════════════════════

/** 源泉徴収セル（要全行検算） */
const TAX_CELLS = {
  fixed:  { cell: 'AE5', sourceCol: 'AD' },  // 固定費
  result: { cell: 'AG5', sourceCol: 'AF' },  // 成果報酬
};

// ═══════════════════════════════════════════════
// 5. 検証用セル
// ═══════════════════════════════════════════════

/** before/after で値を突合するセル（合計行） */
const VALIDATION_SUMMARY_CELLS = [
  'S2', 'T2', 'Z2', 'AA2', 'AH2', 'AI2',
  'AJ2', 'AL2', 'AN2', 'AP2',
  'BE2', 'BF2', 'BO2', 'N2',
];

/** 詳細検証で突合する列 */
const VALIDATION_DETAIL_COLS = [
  'H', 'I', 'S', 'T', 'U', 'V', 'W',
  'Z', 'AA', 'AE', 'AG', 'AH', 'BF',
];

/** ランダム検証の行数 */
const VALIDATION_RANDOM_ROWS = 10;

// ═══════════════════════════════════════════════
// 6. 負荷テスト設定
// ═══════════════════════════════════════════════

const LOAD_TEST_CONFIG = {
  rounds: 5,
  writesPerRound: 3,
  writeColumn: 'F',
  coolDownMs: 500,
  restoreValues: true,
};

// ═══════════════════════════════════════════════
// エクスポート（GASではグローバルスコープ）
// ═══════════════════════════════════════════════

const CONFIG = {
  targetSheetName: TARGET_SHEET_NAME,
  dataStartRow: DATA_START_ROW,
  dataEndRow: DATA_END_ROW,
  subSectionStart: SUB_SECTION_START,
  subSectionEnd: SUB_SECTION_END,
  masterSheetName: MASTER_SHEET_NAME,
  cacheSheetName: CACHE_SHEET_NAME,

  step1: {
    sumCellsDataRange: SUM_CELLS_DATA_RANGE,
    sumCellsSubRange: SUM_CELLS_SUB_RANGE,
    sumCellsClosed: SUM_CELLS_CLOSED,
  },
  step2: {
    xlookupMappings: XLOOKUP_MAPPINGS,
    snsCacheMapping: SNS_CACHE_MAPPING,
  },
  step5: {
    taxCells: TAX_CELLS,
  },

  validation: {
    summaryCells: VALIDATION_SUMMARY_CELLS,
    detailCols: VALIDATION_DETAIL_COLS,
    randomRows: VALIDATION_RANDOM_ROWS,
  },

  loadTest: LOAD_TEST_CONFIG,
};
