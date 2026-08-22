// LocalDbService 束3(抽出記録・メソッド・注湯ステップ)のテスト。
//
// 正本: docs/local_db_schema_design.md §7.5.3(束3の完了条件)。
// 対象: coffee_data(CoffeeRecord) / methods_master(MethodMaster)
// / pouring_steps(PouringStep)。
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bean_base/db/local_database.dart';
import 'package:bean_base/models/coffee_record.dart';
import 'package:bean_base/models/method_master.dart';
import 'package:bean_base/models/pouring_step.dart';
import 'package:bean_base/services/local_db_service.dart';

CoffeeRecord _record({
  required String id,
  required DateTime brewedAt,
  String beanId = '',
  String methodId = '',
  String originId = '',
  String comment = '',
}) =>
    CoffeeRecord(
      id: id,
      brewedAt: brewedAt,
      grinderId: '',
      dripperId: '',
      filterId: '',
      beanId: beanId,
      roastLevel: '',
      origin: '',
      beanWeight: 15.0,
      grindSize: '',
      methodId: methodId,
      taste: '',
      concentration: '',
      temperature: 92.0,
      bloomingWater: 30.0,
      totalWater: 240.0,
      bloomingTime: 30,
      totalTime: 180,
      scoreFragrance: 5,
      scoreAcidity: 5,
      scoreBitterness: 5,
      scoreSweetness: 5,
      scoreComplexity: 5,
      scoreFlavor: 5,
      scoreOverall: 5,
      comment: comment,
      originId: originId,
    );

