// ignore_for_file: always_use_package_imports
// ローカルDB(drift)版のDataService実装。公開版(Android)の永続化バックエンド。
//
// 正本: docs/local_db_schema_design.md §7(実装規約)。
// T5-B13は4束に分割している(§7.5)。
// 束1(T5-B13-1、当バンドル): 全44メソッドの骨格 + 共通ヘルパー + 例外クラス
// + mill_master/dripper_master/filter_master/origin_masterの14メソッドを実装。
// 担当外のメソッドは本体を`throw UnimplementedError('T5-B13-N で実装予定');`の1行にする
// (束2: 豆/購入店/購入履歴、束3: 抽出記録/メソッド/注湯ステップ、束4: 解析/レシピ提案)。
//
// メソッドの並び順はlib/services/data_service.dartの宣言順と完全に一致させている
// (差分レビューを容易にするため)。
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
import 'data_service.dart';

/// ローカルDB操作時のユーザー向け例外。
///
/// 正本: docs/local_db_schema_design.md §7.3。メッセージは常に日本語のユーザー向け文言。
class LocalDbException implements Exception {
  const LocalDbException(this.message);

  /// 日本語のユーザー向け文言。
  final String message;

  @override
  String toString() => message;
}

class LocalDbService implements DataService {
  LocalDbService(this._db);

  /// テストが`NativeDatabase.memory()`で作ったDBを渡せるよう必須の位置引数で受け取る。
  /// LocalDbService自身はDBの生成もcloseも行わない(設計書§7.5.1-3)。
  final LocalDatabase _db;

  // ==========================================================================
  // 共通ヘルパー(設計書§7.5.1-7・8)
  // ==========================================================================

  /// 空IDガード。`add*`/`update*`/`save*`は`forDelete: false`、`delete*`は`true`。
  void _requireId(String id, {required bool forDelete}) {
    if (id.trim().isEmpty) {
      _fail(forDelete ? 'IDが空のため削除できません。' : 'IDが空のため保存できません。');
    }
  }

  /// 書き込み成功時のログ(設計書§7.3・§7.5.1-8)。
  void _logWrite(String table, String action, String id) {
    debugPrint('[Antigravity] ローカルDB: $table へ$action(ID: $id)');
  }

  /// 例外送出直前にログを出してから`LocalDbException`を投げる。
  Never _fail(String message) {
    debugPrint('[Antigravity] ローカルDBエラー: $message');
    throw LocalDbException(message);
  }

  /// 一覧取得の並び順(登録順=rowid昇順、設計書§7.1・§7.5.1-9)。
  ///
  /// **実装方式の記録**: driftが生成したテーブルクラス(例:`$MillMasterTableTable`)には
  /// `rowId`という列ゲッターは生成されない(生成される列は設計書§4の各テーブルのアプリ列のみ)。
  /// そのため`OrderingTerm.asc(t.rowId)`は使えず、`CustomExpression<int>('rowid')`で
  /// SQLiteが暗黙に持つrowid列を直接指定する方式を採用した。束2以降もこのヘルパーを使う。
  OrderingTerm _byRowId() =>
      OrderingTerm(expression: const CustomExpression<int>('rowid'));

  // ==========================================================================
  // Coffee Records — 束3(T5-B13-3)で実装予定
  // ==========================================================================

  @override
  Future<List<CoffeeRecord>> getCoffeeRecords() {
    throw UnimplementedError('T5-B13-3 で実装予定');
  }

  @override
  Future<void> addCoffeeRecord(CoffeeRecord record) {
    throw UnimplementedError('T5-B13-3 で実装予定');
  }

  @override
  Future<void> updateCoffeeRecord(CoffeeRecord record) {
    throw UnimplementedError('T5-B13-3 で実装予定');
  }

  @override
  Future<void> deleteCoffeeRecord(String id) {
    throw UnimplementedError('T5-B13-3 で実装予定');
  }

  // ==========================================================================
  // Beans (bean_master) — 束2(T5-B13-2、当バンドルで実装)
  // ==========================================================================

