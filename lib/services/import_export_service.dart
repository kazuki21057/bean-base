// ローカルDB(drift)の全12テーブルをエクスポート/インポートするサービス(T5-B15)。
//
// 正本: docs/local_db_schema_design.md §5.2(ID正規化)・§6(対応表)・§6.1(形式)。
// - JSONのキーは日本語シート列名に揃える(`SheetsService`の`keyMap`/`reverseMap`から
//   機械的に写した対応表を使う。personal↔public相互運用のため)。
// - CSVは1テーブル=1ファイル、ヘッダー行に日本語列名。
// - インポートはトランザクション1つで全テーブルをupsert(`insertOnConflictUpdate`)。
//   途中失敗時は全ロールバックし、日本語エラーメッセージ(`LocalDbException`)を投げる。
// UI(P920データ設定画面)は別タスク。ここはサービス層のみ。
// ignore_for_file: always_use_package_imports, avoid_catches_without_on_clauses
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../db/local_database.dart';
import '../db/mappers.dart';
import '../models/analysis_snapshot.dart';
import '../models/bean_master.dart';
import '../models/bean_purchase.dart';
import '../models/coffee_record.dart';
import '../models/equipment_masters.dart';
import '../models/method_master.dart';
import '../models/origin_master.dart';
import '../models/pouring_step.dart';
import '../models/recipe_suggestion.dart';
import '../models/store_master.dart';
import 'local_db_service.dart' show LocalDbException;

/// 外部由来(SheetsのJSON等)の数値/文字列IDを文字列へ正規化する。
///
/// 正本: docs/local_db_schema_design.md §5.2-5。
/// `1.0`のような小数表記の数値ID(SheetsのJSONは`double`になりうる)は
/// 整数表記へ寄せる(`123.0`のままだと文字列突合が壊れるため)。
/// 置き場所はこの通り、トップレベル関数として本ファイルに置く
/// (`LocalDbService`にも`SheetsService`にも置かない、設計書§5.2-5)。
String normalizeExternalId(dynamic value) {
  if (value == null) return '';
  if (value is num) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }
  return value.toString().trim();
}

/// バックアップの並び順=登録順(rowid昇順、`LocalDbService`と同じ方式)。
OrderingTerm _byRowId() =>
    OrderingTerm(expression: const CustomExpression<int>('rowid'));

class ImportExportService {
  ImportExportService(this._db);

  final LocalDatabase _db;

  /// エクスポートJSONの形式バージョン(`schemaVersion`とは別。今回が最初のため1固定)。
  static const int formatVersion = 1;

  // ==========================================================================
  // 列対応表(日本語シート列名 → Dartモデルの英語フィールド名)
  // 正本: lib/services/sheets_service.dart の keyMap/reverseMap から機械的に写す。
  // ==========================================================================

  static const Map<String, String> _coffeeDataColumnMap = {
    '記録ID': 'id',
    '記録日': 'brewedAt',
    'ミル': 'grinderId',
    'ドリッパー': 'dripperId',
    'フィルター': 'filterId',
    '豆名': 'beanId',
    '焙煎度': 'roastLevel',
    '産地': 'origin',
    '産地ID': 'originId',
    '豆の量(g)': 'beanWeight',
    '挽き目': 'grindSize',
    '抽出方法': 'methodId',
    '味': 'taste',
    '濃度': 'concentration',
    '湯温(℃)': 'temperature',
    '蒸らし湯量(ml)': 'bloomingWater',
    '湯量(ml)': 'totalWater',
    '蒸らし時間(秒)': 'bloomingTime',
    '抽出時間(秒)': 'totalTime',
    '香り(1-10)': 'scoreFragrance',
    '酸味(1-10)': 'scoreAcidity',
    '苦味(1-10)': 'scoreBitterness',
    '甘味(1-10)': 'scoreSweetness',
    '複雑さ(1-10)': 'scoreComplexity',
    'フレーバー(1-10)': 'scoreFlavor',
    '総合評価(1-10)': 'scoreOverall',
    'コメント': 'comment',
    'ミル写真URL': 'grinderImageUrl',
    'ドリッパー写真URL': 'dripperImageUrl',
    'フィルタ写真URL': 'filterImageUrl',
    '豆写真URL': 'beanImageUrl',
  };
  static const Set<String> _coffeeDataIdFields = {
    'id', 'grinderId', 'dripperId', 'filterId', 'beanId', 'originId', 'methodId',
  };

