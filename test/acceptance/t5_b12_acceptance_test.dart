// 受け入れテスト: T5-B12
// 完了条件(docs/改修マスタープラン.md より): 意図的にスキーマを1バージョン上げたテストが通る
// (docs/local_db_schema_design.md §10-1・§10-3の記述をそのまま検証する:
//  1. `LocalDatabase`の12テーブルの列数が設計書§4のとおりになる
//  2. 意図的にschemaVersionを1バージョン上げて列を1つ追加したときの
//     v1→v2マイグレーションが通り、既存行のデータが保持される)
//
// 受入: test/acceptance/t5_b12_acceptance_test.dart
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bean_base/db/local_database.dart';

import 'support/migration_check_db_v1.dart';
import 'support/migration_check_db_v2.dart';

void main() {
  group('受け入れ(T5-B12)', () {
    test('LocalDatabaseの12テーブルの列数が設計書§4のとおりになる(§10-1)', () async {
      final db = LocalDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      // 設計書§4のテーブルごとの列数: 31/21/13/8/5/5/5/5/19/9/5/12
      final expectedColumnCounts = <String, int>{
        'coffee_data': 31,
        'bean_master': 21,
        'methods_master': 13,
        'pouring_steps': 8,
        'mill_master': 5,
        'dripper_master': 5,
        'filter_master': 5,
        'origin_master': 5,
        'store_master': 19,
        'bean_purchases': 9,
        'analysis_history': 5,
        'recipe_suggestions': 12,
      };

      for (final entry in expectedColumnCounts.entries) {
        final result =
            await db.customSelect('PRAGMA table_info(${entry.key})').get();
        expect(
          result.length,
          entry.value,
          reason: '${entry.key}の列数が設計書と一致しない',
        );
      }
    });

    test('意図的にschemaVersionを1バージョン上げたv1→v2マイグレーションが通り、既存行が保持される(§10-3)', () async {
      // 実アプリの`lib/db/tables.dart`・`lib/db/local_database.dart`は
      // v1のまま出荷する(設計書§8.1・T5-B12完了条件の「確認後v1へ戻す」を
      // 恒久的に満たすため)。マイグレーション機構そのものの検証は
      // `support/migration_check_db_v1.dart`・`_v2.dart`の専用スキーマで行う。
      final dbFile = File(
        '${Directory.systemTemp.path}/t5_b12_migration_check_${DateTime.now().microsecondsSinceEpoch}.sqlite',
      );
      addTearDown(() {
        if (dbFile.existsSync()) {
          dbFile.deleteSync();
        }
      });

      // v1でDBを作成し、行を1件登録する。
      final dbV1 = MigrationCheckDbV1(NativeDatabase(dbFile));
      await dbV1.into(dbV1.migrationCheckTableV1).insert(
            MigrationCheckTableV1Companion.insert(
              id: 'check_1',
              label: const Value('既存データ'),
            ),
          );
      await dbV1.close();

      // 同じファイルをv2のDBクラス(列を1つ追加・onUpgradeでaddColumn)で開き、
      // マイグレーションを実行する。
      final dbV2 = MigrationCheckDbV2(NativeDatabase(dbFile));
      final rows = await dbV2.select(dbV2.migrationCheckTableV2).get();
      await dbV2.close();

      expect(rows, hasLength(1));
      expect(rows.single.id, 'check_1');
      expect(rows.single.label, '既存データ', reason: '既存行のデータが移行後も保持されること');
      expect(rows.single.addedNote, null, reason: '新規追加列は未設定のためnullであること');
    });
  });
}
