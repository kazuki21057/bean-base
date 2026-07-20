import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/coffee_record.dart';
import '../models/bean_master.dart';
import '../models/equipment_masters.dart';
import '../models/method_master.dart';
import '../models/pouring_step.dart';
import '../models/origin_master.dart';
import '../models/analysis_snapshot.dart';
import '../models/recipe_suggestion.dart';
import 'data_service.dart';

class FirestoreService implements DataService {
  final FirebaseFirestore _firestore;
  final String _userId; // Assuming single-user or injected userId

  FirestoreService({
    FirebaseFirestore? firestore,
    String userId = 'default_user',
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _userId = userId;

  DocumentReference get _userDoc => _firestore.collection('users').doc(_userId);

  // --- Coffee Records ---

  @override
  Future<List<CoffeeRecord>> getCoffeeRecords() async {
    final snapshot = await _userDoc.collection('records').get();
    return snapshot.docs.map((doc) => CoffeeRecord.fromJson(doc.data())).toList();
  }

  @override
  Future<void> addCoffeeRecord(CoffeeRecord record) async {
    await _userDoc.collection('records').doc(record.id).set(record.toJson());
  }

  @override
  Future<void> updateCoffeeRecord(CoffeeRecord record) async {
    await _userDoc.collection('records').doc(record.id).update(record.toJson());
  }

  @override
  Future<void> deleteCoffeeRecord(String id) async {
    await _userDoc.collection('records').doc(id).delete();
  }

  // --- Beans ---

  @override
  Future<List<BeanMaster>> getBeans() async {
    final snapshot = await _userDoc.collection('beans').get();
    return snapshot.docs.map((doc) => BeanMaster.fromJson(doc.data())).toList();
  }

  @override
  Future<void> addBean(BeanMaster bean) async {
    await _userDoc.collection('beans').doc(bean.id).set(bean.toJson());
  }

  @override
  Future<void> updateBean(BeanMaster bean) async {
    await _userDoc.collection('beans').doc(bean.id).update(bean.toJson());
  }

  @override
  Future<void> deleteBean(String id) async {
    await _userDoc.collection('beans').doc(id).delete();
  }

  // --- Methods ---

  @override
  Future<List<MethodMaster>> getMethods() async {
    final snapshot = await _userDoc.collection('methods').get();
    return snapshot.docs.map((doc) => MethodMaster.fromJson(doc.data())).toList();
  }

  @override
  Future<void> addMethod(MethodMaster method) async {
    await _userDoc.collection('methods').doc(method.id).set(method.toJson());
  }

  @override
  Future<void> updateMethod(MethodMaster method) async {
    await _userDoc.collection('methods').doc(method.id).update(method.toJson());
  }

  @override
  Future<void> deleteMethod(String id) async {
    await _userDoc.collection('methods').doc(id).delete();
  }

  // --- Pouring Steps ---

  @override
  Future<List<PouringStep>> getPouringSteps() async {
    final snapshot = await _userDoc.collection('pouringSteps').get();
    return snapshot.docs.map((doc) => PouringStep.fromJson(doc.data())).toList();
  }

  @override
  Future<void> addPouringStep(PouringStep step) async {
    await _userDoc.collection('pouringSteps').doc(step.id).set(step.toJson());
  }

  @override
  Future<void> updatePouringStep(PouringStep step) async {
    await _userDoc.collection('pouringSteps').doc(step.id).update(step.toJson());
  }

  @override
  Future<void> deletePouringStep(String id) async {
    await _userDoc.collection('pouringSteps').doc(id).delete();
  }

  @override
  Future<void> deletePouringStepsForMethod(String methodId) async {
    final snapshot = await _userDoc.collection('pouringSteps').where('methodId', isEqualTo: methodId).get();
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // --- Grinders ---

  @override
  Future<List<GrinderMaster>> getGrinders() async {
    final snapshot = await _userDoc.collection('grinders').get();
    return snapshot.docs.map((doc) => GrinderMaster.fromJson(doc.data())).toList();
  }

  @override
  Future<void> addGrinder(GrinderMaster grinder) async {
    await _userDoc.collection('grinders').doc(grinder.id).set(grinder.toJson());
  }

  @override
  Future<void> updateGrinder(GrinderMaster grinder) async {
    await _userDoc.collection('grinders').doc(grinder.id).update(grinder.toJson());
  }

  @override
  Future<void> deleteGrinder(String id) async {
    await _userDoc.collection('grinders').doc(id).delete();
  }

  // --- Drippers ---

  @override
  Future<List<DripperMaster>> getDrippers() async {
    final snapshot = await _userDoc.collection('drippers').get();
    return snapshot.docs.map((doc) => DripperMaster.fromJson(doc.data())).toList();
  }

  @override
  Future<void> addDripper(DripperMaster dripper) async {
    await _userDoc.collection('drippers').doc(dripper.id).set(dripper.toJson());
  }

  @override
  Future<void> updateDripper(DripperMaster dripper) async {
    await _userDoc.collection('drippers').doc(dripper.id).update(dripper.toJson());
  }

  @override
  Future<void> deleteDripper(String id) async {
    await _userDoc.collection('drippers').doc(id).delete();
  }

  // --- Filters ---

  @override
  Future<List<FilterMaster>> getFilters() async {
    final snapshot = await _userDoc.collection('filters').get();
    return snapshot.docs.map((doc) => FilterMaster.fromJson(doc.data())).toList();
  }

  @override
  Future<void> addFilter(FilterMaster filter) async {
    await _userDoc.collection('filters').doc(filter.id).set(filter.toJson());
  }

  @override
  Future<void> updateFilter(FilterMaster filter) async {
    await _userDoc.collection('filters').doc(filter.id).update(filter.toJson());
  }

  @override
  Future<void> deleteFilter(String id) async {
    await _userDoc.collection('filters').doc(id).delete();
  }

  // --- T4-1d: FirestoreServiceはレガシー(未使用)のため未実装 ---
  // CLAUDE.md「Legacy (do not extend without explicit instruction)」参照。

  @override
  Future<List<OriginMaster>> fetchOriginMasters() =>
      throw UnimplementedError('FirestoreService is legacy and unused.');

  @override
  Future<void> saveOriginMaster(OriginMaster origin) =>
      throw UnimplementedError('FirestoreService is legacy and unused.');

  @override
  Future<List<AnalysisSnapshot>> fetchAnalysisSnapshots({String? type}) =>
      throw UnimplementedError('FirestoreService is legacy and unused.');

  @override
  Future<void> saveAnalysisSnapshot(AnalysisSnapshot snapshot) =>
      throw UnimplementedError('FirestoreService is legacy and unused.');

  @override
  Future<List<RecipeSuggestion>> fetchRecipeSuggestions() =>
      throw UnimplementedError('FirestoreService is legacy and unused.');

  @override
  Future<void> saveRecipeSuggestion(RecipeSuggestion suggestion) =>
      throw UnimplementedError('FirestoreService is legacy and unused.');

  @override
  Future<void> updateRecipeSuggestion(RecipeSuggestion suggestion) =>
      throw UnimplementedError('FirestoreService is legacy and unused.');
}

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});
