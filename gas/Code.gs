// ------------------------------------------------------------------
// GAS Web App Script for BeanBase 2.0
// リポジトリ管理化 (T4-1c1/c2、設計書§3.4.2)。
// 元の内容は tools/gas_complete.js (画像アップロード対応版、現行デプロイの
// 参照実装として過去セッションで確認済み) をベースに、
// ALLOWED_SHEETS ホワイトリストと ensureSheet_ による新規シート自動生成を追加。
// ------------------------------------------------------------------

// ★ Google Drive の画像保存先フォルダID（URLの /folders/<ID> 部分）
const DRIVE_FOLDER_ID = '1Hs8d36riqqkl9qrojuGlZpkIAMim-fou';

// シート名ホワイトリスト (T4-1c2、設計書§3.4.2④)。既存7シート+新規3シート。
const ALLOWED_SHEETS = [
  'coffee_data',
  'bean_master',
  'methods_master',
  'pouring_steps',
  'mill_master',
  'dripper_master',
  'filter_master',
  'origin_master',
  'analysis_history',
  'recipe_suggestions',
];

// 新規シートのヘッダー定義 (設計書§3.4.1)。ensureSheet_ が無ければ自動生成する。
const NEW_SHEET_HEADERS = {
  'origin_master': ['産地ID', '国コード', '産地名', '産地名(英)', '地域'],
  'analysis_history': ['履歴ID', '作成日時', '種別', 'データ件数', '本文JSON'],
  'recipe_suggestions': [
    '提案ID', '作成日時', '豆ID', '産地ID', '焙煎度',
    '湯温', '湯豆比', '抽出時間', '提案根拠', '採否', '結果記録ID',
  ],
};

// 新規シートが無ければヘッダー行付きで自動生成する (冪等、設計書§3.4.2⑤)。
// 既存7シート(NEW_SHEET_HEADERSに無いもの)は自動生成しない(元々存在するはずのため)。
function ensureSheet_(ss, name) {
  var sheet = ss.getSheetByName(name);
  if (sheet) return sheet;

  var headers = NEW_SHEET_HEADERS[name];
  if (!headers) return null;

  sheet = ss.insertSheet(name);
  sheet.appendRow(headers);
  return sheet;
}

// 既存シートへの新規列追加 (冪等)。T4-1b: bean_master に産地ID/焙煎日列を追加。
// T4-2d: coffee_data にも産地ID列を追加(CoffeeRecord.originIdの保存先。
// SheetsServiceのkeyMap/reverseMapに対応するマッピング追加とセット)。
// T3-23: bean_master に 初期購入量(g) 列を追加。Cycle 20 T2-2b で
// BeanMaster.initialQuantityGrams と SheetsService の reverseMap('初期購入量(g)')は
// 実装済みだったが、本番シートへの列プロビジョニングが漏れており、残量%計算
// (calculateBeanRemainingPercent)が常に0を返していた(全豆で初期量が未保存だった)。
// ここに列を追加することで初期購入量が保存・取得できるようになる。
const EXISTING_SHEET_EXTRA_COLUMNS = {
  'bean_master': ['産地ID', '焙煎日', '初期購入量(g)'],
  'coffee_data': ['産地ID'],
};

function ensureColumns_(sheet, sheetName) {
  var extra = EXISTING_SHEET_EXTRA_COLUMNS[sheetName];
  if (!extra) return;

  var headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
  var toAdd = extra.filter(function (h) { return headers.indexOf(h) === -1; });
  if (toAdd.length === 0) return;

  var startCol = sheet.getLastColumn() + 1;
  sheet.getRange(1, startCol, 1, toAdd.length).setValues([toAdd]);
}

// GETリクエスト: データの読み込み
function doGet(e) {
  const sheetName = e.parameter.sheet;
  const ss = SpreadsheetApp.getActiveSpreadsheet();

  if (!sheetName) {
    const allSheets = ss.getSheets().map(s => s.getName());
    return createJsonResponse({
      available_sheets: allSheets,
      message: "Please specify a sheet name using ?sheet=<name>"
    });
  }

  if (ALLOWED_SHEETS.indexOf(sheetName) === -1) {
    return createJsonResponse({ error: "Sheet not allowed: " + sheetName });
  }

  const sheet = ensureSheet_(ss, sheetName) || ss.getSheetByName(sheetName);
  if (!sheet) {
    return createJsonResponse({ error: "Sheet not found: " + sheetName });
  }

  const rows = sheet.getDataRange().getValues();
  if (rows.length === 0) {
    return createJsonResponse([]);
  }

  // 1行目をヘッダーとする
  const headers = rows[0];
  const data = rows.slice(1).map(row => {
    let obj = {};
    headers.forEach((header, index) => {
      // 日付型は文字列に変換しておく (JSON化のため)
      let val = row[index];
      if (val instanceof Date) {
        val = val.toISOString();
      }
      obj[header] = val;
    });
    return obj;
  });

  return createJsonResponse(data);
}

