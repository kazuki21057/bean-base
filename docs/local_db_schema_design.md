# ローカルDB(drift)スキーマ設計書 — T5-B11

- 作成日: 2026-08-21(T5-B11、architect)
- 対象: トラックB(公開版=Android)の永続化バックエンド。`AppEdition.useLocalDb == true` のときに使う端末内SQLite。
- 前提: パッケージ選定は`docs/research/2026-08-21_local_db.md`で **drift** に確定済み。
- この設計書の位置づけ: **T5-B12(マイグレーション基盤)・T5-B13(`LocalDbService`)・T5-B14(画像ローカル保存)・T5-B15(エクスポート/インポート)の正本**。implementerはここに書かれた名前・型・挙動をそのまま実装し、設計判断をしない。ここに無い判断が必要になったら実装を止めてarchitectへ差し戻す。

---

## 0. 絶対規則(実装時に必ず守る)

1. **既存のモデルクラス(`lib/models/`)を書き換えない。** driftの生成する行クラス(`*Row`)は別物として扱い、`lib/db/mappers.dart`の変換関数でモデルへ橋渡しする。`DataService`の契約(引数・戻り値の型)は一切変えない。
2. **`DataService`の44メソッドの外形的な挙動をSheets版と一致させる。** 一致させない箇所は§7.2に列挙した5点だけ(それ以外の差異を実装者判断で入れない)。
3. **テーブル名はGoogle Sheetsのシート名と完全一致させる**(`bean_master`・`coffee_data`など)。列名は日本語ではなくDartフィールド名のsnake_caseとし、日本語シート列名との対応は§6の対応表と、T5-B15で実装する変換マップだけが持つ。
4. **外部キー制約(FOREIGN KEY)を張らない。** 理由は§4.4。
5. **IDは呼び出し側が生成した文字列をそのまま格納する。** `LocalDbService`はIDを生成しない(§5)。
6. スキーマを変更するときは必ず§8の手順(バージョンを上げる → `make-migrations` → 生成テスト実行)を踏む。手書きの`onUpgrade`にSQLを直書きしない。

---

## 1. 追加する依存とファイル配置

### 1.1 pubspec

`flutter pub add drift drift_flutter` および `flutter pub add dev:drift_dev` で追加する(**バージョンは決め打ちにせず解決結果をそのままpubspecに残す**。調査時点の値は変動しうるため——`docs/research/2026-08-21_local_db.md`「変動しうる情報への注記」)。`drift_flutter`は`sqlite3_flutter_libs`と`path_provider`の配線を内包するため、この2つを直接追加する必要はない(`path_provider`は既に依存にある)。`build_runner`・`json_serializable`は既存のものをそのまま使う。

### 1.2 `build.yaml`(新規または既存へ追記)

列名の変換規則を**明示的に固定する**(driftの既定値に依存しない)。

```yaml
targets:
  $default:
    builders:
      drift_dev:
        options:
          case_from_dart_to_sql: snake_case
```

### 1.3 ファイル配置

| パス | 内容 | 作成タスク |
|---|---|---|
| `lib/db/tables.dart` | 12個のテーブル定義クラス | T5-B12 |
| `lib/db/local_database.dart` | `@DriftDatabase`付きの`LocalDatabase`クラス、`schemaVersion`、`MigrationStrategy`、接続生成 | T5-B12 |
| `lib/db/schema_versions.dart` | **生成物**(`make-migrations`が出力)。手で編集しない | T5-B12 |
| `drift_schemas/` | **生成物**。バージョンごとのスキーマJSON。gitにコミットする | T5-B12 |
| `lib/db/mappers.dart` | 行クラス↔既存モデルの相互変換(extension) | T5-B13 |
| `lib/services/local_db_service.dart` | `LocalDbService implements DataService`、`LocalDbException` | T5-B13 |
| `test/db/local_database_test.dart` | CRUD・型往復のユニットテスト | T5-B12/B13 |
| `test/db/migration_test.dart` | **生成物ベース**のマイグレーションテスト | T5-B12 |

コード生成は `dart run build_runner build --force-jit`(`--delete-conflicting-outputs`はbuild_runner 2.15.1で廃止済みのため使わない)。

---

## 2. データベースクラスの定義(`lib/db/local_database.dart`)

```
@DriftDatabase(tables: [
  CoffeeDataTable, BeanMasterTable, MethodsMasterTable, PouringStepsTable,
  MillMasterTable, DripperMasterTable, FilterMasterTable, OriginMasterTable,
  StoreMasterTable, BeanPurchasesTable, AnalysisHistoryTable, RecipeSuggestionsTable,
])
class LocalDatabase extends _$LocalDatabase { ... }
```

確定事項:

- **クラス名**: `LocalDatabase`。
- **DBファイル名**: `driftDatabase(name: 'bean_base')` を使う(`drift_flutter`。実ファイルは端末のアプリサポートディレクトリに`bean_base.sqlite`として作られる)。
- **`schemaVersion`**: 初期値 **1**(§8)。
- **日時の保存形式**: コンストラクタで `options: const DriftDatabaseOptions(storeDateTimeAsText: true)` を指定する。**ISO-8601のテキストで保存する**(理由: Sheetsの保存形式と揃い、エクスポートJSONがそのまま人間に読め、`ORDER BY`が文字列比較で正しく効く)。
  - **注意(未検証)**: テキストモードでのタイムゾーンの往復(UTC保存→読み出し時のローカル変換)の挙動は実測していない。T5-B12のテストに「`DateTime`を書いて読み戻し、`readBack.isAtSameMomentAs(original)`が真」というケースを**必ず**入れて確認すること。ずれた場合はarchitectへ差し戻す(勝手に`storeDateTimeAsText: false`へ変えない。Sheets互換のエクスポート形式に影響するため)。
