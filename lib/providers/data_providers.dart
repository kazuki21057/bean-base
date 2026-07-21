import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/data_service.dart';
import '../models/coffee_record.dart';
import '../models/bean_master.dart';
import '../models/equipment_masters.dart';
import '../models/method_master.dart';
import '../models/pouring_step.dart';
import '../models/origin_master.dart';
import '../models/analysis_snapshot.dart';

// Data Providers
final coffeeRecordsProvider = FutureProvider<List<CoffeeRecord>>((ref) async {
  final service = ref.watch(dataServiceProvider);
  return service.getCoffeeRecords();
});

final beanMasterProvider = FutureProvider<List<BeanMaster>>((ref) async {
  return ref.watch(dataServiceProvider).getBeans();
});

final methodMasterProvider = FutureProvider<List<MethodMaster>>((ref) async {
  return ref.watch(dataServiceProvider).getMethods();
});

final grinderMasterProvider = FutureProvider<List<GrinderMaster>>((ref) async {
  return ref.watch(dataServiceProvider).getGrinders();
});

final dripperMasterProvider = FutureProvider<List<DripperMaster>>((ref) async {
  return ref.watch(dataServiceProvider).getDrippers();
});

final filterMasterProvider = FutureProvider<List<FilterMaster>>((ref) async {
  return ref.watch(dataServiceProvider).getFilters();
});

final pouringStepsProvider = FutureProvider<List<PouringStep>>((ref) async {
  return ref.watch(dataServiceProvider).getPouringSteps();
});

/// T4-1e(設計書§3.2): 産地マスタ選択ドロップダウン用。
final originMasterProvider = FutureProvider<List<OriginMaster>>((ref) async {
  return ref.watch(dataServiceProvider).fetchOriginMasters();
});

/// T4-4c(設計書§7.3): 好みプロファイルの履歴(preference_section.dartの履歴タブ用)。
final preferenceSnapshotsProvider = FutureProvider<List<AnalysisSnapshot>>((ref) async {
  return ref.watch(dataServiceProvider).fetchAnalysisSnapshots(type: 'preference');
});

// AI Analysis State
final aiAnalysisResultProvider = StateProvider<String?>((ref) => null);
final aiAnalysisLoadingProvider = StateProvider<bool>((ref) => false);
