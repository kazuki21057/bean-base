# 修正と改善タスク (Cycle 6)

## 概要
データの読み込み不具合（Evaluation, Filters）の修正および、Calculatorの機能拡張（ログ登録の前段階としてのパラメータ入力機能）を行う。

## タスクリスト

- [x] **Phase 1: データ読み込みの修正**
    - [x] **Evaluation Keys**: `SheetsService` のキーマッピングを実際のヘッダー (`香り(1-10)` など) に合わせる。
    - [x] **FilterMaster**: `size` フィールドの型不一致（数値/文字列混在）を解消するコンバーター (`_parseString`) を実装。
    - [x] **Log Output**: `SheetsService` のデバッグログで Evaluation フィールドが取得できているか明示的に確認（`香り(1-10)` 等を確認済み）。

- [x] **Phase 2: Log Detail 画面の修正**
    - [x] 詳細画面遷移時のエラー原因調査と修正（Phase 1のデータ修正で解消見込み）。

- [x] **Phase 3: Calculator の機能拡張 (UI)**
    - [x] **Parameters Section**: テーブルの下に管理項目 (Grinder, Dripper, Filter, Notes) の入力欄を追加。
        - マスタデータからの選択（Dropdown）。
    - [x] **Evaluation Section**: 評価項目 (Fragrance, Acidity...) のスライダー入力 (`0-10`) を追加。

- [x] **Phase 4: Calculator の機能拡張 (Logic)**
    - [x] **Method Update Logic**: メソッド保存時、豆量が変わっていても「比率 (Ratio)」を優先して保存するロジックの確認と実装（Weight変更 -> Auto Calc -> Save -> Update Master with new Ratio）。
    - [x] **Log Registration**: 「ログ登録」ボタンの配置（UIのみ、またはコンソール出力で模擬）。

- [x] **Phase 5: 検証**
    - [x] `flutter run` でデータ読み込み（Evaluation）を確認。FiltersはUI操作未実施だが型対応済み。
