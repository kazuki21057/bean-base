import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/coffee_record.dart';
import '../models/bean_master.dart';
import '../models/equipment_masters.dart';
import '../models/method_master.dart';
import '../models/pouring_step.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;
  final String _userId; // Assuming single-user or injected userId

  FirestoreService({
    FirebaseFirestore? firestore,
    String userId = 'default_user',
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _userId = userId;

  DocumentReference get _userDoc => _firestore.collection('users').doc(_userId);

  // --- Coffee Records ---

  Future<List<CoffeeRecord>> getCoffeeRecords() async {
    final snapshot = await _userDoc.collection('records').get();
    return snapshot.docs.map((doc) => CoffeeRecord.fromJson(doc.data())).toList();
  }

  Future<void> addCoffeeRecord(CoffeeRecord record) async {
    await _userDoc.collection('records').doc(record.id).set(record.toJson());
  }

  Future<void> updateCoffeeRecord(CoffeeRecord record) async {
    await _userDoc.collection('records').doc(record.id).update(record.toJson());
  }

  Future<void> deleteCoffeeRecord(String id) async {
    await _userDoc.collection('records').doc(id).delete();
  }

  // --- Beans ---

  Future<List<BeanMaster>> getBeans() async {
    final snapshot = await _userDoc.collection('beans').get();
    return snapshot.docs.map((doc) => BeanMaster.fromJson(doc.data())).toList();
  }

  Future<void> addBean(BeanMaster bean) async {
    await _userDoc.collection('beans').doc(bean.id).set(bean.toJson());
  }

  Future<void> updateBean(BeanMaster bean) async {
    await _userDoc.collection('beans').doc(bean.id).update(bean.toJson());
  }

  Future<void> deleteBean(String id) async {
    await _userDoc.collection('beans').doc(id).delete();
  }

  // --- Methods ---

  Future<List<MethodMaster>> getMethods() async {
    final snapshot = await _userDoc.collection('methods').get();
    return snapshot.docs.map((doc) => MethodMaster.fromJson(doc.data())).toList();
  }

  Future<void> addMethod(MethodMaster method) async {
    await _userDoc.collection('methods').doc(method.id).set(method.toJson());
  }

  Future<void> updateMethod(MethodMaster method) async {
    await _userDoc.collection('methods').doc(method.id).update(method.toJson());
  }

  Future<void> deleteMethod(String id) async {
    await _userDoc.collection('methods').doc(id).delete();
  }

  // --- Pouring Steps ---

  Future<List<PouringStep>> getPouringSteps() async {
    final snapshot = await _userDoc.collection('pouringSteps').get();
    return snapshot.docs.map((doc) => PouringStep.fromJson(doc.data())).toList();
  }

  Future<void> addPouringStep(PouringStep step) async {
    await _userDoc.collection('pouringSteps').doc(step.id).set(step.toJson());
  }

  Future<void> updatePouringStep(PouringStep step) async {
    await _userDoc.collection('pouringSteps').doc(step.id).update(step.toJson());
  }

  Future<void> deletePouringStep(String id) async {
    await _userDoc.collection('pouringSteps').doc(id).delete();
  }

  Future<void> deletePouringStepsForMethod(String methodId) async {
    final snapshot = await _userDoc.collection('pouringSteps').where('methodId', isEqualTo: methodId).get();
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // --- Grinders ---

  Future<List<GrinderMaster>> getGrinders() async {
    final snapshot = await _userDoc.collection('grinders').get();
    return snapshot.docs.map((doc) => GrinderMaster.fromJson(doc.data())).toList();
  }

  Future<void> addGrinder(GrinderMaster grinder) async {
    await _userDoc.collection('grinders').doc(grinder.id).set(grinder.toJson());
  }

  Future<void> updateGrinder(GrinderMaster grinder) async {
    await _userDoc.collection('grinders').doc(grinder.id).update(grinder.toJson());
  }

  Future<void> deleteGrinder(String id) async {
    await _userDoc.collection('grinders').doc(id).delete();
  }

  // --- Drippers ---

  Future<List<DripperMaster>> getDrippers() async {
    final snapshot = await _userDoc.collection('drippers').get();
    return snapshot.docs.map((doc) => DripperMaster.fromJson(doc.data())).toList();
  }

  Future<void> addDripper(DripperMaster dripper) async {
    await _userDoc.collection('drippers').doc(dripper.id).set(dripper.toJson());
  }

  Future<void> updateDripper(DripperMaster dripper) async {
    await _userDoc.collection('drippers').doc(dripper.id).update(dripper.toJson());
  }

  Future<void> deleteDripper(String id) async {
    await _userDoc.collection('drippers').doc(id).delete();
  }

  // --- Filters ---

  Future<List<FilterMaster>> getFilters() async {
    final snapshot = await _userDoc.collection('filters').get();
    return snapshot.docs.map((doc) => FilterMaster.fromJson(doc.data())).toList();
  }

  Future<void> addFilter(FilterMaster filter) async {
    await _userDoc.collection('filters').doc(filter.id).set(filter.toJson());
  }

  Future<void> updateFilter(FilterMaster filter) async {
    await _userDoc.collection('filters').doc(filter.id).update(filter.toJson());
  }

  Future<void> deleteFilter(String id) async {
    await _userDoc.collection('filters').doc(id).delete();
  }
}

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});