- **`MigrationStrategy`**:
  - `onCreate`: `await m.createAll();` の後に §9 の初期データ投入を行う。
  - `onUpgrade`: `stepByStep(...)`(`schema_versions.dart`の生成物)を使う。バージョン1しかない現時点では中身は空。
  - `beforeOpen`: 何もしない(外部キーを使わないため`PRAGMA foreign_keys`の設定は不要)。
- **Riverpod配線**(T5-B13):
  - `lib/providers/data_providers.dart` に `final localDatabaseProvider = Provider<LocalDatabase>((ref) { final db = LocalDatabase(); ref.onDispose(db.close); return db; });` を追加する。
  - `lib/services/data_service.dart` の `dataServiceProvider` の `throw UnimplementedError('LocalDbService is not yet implemented (T5-B13)')` を `return LocalDbService(ref.watch(localDatabaseProvider));` に置き換える。**インスタンスはアプリ全体で1つ**(driftは同一ファイルを複数インスタンスで開くと警告を出す)。

---

## 3. 型変換の規則(全テーブル共通)

Dartモデルのフィールド型から**機械的に**決める。個別の判断をしない。

| モデルの型と既定値 | drift定義 | SQL |
|---|---|---|
| `String`(非null、`@JsonKey(defaultValue: '')`) | `text().withDefault(const Constant(''))` | `TEXT NOT NULL DEFAULT ''` |
| `String`(非null、`@JsonKey(defaultValue: '-')`) | `text().withDefault(const Constant('-'))` | `TEXT NOT NULL DEFAULT '-'` |
| `String?` | `text().nullable()` | `TEXT` |
| `double`(非null) | `real().withDefault(const Constant(0.0))` | `REAL NOT NULL DEFAULT 0.0` |
| `double?` | `real().nullable()` | `REAL` |
| `int`(非null) | `integer().withDefault(const Constant(0))` | `INTEGER NOT NULL DEFAULT 0` |
| `bool`(非null、既定false) | `boolean().withDefault(const Constant(false))` | `INTEGER NOT NULL DEFAULT 0` |
| `bool?`(3値) | `boolean().nullable()` | `INTEGER` |
| `DateTime`(非null) | `dateTime()` | `TEXT NOT NULL`(既定値なし。呼び出し側が必ず与える) |
| `DateTime?` | `dateTime().nullable()` | `TEXT` |
| ID(主キー) | `text()` + `@override Set<Column> get primaryKey => {id};` | `TEXT NOT NULL PRIMARY KEY` |

補足:

- **主キーに`autoIncrement`を使わない。** IDは常にアプリ生成の文字列(§5)。
- **`id`列にだけは`withDefault`を付けない**(空IDの混入を防ぐため。空文字チェックは`LocalDbService`側で行う、§5)。
- 画像URL列は**すべて`TEXT`のまま**。T5-B14でDrive URLから端末内ファイルパスへ意味が変わるが、**型も列名も変えないためスキーマ移行は不要**(T5-B14はマイグレーションを伴わない)。

---

## 4. テーブル定義(12テーブル / 全138列)

各表の見方: 「SQL列名」はdriftが`snake_case`変換で生成する実際の列名、「drift定義」は`lib/db/tables.dart`に書くゲッターの本体、「モデル」は対応する既存Dartモデルのフィールド、「Sheets列」は§6の対応表と同じ日本語列名。

### 4.1 `coffee_data`(抽出記録) — 31列

テーブルクラス `CoffeeDataTable` / `@DataClassName('CoffeeDataRow')` / `@override String get tableName => 'coffee_data';` / 対応モデル `CoffeeRecord`

| SQL列名 | drift定義(ゲッター名 = モデルのフィールド名) | モデル型 | Sheets列 |
|---|---|---|---|
| `id` | `text()` **PK** | String | 記録ID |
| `brewed_at` | `dateTime()` | DateTime | 記録日 |
| `grinder_id` | `text().withDefault(const Constant(''))` | String | ミル |
| `dripper_id` | 同上 | String | ドリッパー |
| `filter_id` | 同上 | String | フィルター |
| `bean_id` | 同上 | String | 豆名 |
| `roast_level` | 同上 | String | 焙煎度 |
| `origin` | 同上 | String | 産地 |
| `origin_id` | 同上 | String | 産地ID |
| `bean_weight` | `real().withDefault(const Constant(0.0))` | double | 豆の量(g) |
| `grind_size` | `text().withDefault(const Constant(''))` | String | 挽き目 |
| `method_id` | 同上 | String | 抽出方法 |
| `taste` | 同上 | String | 味 |
| `concentration` | 同上 | String | 濃度 |
| `temperature` | `real().withDefault(const Constant(0.0))` | double | 湯温(℃) |
| `blooming_water` | 同上 | double | 蒸らし湯量(ml) |
| `total_water` | 同上 | double | 湯量(ml) |
| `blooming_time` | `integer().withDefault(const Constant(0))` | int | 蒸らし時間(秒) |
| `total_time` | 同上 | int | 抽出時間(秒) |
| `score_fragrance` | 同上 | int | 香り(1-10) |
| `score_acidity` | 同上 | int | 酸味(1-10) |
| `score_bitterness` | 同上 | int | 苦味(1-10) |
| `score_sweetness` | 同上 | int | 甘味(1-10) |
| `score_complexity` | 同上 | int | 複雑さ(1-10) |
| `score_flavor` | 同上 | int | フレーバー(1-10) |
| `score_overall` | 同上 | int | 総合評価(1-10) |
| `comment` | `text().withDefault(const Constant(''))` | String | コメント |
| `grinder_image_url` | `text().nullable()` | String? | ミル写真URL |
| `dripper_image_url` | 同上 | String? | ドリッパー写真URL |
| `filter_image_url` | 同上 | String? | フィルタ写真URL |
| `bean_image_url` | 同上 | String? | 豆写真URL |

