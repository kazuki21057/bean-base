import 'package:bean_base/models/analysis_snapshot.dart';
import 'package:bean_base/models/bean_master.dart';
import 'package:bean_base/models/coffee_record.dart';
import 'package:bean_base/models/equipment_masters.dart';
import 'package:bean_base/models/method_master.dart';
import 'package:bean_base/models/origin_master.dart';
import 'package:bean_base/models/pouring_step.dart';
import 'package:bean_base/models/recipe_suggestion.dart';
import 'package:bean_base/services/data_service.dart';
import 'package:bean_base/services/migration_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDataService implements DataService {
  final List<BeanMaster> beans;
  final List<OriginMaster> origins;
  final List<BeanMaster> updated = [];

  _FakeDataService(this.beans, this.origins);

  @override
  Future<List<BeanMaster>> getBeans() async => beans;
  @override
  Future<void> updateBean(BeanMaster bean) async {
    updated.add(bean);
    final index = beans.indexWhere((b) => b.id == bean.id);
    if (index >= 0) beans[index] = bean;
  }

  @override
  Future<List<OriginMaster>> fetchOriginMasters() async => origins;
  @override
  Future<void> saveOriginMaster(OriginMaster origin) async {}

  @override
  Future<void> addBean(BeanMaster bean) async {}
  @override
  Future<void> deleteBean(String id) async {}
  @override
  Future<void> addCoffeeRecord(CoffeeRecord record) async {}
  @override
  Future<void> updateCoffeeRecord(CoffeeRecord record) async {}
  @override
  Future<void> deleteCoffeeRecord(String id) async {}
  @override
  Future<List<CoffeeRecord>> getCoffeeRecords() async => [];
  @override
  Future<void> addDripper(DripperMaster dripper) async {}
  @override
  Future<void> updateDripper(DripperMaster dripper) async {}
  @override
  Future<void> deleteDripper(String id) async {}
  @override
  Future<List<DripperMaster>> getDrippers() async => [];
  @override
  Future<void> addFilter(FilterMaster filter) async {}
  @override
  Future<void> updateFilter(FilterMaster filter) async {}
  @override
  Future<void> deleteFilter(String id) async {}
  @override
  Future<List<FilterMaster>> getFilters() async => [];
  @override
  Future<void> addGrinder(GrinderMaster grinder) async {}
  @override
  Future<void> updateGrinder(GrinderMaster grinder) async {}
  @override
  Future<void> deleteGrinder(String id) async {}
  @override
  Future<List<GrinderMaster>> getGrinders() async => [];
  @override
  Future<void> addMethod(MethodMaster method) async {}
  @override
  Future<void> updateMethod(MethodMaster method) async {}
  @override
  Future<void> deleteMethod(String id) async {}
  @override
  Future<List<MethodMaster>> getMethods() async => [];
  @override
  Future<void> addPouringStep(PouringStep step) async {}
  @override
  Future<void> updatePouringStep(PouringStep step) async {}
  @override
  Future<void> deletePouringStep(String id) async {}
  @override
  Future<void> deletePouringStepsForMethod(String methodId) async {}
  @override
  Future<List<PouringStep>> getPouringSteps() async => [];
  @override
  Future<List<AnalysisSnapshot>> fetchAnalysisSnapshots({String? type}) async => [];
  @override
  Future<void> saveAnalysisSnapshot(AnalysisSnapshot snapshot) async {}
  @override
  Future<List<RecipeSuggestion>> fetchRecipeSuggestions() async => [];
  @override
  Future<void> saveRecipeSuggestion(RecipeSuggestion suggestion) async {}
  @override
  Future<void> updateRecipeSuggestion(RecipeSuggestion suggestion) async {}
}

BeanMaster _bean(String id, String origin, {String originId = ''}) {
  return BeanMaster(
    id: id,
    name: 'bean_$id',
    roastLevel: '中煎り',
    origin: origin,
    originId: originId,
  );
}

void main() {
  final origins = [
    OriginMaster(id: 'o_et', countryCode: 'ET', nameJa: 'エチオピア', nameEn: 'Ethiopia', region: 'アフリカ'),
    OriginMaster(id: 'o_br', countryCode: 'BR', nameJa: 'ブラジル', nameEn: 'Brazil', region: '中南米'),
  ];

  group('MigrationService.runAutoMigration', () {
    test('原文一致・英語小文字一致でoriginIdが突合される', () async {
      final beans = [
        _bean('1', 'エチオピア'),
        _bean('2', 'Ethiopia'), // 大文字小文字無視でethiopia一致
        _bean('3', 'ブラジル'),
      ];
      final service = _FakeDataService(beans, origins);
      final result = await MigrationService().runAutoMigration(service);

      expect(result.totalBeans, 3);
      expect(result.alreadyMapped, 0);
      expect(result.matched, 3);
      expect(result.unmatchedOrigins, isEmpty);
      expect(beans[0].originId, 'o_et');
      expect(beans[1].originId, 'o_et');
      expect(beans[2].originId, 'o_br');
    });

    test('突合できない産地文字列はunmatchedOriginsに集約される', () async {
      final beans = [_bean('1', '謎の産地X')];
      final service = _FakeDataService(beans, origins);
      final result = await MigrationService().runAutoMigration(service);

      expect(result.matched, 0);
      expect(result.unmatchedOrigins, ['謎の産地X']);
      expect(beans[0].originId, '');
    });

    test('冪等: originId設定済みの豆はスキップされる', () async {
      final beans = [_bean('1', 'エチオピア', originId: 'already_set')];
      final service = _FakeDataService(beans, origins);
      final result = await MigrationService().runAutoMigration(service);

      expect(result.alreadyMapped, 1);
      expect(result.matched, 0);
      expect(service.updated, isEmpty);
      expect(beans[0].originId, 'already_set');
    });
  });

  group('MigrationService.confirmManualMapping', () {
    test('指定した産地文字列を持つ未設定の豆すべてにoriginIdを反映する', () async {
      final beans = [
        _bean('1', '謎の産地X'),
        _bean('2', '謎の産地X'),
        _bean('3', '謎の産地X', originId: 'already_set'), // スキップされる
        _bean('4', '別の産地'),
      ];
      final service = _FakeDataService(beans, origins);
      final count = await MigrationService()
          .confirmManualMapping(service, '謎の産地X', origins[0]);

      expect(count, 2);
      expect(beans[0].originId, 'o_et');
      expect(beans[1].originId, 'o_et');
      expect(beans[2].originId, 'already_set');
      expect(beans[3].originId, '');
    });
  });
}
