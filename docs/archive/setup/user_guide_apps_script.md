# Google Apps Script (GAS) セットアップガイド

Google Sheets をデータベースとして使用するため、以下の手順で API を公開してください。

## 1. Google Sheets の準備
既存のスプレッドシートを開き、メニューの **[拡張機能] > [Apps Script]** をクリックします。

## 2. スクリプトの記述
`original-data/coffee_data_for_AppsScript.xlsx` に全てのデータが集約されています。
このファイルを Google Drive にアップロードし、Google スプレッドシートとして開いてください。
その後、メニューの **[拡張機能] > [Apps Script]** を開き、以下のコードを `コード.gs` に貼り付けてください。

```javascript
function doGet(e) {
  const sheetName = e.parameter.sheet;
  const ss = SpreadsheetApp.getActiveSpreadsheet();

  // シート名の指定がない場合は全シート名を返す（デバッグ用）
  if (!sheetName) {
    const allSheets = ss.getSheets().map(s => s.getName());
    return ContentService.createTextOutput(JSON.stringify({
      available_sheets: allSheets,
      message: "Please specify a sheet name using ?sheet=<name>"
    })).setMimeType(ContentService.MimeType.JSON);
  }
  
  const sheet = ss.getSheetByName(sheetName);
  
  if (!sheet) {
    return ContentService.createTextOutput(JSON.stringify({
      error: "Sheet not found: " + sheetName,
      available_sheets: ss.getSheets().map(s => s.getName())
    })).setMimeType(ContentService.MimeType.JSON);
  }

  const rows = sheet.getDataRange().getValues();
  if (rows.length === 0) {
     return ContentService.createTextOutput(JSON.stringify([]))
      .setMimeType(ContentService.MimeType.JSON);
  }

  // 1行目をヘッダーとして扱う
  const headers = rows[0];
  const data = rows.slice(1).map(row => {
    let obj = {};
    headers.forEach((header, index) => {
      // 日付型などは文字列に変換しておくと安全ですが、ここでは生の値を渡します
      obj[header] = row[index];
    });
    return obj;
  });

  return ContentService.createTextOutput(JSON.stringify(data))
    .setMimeType(ContentService.MimeType.JSON);
}
```

> [!TIP]
> `coffee_data_for_AppsScript.xlsx` 内のシート名が日本語の場合（例: "豆マスター"）、APIリクエスト時にエンコードが必要になります。
> 可能であれば、シート名を以下のように英語に変更することを推奨します：
> - `coffee_data`
> - `bean_master`
> - `grinder_master`
> - `dripper_master`
> - `filter_master`
> - `methods_master`
> - `pouring_steps`

## 3. デプロイ
1.  右上の **[デプロイ]** ボタン > **[新しいデプロイ]** をクリック。
2.  「種類の選択」の歯車アイコン > **[ウェブアプリ]** を選択。
3.  以下の設定を行います：
    -   **説明**: `BeanBase API`
    -   **次のユーザーとして実行**: `自分 (メールアドレス)`
    -   **アクセスできるユーザー**: `全員` (※重要: これによりAPIキーなしでアプリからアクセス可能になります。プロトタイプ用途。)
4.  **[デプロイ]** をクリック。
5.  **ウェブアプリの URL** (末尾が `/exec` のもの) が発行されます。この URL をコピーしてください。

## 4. URL の共有
チャットで「ウェブアプリの URL」を教えてください。アプリの実装に使用します。
