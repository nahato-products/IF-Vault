/**
 * ANSEM IFマスタ一括登録テンプレート - 自動セットアップスクリプト
 *
 * 【使い方】
 * 1. Google Sheets で新規スプレッドシートを作成
 * 2. CSVファイル「IF一括登録テンプレート.csv」をインポート
 * 3. 拡張機能 → Apps Script を開く
 * 4. このコードを貼り付けて保存
 * 5. setupTemplate() を実行
 */

// ======================
// メイン実行関数
// ======================
function setupTemplate() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();

  // メインシート設定
  const main = ss.getSheets()[0];
  main.setName('IF登録');

  // 選択肢シート作成
  const choicesSheet = createChoicesSheet(ss);

  // ヘッダー書式設定
  setupHeader(main);

  // セクション色分け
  setupSectionColors(main);

  // ドロップダウン設定
  setupDropdowns(main, choicesSheet);

  // バリデーション設定
  setupValidation(main);

  // 条件付き書式
  setupConditionalFormatting(main);

  // 列幅調整
  setupColumnWidths(main);

  // ヘッダー行固定
  main.setFrozenRows(1);

  // サンプル行の書式（2行目をグレーに）
  if (main.getLastRow() >= 2) {
    main.getRange(2, 1, 1, 25).setBackground('#F5F5F5').setFontColor('#888888');
  }

  // 選択肢シートを非表示
  choicesSheet.hideSheet();

  SpreadsheetApp.getUi().alert(
    '✅ セットアップ完了！\n\n' +
    '・ヘッダー色分け設定済み\n' +
    '・ドロップダウン設定済み\n' +
    '・バリデーション設定済み\n' +
    '・2行目はサンプルデータです（入力時は3行目から）'
  );
}

// ======================
// 選択肢シート作成
// ======================
function createChoicesSheet(ss) {
  let sheet = ss.getSheetByName('選択肢');
  if (sheet) ss.deleteSheet(sheet);
  sheet = ss.insertSheet('選択肢');

  // A列: 担当者一覧（※実際の担当者名に書き換えてください）
  const agents = [
    '担当者一覧',
    '山田太郎',
    '佐藤花子',
    '鈴木一郎',
    '高橋美咲',
    '田中大輔',
  ];
  sheet.getRange(1, 1, agents.length, 1).setValues(agents.map(v => [v]));

  // B列: コンプラチェック
  const compliance = ['コンプラ', '○', '×'];
  sheet.getRange(1, 2, compliance.length, 1).setValues(compliance.map(v => [v]));

  // C列: 区分
  const types = ['区分', '事務所所属', 'フリーランス', '企業専属'];
  sheet.getRange(1, 3, types.length, 1).setValues(types.map(v => [v]));

  // D列: 敬称
  const honorifics = ['敬称', '様', '御中', 'さん'];
  sheet.getRange(1, 4, honorifics.length, 1).setValues(honorifics.map(v => [v]));

  // E列: ジャンル（※実際のカテゴリに書き換えてください）
  const genres = [
    'ジャンル',
    '美容',
    'ファッション',
    'グルメ',
    '旅行',
    'ガジェット',
    'フィットネス',
    'ゲーム',
    'ビジネス',
    'ライフスタイル',
    'エンタメ',
    'その他',
  ];
  sheet.getRange(1, 5, genres.length, 1).setValues(genres.map(v => [v]));

  // F列: 口座種別
  const accountTypes = ['口座種別', '普通', '当座', '貯蓄'];
  sheet.getRange(1, 6, accountTypes.length, 1).setValues(accountTypes.map(v => [v]));

  return sheet;
}

// ======================
// ヘッダー書式
// ======================
function setupHeader(sheet) {
  const header = sheet.getRange(1, 1, 1, 25);
  header.setFontWeight('bold');
  header.setFontSize(10);
  header.setHorizontalAlignment('center');
  header.setVerticalAlignment('middle');
  header.setWrap(true);
  sheet.setRowHeight(1, 40);
}

// ======================
// セクション色分け
// ======================
function setupSectionColors(sheet) {
  const maxRow = 500; // 十分な行数

  // 🟦 基本情報（A〜H列）— 青系
  sheet.getRange(1, 1, 1, 8).setBackground('#D0E0FF');
  sheet.getRange(2, 1, maxRow, 8).setBackground('#F0F5FF');

  // 🟩 SNS（I〜M列）— 緑系
  sheet.getRange(1, 9, 1, 5).setBackground('#D0FFD0');
  sheet.getRange(2, 9, maxRow, 5).setBackground('#F0FFF0');

  // 🟨 銀行口座（N〜R列）— 黄系
  sheet.getRange(1, 14, 1, 5).setBackground('#FFFFD0');
  sheet.getRange(2, 14, maxRow, 5).setBackground('#FFFFF0');

  // 🟪 請求先・住所（S〜Y列）— 紫系
  sheet.getRange(1, 19, 1, 7).setBackground('#E8D0FF');
  sheet.getRange(2, 19, maxRow, 7).setBackground('#F8F0FF');
}

// ======================
// ドロップダウン設定
// ======================
function setupDropdowns(sheet, choicesSheet) {
  const maxRow = 500;

  // A列: 担当者
  setDropdownFromSheet(sheet, choicesSheet, 'A', 1, 2);

  // C列: コンプラチェック
  setDropdownFromSheet(sheet, choicesSheet, 'C', 2, 2);

  // D列: 区分
  setDropdownFromSheet(sheet, choicesSheet, 'D', 3, 2);

  // F列: 様/御中
  setDropdownFromSheet(sheet, choicesSheet, 'F', 4, 2);

  // H列: ジャンル
  setDropdownFromSheet(sheet, choicesSheet, 'H', 5, 2);

  // P列: 口座種別
  setDropdownFromSheet(sheet, choicesSheet, 'P', 6, 2);
}

