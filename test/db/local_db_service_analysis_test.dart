// LocalDbService 束4(解析スナップショット・レシピ提案)のテスト。
//
// 正本: docs/local_db_schema_design.md §7.5.3(束4の完了条件)。
// 対象: analysis_history(AnalysisSnapshot) / recipe_suggestions(RecipeSuggestion)。
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bean_base/db/local_database.dart';
import 'package:bean_base/models/analysis_snapshot.dart';
import 'package:bean_base/models/recipe_suggestion.dart';
import 'package:bean_base/services/local_db_service.dart';

AnalysisSnapshot _snapshot({
  required String id,
  required String type,
  int dataCount = 10,
  String payloadJson = '{}',
}) =>
    AnalysisSnapshot(
      id: id,
      createdAt: DateTime(2026, 1, 1),
      type: type,
      dataCount: dataCount,
      payloadJson: payloadJson,
    );

RecipeSuggestion _suggestion({
  required String id,
  String rationale = '',
  String accepted = '',
}) =>
    RecipeSuggestion(
      id: id,
      createdAt: DateTime(2026, 1, 1),
      beanId: 'b1',
      originId: '',
      roastLevel: '',
      methodId: 'm1',
      temperature: 92.0,
      brewRatio: 16.0,
      totalTimeSec: 180,
      rationale: rationale,
      accepted: accepted,
      resultRecordId: '',
    );

void main() {
  group('LocalDbService 解析スナップショット・レシピ提案(束4)', () {
    late LocalDatabase db;
    late LocalDbService service;

    setUp(() {
      db = LocalDatabase(NativeDatabase.memory());
      service = LocalDbService(db);
    });

    tearDown(() async {
      await db.close();
    });

    group('解析スナップショット(analysis_history)', () {
      test('type指定で絞り込み、未指定なら全件を登録順で返す', () async {
        await service.saveAnalysisSnapshot(_snapshot(id: 's1', type: 'pca'));
        await service.saveAnalysisSnapshot(_snapshot(id: 's2', type: 'gp'));
        await service.saveAnalysisSnapshot(_snapshot(id: 's3', type: 'pca'));

        final pcaOnly = await service.fetchAnalysisSnapshots(type: 'pca');
        expect(pcaOnly.map((s) => s.id).toList(), ['s1', 's3']);

        final all = await service.fetchAnalysisSnapshots();
        expect(all.map((s) => s.id).toList(), ['s1', 's2', 's3']);
      });

      test('saveAnalysisSnapshotは同一IDでupsertする(行が増えず値が更新される)', () async {
        await service.saveAnalysisSnapshot(
          _snapshot(id: 's1', type: 'pca', dataCount: 10),
        );
        await service.saveAnalysisSnapshot(
          _snapshot(id: 's1', type: 'pca', dataCount: 20),
        );

        final all = await service.fetchAnalysisSnapshots();
        expect(all.length, 1);
        expect(all.single.dataCount, 20);
      });

      test('空IDでの保存はLocalDbException', () async {
        expect(
          () => service.saveAnalysisSnapshot(_snapshot(id: '', type: 'pca')),
          throwsA(isA<LocalDbException>()),
        );
      });
    });

    group('レシピ提案(recipe_suggestions)', () {
      test('追加→登録順で一覧→updateRecipeSuggestionで更新', () async {
        await service.saveRecipeSuggestion(_suggestion(id: 'r1'));
        await service.saveRecipeSuggestion(_suggestion(id: 'r2'));

        final list1 = await service.fetchRecipeSuggestions();
        expect(list1.map((r) => r.id).toList(), ['r1', 'r2']);

        await service.updateRecipeSuggestion(
          _suggestion(id: 'r1', accepted: 'true'),
        );
        final list2 = await service.fetchRecipeSuggestions();
        expect(list2.firstWhere((r) => r.id == 'r1').accepted, 'true');
      });

      test('saveRecipeSuggestionは同一IDでupsertする(行が増えず値が更新される)', () async {
        await service.saveRecipeSuggestion(
          _suggestion(id: 'r1', rationale: '初回'),
        );
        await service.saveRecipeSuggestion(
          _suggestion(id: 'r1', rationale: '再計算'),
        );

        final list = await service.fetchRecipeSuggestions();
        expect(list.length, 1);
        expect(list.single.rationale, '再計算');
      });

      test('updateRecipeSuggestionは存在しないIDでLocalDbExceptionを投げる', () async {
        expect(
          () => service.updateRecipeSuggestion(_suggestion(id: 'none')),
          throwsA(isA<LocalDbException>()),
        );
      });

      test('空IDでの保存はLocalDbException', () async {
        expect(
          () => service.saveRecipeSuggestion(_suggestion(id: '')),
          throwsA(isA<LocalDbException>()),
        );
      });
    });
  });
}
