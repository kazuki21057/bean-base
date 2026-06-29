/**
 * BeanBase: GAS Web App への画像アップロード機能追加パッチ
 *
 * 既存の GAS スクリプト（doPost 関数）に以下のコードをマージしてください。
 * デプロイ後は「新しいデプロイ」で URL を更新し、sheets_service.dart の
 * kGoogleSheetsApiUrl を最新 URL に変更してください。
 *
 * ■ Drive フォルダの準備
 *   1. Google Drive で「BeanBase Images」フォルダを作成
 *   2. フォルダの ID（URLの /folders/<ID> 部分）を DRIVE_FOLDER_ID に設定
 */

// ★ここを自分のフォルダIDに変更
const DRIVE_FOLDER_ID = 'YOUR_DRIVE_FOLDER_ID';

/**
 * doPost のハンドラに以下の分岐を追加する。
 * 既存の doPost 内の if-else チェーンに組み込んでください。
 *
 * function doPost(e) {
 *   const params = JSON.parse(e.postData.contents);
 *   const action = params.action;
 *
 *   if (action === 'uploadImage') { ... }        // ← 追加
 *   else if (action === 'deleteImage') { ... }   // ← 追加
 *   else if (action === 'create') { ... }        // 既存
 *   else if (action === 'update') { ... }        // 既存
 *   ...
 * }
 */

function handleUploadImage(params) {
  try {
    const folder = DriveApp.getFolderById(DRIVE_FOLDER_ID);
    const decoded = Utilities.base64Decode(params.data);
    const blob = Utilities.newBlob(decoded, params.mimeType, params.filename);
    const file = folder.createFile(blob);
    file.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
    const fileId = file.getId();
    const url = 'https://drive.google.com/uc?export=view&id=' + fileId;
    return ContentService
      .createTextOutput(JSON.stringify({ success: true, url: url, fileId: fileId }))
      .setMimeType(ContentService.MimeType.JSON);
  } catch (err) {
    return ContentService
      .createTextOutput(JSON.stringify({ success: false, error: err.toString() }))
      .setMimeType(ContentService.MimeType.JSON);
  }
}

function handleDeleteImage(params) {
  try {
    const file = DriveApp.getFileById(params.fileId);
    file.setTrashed(true);
    return ContentService
      .createTextOutput(JSON.stringify({ success: true }))
      .setMimeType(ContentService.MimeType.JSON);
  } catch (err) {
    return ContentService
      .createTextOutput(JSON.stringify({ success: false, error: err.toString() }))
      .setMimeType(ContentService.MimeType.JSON);
  }
}

/**
 * doPost の統合例（既存の doPost を置き換えるのではなく、分岐追加のサンプル）:
 *
 * function doPost(e) {
 *   const params = JSON.parse(e.postData.contents);
 *   const action = params.action;
 *
 *   if (action === 'uploadImage') return handleUploadImage(params);
 *   if (action === 'deleteImage') return handleDeleteImage(params);
 *
 *   // 既存の action 分岐 (create, update, delete, etc.) ...
 * }
 */
