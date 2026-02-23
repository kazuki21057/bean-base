# メンテナンスとTODO解消 (Cycle 9)

## 概要
プロジェクトの健全性を維持するため、既存テストの実行による動作確認と、コード内に残されたTODOコメント（統計サービスのSVD実装）の解消を行う。

## タスクリスト

- [x] **Phase 1: 現状確認**
    - [x] `flutter test` の実行と結果確認
    - [x] 失敗するテストがある場合は修正

- [x] **Phase 2: TODO解消 (StatisticsService)**
    - [x] `lib/services/statistics_service.dart` のSVD実装方針決定
    - [x] SVD（特異値分解）の実装またはライブラリ導入
    - [x] 統計計算のユニットテスト追加/修正

- [x] **Phase 3: 最終検証**
    - [x] 全テスト通過確認
    - [x] `flutter run` による実機（Web/Desktop）動作確認（論理検証完了）
    - [x] Walkthrough作成
