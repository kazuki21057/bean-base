# メンテナンス計画とSVD実装 (Cycle 9)

## Goal Description
プロジェクトの健全性確認（テスト実行）と、`StatisticsService` に残されたTODO（特異値分解の実装）の解消を行う。

## User Review Required
特になし

## Proposed Changes

### StatisticsService
#### [MODIFY] [statistics_service.dart](file:///c:/src/Antigravity/BeanBase2.0/lib/services/statistics_service.dart)
- SVD（特異値分解）の実装を追加または外部ライブラリ (`ml_linalg` 等) の導入検討
- PCA（主成分分析）計算ロジックの改善

### Tests
#### [NEW] [statistics_service_test.dart](file:///c:/src/Antigravity/BeanBase2.0/test/statistics_service_test.dart)
- SVD計算およびPCA結果の検証テスト追加

## Verification Plan
### Automated Tests
- `flutter test`
    - `test/statistics_service_test.dart`
    - `test/verification_test.dart`

### Manual Verification
- `flutter run` で統計画面の動作確認（散布図の表示確認）
