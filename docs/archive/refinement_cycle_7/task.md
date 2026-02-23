# 修正と改善タスク (Cycle 7)

## 概要
報告された詳細画面クラッシュ、Calculatorの表示崩れ、および各機能追加要望に対応する。

## タスクリスト

- [x] **Phase 1: バグ修正**
    - [x] **Log Detail**: 詳細画面遷移時の `TypeError` を修正 (`firstWhere` の `orElse` 型不一致 -> 冗長ループ化)。
    - [x] **Calculator**: 画面オーバーフローを修正（`SingleChildScrollView` の適用確認、テーブルのCollapse化でスペース確保）。

- [x] **Phase 2: Calculator 機能拡張**
    - [x] **Step Reordering**: ステップの入れ替え機能（Up/Downボタン）を追加。
    - [x] **Active Step Highlight**: タイマー時間と連動して、現在のステップ行をハイライト表示。
        - **Collapsible Table**: テーブルを `ExpansionTile` で隠せるように変更（デフォルトCollapsed）。

- [x] **Phase 3: Dashboard 改善**
    - [x] **Recent Brews**:
        - "Reuse" (再利用) ボタン追加 -> Calculatorへ遷移 (MethodId, BeanWeight引き継ぎ)。
        - Score表示を円形（サイズ可変 1-10）に変更。
    - [x] **Inventory**: クリックで `MasterDetailScreen` (Bean) へ遷移。

- [x] **Phase 4: Masters 改善**
    - [x] **Bean Detail**: 日付表示を `yyyy/MM/dd` 形式に変更（時刻削除）。

- [x] **Phase 5: 検証**
    - [x] `flutter run` で全修正箇所の動作確認（コンパイル成功、画面遷移ロジック実装済み）。
