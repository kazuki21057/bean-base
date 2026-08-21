// ローカルDB(drift)テーブル定義。
//
// 正本: docs/local_db_schema_design.md §4(12テーブル・全138列)。
// ここに書かれていない列・型・既定値を実装者判断で追加/変更しない。
// 設計に無い判断が必要になった場合はarchitectへ差し戻すこと。
import 'package:drift/drift.dart';

/// `coffee_data`(抽出記録) — 31列。対応モデル: `CoffeeRecord`。
@DataClassName('CoffeeDataRow')
@TableIndex(name: 'idx_coffee_data_brewed_at', columns: {#brewedAt})
@TableIndex(name: 'idx_coffee_data_bean_id', columns: {#beanId})
@TableIndex(name: 'idx_coffee_data_method_id', columns: {#methodId})
class CoffeeDataTable extends Table {
  @override
  String get tableName => 'coffee_data';

  TextColumn get id => text()();
  DateTimeColumn get brewedAt => dateTime()();
  TextColumn get grinderId => text().withDefault(const Constant(''))();
  TextColumn get dripperId => text().withDefault(const Constant(''))();
  TextColumn get filterId => text().withDefault(const Constant(''))();
  TextColumn get beanId => text().withDefault(const Constant(''))();
  TextColumn get roastLevel => text().withDefault(const Constant(''))();
  TextColumn get origin => text().withDefault(const Constant(''))();
  TextColumn get originId => text().withDefault(const Constant(''))();
  RealColumn get beanWeight => real().withDefault(const Constant(0.0))();
  TextColumn get grindSize => text().withDefault(const Constant(''))();
  TextColumn get methodId => text().withDefault(const Constant(''))();
  TextColumn get taste => text().withDefault(const Constant(''))();
  TextColumn get concentration => text().withDefault(const Constant(''))();
  RealColumn get temperature => real().withDefault(const Constant(0.0))();
  RealColumn get bloomingWater => real().withDefault(const Constant(0.0))();
  RealColumn get totalWater => real().withDefault(const Constant(0.0))();
  IntColumn get bloomingTime => integer().withDefault(const Constant(0))();
  IntColumn get totalTime => integer().withDefault(const Constant(0))();
  IntColumn get scoreFragrance => integer().withDefault(const Constant(0))();
  IntColumn get scoreAcidity => integer().withDefault(const Constant(0))();
  IntColumn get scoreBitterness => integer().withDefault(const Constant(0))();
  IntColumn get scoreSweetness => integer().withDefault(const Constant(0))();
  IntColumn get scoreComplexity => integer().withDefault(const Constant(0))();
  IntColumn get scoreFlavor => integer().withDefault(const Constant(0))();
  IntColumn get scoreOverall => integer().withDefault(const Constant(0))();
  TextColumn get comment => text().withDefault(const Constant(''))();
  TextColumn get grinderImageUrl => text().nullable()();
  TextColumn get dripperImageUrl => text().nullable()();
  TextColumn get filterImageUrl => text().nullable()();
  TextColumn get beanImageUrl => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// `bean_master`(豆マスタ) — 21列。対応モデル: `BeanMaster`。
@DataClassName('BeanMasterRow')
@TableIndex(name: 'idx_bean_master_store_id', columns: {#storeId})
@TableIndex(name: 'idx_bean_master_origin_id', columns: {#originId})
class BeanMasterTable extends Table {
  @override
  String get tableName => 'bean_master';

  TextColumn get id => text()();
  TextColumn get name => text().withDefault(const Constant('-'))();
  TextColumn get roastLevel => text().withDefault(const Constant(''))();
  TextColumn get origin => text().withDefault(const Constant(''))();
  TextColumn get store => text().withDefault(const Constant(''))();
  TextColumn get type => text().withDefault(const Constant(''))();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get beanImageUrl => text().nullable()();
  TextColumn get infoImageUrl => text().nullable()();
  DateTimeColumn get purchaseDate => dateTime().nullable()();
  DateTimeColumn get firstUseDate => dateTime().nullable()();
  DateTimeColumn get lastUseDate => dateTime().nullable()();
  BoolColumn get isInStock => boolean().withDefault(const Constant(false))();
  RealColumn get initialQuantityGrams => real().nullable()();
  TextColumn get originId => text().withDefault(const Constant(''))();
  DateTimeColumn get roastDate => dateTime().nullable()();
  RealColumn get stockBaselineGrams => real().nullable()();
  DateTimeColumn get stockBaselineAt => dateTime().nullable()();
  TextColumn get storageLocation => text().withDefault(const Constant(''))();
  BoolColumn get seekOptimalConditions => boolean().nullable()();
  TextColumn get storeId => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

/// `methods_master`(メソッドマスタ) — 13列。対応モデル: `MethodMaster`。
@DataClassName('MethodsMasterRow')
class MethodsMasterTable extends Table {
  @override
  String get tableName => 'methods_master';

  TextColumn get id => text()();
  TextColumn get name => text().withDefault(const Constant('-'))();
  TextColumn get author => text().withDefault(const Constant(''))();
  RealColumn get baseBeanWeight => real().withDefault(const Constant(0.0))();
  RealColumn get baseWaterAmount => real().withDefault(const Constant(0.0))();
  RealColumn get temperature => real().nullable()();
  TextColumn get grindSize => text().nullable()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get recommendedEquipment => text().withDefault(const Constant(''))();
  TextColumn get sourceUrl => text().nullable()();
  TextColumn get recommendedRoastLevel => text().nullable()();
  TextColumn get recommendedRoastMin => text().nullable()();
  TextColumn get recommendedRoastMax => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// `pouring_steps`(注湯ステップ) — 8列。対応モデル: `PouringStep`。
/// 外部キー制約は張らない(設計書§4.4)。
@DataClassName('PouringStepRow')
@TableIndex(name: 'idx_pouring_steps_method_id', columns: {#methodId, #stepOrder})
class PouringStepsTable extends Table {
  @override
  String get tableName => 'pouring_steps';

  TextColumn get id => text()();
  TextColumn get methodId => text().withDefault(const Constant(''))();
  IntColumn get stepOrder => integer().withDefault(const Constant(0))();
  IntColumn get duration => integer().withDefault(const Constant(0))();
  RealColumn get waterAmount => real().withDefault(const Constant(0.0))();
  RealColumn get waterReference => real().withDefault(const Constant(0.0))();
  RealColumn get waterRatio => real().nullable()();
  TextColumn get description => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

/// `mill_master`(グラインダーマスタ) — 5列。対応モデル: `GrinderMaster`。
@DataClassName('MillMasterRow')
class MillMasterTable extends Table {
  @override
  String get tableName => 'mill_master';

  TextColumn get id => text()();
  TextColumn get name => text().withDefault(const Constant('-'))();
  TextColumn get grindRange => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get imageUrl => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// `dripper_master`(ドリッパーマスタ) — 5列。対応モデル: `DripperMaster`。
@DataClassName('DripperMasterRow')
class DripperMasterTable extends Table {
  @override
  String get tableName => 'dripper_master';

  TextColumn get id => text()();
  TextColumn get name => text().withDefault(const Constant('-'))();
  TextColumn get material => text().nullable()();
  TextColumn get shape => text().nullable()();
  TextColumn get imageUrl => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// `filter_master`(フィルターマスタ) — 5列。対応モデル: `FilterMaster`。
@DataClassName('FilterMasterRow')
class FilterMasterTable extends Table {
  @override
  String get tableName => 'filter_master';

  TextColumn get id => text()();
  TextColumn get name => text().withDefault(const Constant('-'))();
  TextColumn get material => text().nullable()();
  TextColumn get size => text().nullable()();
  TextColumn get imageUrl => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// `origin_master`(産地マスタ) — 5列。対応モデル: `OriginMaster`。
@DataClassName('OriginMasterRow')
class OriginMasterTable extends Table {
  @override
  String get tableName => 'origin_master';

  TextColumn get id => text()();
  TextColumn get countryCode => text().withDefault(const Constant(''))();
  TextColumn get nameJa => text().withDefault(const Constant(''))();
  TextColumn get nameEn => text().withDefault(const Constant(''))();
  TextColumn get region => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

/// `store_master`(購入店マスタ) — 19列。対応モデル: `StoreMaster`。
@DataClassName('StoreMasterRow')
class StoreMasterTable extends Table {
  @override
  String get tableName => 'store_master';

  TextColumn get id => text()();
  TextColumn get name => text().withDefault(const Constant('-'))();
  TextColumn get formalName => text().withDefault(const Constant(''))();
  TextColumn get url => text().withDefault(const Constant(''))();
  TextColumn get prefecture => text().withDefault(const Constant(''))();
  TextColumn get address => text().withDefault(const Constant(''))();
  BoolColumn get hasOnlineShop => boolean().withDefault(const Constant(false))();
  BoolColumn get hasPhysicalStore => boolean().withDefault(const Constant(false))();
  BoolColumn get hasRoastery => boolean().withDefault(const Constant(false))();
  TextColumn get beanTendency => text().withDefault(const Constant(''))();
  TextColumn get memo => text().withDefault(const Constant(''))();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get snsUrl => text().withDefault(const Constant(''))();
  TextColumn get businessHours => text().withDefault(const Constant(''))();
  TextColumn get closedDays => text().withDefault(const Constant(''))();
  TextColumn get phone => text().withDefault(const Constant(''))();
  TextColumn get openedYear => text().withDefault(const Constant(''))();
  TextColumn get sourceUrl => text().withDefault(const Constant(''))();
  DateTimeColumn get infoFetchedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// `bean_purchases`(購入履歴) — 9列。対応モデル: `BeanPurchase`。
@DataClassName('BeanPurchaseRow')
@TableIndex(name: 'idx_bean_purchases_bean_id', columns: {#beanId})
class BeanPurchasesTable extends Table {
  @override
  String get tableName => 'bean_purchases';

  TextColumn get id => text()();
  TextColumn get beanId => text().withDefault(const Constant(''))();
  DateTimeColumn get purchasedAt => dateTime().nullable()();
  DateTimeColumn get roastDate => dateTime().nullable()();
  RealColumn get quantityGrams => real().nullable()();
  TextColumn get storeId => text().withDefault(const Constant(''))();
  TextColumn get storeName => text().withDefault(const Constant(''))();
  TextColumn get memo => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// `analysis_history`(解析スナップショット) — 5列。対応モデル: `AnalysisSnapshot`。
@DataClassName('AnalysisHistoryRow')
@TableIndex(name: 'idx_analysis_history_type', columns: {#type})
class AnalysisHistoryTable extends Table {
  @override
  String get tableName => 'analysis_history';

  TextColumn get id => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get type => text().withDefault(const Constant(''))();
  IntColumn get dataCount => integer().withDefault(const Constant(0))();
  TextColumn get payloadJson => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

/// `recipe_suggestions`(レシピ提案) — 12列。対応モデル: `RecipeSuggestion`。
@DataClassName('RecipeSuggestionRow')
@TableIndex(name: 'idx_recipe_suggestions_bean_id', columns: {#beanId})
class RecipeSuggestionsTable extends Table {
  @override
  String get tableName => 'recipe_suggestions';

  TextColumn get id => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get beanId => text().withDefault(const Constant(''))();
  TextColumn get originId => text().withDefault(const Constant(''))();
  TextColumn get roastLevel => text().withDefault(const Constant(''))();
  TextColumn get methodId => text().withDefault(const Constant(''))();
  RealColumn get temperature => real().withDefault(const Constant(0.0))();
  RealColumn get brewRatio => real().withDefault(const Constant(0.0))();
  IntColumn get totalTimeSec => integer().withDefault(const Constant(0))();
  TextColumn get rationale => text().withDefault(const Constant(''))();
  TextColumn get accepted => text().withDefault(const Constant(''))();
  TextColumn get resultRecordId => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}