**注意**: Sheetsの`ミル`/`ドリッパー`/`フィルター`/`豆名`列は**名前に反してIDを格納している**(`SheetsService.getCoffeeRecords`のkeyMapで確認済み)。`豆名`はシートによって意味が違う(`coffee_data`ではID、`bean_master`では名称)ため、T5-B15の変換マップは**必ずシートごとに持つ**こと。

`brewRatio`は`CoffeeRecord`の導出getterであり**列を作らない**(json_serializableの対象外であることはモデル内コメントで確認済み)。

インデックス: `@TableIndex(name: 'idx_coffee_data_brewed_at', columns: {#brewedAt})`、`@TableIndex(name: 'idx_coffee_data_bean_id', columns: {#beanId})`、`@TableIndex(name: 'idx_coffee_data_method_id', columns: {#methodId})`。

### 4.2 `bean_master`(豆マスタ) — 21列

テーブルクラス `BeanMasterTable` / `@DataClassName('BeanMasterRow')` / `tableName = 'bean_master'` / 対応モデル `BeanMaster`

| SQL列名 | drift定義 | モデル型 | Sheets列 |
|---|---|---|---|
| `id` | `text()` **PK** | String | 豆ID |
| `name` | `text().withDefault(const Constant('-'))` | String | 豆名 |
| `roast_level` | `text().withDefault(const Constant(''))` | String | 焙煎度 |
| `origin` | 同上 | String | 産地 |
| `store` | 同上 | String | 購入店舗 |
| `type` | 同上 | String | 豆の種類 |
| `image_url` | `text().nullable()` | String? | 豆画像URL |
| `bean_image_url` | `text().nullable()` | String? | 豆粒画像URL |
| `info_image_url` | `text().nullable()` | String? | 情報画像URL |
| `purchase_date` | `dateTime().nullable()` | DateTime? | 購入日 |
| `first_use_date` | 同上 | DateTime? | 開封日 |
| `last_use_date` | 同上 | DateTime? | 使い切り日 |
| `is_in_stock` | `boolean().withDefault(const Constant(false))` | bool | 在庫 |
| `initial_quantity_grams` | `real().nullable()` | double? | 初期購入量(g) |
| `origin_id` | `text().withDefault(const Constant(''))` | String | 産地ID |
| `roast_date` | `dateTime().nullable()` | DateTime? | 焙煎日 |
| `stock_baseline_grams` | `real().nullable()` | double? | 在庫基準量(g) |
| `stock_baseline_at` | `dateTime().nullable()` | DateTime? | 在庫基準日時 |
| `storage_location` | `text().withDefault(const Constant(''))` | String | 保存場所 |
| `seek_optimal_conditions` | `boolean().nullable()` | bool?(3値) | 最適条件探索 |
| `store_id` | `text().withDefault(const Constant(''))` | String | 購入店ID |

**`seek_optimal_conditions`のNULLは「未回答」を意味する**(`false`=探索しない、と区別する)。Sheets側では空文字が未回答なので、T5-B15のインポートでは**空文字→NULL**、エクスポートでは**NULL→空文字**に変換する。

インデックス: `@TableIndex(name: 'idx_bean_master_store_id', columns: {#storeId})`、`@TableIndex(name: 'idx_bean_master_origin_id', columns: {#originId})`。

### 4.3 `methods_master`(メソッドマスタ) — 13列

テーブルクラス `MethodsMasterTable` / `@DataClassName('MethodsMasterRow')` / `tableName = 'methods_master'` / 対応モデル `MethodMaster`

| SQL列名 | drift定義 | モデル型 | Sheets列 |
|---|---|---|---|
| `id` | `text()` **PK** | String | メソッドID |
| `name` | `text().withDefault(const Constant('-'))` | String | メソッド名 |
| `author` | `text().withDefault(const Constant(''))` | String | 発案者 |
| `base_bean_weight` | `real().withDefault(const Constant(0.0))` | double | 基準豆量(g) |
| `base_water_amount` | 同上 | double | 基準湯量(ml) |
| `temperature` | `real().nullable()` | double? | 湯温（℃） |
| `grind_size` | `text().nullable()` | String? | 挽き目（Kingrinder K6） |
| `description` | `text().withDefault(const Constant(''))` | String | 説明 |
| `recommended_equipment` | 同上 | String | 推奨機器 |
| `source_url` | `text().nullable()` | String? | ソース |
| `recommended_roast_level` | `text().nullable()` | String? | 推奨焙煎度 |
| `recommended_roast_min` | `text().nullable()` | String? | 推奨焙煎度(最浅) |
| `recommended_roast_max` | `text().nullable()` | String? | 推奨焙煎度(最深) |

**Sheets列名の全角括弧に注意**: `湯温（℃）`・`挽き目（Kingrinder K6）`は**全角**、`coffee_data`の`湯温(℃)`は**半角**。T5-B15の変換マップは1文字も変えずに写すこと。

インデックスなし(件数が少ないため)。

### 4.4 `pouring_steps`(注湯ステップ) — 8列

テーブルクラス `PouringStepsTable` / `@DataClassName('PouringStepRow')` / `tableName = 'pouring_steps'` / 対応モデル `PouringStep`

| SQL列名 | drift定義 | モデル型 | Sheets列 |
|---|---|---|---|
| `id` | `text()` **PK** | String | ID |
| `method_id` | `text().withDefault(const Constant(''))` | String | メソッドID（親） |
| `step_order` | `integer().withDefault(const Constant(0))` | int | 並び順 |
| `duration` | 同上 | int | 加算時間（秒） |
| `water_amount` | `real().withDefault(const Constant(0.0))` | double | 加算湯量（ml） |
| `water_reference` | 同上 | double | 湯量基準(豆量15g) |
| `water_ratio` | `real().nullable()` | double? | 湯量係数 |
| `description` | `text().withDefault(const Constant(''))` | String | 注意事項 |

