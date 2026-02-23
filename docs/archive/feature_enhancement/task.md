# 修正と改善タスク (Cycle 5)

## 概要
ユーザーからの包括的な改善要望（Dashboardの在庫管理、ログ詳細の改善、Calculatorの機能拡張、Mastersの整理）に対応する。

## タスクリスト

- [x] **Phase 1: モデルとデータの拡張**
    - [x] `BeanMaster` に在庫管理用フィールド (`purchaseDate`, `firstUseDate`, `lastUseDate`, `isInStock`) を追加
    - [x] `SheetsService` の `BeanMaster` キーマッピングを更新（スプレッドシート側にカラムがなくてもデフォルト値で対応、あるいはロジックで補完）
    - [x] `Filters` のデータ読み込みマッピング確認（元データが反映されるように）

- [x] **Phase 2: Dashboard (Home) の改善**
    - [x] **Inventory Section**: 手持ちの豆（在庫あり）を表示するセクションを追加（名前、購入日、使用日）
    - [x] **Recent Brews**:
        - [x] 空の項目（Detailsなし）を表示しないフィルタリング
        - [x] `Score` を表示

- [x] **Phase 3: All Coffee Logs & Masters の改善**
    - [x] **ID解決**: 一覧表示で ID (`method001`) ではなく名称 (`V60 Standard`) を表示（`Master` データとの突き合わせロジック実装）
    - [x] **Log Detail**:
        - [x] Evaluation (Spider Chart/Score) が表示されない問題を修正（`allowZero` 実装）
        - [x] Water Temp が表示されない問題を修正
        - [x] Total Time を `mm:ss` 表記に変更
    - [x] **Masters**:
        - [x] Beans: `name` が `-` のものを非表示に
        - [x] Methods: Pouring Steps の Time/Water を加算して合計表示。Timeは `mm:ss`
        - [x] Filters: Material/Size 表示追加

- [x] **Phase 4: Brewing Calculator の機能拡張**
    - [x] **Proportional Update**: `Bean Weight` 変更時に Pouring Steps の `Water Amount` を自動再計算（比率維持）
    - [x] **Timer**: 画面にストップウォッチ/タイマー機能を追加
    - [x] **UI Polish**: Add/Save ボタンの配置変更（表の右下へ）

- [ ] **Phase 5: 検証**
    - [ ] `flutter run` での実機検証
    - [ ] リストスワイプでのレシピコピー（遷移）の実装（実装完了、検証待ち）
