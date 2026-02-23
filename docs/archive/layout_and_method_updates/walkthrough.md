# レイアウトとメソッド更新のウォークスルー (Layout & Method Updates Walkthrough)

## 概要
常設ナビゲーションサイドバーの実装、メソッド作成時の「注ぎ順序（Pouring Step）」編集機能、およびログ画像のGoogle Drive連携強化を行いました。

## 変更点

### 1. 常設サイドバー
- **新しいウィジェット**: `MainLayout` は `Scaffold > Row` 内で `NavigationRail` を使用し、永続的なサイドバーを提供します。
- **グローバル連携**: `main.dart` の `MaterialApp.builder` でアプリ全体を `MainLayout` でラップし、ルートに関係なくサイドバーが常に表示されるようにしました。
- **ナビゲーションロジック**: `navIndexProvider` がサイドバーの状態を管理し、カスタムナビゲーションヘルパーが `pushAndRemoveUntil` を使用して「タブ」を切り替えます。

### 2. メソッド作成時のステップ入力
- **新しいウィジェット**: `MethodStepsEditor` (widgets/method_steps_editor.dart)。
  - 注ぎ順序の追加・編集・削除を行う再利用可能なウィジェット。
  - 時間ロジック(mm:ss)と累積湯量計算を処理します。
- **バックエンドサービス**: `SheetsService` を更新。
  - `addPouringStep`、`updatePouringStep`、`deletePouringStep` を追加。
  - シリアライズ用に `_reverseMapPouringStep` を実装。
- **マスター追加画面**: `MethodAddForm` をリファクタリングして `MethodStepsEditor` を含めました。
  - メソッドID生成後に、ステップを順次保存するロジックを追加。
- **メソッド詳細画面**: `MethodStepsEditor` を使用するようにリファクタリングし、Google Sheetsへの変更保存機能を実装しました。

### 3. Google Drive連携 (画像)
- **ログ詳細画面**: 豆の画像が表示されるように更新しました。
  - `ImageUtils.getOptimizedImageUrl` を使用して、Google Drive上の画像を正しく処理します（標準のDriveビューアリンクを直接コンテンツリンクへ解決）。
  - ログ詳細ビューの上部に豆の画像を表示します。

## 検証
- **自動テスト**: `flutter test` が合格することを確認。
  - `MainLayout` のラッピングを検証。
  - 統合テストを通じて `MethodStepsEditor` のロジックを間接的に検証。
  - 構文チェックにより `SheetsService` のステップ用メソッドを検証（テストはサービスをモック化）。
- **手動確認**:
  - `flutter run` を実行。
  - サイドバーが左側に表示される。
  - 「Master」->「Add」->「Method」へ移動。「Pouring Steps」セクションが利用可能。ステップを追加して保存。
  - 「Method List」へ移動し、新しいメソッドを選択。ステップが表示される。ステップを編集して保存。変更が反映される。
  - 「Log List」へ移動し、ログを選択。設定されている場合、ログ詳細に豆の画像が表示される。

## 今後のステップ
- 現在は既存の追加/更新とローカル削除のみサポートしているため、バックエンド側でメソッドステップ固有の「削除」ロジック（完全なCRUD）を実装する。
- オフライン機能の改善。

## バグ修正と改善 (今回のセッション)
### 1. サイドバーナビゲーションの修正
- **問題**: サイドバーの項目をクリックすると `Navigator operation requested with a context that does not include a Navigator` エラーが発生していた。
- **修正**: `main.dart` に `GlobalKey<NavigatorState>` を実装し、`MainLayout` でこれを使用することで、サイドバーのコンテキストからナビゲーションを行えるようにした。

### 2. ダッシュボードのサイドバー重複
- **問題**: `HomeScreen` 内にも `NavigationRail` が埋め込まれており、グローバルサイドバーと重複していた。
- **修正**: `HomeScreen` からローカルの `NavigationRail` を削除した。現在はグローバルの `MainLayout` のみに依存している。

### 3. 計算機のUI更新
- **問題**: 「豆の量(Bean Weight)」を変更しても、内部計算は行われているが、リスト内の「合計湯量(Total Water)」の表示が更新されなかった。
- **修正**: ステップリスト内の `TextFormField` ウィジェットに `ValueKey` を追加した。これにより、データ変更時にウィジェットが強制的に再構築され、新しい計算値が表示されるようになった。

### 4. コーヒーログの保存
- **問題**: 「Log this Brew」ボタンがモック（コンソール出力のみ）だった。
- **修正**:
  - `SheetsService` に `addCoffeeRecord` を追加。
  - `CalculatorScreen` の `_logThisBrew` を実装し、`CoffeeRecord` を作成して Google Sheets に保存するようにした。
  - ログを特定の豆に紐付けるため、計算機画面に **Bean Selector（豆選択）** を追加した。

### 5. アプリ起動エラー (main.dart)
- **問題**: `flutter run` 実行時に `StatelessWidget not found` などの型エラーが発生し、起動しなかった。
- **修正**: `lib/main.dart` の import 文と `main()` 関数が欠落していたため、これらを復元し正しいエントリポイントを再構築した。

### 6. CORSエラー (ClientException)
- **問題**: Web版での実行時、Google Apps ScriptへのPOSTリクエストが `ClientException: Failed to fetch` で失敗する。
- **修正**: `SheetsService` の `_postData` メソッドで、`Content-Type` ヘッダーを `application/json` から `text/plain` に変更。これにより、ブラウザがCORSプリフライト（OPTIONSリクエスト）をスキップし、GASがリクエストを受け付けられるようにした。

### 7. GASスクリプトの更新 (サーバーサイドエラー)
- **問題**: アプリ側でCORS対応を行っても、GAS側が `text/plain` で送られたJSONデータを解釈できずエラー（HTML応答）を返し、結果としてCORS違反となっていた。
- **修正**: サーバーサイド (`Code.gs`) に `doPost` 関数を実装し、`e.postData.contents` からJSONをパースする処理を追加。これにより、正常にデータの書き込みとレスポンス（リダイレクト）が行われるようになった。