インデックス: `@TableIndex(name: 'idx_pouring_steps_method_id', columns: {#methodId, #stepOrder})`。

**外部キー制約を張らない理由(§0-4の根拠)**: Sheetsにはリレーショナル整合性が無く、本番データには削除済みマスタを指す`beanId`/`methodId`や空文字IDが実在しうる。FKを宣言するとT5-B15のインポートがそこで失敗し、公開版ユーザーのデータ復元が壊れる(データ消失クレームはレビュー低評価の最大要因——マスタープラン T5-B15の注記)。整合性は従来どおりアプリ側で扱い、DBは素通しにする。

### 4.5 `mill_master`(グラインダーマスタ) — 5列

`MillMasterTable` / `@DataClassName('MillMasterRow')` / `tableName = 'mill_master'` / モデル `GrinderMaster`

| SQL列名 | drift定義 | モデル型 | Sheets列 |
|---|---|---|---|
| `id` | `text()` **PK** | String | ミルID |
| `name` | `text().withDefault(const Constant('-'))` | String | ミル名 |
| `grind_range` | `text().nullable()` | String? | 挽き目調整段階 |
| `description` | `text().nullable()` | String? | 説明 |
| `image_url` | `text().nullable()` | String? | ミル画像URL |

`grindSteps`は`GrinderMaster`の導出getterなので**列を作らない**。

### 4.6 `dripper_master`(ドリッパーマスタ) — 5列

`DripperMasterTable` / `@DataClassName('DripperMasterRow')` / `tableName = 'dripper_master'` / モデル `DripperMaster`

| SQL列名 | drift定義 | モデル型 | Sheets列 |
|---|---|---|---|
| `id` | `text()` **PK** | String | ドリッパーID |
| `name` | `text().withDefault(const Constant('-'))` | String | ドリッパー名 |
| `material` | `text().nullable()` | String? | 素材 |
| `shape` | `text().nullable()` | String? | 形状 |
| `image_url` | `text().nullable()` | String? | ドリッパー画像URL |

### 4.7 `filter_master`(フィルターマスタ) — 5列

`FilterMasterTable` / `@DataClassName('FilterMasterRow')` / `tableName = 'filter_master'` / モデル `FilterMaster`

| SQL列名 | drift定義 | モデル型 | Sheets列 |
|---|---|---|---|
| `id` | `text()` **PK** | String | フィルターID |
| `name` | `text().withDefault(const Constant('-'))` | String | フィルター名 |
| `material` | `text().nullable()` | String? | 素材 |
| `size` | `text().nullable()` | String? | サイズ |
| `image_url` | `text().nullable()` | String? | フィルター画像URL |

**`size`はTEXT**(`FilterMaster.size`が`String?`で、Sheetsが数値を返しても`_parseString`で文字列化している。`02`のような前ゼロ表記を壊さないため数値にしない)。

### 4.8 `origin_master`(産地マスタ) — 5列

`OriginMasterTable` / `@DataClassName('OriginMasterRow')` / `tableName = 'origin_master'` / モデル `OriginMaster`

| SQL列名 | drift定義 | モデル型 | Sheets列 |
|---|---|---|---|
| `id` | `text()` **PK** | String | 産地ID |
| `country_code` | `text().withDefault(const Constant(''))` | String | 国コード |
| `name_ja` | 同上 | String | 産地名 |
| `name_en` | 同上 | String | 産地名(英) |
| `region` | 同上 | String | 地域 |

### 4.9 `store_master`(購入店マスタ) — 19列

`StoreMasterTable` / `@DataClassName('StoreMasterRow')` / `tableName = 'store_master'` / モデル `StoreMaster`

| SQL列名 | drift定義 | モデル型 | Sheets列 |
|---|---|---|---|
| `id` | `text()` **PK** | String | 購入店ID |
| `name` | `text().withDefault(const Constant('-'))` | String | 店名 |
| `formal_name` | `text().withDefault(const Constant(''))` | String | 正式名称 |
| `url` | 同上 | String | URL |
| `prefecture` | 同上 | String | 都道府県 |
| `address` | 同上 | String | 住所 |
| `has_online_shop` | `boolean().withDefault(const Constant(false))` | bool | オンライン販売 |
| `has_physical_store` | 同上 | bool | 実店舗 |
| `has_roastery` | 同上 | bool | 焙煎所併設 |
| `bean_tendency` | `text().withDefault(const Constant(''))` | String | 取扱豆の傾向 |
| `memo` | 同上 | String | メモ |
| `image_url` | `text().nullable()` | String? | 店舗画像URL |
| `sns_url` | `text().withDefault(const Constant(''))` | String | SNS |
| `business_hours` | 同上 | String | 営業時間 |
| `closed_days` | 同上 | String | 定休日 |
| `phone` | 同上 | String | 電話番号 |
| `opened_year` | 同上 | String | 開業年 |
| `source_url` | 同上 | String | 情報取得元 |
| `info_fetched_at` | `dateTime().nullable()` | DateTime? | 情報取得日 |

**`opened_year`はTEXT**(モデルが`String`。`2019`のような値でも数値化しない)。

### 4.10 `bean_purchases`(購入履歴) — 9列

`BeanPurchasesTable` / `@DataClassName('BeanPurchaseRow')` / `tableName = 'bean_purchases'` / モデル `BeanPurchase`

| SQL列名 | drift定義 | モデル型 | Sheets列 |
|---|---|---|---|
| `id` | `text()` **PK** | String | 購入ID |
| `bean_id` | `text().withDefault(const Constant(''))` | String | 豆ID |
| `purchased_at` | `dateTime().nullable()` | DateTime? | 購入日 |
| `roast_date` | 同上 | DateTime? | 焙煎日 |
| `quantity_grams` | `real().nullable()` | double? | 購入量(g) |
| `store_id` | `text().withDefault(const Constant(''))` | String | 購入店ID |
| `store_name` | 同上 | String | 購入店名 |
| `memo` | 同上 | String | メモ |
| `created_at` | `dateTime().nullable()` | DateTime? | 登録日時 |

