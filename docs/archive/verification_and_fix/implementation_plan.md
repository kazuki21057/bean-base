# 実装計画: 検証と修正

## 目的
アプリケーションの既存データ読み込みと画面遷移を検証し、安定動作を確保する。

## 変更内容

### 1. 検証用テストの作成
- `test/verification_test.dart` を新規作成する。
- `SheetsService` のデータ取得メソッドをモック、または実際のデータ構造に近い形でテストデータを定義する。
- 画面遷移 (`HomeScreen` -> 詳細画面など) のウィジェットテストを実装する。

### 2. データ読み込み修正 (`lib/providers/services/sheets_service.dart`)
- 前回修正されたキーマッピング (`_remapKeys`) が正しく機能しているか確認する。
- 不足しているフィールドや型変換エラーがあれば修正する。

### 3. モデル修正 (`lib/models/*.dart`)
- テストで発見された新たな `Null` エラーや型不一致に対応する。

## 検証方法
- `flutter test test/verification_test.dart` を実行し、全テスト通過を確認する。
