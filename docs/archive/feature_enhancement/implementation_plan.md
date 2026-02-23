# 実装計画: Feature Enhancement (Cycle 5)

## 目的
ユーザー体験を向上させるため、Dashboardでの在庫管理、リスト表示の改善、Calculatorの機能強化を行う。

## 変更内容

### 1. Data Models & Service
- **`BeanMaster` (`lib/models/bean_master.dart`)**
    - フィールド追加: `purchaseDate` (DateTime?), `firstUseDate` (DateTime?), `lastUseDate` (DateTime?), `isInStock` (bool)
    - `SheetsService`: シートにカラムが未定義と想定されるため、モック的に現在日時を入れるか、あるいはローカル保存（SharedPreferences等）を検討する必要があるが、今回は簡易的に「全ての豆を在庫あり」とし、日付はランダムまたは固定値で埋める（あるいはシートに新カラムの想定を追加）。
    - *方針*: ユーザーは「管理項目を追加して」と言っているため、モデルに追加し、シートからの読み込みにも（将来的に）対応できるようにする。現時点では `null` 許容とし、UI側で編集可能にするのがベストだが、今回は表示のみの要望のため、ダミーデータまたはログからの逆算（Last Use）を実装する。
    - **Last Useの逆算**: `CoffeeRecord` の `beanId` と `brewedAt` を使って、最新の使用日を `BeanMaster` に動的に紐付ける（Providerで結合）。

### 2. Dashboard (`lib/screens/home_screen.dart`)
- **Inventory Section**: `BeanMaster` リストを表示。
    - `CoffeeRecord` から集計した `lastUseDate` を表示。
- **Recent Brews**:
    - `CoffeeRecord` のリストから、`totalTime == 0` や `methodId` が空のものを除外。
    - リストアイテムに `scoreOverall` をバッジ等で表示。

### 3. Log List & Details (`lib/screens/*_screen.dart`)
- **ID to Name**:
    - `flutter_riverpod` の `ref.watch` で `beanMasterProvider`, `methodMasterProvider` を取得し、IDから名前を引くヘルパー関数あるいはProviderを作成。
    - `CoffeeRecord` 自体にはIDしか保持しないため、UI側で解決する。
- **Log Detail**:
    - `Evaluation`: `SpiderChart` ウィジェット（既存にあれば利用、なければ `fl_chart` 等または簡易表示）を表示。データがない場合は非表示。
    - `Temperature`: `temperature` フィールドを表示（データ読み込み修正で解決済みのはずだが確認）。
    - `Total Time`: `mm:ss` フォーマット。

### 4. Brewing Calculator (`lib/screens/calculator_screen.dart`)
- **Proportional Update**:
    - `_beanWeightController` の変更を検知し、`_workingSteps` の `waterAmount` を `(NewWeight / OldWeight)` 比率で更新するロジックを実装。
- **Timer**:
    - `Stopwatch` クラスを使用した簡易タイマーウィジェットを追加（Start/Stop/Reset）。
- **UI Layout**:
    - Add/Save ボタンを Table の下（右寄せ）に配置。

### 5. Swipe to Copy
- `LogListScreen` の `ListView` を `Dismissible` または `Slidable` でラップ（あるいは `InkWell` の `onLongPress` か、明示的なコピーボタン）。
- スワイプ -> 「このレシピで淹れる」 -> `CalculatorScreen` に遷移し、ログの `PouringSteps` (Methodから取得、あるいはログ自体にStep情報があればそれ) を展開。
    - *注意*: ログには `steps` は保存されていない（`methodId` のみ）。したがって、`methodId` に紐づく `MethodMaster` -> `PouringSteps` をロードして Calculator に渡す。

## 検証計画
`flutter run` で動作確認。