  @override
  Future<List<BeanMaster>> getBeans() async {
    final rows = await (_db.select(_db.beanMasterTable)
          ..orderBy([(_) => _byRowId()]))
        .get();
    return rows.map((r) => r.toModel()).toList();
  }

  @override
  Future<void> addBean(BeanMaster bean) async {
    _requireId(bean.id, forDelete: false);
    final id = bean.id;
    await _db.transaction(() async {
      final exists = await (_db.select(_db.beanMasterTable)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (exists != null) {
        _fail('既に同じIDのデータが存在します(ID: $id)');
      }
      await _db.into(_db.beanMasterTable).insert(bean.toCompanion());
    });
    _logWrite('bean_master', '追加', id);
  }

  @override
  Future<void> updateBean(BeanMaster bean) async {
    _requireId(bean.id, forDelete: false);
    final ok =
        await _db.update(_db.beanMasterTable).replace(bean.toCompanion());
    if (!ok) {
      _fail('更新対象のデータが見つかりません(ID: ${bean.id})');
    }
    _logWrite('bean_master', '更新', bean.id);
  }

  @override
  Future<void> deleteBean(String id) async {
    _requireId(id, forDelete: true);
    await (_db.delete(_db.beanMasterTable)..where((t) => t.id.equals(id)))
        .go();
    _logWrite('bean_master', '削除', id);
  }

  // ==========================================================================
  // Methods — 束3(T5-B13-3)で実装予定
  // ==========================================================================

  @override
  Future<List<MethodMaster>> getMethods() {
    throw UnimplementedError('T5-B13-3 で実装予定');
  }

  @override
  Future<void> addMethod(MethodMaster method) {
    throw UnimplementedError('T5-B13-3 で実装予定');
  }

  @override
  Future<void> updateMethod(MethodMaster method) {
    throw UnimplementedError('T5-B13-3 で実装予定');
  }

  @override
  Future<void> deleteMethod(String id) {
    throw UnimplementedError('T5-B13-3 で実装予定');
  }

  // ==========================================================================
  // Pouring Steps — 束3(T5-B13-3)で実装予定
  // ==========================================================================

  @override
  Future<List<PouringStep>> getPouringSteps() {
    throw UnimplementedError('T5-B13-3 で実装予定');
  }

  @override
  Future<void> addPouringStep(PouringStep step) {
    throw UnimplementedError('T5-B13-3 で実装予定');
  }

  @override
  Future<void> updatePouringStep(PouringStep step) {
    throw UnimplementedError('T5-B13-3 で実装予定');
  }

  @override
  Future<void> deletePouringStep(String id) {
    throw UnimplementedError('T5-B13-3 で実装予定');
  }

  @override
  Future<void> deletePouringStepsForMethod(String methodId) {
    throw UnimplementedError('T5-B13-3 で実装予定');
  }

  // ==========================================================================
  // Grinders (mill_master) — 束1(T5-B13-1、当バンドルで実装)
  // ==========================================================================

  @override
  Future<List<GrinderMaster>> getGrinders() async {
    final rows = await (_db.select(_db.millMasterTable)
          ..orderBy([(_) => _byRowId()]))
        .get();
    return rows.map((r) => r.toModel()).toList();
  }

  @override
  Future<void> addGrinder(GrinderMaster grinder) async {
    _requireId(grinder.id, forDelete: false);
    final id = grinder.id;
    await _db.transaction(() async {
      final exists = await (_db.select(_db.millMasterTable)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (exists != null) {
        _fail('既に同じIDのデータが存在します(ID: $id)');
      }
      await _db.into(_db.millMasterTable).insert(grinder.toCompanion());
    });
    _logWrite('mill_master', '追加', id);
  }

  @override
  Future<void> updateGrinder(GrinderMaster grinder) async {
    _requireId(grinder.id, forDelete: false);
    final ok =
        await _db.update(_db.millMasterTable).replace(grinder.toCompanion());
    if (!ok) {
      _fail('更新対象のデータが見つかりません(ID: ${grinder.id})');
    }
    _logWrite('mill_master', '更新', grinder.id);
  }

  @override
  Future<void> deleteGrinder(String id) async {
    _requireId(id, forDelete: true);
    await (_db.delete(_db.millMasterTable)..where((t) => t.id.equals(id)))
        .go();
    _logWrite('mill_master', '削除', id);
  }

  // ==========================================================================
  // Drippers (dripper_master) — 束1(T5-B13-1、当バンドルで実装)
  // ==========================================================================

  @override
  Future<List<DripperMaster>> getDrippers() async {
    final rows = await (_db.select(_db.dripperMasterTable)
          ..orderBy([(_) => _byRowId()]))
        .get();
    return rows.map((r) => r.toModel()).toList();
  }

  @override
  Future<void> addDripper(DripperMaster dripper) async {
    _requireId(dripper.id, forDelete: false);
    final id = dripper.id;
    await _db.transaction(() async {
      final exists = await (_db.select(_db.dripperMasterTable)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (exists != null) {
        _fail('既に同じIDのデータが存在します(ID: $id)');
      }
      await _db.into(_db.dripperMasterTable).insert(dripper.toCompanion());
    });
    _logWrite('dripper_master', '追加', id);
  }

  @override
  Future<void> updateDripper(DripperMaster dripper) async {
    _requireId(dripper.id, forDelete: false);
    final ok = await _db
        .update(_db.dripperMasterTable)
        .replace(dripper.toCompanion());
    if (!ok) {
      _fail('更新対象のデータが見つかりません(ID: ${dripper.id})');
    }
    _logWrite('dripper_master', '更新', dripper.id);
  }

  @override
  Future<void> deleteDripper(String id) async {
    _requireId(id, forDelete: true);
    await (_db.delete(_db.dripperMasterTable)..where((t) => t.id.equals(id)))
        .go();
    _logWrite('dripper_master', '削除', id);
  }

  // ==========================================================================
  // Filters (filter_master) — 束1(T5-B13-1、当バンドルで実装)
  // ==========================================================================

  @override
  Future<List<FilterMaster>> getFilters() async {
    final rows = await (_db.select(_db.filterMasterTable)
          ..orderBy([(_) => _byRowId()]))
        .get();
    return rows.map((r) => r.toModel()).toList();
  }

  @override
  Future<void> addFilter(FilterMaster filter) async {
    _requireId(filter.id, forDelete: false);
    final id = filter.id;
    await _db.transaction(() async {
      final exists = await (_db.select(_db.filterMasterTable)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (exists != null) {
        _fail('既に同じIDのデータが存在します(ID: $id)');
      }
      await _db.into(_db.filterMasterTable).insert(filter.toCompanion());
    });
    _logWrite('filter_master', '追加', id);
  }

  @override
  Future<void> updateFilter(FilterMaster filter) async {
    _requireId(filter.id, forDelete: false);
    final ok =
        await _db.update(_db.filterMasterTable).replace(filter.toCompanion());
    if (!ok) {
      _fail('更新対象のデータが見つかりません(ID: ${filter.id})');
    }
    _logWrite('filter_master', '更新', filter.id);
  }

  @override
  Future<void> deleteFilter(String id) async {
    _requireId(id, forDelete: true);
    await (_db.delete(_db.filterMasterTable)..where((t) => t.id.equals(id)))
        .go();
    _logWrite('filter_master', '削除', id);
  }

  // ==========================================================================
  // Origin Masters (origin_master) — 束1(T5-B13-1、当バンドルで実装)
  // ==========================================================================

  @override
  Future<List<OriginMaster>> fetchOriginMasters() async {
    final rows = await (_db.select(_db.originMasterTable)
          ..orderBy([(_) => _byRowId()]))
        .get();
    return rows.map((r) => r.toModel()).toList();
  }

  /// upsert。同一IDの2回目の呼び出しでは行が増えず値だけ更新される。
  /// `insertOnConflictUpdate`(drift組み込みのUPSERT)を使う実装方式を採用した。
  @override
  Future<void> saveOriginMaster(OriginMaster origin) async {
    _requireId(origin.id, forDelete: false);
    await _db
        .into(_db.originMasterTable)
        .insertOnConflictUpdate(origin.toCompanion());
    _logWrite('origin_master', '保存', origin.id);
  }

  // ==========================================================================
  // Store Masters (store_master) — 束2(T5-B13-2、当バンドルで実装)
  // ==========================================================================

  @override
  Future<List<StoreMaster>> getStores() async {
    final rows = await (_db.select(_db.storeMasterTable)
          ..orderBy([(_) => _byRowId()]))
        .get();
    return rows.map((r) => r.toModel()).toList();
  }

  @override
  Future<void> addStore(StoreMaster store) async {
    _requireId(store.id, forDelete: false);
    final id = store.id;
    await _db.transaction(() async {
      final exists = await (_db.select(_db.storeMasterTable)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (exists != null) {
        _fail('既に同じIDのデータが存在します(ID: $id)');
      }
      await _db.into(_db.storeMasterTable).insert(store.toCompanion());
    });
    _logWrite('store_master', '追加', id);
  }

  @override
  Future<void> updateStore(StoreMaster store) async {
    _requireId(store.id, forDelete: false);
    final ok =
        await _db.update(_db.storeMasterTable).replace(store.toCompanion());
    if (!ok) {
      _fail('更新対象のデータが見つかりません(ID: ${store.id})');
    }
    _logWrite('store_master', '更新', store.id);
  }

  @override
  Future<void> deleteStore(String id) async {
    _requireId(id, forDelete: true);
    await (_db.delete(_db.storeMasterTable)..where((t) => t.id.equals(id)))
        .go();
    _logWrite('store_master', '削除', id);
  }

  // ==========================================================================
  // Bean Purchases (bean_purchases) — 束2(T5-B13-2、当バンドルで実装)
  // ==========================================================================

  @override
  Future<List<BeanPurchase>> getBeanPurchases() async {
    final rows = await (_db.select(_db.beanPurchasesTable)
          ..orderBy([(_) => _byRowId()]))
        .get();
    return rows.map((r) => r.toModel()).toList();
  }

  @override
  Future<void> addBeanPurchase(BeanPurchase purchase) async {
    _requireId(purchase.id, forDelete: false);
    final id = purchase.id;
    await _db.transaction(() async {
      final exists = await (_db.select(_db.beanPurchasesTable)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (exists != null) {
        _fail('既に同じIDのデータが存在します(ID: $id)');
      }
      await _db.into(_db.beanPurchasesTable).insert(purchase.toCompanion());
    });
    _logWrite('bean_purchases', '追加', id);
  }

  @override
  Future<void> updateBeanPurchase(BeanPurchase purchase) async {
    _requireId(purchase.id, forDelete: false);
    final ok = await _db
        .update(_db.beanPurchasesTable)
        .replace(purchase.toCompanion());
    if (!ok) {
      _fail('更新対象のデータが見つかりません(ID: ${purchase.id})');
    }
    _logWrite('bean_purchases', '更新', purchase.id);
  }

  @override
  Future<void> deleteBeanPurchase(String id) async {
    _requireId(id, forDelete: true);
    await (_db.delete(_db.beanPurchasesTable)..where((t) => t.id.equals(id)))
        .go();
    _logWrite('bean_purchases', '削除', id);
  }

  // ==========================================================================
  // Analysis Snapshots — 束4(T5-B13-4)で実装予定
  // ==========================================================================

  @override
  Future<List<AnalysisSnapshot>> fetchAnalysisSnapshots({String? type}) {
    throw UnimplementedError('T5-B13-4 で実装予定');
  }

  @override
  Future<void> saveAnalysisSnapshot(AnalysisSnapshot snapshot) {
    throw UnimplementedError('T5-B13-4 で実装予定');
  }

  // ==========================================================================
  // Recipe Suggestions — 束4(T5-B13-4)で実装予定
  // ==========================================================================

  @override
  Future<List<RecipeSuggestion>> fetchRecipeSuggestions() {
    throw UnimplementedError('T5-B13-4 で実装予定');
  }

  @override
  Future<void> saveRecipeSuggestion(RecipeSuggestion suggestion) {
    throw UnimplementedError('T5-B13-4 で実装予定');
  }

  @override
  Future<void> updateRecipeSuggestion(RecipeSuggestion suggestion) {
    throw UnimplementedError('T5-B13-4 で実装予定');
  }
}