  static const Map<String, String> _beanMasterColumnMap = {
    '豆ID': 'id',
    '豆名': 'name',
    '焙煎度': 'roastLevel',
    '産地': 'origin',
    '購入店舗': 'store',
    '豆の種類': 'type',
    '豆画像URL': 'imageUrl',
    '豆粒画像URL': 'beanImageUrl',
    '情報画像URL': 'infoImageUrl',
    '購入日': 'purchaseDate',
    '開封日': 'firstUseDate',
    '使い切り日': 'lastUseDate',
    '在庫': 'isInStock',
    '初期購入量(g)': 'initialQuantityGrams',
    '産地ID': 'originId',
    '焙煎日': 'roastDate',
    '在庫基準量(g)': 'stockBaselineGrams',
    '在庫基準日時': 'stockBaselineAt',
    '保存場所': 'storageLocation',
    '最適条件探索': 'seekOptimalConditions',
    '購入店ID': 'storeId',
  };
  static const Set<String> _beanMasterIdFields = {'id', 'originId', 'storeId'};

  static const Map<String, String> _methodsMasterColumnMap = {
    'メソッドID': 'id',
    'メソッド名': 'name',
    '発案者': 'author',
    '基準豆量(g)': 'baseBeanWeight',
    '基準湯量(ml)': 'baseWaterAmount',
    '湯温（℃）': 'temperature',
    '挽き目（Kingrinder K6）': 'grindSize',
    '説明': 'description',
    '推奨機器': 'recommendedEquipment',
    'ソース': 'sourceUrl',
    '推奨焙煎度': 'recommendedRoastLevel',
    '推奨焙煎度(最浅)': 'recommendedRoastMin',
    '推奨焙煎度(最深)': 'recommendedRoastMax',
  };
  static const Set<String> _methodsMasterIdFields = {'id'};

  static const Map<String, String> _pouringStepsColumnMap = {
    'ID': 'id',
    'メソッドID（親）': 'methodId',
    '並び順': 'stepOrder',
    '加算時間（秒）': 'duration',
    '加算湯量（ml）': 'waterAmount',
    '湯量基準(豆量15g)': 'waterReference',
    '湯量係数': 'waterRatio',
    '注意事項': 'description',
  };
  static const Set<String> _pouringStepsIdFields = {'id', 'methodId'};

  static const Map<String, String> _millMasterColumnMap = {
    'ミルID': 'id',
    'ミル名': 'name',
    '挽き目調整段階': 'grindRange',
    '説明': 'description',
    'ミル画像URL': 'imageUrl',
  };
  static const Set<String> _millMasterIdFields = {'id'};

  static const Map<String, String> _dripperMasterColumnMap = {
    'ドリッパーID': 'id',
    'ドリッパー名': 'name',
    '素材': 'material',
    '形状': 'shape',
    'ドリッパー画像URL': 'imageUrl',
  };
  static const Set<String> _dripperMasterIdFields = {'id'};

  static const Map<String, String> _filterMasterColumnMap = {
    'フィルターID': 'id',
    'フィルター名': 'name',
    '素材': 'material',
    'サイズ': 'size',
    'フィルター画像URL': 'imageUrl',
  };
  static const Set<String> _filterMasterIdFields = {'id'};

  static const Map<String, String> _originMasterColumnMap = {
    '産地ID': 'id',
    '国コード': 'countryCode',
    '産地名': 'nameJa',
    '産地名(英)': 'nameEn',
    '地域': 'region',
  };
  static const Set<String> _originMasterIdFields = {'id'};

