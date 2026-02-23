# 修正と改善タスク (Cycle 8)

## 概要
ユーザーフィードバックに基づく機能改善（Calculator機能強化、Dashboard/LogList UI改善、Masters追加機能）およびバグ修正を行う。

## タスクリスト

- [x] **Phase 1: バグ修正とCalculator調整**
    - [x] **Water Temp**: データ読み込み (`SheetsService`) で `temperature` が取得できていない問題を修正。
    - [x] **Calculator Highlight**: タイマー連動ハイライトを「現在の行の1つ上」に変更。
    - [x] **Calculator Inputs**: ログ管理項目（湯温、挽き目、味、濃度など）を入力できるようにフィールドを追加。

- [x] **Phase 2: Dashboard / Log List UI改善**
    - [x] **Score Bubble**:
        - 円の大きさの差分を強調（文字サイズも連動）。
        - 配置を行の右端（Reuseボタンの左）に変更。
        - Dashboard (`Recent Brews`) と Log List (`CoffeeLogListScreen`) の両方に適用。
    - [x] **Reuse Logic**:
        - `Reuse` ボタン押下時、Evaluation, Equipment, Parameters など全ての情報を `CalculatorScreen` に引き継ぐ。

- [x] **Phase 3: Masters 機能追加**
    - [x] **Add Button**: 各マスター管理画面に「追加 (+)」ボタンを配置（UIのみ、またはLog like input?）。
    - [x] **Bean Registration**: 豆登録時に「購入店舗」「産地」「焙煎度」「種類」から名称を自動生成するロジックを実装。
        - `BeanMaster` に不足しているフィールドがあれば検討（今回は既存フィールド流用またはDescriptionへ結合？）。

- [x] **Phase 4: 検証**
    - [x] `flutter run` でハイライト挙動、データ引き継ぎ、UI表示、データ読み込みを確認。
