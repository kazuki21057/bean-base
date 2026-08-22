// LocalDbService 束1(基盤+器具マスタ)のテスト。
//
// 正本: docs/local_db_schema_design.md §7.5.3(束1の完了条件)。
// 対象: mill_master(GrinderMaster) / dripper_master(DripperMaster)
// / filter_master(FilterMaster) / origin_master(OriginMaster)。
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bean_base/db/local_database.dart';
import 'package:bean_base/models/equipment_masters.dart';
import 'package:bean_base/models/origin_master.dart';
import 'package:bean_base/services/local_db_service.dart';

void main() {
  group('LocalDbService 器具マスタ(束1)', () {
    late LocalDatabase db;
    late LocalDbService service;

    setUp(() {
      db = LocalDatabase(NativeDatabase.memory());
      service = LocalDbService(db);
    });

    tearDown(() async {
      await db.close();
    });

    group('グラインダー(mill_master)', () {
      test('追加→登録順で一覧→更新→削除', () async {
        await service.addGrinder(GrinderMaster(id: 'g1', name: '1号'));
        await service.addGrinder(GrinderMaster(id: 'g2', name: '2号'));

        final list1 = await service.getGrinders();
        expect(list1.map((g) => g.id).toList(), ['g1', 'g2']);

        await service.updateGrinder(GrinderMaster(id: 'g1', name: '1号改'));
        final list2 = await service.getGrinders();
        expect(list2.firstWhere((g) => g.id == 'g1').name, '1号改');

        await service.deleteGrinder('g1');
        final list3 = await service.getGrinders();
        expect(list3.map((g) => g.id).toList(), ['g2']);
      });

      test('空IDの追加はLocalDbException', () async {
        expect(
          () => service.addGrinder(GrinderMaster(id: '', name: 'x')),
          throwsA(isA<LocalDbException>()),
        );
      });

      test('重複IDの追加はLocalDbException', () async {
        await service.addGrinder(GrinderMaster(id: 'g1', name: '1号'));
        expect(
          () => service.addGrinder(GrinderMaster(id: 'g1', name: '別')),
          throwsA(isA<LocalDbException>()),
        );
      });

      test('存在しないIDの更新はLocalDbException', () async {
        expect(
          () => service.updateGrinder(GrinderMaster(id: 'none', name: 'x')),
          throwsA(isA<LocalDbException>()),
        );
      });

      test('存在しないIDの削除は例外を投げず件数も変わらない', () async {
        await service.addGrinder(GrinderMaster(id: 'g1', name: '1号'));
        await service.deleteGrinder('none');
        final list = await service.getGrinders();
        expect(list.length, 1);
      });
    });

    group('ドリッパー(dripper_master)', () {
      test('追加→登録順で一覧→更新→削除', () async {
        await service.addDripper(DripperMaster(id: 'd1', name: 'V60'));
        await service.addDripper(DripperMaster(id: 'd2', name: 'Kalita'));

        final list1 = await service.getDrippers();
        expect(list1.map((d) => d.id).toList(), ['d1', 'd2']);

        await service.updateDripper(DripperMaster(id: 'd1', name: 'V60改'));
        final list2 = await service.getDrippers();
        expect(list2.firstWhere((d) => d.id == 'd1').name, 'V60改');

        await service.deleteDripper('d1');
        final list3 = await service.getDrippers();
        expect(list3.map((d) => d.id).toList(), ['d2']);
      });

      test('空ID追加/重複ID追加/不在ID更新はLocalDbException、不在ID削除は例外なし', () async {
        expect(
          () => service.addDripper(DripperMaster(id: '', name: 'x')),
          throwsA(isA<LocalDbException>()),
        );
        await service.addDripper(DripperMaster(id: 'd1', name: 'V60'));
        expect(
          () => service.addDripper(DripperMaster(id: 'd1', name: '別')),
          throwsA(isA<LocalDbException>()),
        );
        expect(
          () => service.updateDripper(DripperMaster(id: 'none', name: 'x')),
          throwsA(isA<LocalDbException>()),
        );
        await service.deleteDripper('none');
        final list = await service.getDrippers();
        expect(list.length, 1);
      });
    });

    group('フィルター(filter_master)', () {
      test('追加→登録順で一覧→更新→削除', () async {
        await service.addFilter(FilterMaster(id: 'f1', name: '01'));
        await service.addFilter(FilterMaster(id: 'f2', name: '02'));

        final list1 = await service.getFilters();
        expect(list1.map((f) => f.id).toList(), ['f1', 'f2']);

        await service.updateFilter(FilterMaster(id: 'f1', name: '01改'));
        final list2 = await service.getFilters();
        expect(list2.firstWhere((f) => f.id == 'f1').name, '01改');

        await service.deleteFilter('f1');
        final list3 = await service.getFilters();
        expect(list3.map((f) => f.id).toList(), ['f2']);
      });

      test('空ID追加/重複ID追加/不在ID更新はLocalDbException、不在ID削除は例外なし', () async {
        expect(
          () => service.addFilter(FilterMaster(id: '', name: 'x')),
          throwsA(isA<LocalDbException>()),
        );
        await service.addFilter(FilterMaster(id: 'f1', name: '01'));
        expect(
          () => service.addFilter(FilterMaster(id: 'f1', name: '別')),
          throwsA(isA<LocalDbException>()),
        );
        expect(
          () => service.updateFilter(FilterMaster(id: 'none', name: 'x')),
          throwsA(isA<LocalDbException>()),
        );
        await service.deleteFilter('none');
        final list = await service.getFilters();
        expect(list.length, 1);
      });

      test('sizeの前ゼロ文字列が数値化されず保持される', () async {
        await service.addFilter(
          FilterMaster(id: 'f1', name: 'フィルター', size: '02'),
        );
        final list = await service.getFilters();
        expect(list.single.size, '02');
      });
    });

    group('産地マスタ(origin_master)', () {
      test('新規DBはシード15件を返す(origin_1〜origin_15)', () async {
        final list = await service.fetchOriginMasters();
        expect(list.length, 15);
        expect(
          list.map((o) => o.id).toList(),
          List.generate(15, (i) => 'origin_${i + 1}'),
        );
      });

      test('saveOriginMasterはupsert(同一IDの2回目は行が増えず値が更新される)', () async {
        await service.saveOriginMaster(
          OriginMaster(
            id: 'origin_custom',
            countryCode: 'JP',
            nameJa: '日本',
            nameEn: 'Japan',
            region: 'アジア・太平洋',
          ),
        );
        var list = await service.fetchOriginMasters();
        expect(list.length, 16);

        await service.saveOriginMaster(
          OriginMaster(
            id: 'origin_custom',
            countryCode: 'JP',
            nameJa: '日本(改)',
            nameEn: 'Japan',
            region: 'アジア・太平洋',
          ),
        );
        list = await service.fetchOriginMasters();
        expect(list.length, 16);
        expect(
          list.firstWhere((o) => o.id == 'origin_custom').nameJa,
          '日本(改)',
        );
      });

      test('空IDのsaveOriginMasterはLocalDbException', () async {
        expect(
          () => service.saveOriginMaster(
            OriginMaster(
              id: '',
              countryCode: '',
              nameJa: '',
              nameEn: '',
              region: '',
            ),
          ),
          throwsA(isA<LocalDbException>()),
        );
      });
    });
  });
}
