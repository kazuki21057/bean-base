// ignore_for_file: always_use_package_imports
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/coffee_record.dart';
import '../models/bean_master.dart';
import '../models/equipment_masters.dart';
import '../models/method_master.dart';
import '../models/pouring_step.dart';
import '../models/origin_master.dart';
import '../models/analysis_snapshot.dart';
import '../models/recipe_suggestion.dart';
import '../models/store_master.dart';
import '../models/bean_purchase.dart';
import '../config/app_edition.dart';
import '../providers/local_db_provider.dart';
import 'local_db_service.dart';
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

  // --- Origin Masters (T4-1d, 設計書§3.4.3) ---
  Future<List<OriginMaster>> fetchOriginMasters();
  Future<void> saveOriginMaster(OriginMaster origin);

  // --- Store Masters (T3-67, docs/store_master_design.md§2) ---
  Future<List<StoreMaster>> getStores();
  Future<void> addStore(StoreMaster store);
  Future<void> updateStore(StoreMaster store);
  Future<void> deleteStore(String id);

  // --- Bean Purchases (T3-62, docs/bean_purchase_design.md§2) ---
  Future<List<BeanPurchase>> getBeanPurchases();
  Future<void> addBeanPurchase(BeanPurchase purchase);
  Future<void> updateBeanPurchase(BeanPurchase purchase);
  Future<void> deleteBeanPurchase(String id);

  // --- Analysis Snapshots (T4-1d, 設計書§3.4.3) ---
  Future<List<AnalysisSnapshot>> fetchAnalysisSnapshots({String? type});
  Future<void> saveAnalysisSnapshot(AnalysisSnapshot snapshot);

  // --- Recipe Suggestions (T4-1d, 設計書§3.4.3) ---
  Future<List<RecipeSuggestion>> fetchRecipeSuggestions();
  Future<void> saveRecipeSuggestion(RecipeSuggestion suggestion);
  Future<void> updateRecipeSuggestion(RecipeSuggestion suggestion);
}

/// Single source of truth for the active data backend.
///
/// Cycle 19 (Phase 0): reverted from Firestore to Google Sheets. Flip the
/// returned implementation here to switch backends app-wide.
///
/// T5-B3(E-3): [AppEdition.useLocalDb]経由でバックエンドを切り替える。
/// T5-B13-4でLocalDbServiceへの配線を行った。現状は両エディションとも
/// useLocalDb: falseのため、挙動は従来どおりSheetsServiceのまま変わらない
/// (切替はT5-B14完了後にユーザー判断、docs/local_db_schema_design.md §11-2)。
final dataServiceProvider = Provider<DataService>((ref) {
  final edition = ref.watch(appEditionProvider);
  if (edition.useLocalDb) {
    return LocalDbService(ref.watch(localDatabaseProvider));
  }
  return SheetsService();
});