インデックス: `@TableIndex(name: 'idx_bean_purchases_bean_id', columns: {#beanId})`。

### 4.11 `analysis_history`(解析スナップショット) — 5列

`AnalysisHistoryTable` / `@DataClassName('AnalysisHistoryRow')` / `tableName = 'analysis_history'` / モデル `AnalysisSnapshot`

| SQL列名 | drift定義 | モデル型 | Sheets列 |
|---|---|---|---|
| `id` | `text()` **PK** | String | 履歴ID |
| `created_at` | `dateTime()` | DateTime(非null) | 作成日時 |
| `type` | `text().withDefault(const Constant(''))` | String | 種別 |
| `data_count` | `integer().withDefault(const Constant(0))` | int | データ件数 |
| `payload_json` | `text().withDefault(const Constant(''))` | String | 本文JSON |

インデックス: `@TableIndex(name: 'idx_analysis_history_type', columns: {#type})`(`fetchAnalysisSnapshots(type:)`の絞り込みに使う)。

### 4.12 `recipe_suggestions`(レシピ提案) — 12列

`RecipeSuggestionsTable` / `@DataClassName('RecipeSuggestionRow')` / `tableName = 'recipe_suggestions'` / モデル `RecipeSuggestion`

| SQL列名 | drift定義 | モデル型 | Sheets列 |
|---|---|---|---|
| `id` | `text()` **PK** | String | 提案ID |
| `created_at` | `dateTime()` | DateTime(非null) | 作成日時 |
| `bean_id` | `text().withDefault(const Constant(''))` | String | 豆ID |
| `origin_id` | 同上 | String | 産地ID |
| `roast_level` | 同上 | String | 焙煎度 |
| `method_id` | 同上 | String | メソッドID |
| `temperature` | `real().withDefault(const Constant(0.0))` | double | 湯温 |
| `brew_ratio` | 同上 | double | 湯豆比 |
| `total_time_sec` | `integer().withDefault(const Constant(0))` | int | 抽出時間 |
| `rationale` | `text().withDefault(const Constant(''))` | String | 提案根拠 |
| `accepted` | 同上 | String | 採否 |
| `result_record_id` | 同上 | String | 結果記録ID |

**`accepted`はboolではなくTEXT**(モデルが`String`。空文字=未回答という3値運用のため)。

インデックス: `@TableIndex(name: 'idx_recipe_suggestions_bean_id', columns: {#beanId})`。

### 4.13 テーブルを作らないモデル

- `PendingBrewInfo`(`lib/models/pending_brew_info.dart`): 030→031画面間の受け渡し専用でSheetsにも永続化していない。**テーブルを作らない。**
- `CoffeeRecord.brewRatio` / `GrinderMaster.grindSteps`: 導出getterのため列を作らない。

---

## 5. ID(外部ID処理の一貫性)

### 5.1 現状の事実

- IDは**画面側で生成**されている。`DateTime.now().millisecondsSinceEpoch.toString()`(例: `lib/screens/create/bean_create_screen.dart:495`、`grinder_create_screen.dart:63`、`dripper_create_screen.dart:73`、`filter_create_screen.dart:73`、`method_create_screen.dart:133`、`store_create_screen.dart:328`、`brew_evaluation_screen.dart:222`)、接頭辞付きの派生形(`bp_`=購入履歴 `bean_detail_screen.dart:183`、`snap_`=解析履歴、`sugg_`=レシピ提案、`new_`=注湯ステップ)、および固定スラッグ(`origin_1`〜`origin_15`、`store_navy`等)が混在する。
- `SheetsService`が`.toString()`でキャストしているのは、**Sheetsが数字だけのIDを数値セルとして返す**ため(`_remapKeys`のnum→String変換、`CLAUDE.md`の規約、教訓T3-67)。

### 5.2 確定する方針

1. **UUIDを導入しない。ID生成方法を変えない。** 既存の画面コードは公開版でもそのまま使うため、生成規則を変えると`lib/screens/`の広範な変更とデータ互換性の議論が必要になり、T5-B13のスコープを超える。IDの型は今後も**アプリ生成の文字列**とする。
2. **`LocalDbService`はIDを生成しない。** 受け取った`model.id`をそのまま主キーに入れる。
3. **空IDは弾く。** すべての`add*`/`update*`/`save*`の冒頭で `if (id.trim().isEmpty) throw const LocalDbException('IDが空のため保存できません。');`、`delete*`の冒頭で `if (id.trim().isEmpty) throw const LocalDbException('IDが空のため削除できません。');` を実行する。**これはSheets版には無い新しい制約**であり、その理由は§7.2-5に記す。
4. **ローカルDBでは数値化の問題が原理的に起きない**(列型がTEXTでSQLiteは入れた文字列をそのまま返すため)。したがって`LocalDbService`側に`.toString()`変換は**書かない**。
5. **`.toString()`正規化が必要なのは「外から来たJSON」を読むときだけ**。すなわち**T5-B15のインポート処理**だけが以下の正規化を行う:
   - `normalizeExternalId(dynamic v) => v == null ? '' : v.toString().trim();`
   - 置き場所: `lib/services/import_export_service.dart`(T5-B15で新設)のトップレベル関数。`LocalDbService`にも`SheetsService`にも置かない。
   - 適用対象: 列名が`ID`で終わる/`id`にマップされる全列(`id`・`beanId`・`originId`・`storeId`・`methodId`・`grinderId`・`dripperId`・`filterId`・`resultRecordId`)。
   - `1.0`のような小数表記で来た数値ID(SheetsのJSONは`double`になりうる)は、`v is num && v == v.roundToDouble() ? v.toInt().toString() : v.toString()` で**整数表記へ寄せる**。これをしないとpersonal版でIDが`123`、インポート後に`123.0`となり突合が壊れる。
