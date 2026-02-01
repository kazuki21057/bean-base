# Refinement Cycle 6: Fixes & Calculator Expansion

## 概要
データ読み込みに関する不具合（Evaluation, Filters）を修正し、Brewing Calculatorに詳細なログ入力機能を追加しました。

## 変更内容

### 1. Data Loading Fixes
- **Evaluation Keys**: スプレッドシートのカラム名 `(1-10)` に対応しました。これにより、ログ詳細画面や一覧画面でスコアが正しく表示されるようになります。
- **FilterMaster**: `size` フィールドの型不一致（数値/文字列の混在）に対応しました。読み込みエラーが解消され、全フィルターが表示されます。

### 2. Brewing Calculator 機能拡張
- **追加 UI**:
    - **Equipment**: Grinder, Dripper, Filter をプルダウンから選択可能にしました。
    - **Evaluation**: 香り、酸味、コクなどの7項目をスライダー (0-10) で入力可能にしました。
    - **Notes**: メモ入力欄を追加しました。
    - **Log Preview**: 「Log this Brew」ボタンを追加（現在はコンソール出力によるプレビューのみ）。
- **ロジック改善**:
    - **Ratio Preservation**: メソッドを保存/上書きする際、豆の量を変更していても、新しい豆量に基づいた「比率 (Ratio)」を再計算して保存するようにしました。これにより、次回ロード時にどの豆量で始めても比率が維持されます。

## 検証結果
- **データ読み込み**: `flutter run` のログにて、`Evaluation` (香り(1-10)...) および `FilterMaster` のデータが正しくパースされていることを確認しました。
- **Calculator**: 豆量を変更して保存した際、ステップの比率が正しく更新されることをロジック上で確認しました。

## 次のステップ
- **Log Registration**: 現在はプレビューのみのログ登録機能を、実際にAPI経由でスプレッドシート（`coffee_data`）に書き込む実装をする（Cycle 7以降）。
