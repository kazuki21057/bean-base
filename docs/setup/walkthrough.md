# BeanBase 2.0 セットアップ & プロトタイプ完了

## 概要
BeanBase 2.0 のプロジェクト初期化、Google Sheets 連携、および主要なUI画面の実装が完了しました。
Flutter Web アプリケーションとして動作し、Google Sheets をバックエンドデータベースとして利用します。

## 成果物
### 1. プロジェクト構成
- **Flutter Web プロジェクト**: `bean_base`
- **主要ライブラリ**: `flutter_riverpod`, `http`, `fl_chart`, `json_serializable`

### 2. データモデル & 連携
- **データモデル**: JSONからDartオブジェクトへの変換ロジック (`CoffeeRecord`, `MethodMaster` 等)
- **Sheets Service**: Google Apps Script (Web App) からデータを取得する `SheetsService` クラス
- **API**: ユーザー提供の GAS Web App URL を設定済み

### 3. UI 実装
- **ホーム画面 (`HomeScreen`)**:
  - ダッシュボードとして機能
  - ナビゲーションレールによる画面切り替え
  - 最新の抽出ログ表示
- **ログリスト画面 (`CoffeeLogListScreen`)**:
  - 全抽出記録のリスト表示
- **マスタリスト画面 (`MasterListScreen`)**:
  - 豆、レシピ、器具などのマスタデータ閲覧
- **抽出計算機 (`CalculatorScreen`)**:
  - **コア機能**: レシピと豆量を選択すると、注湯ステップ（湯量・時間）を自動計算
  - スケーリングロジック（豆量比率）を実装

## 動作確認方法
Windows 環境での `.dart_tool` フォルダのロック競合により、自動生成コードの作成 (`build_runner`) が失敗している可能性があります。
アプリを起動する前に、以下の手順を実行してください：

1.  **VS Code を再起動** してください（ファイルロックを解除するため）。
2.  ターミナルで以下のコマンドを実行し、コード生成を完了させてください：
    ```powershell
    flutter pub run build_runner build --delete-conflicting-outputs
    ```
3.  アプリを起動します：
    ```powershell
    flutter run -d chrome
    ```

## スクリーンショット (完成イメージ)
※ ビルド完了後に確認可能
- **Calculator**: レシピ「4:6メソッド」を選択し「20g」と入力すると、各ステップの湯量が自動計算されます。
- **Home**: Google Sheets にある直近のログが表示されます。

## 今後のステップ
- 実際の抽出タイマー機能の実装
- 統計画面のグラフ実装 (`fl_chart` 利用)
- UIデザインのブラッシュアップ
