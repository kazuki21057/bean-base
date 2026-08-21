// ローカルDB(drift)のデータベースクラス定義。
//
// 正本: docs/local_db_schema_design.md §2。
// 公開版(Android)の永続化バックエンド。`AppEdition.useLocalDb == true` のときに使う。
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

import 'package:bean_base/db/local_database.steps.dart';
import 'package:bean_base/db/tables.dart';
import 'package:bean_base/models/origin_master.dart';

part 'local_database.g.dart';

@DriftDatabase(tables: [
  CoffeeDataTable,
  BeanMasterTable,
  MethodsMasterTable,
  PouringStepsTable,
  MillMasterTable,
  DripperMasterTable,
  FilterMasterTable,
  OriginMasterTable,
  StoreMasterTable,
  BeanPurchasesTable,
  AnalysisHistoryTable,
  RecipeSuggestionsTable,
])
class LocalDatabase extends _$LocalDatabase {
  /// [executor]を渡すとテスト用に任意の接続(例: `NativeDatabase.memory()`)で開ける。
  /// 省略時は`_openConnection()`(端末内の`bean_base.sqlite`)を使う。
  LocalDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  // ISO-8601テキストで保存する(設計書§2)。Sheetsの保存形式と揃え、
  // エクスポートJSONがそのまま人間に読める形にするため。
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          try {
            await batch((b) {
              b.insertAll(
                originMasterTable,
                kInitialOriginMasters.map(
                  (o) => OriginMasterTableCompanion.insert(
                    id: o.id,
                    countryCode: Value(o.countryCode),
                    nameJa: Value(o.nameJa),
                    nameEn: Value(o.nameEn),
                    region: Value(o.region),
                  ),
                ),
              );
            });
            debugPrint('[Antigravity] LocalDatabase.onCreate: origin_masterへ初期データ${kInitialOriginMasters.length}件を投入');
          } catch (e) {
            debugPrint('[Antigravity] LocalDatabase.onCreate: 初期データ投入エラー $e');
            rethrow;
          }
        },
        onUpgrade: stepByStep(
          from1To2: (Migrator m, Schema2 schema) async {
            await m.addColumn(schema.coffeeData, schema.coffeeData.updatedAt);
          },
        ),
      );
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'bean_base',
    // Web版はローカルDBを実行しない(useLocalDb: false)ため、
    // ここはコンパイルが通ることのみを要件とする(設計書§8.4)。
  );
}
