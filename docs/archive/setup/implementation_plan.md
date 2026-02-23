# 実装計画 - フェーズ 1: セットアップ & プロトタイプ

## 目標
BeanBase 2.0 Flutter Web アプリケーションを初期化します。Google Sheets (`coffee_data`, `methods_master`) と連携し、コーヒーログのリスト表示機能と、メソッド・豆量に基づいた注湯ステップ計算機のプロトタイプを実装します。

## ユーザー確認事項
> [!NOTE]
> **Google Sheets 連携**: **Apps Script Web App** (JSON API) を利用します。
> ユーザー側でのセットアップ作業（スクリプトのデプロイ）が必要になります。後ほど手順を案内します。

## 既存データとスキーマ
`original-data` ディレクトリのCSVファイルに基づき、以下のデータ構造を採用します。
新しいスプレッドシートを作成する際は、これらのデータを初期値としてインポートする機能を検討します（または手動インポートを案内）。
- `coffee_data`: コーヒー抽出ログ
- `methods_master`: 抽出レシピマスタ
- `pouring_steps`: 注湯ステップマスタ
- `coffee_masters`: 豆マスタ
※ `ミル`, `ドリッパー`, `フィルター` については、ログ内にID (`M001`, `D002` etc) が見られますが、マスタCSVがありません。これらもマスタ管理すべきため、新規にマスタ定義を追加します。

## 提案する変更

### プロジェクト構成
標準的な Flutter Web アプリを初期化します。

### データ層
#### [NEW] `lib/models/coffee_record.dart`
`coffee_data` に対応。ID, 日付, ミルID, ドリッパーID, フィルターID, 豆ID, 抽出パラメータ, 評価(1-10), 画像URLなどを保持。

#### [NEW] `lib/models/bean_master.dart`
`豆マスター` に対応。ID, 名前, 焙煎度, 産地, 画像URLなど。

#### [NEW] `lib/models/grinder_master.dart`
`ミルマスター` に対応。ID, 名前, 挽き目調整段階, 説明, 画像URL。

#### [NEW] `lib/models/dripper_master.dart`
`ドリッパーマスター` に対応。ID, 名前, 素材, 形状, 画像URL。

#### [NEW] `lib/models/filter_master.dart`
`フィルターマスター` に対応。ID, 名前, 素材, サイズ, 画像URL。

#### [NEW] `lib/models/method_master.dart`
`methods_master` に対応。レシピ情報。

#### [NEW] `lib/models/pouring_step.dart`
`pouring_steps` に対応。計算ロジック用の係数を含むステップ情報。

#### [NEW] `lib/services/sheets_service.dart`
Apps Script Web App (JSON API) と通信するサービスクラス。
`http` パッケージを使用。

### UI 層
#### [NEW] `lib/screens/home_screen.dart`
ダッシュボード。
- 最近の抽出状況サマリ
- 得点推移グラフ（折れ線グラフ等）
- 高得点ランキング（豆、機器、記録）
- 各機能へのナビゲーション

#### [NEW] `lib/screens/coffee_log_list_screen.dart`
日々の抽出記録 (`CoffeeRecord`) のリスト表示。

#### [NEW] `lib/screens/master_list_screen.dart`
各種マスタデータのリスト表示（タブ切り替えまたは個別画面への遷移）。
- 豆リスト (`BeanList`)
- レシピリスト (`MethodList`)
- ミルリスト (`GrinderList`)
- ドリッパーリスト (`DripperList`)
- フィルタリスト (`FilterList`)

#### [NEW] `lib/screens/statistics_screen.dart`
統計画面。
- 散布図（相関分析）
- 時系列グラフ
- レーダーチャート
※ フェーズ1では枠組みと簡単な可視化の実装を目指す。

#### [NEW] `lib/screens/calculator_screen.dart`
**コア機能**。
入力: メソッド選択, 豆量(g)。
処理: `pouring_steps` の係数と豆量を使用して、各ステップの湯量と時間を計算。
出力: 計算結果のステップリスト表示。タイマー機能への接続。

## 検証計画

### 自動テスト
- 計算ロジック（入力 g -> 出力ステップ）のユニットテスト。

### 手動検証
- `flutter run -d chrome` でアプリを起動。
- リストビューにデータが表示されるか確認（モックデータまたは実データ）。
- 特定のメソッドで20gを入力し、ステップが計算式通りか確認。
