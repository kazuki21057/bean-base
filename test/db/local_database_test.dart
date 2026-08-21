// ローカルDB(drift)のスキーマ検証テスト。
//
// 正本: docs/local_db_schema_design.md §10-1(スキーマ列数一致)。
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bean_base/db/local_database.dart';

void main() {
  group('LocalDatabase スキーマ検証', () {
    late LocalDatabase db;

    setUp(() {
      db = LocalDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('12テーブルが作られ、列数が設計書§4のとおりになる(§10-1)', () async {
      // 設計書§4のテーブルごとの列数: 32/21/13/8/5/5/5/5/19/9/5/12
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
        final result = await db
            .customSelect('PRAGMA table_info(${entry.key})')
            .get();
        expect(
          result.length,
          entry.value,
          reason: '${entry.key}の列数が設計書と一致しない',
        );
      }
    });

    test('DateTimeをテキスト保存で書いて読み戻すと同一時刻になる(設計書§2の未検証項目の確認)', () async {
      final original = DateTime.utc(2026, 8, 21, 9, 30, 15);
      await db.into(db.analysisHistoryTable).insert(
            AnalysisHistoryTableCompanion.insert(
              id: 'hist_datetime_check',
              createdAt: original,
            ),
          );
      final row = await (db.select(db.analysisHistoryTable)
            ..where((t) => t.id.equals('hist_datetime_check')))
          .getSingle();
      expect(row.createdAt.isAtSameMomentAs(original), isTrue);
    });
  });
}
