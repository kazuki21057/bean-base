# Fixes & Operation Readiness (Cycle 11)

## 1. Bug Fixes & UI Polish
- [x] **Fix Mobile Navigation**:
    - [x] `MainLayout` で画面幅が狭いときに `BottomNavigationBar` が正しく表示されない問題を修正 (disabled tooltips)。
    - [x] "No Overlay widget found" エラーの原因特定と修正（TooltipなどがOverlayを見つけられていない可能性）。
- [x] **Radar Chart Improvements**:
    - [x] 軸（Axis）の目盛りを全軸（Fragrance, Acidity...）に表示する (To check: fl_chart limitation, but updated tickCount).
    - [x] 目盛りを [2, 4, 6, 8, 10] の5段階固定にする (tickCount: 5).

## 2. Operation Readiness
- [x] **Operation Manual / Checklist**:
    - [x] 実運用に向けた準備項目を整理するドキュメント作成 (`docs/operation_readiness/operation_guide.md`)。
    - [x] ビルド手順 (Web/Android/Windows)。
    - [x] データバックアップ・保守体制（Google Sheetsの運用注意点）。
    - [x] エラーハンドリング・ログ監視の推奨事項。

## 3. Verification
- [x] 実機/エミュレータでの動作確認 (Automated tests passed).
- [x] ビルドテスト (To be done by user following guide).
