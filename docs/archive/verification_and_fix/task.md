# 検証と修正タスク

## 概要
既存データの読み込みと画面遷移を検証し、不具合があれば修正する。

## タスクリスト
- [x] 現状のコード確認 (Service/Models)
- [x] 検証用テストの作成 (`test/verification_test.dart`)
    - [x] データ読み込みの検証
    - [x] 画面遷移の検証 (`test/screen_transition_test.dart`)
- [x] 不具合の修正 (発見次第)
    - [x] データマッピングの調整 (`SheetsService._remapKeys` の型保持修正)
    - [x] Null安全性向上 (`json_annotation` defaults利用)
- [x] 再検証 (全テスト通過)
- [x] Walkthroughの作成