  static const Map<String, String> _storeMasterColumnMap = {
    '購入店ID': 'id',
    '店名': 'name',
    '正式名称': 'formalName',
    'URL': 'url',
    '都道府県': 'prefecture',
    '住所': 'address',
    'オンライン販売': 'hasOnlineShop',
    '実店舗': 'hasPhysicalStore',
    '焙煎所併設': 'hasRoastery',
    '取扱豆の傾向': 'beanTendency',
    'メモ': 'memo',
    '店舗画像URL': 'imageUrl',
    'SNS': 'snsUrl',
    '営業時間': 'businessHours',
    '定休日': 'closedDays',
    '電話番号': 'phone',
    '開業年': 'openedYear',
    '情報取得元': 'sourceUrl',
    '情報取得日': 'infoFetchedAt',
  };
  static const Set<String> _storeMasterIdFields = {'id'};

  static const Map<String, String> _beanPurchasesColumnMap = {
    '購入ID': 'id',
    '豆ID': 'beanId',
    '購入日': 'purchasedAt',
    '焙煎日': 'roastDate',
    '購入量(g)': 'quantityGrams',
    '購入店ID': 'storeId',
    '購入店名': 'storeName',
    'メモ': 'memo',
    '登録日時': 'createdAt',
  };
  static const Set<String> _beanPurchasesIdFields = {'id', 'beanId', 'storeId'};

  static const Map<String, String> _analysisHistoryColumnMap = {
    '履歴ID': 'id',
    '作成日時': 'createdAt',
    '種別': 'type',
    'データ件数': 'dataCount',
    '本文JSON': 'payloadJson',
  };
  static const Set<String> _analysisHistoryIdFields = {'id'};

  static const Map<String, String> _recipeSuggestionsColumnMap = {
    '提案ID': 'id',
    '作成日時': 'createdAt',
    '豆ID': 'beanId',
    '産地ID': 'originId',
    '焙煎度': 'roastLevel',
    'メソッドID': 'methodId',
    '湯温': 'temperature',
    '湯豆比': 'brewRatio',
    '抽出時間': 'totalTimeSec',
    '提案根拠': 'rationale',
    '採否': 'accepted',
    '結果記録ID': 'resultRecordId',
  };
  static const Set<String> _recipeSuggestionsIdFields = {
    'id', 'beanId', 'originId', 'methodId', 'resultRecordId',
  };

  // ==========================================================================
  // JSONエクスポート
  // ==========================================================================

  /// 全12テーブルをJSON文字列へ書き出す(設計書§6.1のJSON構造)。
  Future<String> exportToJson() async {
    debugPrint('[Antigravity] インポート/エクスポート: JSONエクスポート開始');
    try {
      final tables = <String, dynamic>{
        'coffee_data': await _exportCoffeeData(),
        'bean_master': await _exportBeanMaster(),
        'methods_master': await _exportMethodsMaster(),
        'pouring_steps': await _exportPouringSteps(),
        'mill_master': await _exportMillMaster(),
        'dripper_master': await _exportDripperMaster(),
        'filter_master': await _exportFilterMaster(),
        'origin_master': await _exportOriginMaster(),
        'store_master': await _exportStoreMaster(),
        'bean_purchases': await _exportBeanPurchases(),
        'analysis_history': await _exportAnalysisHistory(),
        'recipe_suggestions': await _exportRecipeSuggestions(),
      };
      final data = <String, dynamic>{
        'formatVersion': formatVersion,
        'schemaVersion': _db.schemaVersion,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'tables': tables,
      };
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      debugPrint('[Antigravity] インポート/エクスポート: JSONエクスポート完了(12テーブル)');
      return jsonStr;
    } catch (e) {
      debugPrint('[Antigravity] インポート/エクスポート: JSONエクスポートエラー $e');
      rethrow;
    }
  }

  // ==========================================================================
  // JSONインポート
  // ==========================================================================