function setDropdownFromSheet(targetSheet, sourceSheet, targetCol, sourceCol, startRow) {
  const sourceData = sourceSheet.getRange(startRow, sourceCol, sourceSheet.getLastRow() - startRow + 1, 1).getValues().flat().filter(v => v !== '');
  if (sourceData.length === 0) return;

  const rule = SpreadsheetApp.newDataValidation()
    .requireValueInList(sourceData, true)
    .setAllowInvalid(false)
    .build();

  const colIndex = targetCol.charCodeAt(0) - 64; // A=1, B=2, ...
  targetSheet.getRange(3, colIndex, 498, 1).setDataValidation(rule);
}

// ======================
// バリデーション設定
// ======================
function setupValidation(sheet) {
  const maxRow = 500;

  // G列（メールアドレス）: メール形式チェック
  const emailRule = SpreadsheetApp.newDataValidation()
    .requireTextIsEmail()
    .setAllowInvalid(true)
    .setHelpText('有効なメールアドレスを入力してください（例: name@example.com）')
    .build();
  sheet.getRange(3, 7, 498, 1).setDataValidation(emailRule);

  // Q列（口座番号）: 7桁数字
  const accountRule = SpreadsheetApp.newDataValidation()
    .requireFormulaSatisfied('=AND(LEN(Q3)=7, ISNUMBER(VALUE(Q3)))')
    .setAllowInvalid(true)
    .setHelpText('半角数字7桁で入力してください（例: 1234567）')
    .build();
  sheet.getRange(3, 17, 498, 1).setDataValidation(accountRule);

  // S列（適格請求書番号）: T+13桁
  const invoiceRule = SpreadsheetApp.newDataValidation()
    .requireFormulaSatisfied('=REGEXMATCH(S3, "^T[0-9]{13}$")')
    .setAllowInvalid(true)
    .setHelpText('T+13桁の数字で入力してください（例: T1234567890123）')
    .build();
  sheet.getRange(3, 19, 498, 1).setDataValidation(invoiceRule);

  // V列（郵便番号）: XXX-XXXX形式
  const postalRule = SpreadsheetApp.newDataValidation()
    .requireFormulaSatisfied('=REGEXMATCH(V3, "^[0-9]{3}-[0-9]{4}$")')
    .setAllowInvalid(true)
    .setHelpText('XXX-XXXX形式で入力してください（例: 150-0001）')
    .build();
  sheet.getRange(3, 22, 498, 1).setDataValidation(postalRule);
}

// ======================
// 条件付き書式
// ======================
function setupConditionalFormatting(sheet) {
  // B列（マスター名）が空の場合 → 赤背景
  const nameRule = SpreadsheetApp.newConditionalFormatRule()
    .whenCellEmpty()
    .setBackground('#FFE0E0')
    .setRanges([sheet.getRange('B3:B500')])
    .build();

  // G列（メール）が不正な場合 → 赤背景
  const emailRule = SpreadsheetApp.newConditionalFormatRule()
    .whenFormulaSatisfied('=AND(G3<>"", NOT(REGEXMATCH(G3, "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")))')
    .setBackground('#FFE0E0')
    .setRanges([sheet.getRange('G3:G500')])
    .build();

  sheet.setConditionalFormatRules([nameRule, emailRule]);
}

// ======================
// 列幅調整
// ======================
function setupColumnWidths(sheet) {
  // 基本情報
  sheet.setColumnWidth(1, 100);  // A: 担当者
  sheet.setColumnWidth(2, 140);  // B: マスター名
  sheet.setColumnWidth(3, 60);   // C: コンプラ
  sheet.setColumnWidth(4, 90);   // D: 区分
  sheet.setColumnWidth(5, 160);  // E: 所属名
  sheet.setColumnWidth(6, 60);   // F: 様/御中
  sheet.setColumnWidth(7, 200);  // G: メールアドレス
  sheet.setColumnWidth(8, 100);  // H: ジャンル

  // SNS
  sheet.setColumnWidth(9, 250);  // I: Instagram
  sheet.setColumnWidth(10, 250); // J: YouTube
  sheet.setColumnWidth(11, 250); // K: Twitter/X
  sheet.setColumnWidth(12, 250); // L: TikTok
  sheet.setColumnWidth(13, 200); // M: その他SNS

  // 銀行口座
  sheet.setColumnWidth(14, 100); // N: 銀行名
  sheet.setColumnWidth(15, 100); // O: 支店名
  sheet.setColumnWidth(16, 70);  // P: 口座種別
  sheet.setColumnWidth(17, 90);  // Q: 口座番号
  sheet.setColumnWidth(18, 140); // R: 口座名義

  // 請求先・住所
  sheet.setColumnWidth(19, 140); // S: 適格請求書番号
  sheet.setColumnWidth(20, 160); // T: 請求先名
  sheet.setColumnWidth(21, 120); // U: 請求部署名
  sheet.setColumnWidth(22, 90);  // V: 郵便番号
  sheet.setColumnWidth(23, 250); // W: 住所
  sheet.setColumnWidth(24, 140); // X: 届け先名称
  sheet.setColumnWidth(25, 120); // Y: 電話番号
}