void main() {
  group('LocalDbService 抽出記録・メソッド・注湯ステップ(束3)', () {
    late LocalDatabase db;
    late LocalDbService service;

    setUp(() {
      db = LocalDatabase(NativeDatabase.memory());
      service = LocalDbService(db);
    });

    tearDown(() async {
      await db.close();
    });

    group('抽出記録(coffee_data)', () {
      test('追加→登録順で一覧→更新→削除', () async {
        await service.addCoffeeRecord(
          _record(id: 'c1', brewedAt: DateTime(2026, 1, 1)),
        );
        await service.addCoffeeRecord(
          _record(id: 'c2', brewedAt: DateTime(2026, 1, 2)),
        );

        final list1 = await service.getCoffeeRecords();
        expect(list1.map((r) => r.id).toList(), ['c1', 'c2']);

        await service.updateCoffeeRecord(
          _record(id: 'c1', brewedAt: DateTime(2026, 1, 1), comment: '改'),
        );
        final list2 = await service.getCoffeeRecords();
        expect(list2.firstWhere((r) => r.id == 'c1').comment, '改');

        await service.deleteCoffeeRecord('c1');
        final list3 = await service.getCoffeeRecords();
        expect(list3.map((r) => r.id).toList(), ['c2']);
      });

      test('空ID追加/重複ID追加/不在ID更新はLocalDbException、不在ID削除は例外なし', () async {
        expect(
          () => service.addCoffeeRecord(
            _record(id: '', brewedAt: DateTime(2026, 1, 1)),
          ),
          throwsA(isA<LocalDbException>()),
        );
        await service.addCoffeeRecord(
          _record(id: 'c1', brewedAt: DateTime(2026, 1, 1)),
        );
        expect(
          () => service.addCoffeeRecord(
            _record(id: 'c1', brewedAt: DateTime(2026, 1, 2)),
          ),
          throwsA(isA<LocalDbException>()),
        );
        expect(
          () => service.updateCoffeeRecord(
            _record(id: 'none', brewedAt: DateTime(2026, 1, 1)),
          ),
          throwsA(isA<LocalDbException>()),
        );
        await service.deleteCoffeeRecord('none');
        final list = await service.getCoffeeRecords();
        expect(list.length, 1);
      });

      test('DateTime往復がisAtSameMomentAsで一致する', () async {
        final brewedAt = DateTime(2026, 8, 1, 10, 30, 15);
        await service.addCoffeeRecord(_record(id: 'c1', brewedAt: brewedAt));
        final list = await service.getCoffeeRecords();
        expect(list.single.brewedAt.isAtSameMomentAs(brewedAt), isTrue);
      });

      test('本番模倣: 削除済み豆のbean_id・空method_id・空origin_idでも全件返る', () async {
        await service.addCoffeeRecord(
          _record(
            id: 'c1',
            brewedAt: DateTime(2026, 1, 1),
            beanId: 'deleted_bean_id',
            methodId: '',
            originId: '',
          ),
        );
        final list = await service.getCoffeeRecords();
        expect(list.length, 1);
        expect(list.single.beanId, 'deleted_bean_id');
        expect(list.single.methodId, '');
        expect(list.single.originId, '');
      });
    });

    group('メソッドマスタ(methods_master)', () {
      test('追加→登録順で一覧→更新→削除', () async {
        await service.addMethod(
          MethodMaster(
            id: 'm1',
            name: 'メソッド1',
            author: '',
            baseBeanWeight: 15.0,
            baseWaterAmount: 240.0,
            description: '',
            recommendedEquipment: '',
          ),
        );
        await service.addMethod(
          MethodMaster(
            id: 'm2',
            name: 'メソッド2',
            author: '',
            baseBeanWeight: 15.0,
            baseWaterAmount: 240.0,
            description: '',
            recommendedEquipment: '',
          ),
        );

        final list1 = await service.getMethods();
        expect(list1.map((m) => m.id).toList(), ['m1', 'm2']);

        await service.updateMethod(
          MethodMaster(
            id: 'm1',
            name: 'メソッド1改',
            author: '',
            baseBeanWeight: 15.0,
            baseWaterAmount: 240.0,
            description: '',
            recommendedEquipment: '',
          ),
        );
        final list2 = await service.getMethods();
        expect(list2.firstWhere((m) => m.id == 'm1').name, 'メソッド1改');

        await service.deleteMethod('m1');
        final list3 = await service.getMethods();
        expect(list3.map((m) => m.id).toList(), ['m2']);
      });

      test('空ID追加/重複ID追加/不在ID更新はLocalDbException、不在ID削除は例外なし', () async {
        MethodMaster m(String id) => MethodMaster(
              id: id,
              name: 'x',
              author: '',
              baseBeanWeight: 15.0,
              baseWaterAmount: 240.0,
              description: '',
              recommendedEquipment: '',
            );
        expect(
          () => service.addMethod(m('')),
          throwsA(isA<LocalDbException>()),
        );
        await service.addMethod(m('m1'));
        expect(
          () => service.addMethod(m('m1')),
          throwsA(isA<LocalDbException>()),
        );
        expect(
          () => service.updateMethod(m('none')),
          throwsA(isA<LocalDbException>()),
        );
        await service.deleteMethod('none');
        final list = await service.getMethods();
        expect(list.length, 1);
      });

      test('temperature/grindSizeのnullが往復する', () async {
        await service.addMethod(
          MethodMaster(
            id: 'm1',
            name: 'メソッド1',
            author: '',
            baseBeanWeight: 15.0,
            baseWaterAmount: 240.0,
            temperature: null,
            grindSize: null,
            description: '',
            recommendedEquipment: '',
          ),
        );
        final list = await service.getMethods();
        expect(list.single.temperature, isNull);
        expect(list.single.grindSize, isNull);
      });
    });

    group('注湯ステップ(pouring_steps)', () {
      test('追加→登録順で一覧→更新→削除', () async {
        await service.addPouringStep(
          PouringStep(
            id: 's1',
            methodId: 'm1',
            stepOrder: 1,
            duration: 30,
            waterAmount: 30.0,
            waterReference: 30.0,
            description: '',
          ),
        );
        await service.addPouringStep(
          PouringStep(
            id: 's2',
            methodId: 'm1',
            stepOrder: 2,
            duration: 30,
            waterAmount: 60.0,
            waterReference: 60.0,
            description: '',
          ),
        );

        final list1 = await service.getPouringSteps();
        expect(list1.map((s) => s.id).toList(), ['s1', 's2']);

        await service.updatePouringStep(
          PouringStep(
            id: 's1',
            methodId: 'm1',
            stepOrder: 1,
            duration: 30,
            waterAmount: 30.0,
            waterReference: 30.0,
            description: '改',
          ),
        );
        final list2 = await service.getPouringSteps();
        expect(list2.firstWhere((s) => s.id == 's1').description, '改');

        await service.deletePouringStep('s1');
        final list3 = await service.getPouringSteps();
        expect(list3.map((s) => s.id).toList(), ['s2']);
      });

      test('空ID追加/重複ID追加/不在ID更新はLocalDbException、不在ID削除は例外なし', () async {
        PouringStep s(String id) => PouringStep(
              id: id,
              methodId: 'm1',
              stepOrder: 1,
              duration: 30,
              waterAmount: 30.0,
              waterReference: 30.0,
              description: '',
            );
        expect(
          () => service.addPouringStep(s('')),
          throwsA(isA<LocalDbException>()),
        );
        await service.addPouringStep(s('s1'));
        expect(
          () => service.addPouringStep(s('s1')),
          throwsA(isA<LocalDbException>()),
        );
        expect(
          () => service.updatePouringStep(s('none')),
          throwsA(isA<LocalDbException>()),
        );
        await service.deletePouringStep('none');
        final list = await service.getPouringSteps();
        expect(list.length, 1);
      });

      test('waterRatioのnullが往復する', () async {
        await service.addPouringStep(
          PouringStep(
            id: 's1',
            methodId: 'm1',
            stepOrder: 1,
            duration: 30,
            waterAmount: 30.0,
            waterReference: 30.0,
            waterRatio: null,
            description: '',
          ),
        );
        final list = await service.getPouringSteps();
        expect(list.single.waterRatio, isNull);
      });

      test('deletePouringStepsForMethodは対象メソッドのステップのみ全削除する', () async {
        await service.addPouringStep(
          PouringStep(
            id: 's1',
            methodId: 'm1',
            stepOrder: 1,
            duration: 30,
            waterAmount: 30.0,
            waterReference: 30.0,
            description: '',
          ),
        );
        await service.addPouringStep(
          PouringStep(
            id: 's2',
            methodId: 'm1',
            stepOrder: 2,
            duration: 30,
            waterAmount: 60.0,
            waterReference: 60.0,
            description: '',
          ),
        );
        await service.addPouringStep(
          PouringStep(
            id: 's3',
            methodId: 'm2',
            stepOrder: 1,
            duration: 30,
            waterAmount: 30.0,
            waterReference: 30.0,
            description: '',
          ),
        );

        await service.deletePouringStepsForMethod('m1');

        final list = await service.getPouringSteps();
        expect(list.map((s) => s.id).toList(), ['s3']);
      });

      test('deletePouringStepsForMethodは対象なしでも例外にしない', () async {
        await service.deletePouringStepsForMethod('none');
        final list = await service.getPouringSteps();
        expect(list, isEmpty);
      });
    });
  });
}