  /// エクスポートJSONを取り込み、全12テーブルを1トランザクションでupsertする。
  /// 途中で失敗したら全ロールバックし、`LocalDbException`(日本語)を投げる。
  ///
  /// 本メソッドはupsert(`insertOnConflictUpdate`)のみを行い、既存データを削除しない。
  /// インポートJSONに存在しないローカルの既存レコードはそのまま残るため、
  /// バックアップ時点の状態への完全復元が必要な場合は、呼び出し側が本メソッド呼び出し前に
  /// 対象テーブルを全消去すること(P920画面タスクの責務)。
  Future<void> importFromJson(String jsonString) async {
    debugPrint('[Antigravity] インポート/エクスポート: JSONインポート開始');
    late final Map<String, dynamic> json;
    try {
      json = jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[Antigravity] インポート/エクスポート: JSON解析エラー $e');
      throw const LocalDbException('読み込みに失敗しました。データは変更されていません。');
    }

    final rawSchemaVersion = json['schemaVersion'];
    final importSchemaVersion =
        rawSchemaVersion is num ? rawSchemaVersion.toInt() : 0;
    if (importSchemaVersion > _db.schemaVersion) {
      throw const LocalDbException(
        'このバックアップは新しいバージョンのアプリで作成されています。アプリを更新してから読み込んでください。',
      );
    }

    final tablesJson = (json['tables'] as Map<String, dynamic>?) ?? const {};

    try {
      await _db.transaction(() async {
        await _importCoffeeData(tablesJson['coffee_data']);
        await _importBeanMaster(tablesJson['bean_master']);
        await _importMethodsMaster(tablesJson['methods_master']);
        await _importPouringSteps(tablesJson['pouring_steps']);
        await _importMillMaster(tablesJson['mill_master']);
        await _importDripperMaster(tablesJson['dripper_master']);
        await _importFilterMaster(tablesJson['filter_master']);
        await _importOriginMaster(tablesJson['origin_master']);
        await _importStoreMaster(tablesJson['store_master']);
        await _importBeanPurchases(tablesJson['bean_purchases']);
        await _importAnalysisHistory(tablesJson['analysis_history']);
        await _importRecipeSuggestions(tablesJson['recipe_suggestions']);
      });
    } catch (e) {
      debugPrint('[Antigravity] インポート/エクスポート: JSONインポートエラー $e');
      throw const LocalDbException('読み込みに失敗しました。データは変更されていません。');
    }
    debugPrint('[Antigravity] インポート/エクスポート: JSONインポート完了');
  }

  // ==========================================================================
  // CSVエクスポート(1テーブル=1ファイル、CSVインポートは対象外)
  // ==========================================================================

  /// テーブル名 → CSV文字列(ヘッダー行=日本語列名)。
  Future<Map<String, String>> exportToCsv() async {
    debugPrint('[Antigravity] インポート/エクスポート: CSVエクスポート開始');
    try {
      final result = <String, String>{
        'coffee_data': _toCsv(_coffeeDataColumnMap, await _exportCoffeeData()),
        'bean_master': _toCsv(_beanMasterColumnMap, await _exportBeanMaster()),
        'methods_master':
            _toCsv(_methodsMasterColumnMap, await _exportMethodsMaster()),
        'pouring_steps':
            _toCsv(_pouringStepsColumnMap, await _exportPouringSteps()),
        'mill_master': _toCsv(_millMasterColumnMap, await _exportMillMaster()),
        'dripper_master':
            _toCsv(_dripperMasterColumnMap, await _exportDripperMaster()),
        'filter_master':
            _toCsv(_filterMasterColumnMap, await _exportFilterMaster()),
        'origin_master':
            _toCsv(_originMasterColumnMap, await _exportOriginMaster()),
        'store_master': _toCsv(_storeMasterColumnMap, await _exportStoreMaster()),
        'bean_purchases':
            _toCsv(_beanPurchasesColumnMap, await _exportBeanPurchases()),
        'analysis_history':
            _toCsv(_analysisHistoryColumnMap, await _exportAnalysisHistory()),
        'recipe_suggestions': _toCsv(
            _recipeSuggestionsColumnMap, await _exportRecipeSuggestions()),
      };
      debugPrint('[Antigravity] インポート/エクスポート: CSVエクスポート完了(12テーブル)');
      return result;
    } catch (e) {
      debugPrint('[Antigravity] インポート/エクスポート: CSVエクスポートエラー $e');
      rethrow;
    }
  }

