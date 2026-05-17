import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../models/coffee_record.dart';
import '../models/bean_master.dart';
import '../models/equipment_masters.dart';
import '../models/method_master.dart';
import '../models/pouring_step.dart';

// Data Providers
final coffeeRecordsProvider = FutureProvider<List<CoffeeRecord>>((ref) async {
  final service = ref.watch(firestoreServiceProvider);
  return service.getCoffeeRecords();
});

final beanMasterProvider = FutureProvider<List<BeanMaster>>((ref) async {
  return ref.watch(firestoreServiceProvider).getBeans();
});

final methodMasterProvider = FutureProvider<List<MethodMaster>>((ref) async {
  return ref.watch(firestoreServiceProvider).getMethods();
});

final grinderMasterProvider = FutureProvider<List<GrinderMaster>>((ref) async {
  return ref.watch(firestoreServiceProvider).getGrinders();
});

final dripperMasterProvider = FutureProvider<List<DripperMaster>>((ref) async {
  return ref.watch(firestoreServiceProvider).getDrippers();
});

final filterMasterProvider = FutureProvider<List<FilterMaster>>((ref) async {
  return ref.watch(firestoreServiceProvider).getFilters();
});

final pouringStepsProvider = FutureProvider<List<PouringStep>>((ref) async {
  return ref.watch(firestoreServiceProvider).getPouringSteps();
});

// AI Analysis State
final aiAnalysisResultProvider = StateProvider<String?>((ref) => null);
final aiAnalysisLoadingProvider = StateProvider<bool>((ref) => false);
