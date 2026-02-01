import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sheets_service.dart';
import '../models/coffee_record.dart';
import '../models/bean_master.dart';
import '../models/equipment_masters.dart';
import '../models/method_master.dart';
import '../models/pouring_step.dart';

// Data Providers
final coffeeRecordsProvider = FutureProvider<List<CoffeeRecord>>((ref) async {
  final service = ref.watch(sheetsServiceProvider);
  return service.getCoffeeRecords();
});

final beanMasterProvider = FutureProvider<List<BeanMaster>>((ref) async {
  return ref.watch(sheetsServiceProvider).getBeans();
});

final methodMasterProvider = FutureProvider<List<MethodMaster>>((ref) async {
  return ref.watch(sheetsServiceProvider).getMethods();
});

final grinderMasterProvider = FutureProvider<List<GrinderMaster>>((ref) async {
  return ref.watch(sheetsServiceProvider).getGrinders();
});

final dripperMasterProvider = FutureProvider<List<DripperMaster>>((ref) async {
  return ref.watch(sheetsServiceProvider).getDrippers();
});

final filterMasterProvider = FutureProvider<List<FilterMaster>>((ref) async {
  return ref.watch(sheetsServiceProvider).getFilters();
});

final pouringStepsProvider = FutureProvider<List<PouringStep>>((ref) async {
  return ref.watch(sheetsServiceProvider).getPouringSteps();
});