  String _toCsv(Map<String, String> columnMap, List<Map<String, dynamic>> rows) {
    final headers = columnMap.keys.toList();
    final buffer = StringBuffer();
    buffer.writeln(headers.map(_csvField).join(','));
    for (final row in rows) {
      buffer.writeln(headers.map((h) => _csvField(row[h])).join(','));
    }
    return buffer.toString();
  }

  String _csvField(dynamic value) {
    if (value == null) return '';
    final s = value.toString();
    if (s.contains(',') || s.contains('"') || s.contains('\n') || s.contains('\r')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  // ==========================================================================
  // 共通ヘルパー(英語キー⇔日本語キーの変換)
  // ==========================================================================

  /// モデルの`toJson()`(英語キー)を日本語シート列名キーへ変換する。
  Map<String, dynamic> _toJapanese(
      Map<String, dynamic> englishJson, Map<String, String> columnMap) {
    final result = <String, dynamic>{};
    columnMap.forEach((japaneseKey, englishKey) {
      if (englishJson.containsKey(englishKey)) {
        result[japaneseKey] = englishJson[englishKey];
      }
    });
    return result;
  }

  /// 日本語シート列名キーのJSONをモデルの`fromJson()`に渡せる英語キーへ変換する。
  /// ID列(設計書§5.2-5の対象列)は`normalizeExternalId`で正規化する。
  Map<String, dynamic> _toEnglish(Map<String, dynamic> japaneseJson,
      Map<String, String> columnMap, Set<String> idFields) {
    final result = <String, dynamic>{};
    japaneseJson.forEach((key, value) {
      final englishKey = columnMap[key] ?? key;
      dynamic v = value;
      if (idFields.contains(englishKey)) {
        v = normalizeExternalId(v);
      } else if (v is String && v.trim().isEmpty) {
        v = null;
      }
      if (v != null) {
        result[englishKey] = v;
      }
    });
    return result;
  }

  List<Map<String, dynamic>> _asRowList(dynamic raw) {
    if (raw == null) return const [];
    return (raw as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  // ==========================================================================
  // テーブルごとのエクスポート/インポート(coffee_data)
  // ==========================================================================

  Future<List<Map<String, dynamic>>> _exportCoffeeData() async {
    final rows = await (_db.select(_db.coffeeDataTable)
          ..orderBy([(_) => _byRowId()]))
        .get();
    return rows
        .map((r) => _toJapanese(r.toModel().toJson(), _coffeeDataColumnMap))
        .toList();
  }

  Future<void> _importCoffeeData(dynamic raw) async {
    for (final item in _asRowList(raw)) {
      final remapped =
          _toEnglish(item, _coffeeDataColumnMap, _coffeeDataIdFields);
      final model = CoffeeRecord.fromJson(remapped);
      await _db
          .into(_db.coffeeDataTable)
          .insertOnConflictUpdate(model.toCompanion());
    }
  }

  // --- bean_master ---

  Future<List<Map<String, dynamic>>> _exportBeanMaster() async {
    final rows = await (_db.select(_db.beanMasterTable)
          ..orderBy([(_) => _byRowId()]))
        .get();
    return rows.map((r) {
      final japaneseRow =
          _toJapanese(r.toModel().toJson(), _beanMasterColumnMap);
      // 設計書 docs/local_db_schema_design.md:189 -
      // seekOptimalConditions(3値bool)のNULLは「未回答」を意味し(falseと区別する)、
      // Sheets側では空文字が未回答に対応するため、JSON nullではなく空文字で出力する。
      if (japaneseRow['最適条件探索'] == null) {
        japaneseRow['最適条件探索'] = '';
      }
      return japaneseRow;
    }).toList();
  }

  Future<void> _importBeanMaster(dynamic raw) async {
    for (final item in _asRowList(raw)) {
      final remapped =
          _toEnglish(item, _beanMasterColumnMap, _beanMasterIdFields);
      final model = BeanMaster.fromJson(remapped);
      await _db
          .into(_db.beanMasterTable)
          .insertOnConflictUpdate(model.toCompanion());
    }
  }

  // --- methods_master ---

  Future<List<Map<String, dynamic>>> _exportMethodsMaster() async {
    final rows = await (_db.select(_db.methodsMasterTable)
          ..orderBy([(_) => _byRowId()]))
        .get();
    return rows
        .map((r) => _toJapanese(r.toModel().toJson(), _methodsMasterColumnMap))
        .toList();
  }

  Future<void> _importMethodsMaster(dynamic raw) async {
    for (final item in _asRowList(raw)) {
      final remapped =
          _toEnglish(item, _methodsMasterColumnMap, _methodsMasterIdFields);
      final model = MethodMaster.fromJson(remapped);
      await _db
          .into(_db.methodsMasterTable)
          .insertOnConflictUpdate(model.toCompanion());
    }
  }

  // --- pouring_steps ---

  Future<List<Map<String, dynamic>>> _exportPouringSteps() async {
    final rows = await (_db.select(_db.pouringStepsTable)
          ..orderBy([(_) => _byRowId()]))
        .get();
    return rows
        .map((r) => _toJapanese(r.toModel().toJson(), _pouringStepsColumnMap))
        .toList();
  }

  Future<void> _importPouringSteps(dynamic raw) async {
    for (final item in _asRowList(raw)) {
      final remapped =
          _toEnglish(item, _pouringStepsColumnMap, _pouringStepsIdFields);
      final model = PouringStep.fromJson(remapped);
      await _db
          .into(_db.pouringStepsTable)
          .insertOnConflictUpdate(model.toCompanion());
    }
  }

  // --- mill_master(グラインダー) ---

  Future<List<Map<String, dynamic>>> _exportMillMaster() async {
    final rows = await (_db.select(_db.millMasterTable)
          ..orderBy([(_) => _byRowId()]))
        .get();
    return rows
        .map((r) => _toJapanese(r.toModel().toJson(), _millMasterColumnMap))
        .toList();
  }

  Future<void> _importMillMaster(dynamic raw) async {
    for (final item in _asRowList(raw)) {
      final remapped =
          _toEnglish(item, _millMasterColumnMap, _millMasterIdFields);
      final model = GrinderMaster.fromJson(remapped);
      await _db
          .into(_db.millMasterTable)
          .insertOnConflictUpdate(model.toCompanion());
    }
  }

  // --- dripper_master ---

  Future<List<Map<String, dynamic>>> _exportDripperMaster() async {
    final rows = await (_db.select(_db.dripperMasterTable)
          ..orderBy([(_) => _byRowId()]))
        .get();
    return rows
        .map((r) => _toJapanese(r.toModel().toJson(), _dripperMasterColumnMap))
        .toList();
  }

  Future<void> _importDripperMaster(dynamic raw) async {
    for (final item in _asRowList(raw)) {
      final remapped =
          _toEnglish(item, _dripperMasterColumnMap, _dripperMasterIdFields);
      final model = DripperMaster.fromJson(remapped);
      await _db
          .into(_db.dripperMasterTable)
          .insertOnConflictUpdate(model.toCompanion());
    }
  }

  // --- filter_master ---

  Future<List<Map<String, dynamic>>> _exportFilterMaster() async {
    final rows = await (_db.select(_db.filterMasterTable)
          ..orderBy([(_) => _byRowId()]))
        .get();
    return rows
        .map((r) => _toJapanese(r.toModel().toJson(), _filterMasterColumnMap))
        .toList();
  }

  Future<void> _importFilterMaster(dynamic raw) async {
    for (final item in _asRowList(raw)) {
      final remapped =
          _toEnglish(item, _filterMasterColumnMap, _filterMasterIdFields);
      final model = FilterMaster.fromJson(remapped);
      await _db
          .into(_db.filterMasterTable)
          .insertOnConflictUpdate(model.toCompanion());
    }
  }

  // --- origin_master ---

  Future<List<Map<String, dynamic>>> _exportOriginMaster() async {
    final rows = await (_db.select(_db.originMasterTable)
          ..orderBy([(_) => _byRowId()]))
        .get();
    return rows
        .map((r) => _toJapanese(r.toModel().toJson(), _originMasterColumnMap))
        .toList();
  }

  Future<void> _importOriginMaster(dynamic raw) async {
    for (final item in _asRowList(raw)) {
      final remapped =
          _toEnglish(item, _originMasterColumnMap, _originMasterIdFields);
      final model = OriginMaster.fromJson(remapped);
      await _db
          .into(_db.originMasterTable)
          .insertOnConflictUpdate(model.toCompanion());
    }
  }

  // --- store_master ---

  Future<List<Map<String, dynamic>>> _exportStoreMaster() async {
    final rows = await (_db.select(_db.storeMasterTable)
          ..orderBy([(_) => _byRowId()]))
        .get();
    return rows
        .map((r) => _toJapanese(r.toModel().toJson(), _storeMasterColumnMap))
        .toList();
  }

  Future<void> _importStoreMaster(dynamic raw) async {
    for (final item in _asRowList(raw)) {
      final remapped =
          _toEnglish(item, _storeMasterColumnMap, _storeMasterIdFields);
      final model = StoreMaster.fromJson(remapped);
      await _db
          .into(_db.storeMasterTable)
          .insertOnConflictUpdate(model.toCompanion());
    }
  }

  // --- bean_purchases ---

  Future<List<Map<String, dynamic>>> _exportBeanPurchases() async {
    final rows = await (_db.select(_db.beanPurchasesTable)
          ..orderBy([(_) => _byRowId()]))
        .get();
    return rows
        .map((r) => _toJapanese(r.toModel().toJson(), _beanPurchasesColumnMap))
        .toList();
  }

  Future<void> _importBeanPurchases(dynamic raw) async {
    for (final item in _asRowList(raw)) {
      final remapped =
          _toEnglish(item, _beanPurchasesColumnMap, _beanPurchasesIdFields);
      final model = BeanPurchase.fromJson(remapped);
      await _db
          .into(_db.beanPurchasesTable)
          .insertOnConflictUpdate(model.toCompanion());
    }
  }

  // --- analysis_history ---

  Future<List<Map<String, dynamic>>> _exportAnalysisHistory() async {
    final rows = await (_db.select(_db.analysisHistoryTable)
          ..orderBy([(_) => _byRowId()]))
        .get();
    return rows
        .map((r) => _toJapanese(r.toModel().toJson(), _analysisHistoryColumnMap))
        .toList();
  }

  Future<void> _importAnalysisHistory(dynamic raw) async {
    for (final item in _asRowList(raw)) {
      final remapped = _toEnglish(
          item, _analysisHistoryColumnMap, _analysisHistoryIdFields);
      final model = AnalysisSnapshot.fromJson(remapped);
      await _db
          .into(_db.analysisHistoryTable)
          .insertOnConflictUpdate(model.toCompanion());
    }
  }

  // --- recipe_suggestions ---

  Future<List<Map<String, dynamic>>> _exportRecipeSuggestions() async {
    final rows = await (_db.select(_db.recipeSuggestionsTable)
          ..orderBy([(_) => _byRowId()]))
        .get();
    return rows
        .map((r) =>
            _toJapanese(r.toModel().toJson(), _recipeSuggestionsColumnMap))
        .toList();
  }

  Future<void> _importRecipeSuggestions(dynamic raw) async {
    for (final item in _asRowList(raw)) {
      final remapped = _toEnglish(
          item, _recipeSuggestionsColumnMap, _recipeSuggestionsIdFields);
      final model = RecipeSuggestion.fromJson(remapped);
      await _db
          .into(_db.recipeSuggestionsTable)
          .insertOnConflictUpdate(model.toCompanion());
    }
  }
}