// POSTリクエスト: データの追加・更新・削除・画像操作
function doPost(e) {
  var jsonData;

  try {
    // text/plain (CORS回避用) として送られたJSONデータをパース
    if (e.postData && e.postData.contents) {
      jsonData = JSON.parse(e.postData.contents);
    }
  } catch (err) {
    // パース失敗時はパラメータを確認
  }

  // 従来のパラメータ(Form)も確認
  if (!jsonData) {
    jsonData = e.parameter;
  }

  if (!jsonData) {
    return createJsonResponse({ error: "No data received" });
  }

  // 画像アクションは先に処理 (シートホワイトリストの対象外)
  if (jsonData.action === 'uploadImage') return handleUploadImage(jsonData);
  if (jsonData.action === 'deleteImage') return handleDeleteImage(jsonData);

  return handleRequest(jsonData);
}

// リクエスト処理の分岐
function handleRequest(params) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheetName = params.sheet;
  const action = params.action;
  const data = params.data; // JSON形式のデータオブジェクト

  if (!sheetName || !action) {
    return createJsonResponse({ error: "Missing 'sheet' or 'action' parameter" });
  }

  if (ALLOWED_SHEETS.indexOf(sheetName) === -1) {
    return createJsonResponse({ error: "Sheet not allowed: " + sheetName });
  }

  const sheet = ensureSheet_(ss, sheetName) || ss.getSheetByName(sheetName);
  if (!sheet) {
    return createJsonResponse({ error: "Sheet not found: " + sheetName });
  }
  ensureColumns_(sheet, sheetName);

  try {
    if (action === "add") {
      return addRow(sheet, data);
    } else if (action === "update") {
      return updateRow(sheet, data);
    } else if (action === "delete") {
      return deleteRow(sheet, data);
    } else {
      return createJsonResponse({ error: "Unknown action: " + action });
    }
  } catch (err) {
    return createJsonResponse({ error: err.toString() });
  }
}

// 行の追加
function addRow(sheet, dataObj) {
  // ヘッダー行を取得
  const headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];

  // 新しい行データを作成
  const newRow = headers.map(header => {
    return dataObj.hasOwnProperty(header) ? dataObj[header] : "";
  });

  sheet.appendRow(newRow);
  return createJsonResponse({ status: "success", action: "add" });
}

// 行の更新 (ヘッダー名に 'ID' を含む列をキーとして更新)
function updateRow(sheet, dataObj) {
  const headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
  const values = sheet.getDataRange().getValues();

  let idColumnIndex = -1;
  let idValue = null;

  for (let i = 0; i < headers.length; i++) {
    if (headers[i].indexOf("ID") !== -1) {
      idColumnIndex = i;
      idValue = dataObj[headers[i]];
      break;
    }
  }

  if (idColumnIndex === -1 || !idValue) {
    return createJsonResponse({ error: "ID column or value not found for update" });
  }

  for (let i = 1; i < values.length; i++) {
    if (String(values[i][idColumnIndex]) === String(idValue)) {
      const rowNumber = i + 1;
      const rowData = headers.map(header => {
        return dataObj.hasOwnProperty(header) ? dataObj[header] : values[i][headers.indexOf(header)];
      });

      sheet.getRange(rowNumber, 1, 1, rowData.length).setValues([rowData]);
      return createJsonResponse({ status: "success", action: "update", row: rowNumber });
    }
  }

  return createJsonResponse({ error: "Record not found for update (ID: " + idValue + ")" });
}

// 行の削除
function deleteRow(sheet, dataObj) {
  const headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
  const values = sheet.getDataRange().getValues();

  let idColumnIndex = -1;
  let idValue = null;

  for (let i = 0; i < headers.length; i++) {
    if (headers[i].indexOf("ID") !== -1) {
      idColumnIndex = i;
      idValue = dataObj[headers[i]];
      break;
    }
  }

  if (idColumnIndex === -1 || !idValue) {
    return createJsonResponse({ error: "ID column or value not found for delete" });
  }

  for (let i = 1; i < values.length; i++) {
    if (String(values[i][idColumnIndex]) === String(idValue)) {
      sheet.deleteRow(i + 1);
      return createJsonResponse({ status: "success", action: "delete", id: idValue });
    }
  }

  return createJsonResponse({ error: "Record not found to delete" });
}

// 画像アップロード (Google Drive)
function handleUploadImage(params) {
  try {
    const folder = DriveApp.getFolderById(DRIVE_FOLDER_ID);
    const decoded = Utilities.base64Decode(params.data);
    const blob = Utilities.newBlob(decoded, params.mimeType, params.filename);
    const file = folder.createFile(blob);
    file.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
    const fileId = file.getId();
    const url = 'https://drive.google.com/uc?export=view&id=' + fileId;
    return createJsonResponse({ success: true, url: url, fileId: fileId });
  } catch (err) {
    return createJsonResponse({ success: false, error: err.toString() });
  }
}

// 画像削除 (Google Drive)
function handleDeleteImage(params) {
  try {
    const file = DriveApp.getFileById(params.fileId);
    file.setTrashed(true);
    return createJsonResponse({ success: true });
  } catch (err) {
    return createJsonResponse({ success: false, error: err.toString() });
  }
}

// JSONレスポンス作成
function createJsonResponse(data) {
  return ContentService.createTextOutput(JSON.stringify(data))
    .setMimeType(ContentService.MimeType.JSON);
}