6. **突合キー**: エクスポート/インポート・将来のpersonal↔public相互運用における一致判定は、**常に上記で正規化した文字列IDの完全一致**とする。名称(豆名・店名など)での突合はしない。

---

## 6. Sheets ↔ ローカルDB 対応表(サマリ)

列レベルの対応は§4の各表の「Sheets列」欄が正本。テーブル単位のサマリは以下。

| Sheetsシート名 | ローカルDBテーブル名 | 列数 | Dartモデル | 備考 |
|---|---|---|---|---|
| `coffee_data` | `coffee_data` | 31 | `CoffeeRecord` | 日本語列名がIDを保持する列あり(§4.1) |
| `bean_master` | `bean_master` | 21 | `BeanMaster` | 3値列あり(§4.2) |
| `methods_master` | `methods_master` | 13 | `MethodMaster` | 列名に全角括弧(§4.3) |
| `pouring_steps` | `pouring_steps` | 8 | `PouringStep` | ID列名が`ID`のみ |
| `mill_master` | `mill_master` | 5 | `GrinderMaster` | クラス名は Grinder、シート/テーブル名は mill |
| `dripper_master` | `dripper_master` | 5 | `DripperMaster` | |
| `filter_master` | `filter_master` | 5 | `FilterMaster` | |
| `origin_master` | `origin_master` | 5 | `OriginMaster` | 初期15件をシード(§9) |
| `store_master` | `store_master` | 19 | `StoreMaster` | 公開版ではシードしない(§9) |
| `bean_purchases` | `bean_purchases` | 9 | `BeanPurchase` | |
| `analysis_history` | `analysis_history` | 5 | `AnalysisSnapshot` | |
| `recipe_suggestions` | `recipe_suggestions` | 12 | `RecipeSuggestion` | |

**Sheets列名の正本は`SheetsService`の`keyMap`/`reverseMap`**(`lib/services/sheets_service.dart`)と`gas/Code.gs`の`NEW_SHEET_HEADERS`/`EXISTING_SHEET_EXTRA_COLUMNS`。T5-B15の変換マップは**この2箇所から機械的に写し、独自の列名を発明しない**。

### 6.1 T5-B15(エクスポート/インポート)の形式

将来のpersonal↔public相互運用のため、**エクスポートJSONのキーは日本語シート列名に揃える**(Sheetsから`?sheet=`でGETした生JSONと同じ形。これによりpersonal版のデータをそのまま公開版へ流し込める)。

```json
{
  "formatVersion": 1,
  "schemaVersion": 1,
  "exportedAt": "2026-08-21T12:34:56.000Z",
  "tables": {
    "bean_master": [ { "豆ID": "1712345678901", "豆名": "...", "在庫": true } ],
    "coffee_data": [ ... ]
  }
}
```

- `schemaVersion`はエクスポート時の`LocalDatabase.schemaVersion`を書く。インポート時に**自分より新しい**`schemaVersion`のファイルを渡されたら、取り込まずに日本語エラー(「このバックアップは新しいバージョンのアプリで作成されています。アプリを更新してから読み込んでください。」)を出す。同じか古い場合は取り込む(古い形式の欠損列は§3の既定値で埋まる)。
- インポートは**トランザクション1つ**で全テーブルを`insertOnConflictUpdate`(upsert)する。途中で失敗したら全ロールバックし、「読み込みに失敗しました。データは変更されていません。」と表示する。
- CSVは1テーブル=1ファイルとし、ヘッダー行に日本語列名を書く(同じ対応表を使う)。

---

## 7. `LocalDbService`(T5-B13)の実装規約

### 7.1 メソッドごとの実装パターン

`DataService`の44メソッドは以下の5パターンのいずれか。個別判断は不要。

| パターン | 対象 | 実装 |
|---|---|---|
| 一覧取得 `getXxx()` / `fetchXxx()` | 12種 | `(select(table)..orderBy([(t) => OrderingTerm.asc(t.rowId)])).get()` → `mappers.dart`でモデルへ変換 |
| 追加 `addXxx()` | 9種 | `into(table).insert(companion)`。主キー重複時は`LocalDbException('既に同じIDのデータが存在します(ID: $id)')`(§7.2-4) |
| 更新 `updateXxx()` | 10種 | `update(table).replace(row)`。戻り値が`false`(0行)なら`LocalDbException('更新対象のデータが見つかりません(ID: $id)')` |
| 削除 `deleteXxx(String id)` | 9種 | `(delete(table)..where((t) => t.id.equals(id))).go()`。**0行でも例外にしない**(Sheets版が黙って無視していた挙動に合わせる) |
| 保存(upsert) `saveOriginMaster` / `saveAnalysisSnapshot` / `saveRecipeSuggestion` | 3種 | `into(table).insertOnConflictUpdate(companion)` |
| 一括削除 `deletePouringStepsForMethod(String methodId)` | 1種 | 上記4パターンのどれにも当てはまらない唯一のメソッド。**§7.2-1のとおり新規に実装する**(Sheets版は中身が空) |

内訳の合計: 12 + 9 + 10 + 9 + 3 + 1 = **44メソッド**(`lib/services/data_service.dart`の全メソッド数と一致する)。

