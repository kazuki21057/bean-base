import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/coffee_record.dart';
import '../models/bean_master.dart';
import '../models/equipment_masters.dart';
import '../models/method_master.dart';
import '../models/pouring_step.dart';
import 'sheets_service.dart';

/// Abstract data-access contract shared by all storage backends.
///
/// Both [SheetsService] and `FirestoreService` implement this interface so the
/// app can switch backends by changing a single provider ([dataServiceProvider]).
/// As of Cycle 19 (Phase 0) the active backend is Google Sheets.
abstract class DataService {
  // --- Coffee Records ---
  Future<List<CoffeeRecord>> getCoffeeRecords();
  Future<void> addCoffeeRecord(CoffeeRecord record);
  Future<void> updateCoffeeRecord(CoffeeRecord record);
  Future<void> deleteCoffeeRecord(String id);

  // --- Beans ---
  Future<List<BeanMaster>> getBeans();
  Future<void> addBean(BeanMaster bean);
  Future<void> updateBean(BeanMaster bean);
  Future<void> deleteBean(String id);

  // --- Methods ---
  Future<List<MethodMaster>> getMethods();
  Future<void> addMethod(MethodMaster method);
  Future<void> updateMethod(MethodMaster method);
  Future<void> deleteMethod(String id);

  // --- Pouring Steps ---
  Future<List<PouringStep>> getPouringSteps();
  Future<void> addPouringStep(PouringStep step);
  Future<void> updatePouringStep(PouringStep step);
  Future<void> deletePouringStep(String id);
  Future<void> deletePouringStepsForMethod(String methodId);

  // --- Grinders ---
  Future<List<GrinderMaster>> getGrinders();
  Future<void> addGrinder(GrinderMaster grinder);
  Future<void> updateGrinder(GrinderMaster grinder);
  Future<void> deleteGrinder(String id);

  // --- Drippers ---
  Future<List<DripperMaster>> getDrippers();
  Future<void> addDripper(DripperMaster dripper);
  Future<void> updateDripper(DripperMaster dripper);
  Future<void> deleteDripper(String id);

  // --- Filters ---
  Future<List<FilterMaster>> getFilters();
  Future<void> addFilter(FilterMaster filter);
  Future<void> updateFilter(FilterMaster filter);
  Future<void> deleteFilter(String id);
}

/// Single source of truth for the active data backend.
///
/// Cycle 19 (Phase 0): reverted from Firestore to Google Sheets. Flip the
/// returned implementation here to switch backends app-wide.
final dataServiceProvider = Provider<DataService>((ref) {
  return SheetsService();
});
