// 受け入れテスト: T5-B12
// 完了条件(docs/改修マスタープラン.md より): 意図的にスキーマを1バージョン上げたテストが通る
// (docs/local_db_schema_design.md §10-1・§10-3の記述をそのまま検証する:
//  1. `LocalDatabase`の12テーブルの列数が設計書§4のとおりになる
//  2. `LocalDatabase.schemaVersion`が2であり、make-migrationsの生成物が揃っている
//  3. 意図的にschemaVersionを1バージョン上げて列を1つ追加したv1→v2マイグレーションが
//     drift公式の`SchemaVerifier`で検証でき、既存行のデータが保持される)
//
// 受入: test/acceptance/t5_b12_acceptance_test.dart
import 'dart:io';

import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bean_base/db/local_database.dart';

import '../db/local_database/generated/schema.dart';
import '../db/local_database/generated/schema_v1.dart' as v1;
import '../db/local_database/generated/schema_v2.dart' as v2;

void main() {
  group('受け入れ(T5-B12)', () {
    test('LocalDatabaseの12テーブルの列数が設計書§4のとおりになる(§10-1)', () async {
      final db = LocalDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      // 設計書§4のテーブルごとの列数: 32/21/13/8/5/5/5/5/19/9/5/12(合計139列)。
      // coffee_dataはv2でupdated_at列が1つ増えたため31→32。
      final expectedColumnCounts = <String, int>{
        'coffee_data': 32,
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

    test('schemaVersionが2であり、make-migrationsの生成物一式が揃っている(§10-3)', () async {
      final db = LocalDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      expect(db.schemaVersion, 2);

      final generatedFiles = <String>[
        'drift_schemas/local_database/drift_schema_v2.json',
        'lib/db/local_database.steps.dart',
        'test/db/local_database/generated/schema_v1.dart',
        'test/db/local_database/generated/schema_v2.dart',
        'test/db/local_database/generated/schema.dart',
        'test/db/local_database/migration_test.dart',
      ];
      for (final path in generatedFiles) {
        expect(
          File(path).existsSync(),
          isTrue,
          reason: '$path がmake-migrationsの生成物として存在しない',
        );
      }
    });

    test('意図的にschemaVersionを2へ上げたv1→v2マイグレーションが通り、既存行が保持される(§10-3)', () async {
      final verifier = SchemaVerifier(GeneratedHelper());

      // スキーマそのものがv1→v2で期待どおりに変わっていることの検証。
      final schemaV1 = await verifier.schemaAt(1);
      final dbAtV1 = LocalDatabase(schemaV1.newConnection());
      await verifier.migrateAndValidate(dbAtV1, 2);
      await dbAtV1.close();

      // 既存データが移行後も保持されることの検証(coffee_dataに本番データを模した2行)。
      // 注意: `storeDateTimeAsText: true`のため、versioned schemaの
      // CoffeeDataDataはDateTime列も生のISO-8601テキスト(String)で表現される。
      final brewedAt1 = DateTime.utc(2026, 8, 20, 9, 30).toIso8601String();
      final brewedAt2 = DateTime.utc(2026, 8, 19, 7, 15).toIso8601String();

      final oldCoffeeData = <v1.CoffeeDataData>[
        v1.CoffeeDataData(
          id: '1',
          brewedAt: brewedAt1,
          grinderId: 'grinder_1',
          dripperId: 'dripper_1',
          filterId: 'filter_1',
          beanId: 'bean_1',
          roastLevel: '中煎り',
          origin: 'エチオピア',
          originId: 'origin_1',
          beanWeight: 15.0,
          grindSize: '中挽き',
          methodId: 'method_1',
          taste: '甘め',
          concentration: '普通',
          temperature: 92.0,
          bloomingWater: 30.0,
          totalWater: 240.0,
          bloomingTime: 30,
          totalTime: 180,
          scoreFragrance: 7,
          scoreAcidity: 5,
          scoreBitterness: 3,
          scoreSweetness: 6,
          scoreComplexity: 4,
          scoreFlavor: 8,
          scoreOverall: 7,
          comment: '甘みが出た',
          grinderImageUrl: null,
          dripperImageUrl: null,
          filterImageUrl: null,
          beanImageUrl: null,
        ),
        v1.CoffeeDataData(
          id: '2',
          brewedAt: brewedAt2,
          grinderId: 'grinder_2',
          dripperId: 'dripper_2',
          filterId: 'filter_2',
          beanId: 'bean_2',
          roastLevel: '深煎り',
          origin: 'ブラジル',
          originId: 'origin_2',
          beanWeight: 18.0,
          grindSize: '粗挽き',
          methodId: 'method_2',
          taste: '苦め',
          concentration: '濃い',
          temperature: 88.0,
          bloomingWater: 36.0,
          totalWater: 300.0,
          bloomingTime: 40,
          totalTime: 210,
          scoreFragrance: 6,
          scoreAcidity: 3,
          scoreBitterness: 8,
          scoreSweetness: 4,
          scoreComplexity: 5,
          scoreFlavor: 6,
          scoreOverall: 6,
          comment: '',
          grinderImageUrl: null,
          dripperImageUrl: null,
          filterImageUrl: null,
          beanImageUrl:
              'https://drive.google.com/uc?id=1AbCdEfGhIjKlMnOpQrStUvWxYz1234&export=view',
        ),
      ];

      final expectedNewCoffeeData = <v2.CoffeeDataData>[
        v2.CoffeeDataData(
          id: '1',
          brewedAt: brewedAt1,
          grinderId: 'grinder_1',
          dripperId: 'dripper_1',
          filterId: 'filter_1',
          beanId: 'bean_1',
          roastLevel: '中煎り',
          origin: 'エチオピア',
          originId: 'origin_1',
          beanWeight: 15.0,
          grindSize: '中挽き',
          methodId: 'method_1',
          taste: '甘め',
          concentration: '普通',
          temperature: 92.0,
          bloomingWater: 30.0,
          totalWater: 240.0,
          bloomingTime: 30,
          totalTime: 180,
          scoreFragrance: 7,
          scoreAcidity: 5,
          scoreBitterness: 3,
          scoreSweetness: 6,
          scoreComplexity: 4,
          scoreFlavor: 8,
          scoreOverall: 7,
          comment: '甘みが出た',
          grinderImageUrl: null,
          dripperImageUrl: null,
          filterImageUrl: null,
          beanImageUrl: null,
          updatedAt: null,
        ),
        v2.CoffeeDataData(
          id: '2',
          brewedAt: brewedAt2,
          grinderId: 'grinder_2',
          dripperId: 'dripper_2',
          filterId: 'filter_2',
          beanId: 'bean_2',
          roastLevel: '深煎り',
          origin: 'ブラジル',
          originId: 'origin_2',
          beanWeight: 18.0,
          grindSize: '粗挽き',
          methodId: 'method_2',
          taste: '苦め',
          concentration: '濃い',
          temperature: 88.0,
          bloomingWater: 36.0,
          totalWater: 300.0,
          bloomingTime: 40,
          totalTime: 210,
          scoreFragrance: 6,
          scoreAcidity: 3,
          scoreBitterness: 8,
          scoreSweetness: 4,
          scoreComplexity: 5,
          scoreFlavor: 6,
          scoreOverall: 6,
          comment: '',
          grinderImageUrl: null,
          dripperImageUrl: null,
          filterImageUrl: null,
          beanImageUrl:
              'https://drive.google.com/uc?id=1AbCdEfGhIjKlMnOpQrStUvWxYz1234&export=view',
          updatedAt: null,
        ),
      ];

      await verifier.testWithDataIntegrity(
        oldVersion: 1,
        newVersion: 2,
        createOld: v1.DatabaseAtV1.new,
        createNew: v2.DatabaseAtV2.new,
        openTestedDatabase: LocalDatabase.new,
        createItems: (batch, oldDb) {
          batch.insertAll(oldDb.coffeeData, oldCoffeeData);
        },
        validateItems: (newDb) async {
          expect(
            await newDb.select(newDb.coffeeData).get(),
            expectedNewCoffeeData,
            reason: '移行後もcoffee_dataの既存行のデータが保持されること',
          );
        },
      );
    });
  });
}