- **並び順**: 全一覧取得を`rowid`昇順(=登録順)にする。Sheetsが行の並び=追記順で返していたのと一致し、画面側のソート前提を壊さない。driftの`t.rowId`が使えない場合は`customOrderBy`等で`rowid ASC`を指定する(**この2つ以外の順序にしない**)。
- **`fetchAnalysisSnapshots({String? type})`**: `type`が非nullなら`..where((t) => t.type.equals(type))`をSQLで適用する(Sheets版はDart側で`where`していたが結果は同じ)。
- **`updateRecipeSuggestion`**: パターン「更新」。

### 7.2 Sheets版とあえて挙動を変える5点

1. **`deletePouringStepsForMethod(String methodId)`**: Sheets版は**中身が空の未実装**(`sheets_service.dart:611-621`)。ローカル版では `(delete(pouringStepsTable)..where((t) => t.methodId.equals(methodId))).go()` を**実装する**。メソッド削除時の孤児ステップが残らなくなる(改善)。
2. **重複ID・存在しないIDの扱い**: Sheets版はGASが`{error: ...}`をHTTP 200で返すため呼び出し側が気づけなかった。ローカル版は§7.1のとおり**日本語メッセージの`LocalDbException`を投げる**。UI側は既存のtry/catchでSnackBar表示に載る。
3. **取得失敗時**: Sheets版は通信失敗時に空リストを返していた(`_fetchData`のcatch)。ローカル版は**空リストで握り潰さず例外を投げる**(ローカルDBの読み取り失敗はネットワーク断と違い、握り潰すとデータ消失に見えるため)。
4. **重複IDの追加を拒否する**: Sheets版の`addRow`(`gas/Code.gs:212-223`)は既存IDの有無を見ずに`appendRow`するため、同じIDの行が2つできても通る。ローカル版は主キー制約でSQLiteが機械的に弾くため**そもそも黙って通すことができない**。DB例外をそのまま漏らさず§7.1の日本語`LocalDbException`へ包み直す。
5. **空IDの保存・削除を拒否する**: Sheets版は`addRow`が空IDでも1行追記でき(`updateRow`/`deleteRow`だけがID未指定を`{error: ...}`で返すが、`_postData`はHTTP 200のためアプリ側は成功として扱う)、結果として空ID行が本番シートに残りうる。ローカル版は主キーTEXTの空文字を許すとその1行が「全ての空ID保存」に上書きされ続けるため、**`add`/`update`/`save`/`delete`の入口で明示的に弾く**(§5-3)。

**4・5は「Sheetsの挙動をそのまま真似ると壊れる」ためにやむを得ず変える**もので、1〜3のような機能改善とは性質が異なる。どちらもユーザーには日本語のSnackBarとして見える。

### 7.3 例外クラス

```
class LocalDbException implements Exception {
  final String message;        // 日本語のユーザー向け文言
  const LocalDbException(this.message);
  @override String toString() => message;
}
```

置き場所は`lib/services/local_db_service.dart`。すべての例外送出の直前に `debugPrint('[Antigravity] ローカルDBエラー: $message');` を出す(`CLAUDE.md`のログ規約)。正常系の書き込みも `debugPrint('[Antigravity] ローカルDB: $tableName へ$action(ID: $id)');` を出す(Sheets版の`_postData`と同じ粒度)。

### 7.4 マッパー(`lib/db/mappers.dart`)

- `extension BeanMasterRowMapper on BeanMasterRow { BeanMaster toModel() => ... }`
- `extension BeanMasterCompanionMapper on BeanMaster { BeanMasterTableCompanion toCompanion() => ... }`
- 全12テーブル分を同じ形で用意する。**null許容の非nullフィールド**(例: DBが`''`、モデルが`String`)は素通し。`Value.absent()`は使わず、**全列を明示的に`Value(...)`で埋める**(部分更新を作らない。`replace`が全列上書きであることと整合させる)。

---

## 8. マイグレーション方針

### 8.1 初期バージョン(v1)の作り方(T5-B12の手順)

1. `lib/db/tables.dart`と`lib/db/local_database.dart`を§2〜§4のとおり書き、`schemaVersion => 1;` とする。
2. `dart run build_runner build --force-jit` で`local_database.g.dart`を生成。
3. `dart run drift_dev make-migrations` を実行する。これがバージョン1のスキーマJSONを`drift_schemas/`へ書き出し、`lib/db/schema_versions.dart`と`test/db/migration_test.dart`(生成テスト)を作る。
   - 使用中のdrift_devに`make-migrations`が無い場合のみ、旧2段階コマンドへフォールバックする: `dart run drift_dev schema dump lib/db/local_database.dart drift_schemas/` → `dart run drift_dev schema steps drift_schemas/ lib/db/schema_versions.dart`。
4. `drift_schemas/`と生成ファイルを**gitにコミットする**(これが無いと将来の差分検出ができない)。
5. `MigrationStrategy`に`onUpgrade: stepByStep(...)`を配線する(v1のみの現時点では実質no-op)。

### 8.2 将来スキーマを変更するときの手順(恒久ルール)

1. `lib/db/tables.dart`を編集する(列追加/削除/型変更)。
2. `LocalDatabase.schemaVersion`を **+1** する。
3. `dart run build_runner build --force-jit`。
4. `dart run drift_dev make-migrations`(新しいスキーマJSONと`fromNtoN+1`の空ステップが生成される)。
5. 生成された`stepByStep`の該当ステップに移行処理を書く(`m.addColumn(...)`・`m.alterTable(TableMigration(...))`等)。**`onUpgrade`に生SQLを直書きしない。**
6. `flutter test test/db/migration_test.dart` を実行し、生成されたスキーマ検証テスト(と`validateDatabaseSchema`)が通ることを確認する。
7. **列の削除・改名は原則やらない**(公開版は端末上に唯一のデータがあり、失敗が即データ消失になる)。やむを得ない場合は「新列を追加 → 既存データをコピーする移行ステップ → 旧列は残したまま非使用にする」の順で行い、旧列の物理削除は次の次のリリース以降にする。

### 8.3 テストの制約(未検証・要確認)

