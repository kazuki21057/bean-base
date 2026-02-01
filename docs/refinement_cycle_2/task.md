# 修正と改善タスク (Cycle 2)

## 概要
ユーザーフィードバックに基づき、Calculatorの表示形式変更、データ読み込みの完全化、詳細画面の機能拡充を行う。

## タスクリスト
- [x] **Phase 1: 抽出画面 (Calculator) の修正**
    - [x] テーブル列の変更 (#, Time, Total Weight, Description)
    - [x] Total Weight の累積計算ロジック実装
- [x] **Phase 2: Master/Log データ読み込みの修正**
    - [x] "Unknown" 表示の排除 (Empty string or "-" へ変更)
    - [x] Coffee Logs が読み込めない原因の特定と修正 (SheetsService/Model converters)
    - [x] ログ詳細画面への遷移実装
- [x] **Phase 3: Method 詳細の拡張**
    - [x] Method 詳細画面で Pouring Steps を表示する機能追加
- [x] **検証**
    - [x] 表示ロジックのユニットテスト/ウィジェットテスト (All passed)
    - [x] Walkthrough更新
