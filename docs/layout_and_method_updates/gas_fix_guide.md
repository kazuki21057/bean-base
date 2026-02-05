# Google Apps Script (GAS) 修正ガイド (完全版)

共有いただいたスクリーンショットを確認したところ、現在は `doGet` 関数しか定義されていないようです。
データの保存を行うには `doPost` 関数と、書き込み処理を行う補助関数が必要です。

現在の `doGet` のロジック（読み込み）を維持しつつ、書き込み機能（`doPost`）を追加した**完全なスクリプト**を作成しました。
以下の手順で、現在の `Code.gs` の内容をすべて書き換えてください。

## 手順

### 1. コードの書き換え
GASエディタ内のコードを**すべて削除**し、以下のコードをそのまま貼り付けてください。

```javascript
// ------------------------------------------------------------------
// GAS Web App Script for BeanBase 2.0
// ------------------------------------------------------------------

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

  const sheet = ss.getSheetByName(sheetName);
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

// POSTリクエスト: データの追加・更新・削除
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

  const sheet = ss.getSheetByName(sheetName);
  if (!sheet) {
    // シートがない場合の自動作成ロジックが必要ならここに追加
    return createJsonResponse({ error: "Sheet not found: " + sheetName });
  }

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
    // データオブジェクトにヘッダーと同名のキーがあればその値をセット、なければ空文字
    return dataObj.hasOwnProperty(header) ? dataObj[header] : "";
  });

  sheet.appendRow(newRow);
  return createJsonResponse({ status: "success", action: "add" });
}

// 行の更新 (ヘッダー名に 'ID' を含む列をキーとして更新)
function updateRow(sheet, dataObj) {
  const headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
  const values = sheet.getDataRange().getValues();
  
  // IDカラム（キーとなる列）を特定
  let idColumnIndex = -1;
  let idValue = null;
  
  for (let i = 0; i < headers.length; i++) {
    // "ID" を含む列名 (例: '記録ID', '豆ID', 'ID') をキーとする
    if (headers[i].indexOf("ID") !== -1) {
      idColumnIndex = i;
      idValue = dataObj[headers[i]];
      break;
    }
  }

  if (idColumnIndex === -1 || !idValue) {
    return createJsonResponse({ error: "ID column or value not found for update" });
  }

  // 行を探して更新
  for (let i = 1; i < values.length; i++) {
    if (String(values[i][idColumnIndex]) === String(idValue)) {
      const rowNumber = i + 1;
      const rowData = headers.map(header => {
        // 更新データがあればセット、なければ元の値を維持
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

// JSONレスポンス作成
function createJsonResponse(data) {
  return ContentService.createTextOutput(JSON.stringify(data))
    .setMimeType(ContentService.MimeType.JSON);
}

// ------------------------------------------------------------------
```

### 2. 新しいデプロイ (New Deployment)
コードを貼り付けたら、**必ず新しいバージョンとしてデプロイ**してください。

1. 右上の **「デプロイ」** > **「新しいデプロイ」** を選択。
2. 種類の選択（歯車）: **「ウェブアプリ」**
3. 説明: 「保存機能の追加」など
4. 次のユーザーとして実行: **「自分」**
5. アクセスできるユーザー: **「全員 (Anyone)」**
6. **「デプロイ」** をクリック。
7. 表示された Web App URL をコピーし、アプリ側の URL と一致しているか確認してください。