driftのテストは`NativeDatabase.memory()`(`package:drift/native.dart`)で行うのが公式の流儀だが、**Windowsホストの`flutter test`でsqlite3ネイティブライブラリが見つからず失敗する可能性がある**(未検証)。T5-B12では次の順で試し、結果を`NEXT_SESSION.md`に記録すること。

1. まず`NativeDatabase.memory()`のまま`flutter test test/db/local_database_test.dart`を実行する。
2. `Couldn't open sqlite3 library`系のエラーが出たら、`dev_dependencies`に`sqlite3`を追加し、公式配布の`sqlite3.dll`をリポジトリ直下へ置いてテスト前に`open.overrideFor(...)`する方式へ切り替える。
3. それでも通らない場合は、DBテストを`integration_test/`へ移してAndroidエミュレータで実行する(`test/acceptance/t5_b12_acceptance_test.dart`はスキーマ検証のみに縮小する)。

**2回試して解決しない場合は打ち切り、分かったことと分からなかったことを分けてarchitectへ差し戻す。**

### 8.4 Web版への影響

`drift_flutter`はWebでは`sqlite3.wasm`とdriftのワーカーを`web/`配下に要求するが、**personal版(Web)は`useLocalDb: false`のまま`LocalDatabase`を構築しない**ため実行時には不要。ただし**コンパイルは通る必要がある**ので、T5-B12の検証項目に `flutter build web` の成功を必ず入れる。Web上で実際にローカルDBを動かす予定はこの段階では無い(必要になったら別タスクでwasm資材を追加する)。

---

## 9. 初期データ(シード)

`MigrationStrategy.onCreate`内で`m.createAll()`の直後に投入する(新規インストール時の1回だけ)。

| テーブル | シード | 根拠 |
|---|---|---|
| `origin_master` | `kInitialOriginMasters`(15件、`lib/models/origin_master.dart`) | 産地は普遍的な参照データで、無いと豆登録の産地選択が空になる。IDは固定値`origin_1`〜`origin_15`で冪等 |
| `store_master` | **投入しない** | `kInitialStoreMasters`の7件は開発者個人が使う神戸周辺の実店舗であり、公開版の一般ユーザーには無意味 |
| その他10テーブル | **投入しない** | ユーザーが自分で登録する |

**ユーザー確認が必要(§11-1)**: `methods_master`(抽出メソッド)を空で出荷すると、公開版の初回起動時に抽出画面でメソッドを選べない。初期メソッド(4:6メソッド等)を同梱するか、空のまま「まずメソッドを登録してください」と案内するかは**製品判断**のため、この設計では決めていない。

---

## 10. 検証観点(T5-B12 / T5-B13)

「効いたと言える」判定条件:

1. **スキーマ**: `LocalDatabase`を新規作成すると12テーブルが作られ、`PRAGMA table_info(<各テーブル>)`の列数が§4の列数(31/21/13/8/5/5/5/5/19/9/5/12)と一致する。
2. **型往復**: 12モデルそれぞれについて「モデル → companion → insert → select → モデル」の往復で**全フィールドが等値**になる。特に次の4ケースを明示的に含める。
   - `DateTime`: `readBack.isAtSameMomentAs(original)`(§2の未検証項目の確認を兼ねる)
   - `bool?`の3値: `null` / `true` / `false` がそのまま戻る(`BeanMaster.seekOptimalConditions`)
   - 数字だけの文字列ID(`'1712345678901'`)が**数値化されずに文字列で戻る**
   - `double?`の`null`と`0.0`が区別される(`BeanMaster.initialQuantityGrams`)
3. **マイグレーション**: 意図的に`schemaVersion`を2へ上げて列を1つ足し、`make-migrations`で生成したステップでv1→v2の移行テストが通る(T5-B12の終了条件そのもの)。**移行後に既存行のデータが保持されている**ことを併せて確認する。
4. **CRUD**: 5マスタ(豆・グラインダー・ドリッパー・フィルター・メソッド)+抽出記録+購入履歴+購入店の全部で 追加→一覧に出る→更新→反映→削除→消える が通る(**マスタ系は必ず全種類で確認する**。`CLAUDE.md`の不変条件)。
5. **異常系**: 空ID→`LocalDbException`、重複ID追加→`LocalDbException`、存在しないIDの更新→`LocalDbException`、存在しないIDの削除→例外なしで無変化。
6. **順序**: 3件を順に追加すると`getXxx()`が追加順で返る。
7. **回帰(本番データ模倣)**: `coffee_data`に「削除済み豆を指す`bean_id`」「空文字の`method_id`」「`origin_id`が空」の行を入れても取得・表示が落ちない(FK非採用の妥当性確認)。
8. **既存の回帰**: `flutter analyze`新規issueゼロ、`flutter test`全パス、`flutter build web`成功、personal版(`lib/main.dart`)がSheetsで従来どおり動く(`useLocalDb: false`の経路に影響が無いこと)。

---

## 11. 残った不明点・ユーザー判断が必要な事項

1. **公開版に初期メソッドを同梱するか**(§9)。製品仕様の好みのため未決。T5-B13着手前にユーザーへ確認する。
2. **`kPublicEdition.useLocalDb`を`true`へ切り替えるタイミング**。現状は両エディションとも`false`(`lib/config/app_edition.dart:108`)。T5-B13完了時に切り替える想定だが、T5-B14(画像ローカル保存)未了の状態で切り替えると公開版の画像がDrive依存のまま残る。**T5-B14完了までは`false`のままにする**ことを推奨するが、切り替え時期の最終判断はユーザーに委ねる。
3. **driftのテキスト日時のタイムゾーン往復**(§2)と**Windowsホストでのsqlite3テスト実行可否**(§8.3)は未検証。T5-B12の実装時に実測して結果をここへ追記すること。
