import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../services/sheets_service.dart';

class FirestoreMigrator {
  final SheetsService sheetsService;
  final String userId;

  FirestoreMigrator({
    required this.sheetsService,
    this.userId = 'default_user',
  });

  Future<void> migrateAllData() async {
    try {
      debugPrint('=== Starting Firestore Migration ===');
      final firestore = FirebaseFirestore.instance;
      final userDocRef = firestore.collection('users').doc(userId);

      // Fetch all data from Google Sheets
      debugPrint('Fetching beans...');
      final beans = await sheetsService.getBeans();
      debugPrint('Fetching grinders...');
      final grinders = await sheetsService.getGrinders();
      debugPrint('Fetching drippers...');
      final drippers = await sheetsService.getDrippers();
      debugPrint('Fetching filters...');
      final filters = await sheetsService.getFilters();
      debugPrint('Fetching methods...');
      final methods = await sheetsService.getMethods();
      debugPrint('Fetching pouring steps...');
      final pouringSteps = await sheetsService.getPouringSteps();
      debugPrint('Fetching coffee records...');
      final records = await sheetsService.getCoffeeRecords();

      debugPrint('Data fetched successfully. Writing to Firestore...');

      // Due to Firestore batch limits (500 ops per batch), we should process in chunks.
      // But for BeanBase, the total count is likely < 500. Let's just be safe and use a helper.
      
      var batch = firestore.batch();
      var operationCount = 0;

      Future<void> commitBatchIfNeeded() async {
        if (operationCount >= 450) {
          await batch.commit();
          batch = firestore.batch();
          operationCount = 0;
          debugPrint('Committed a batch of writes.');
        }
      }

      // 1. Beans
      for (var bean in beans) {
        if (bean.id.isEmpty) continue;
        final docRef = userDocRef.collection('beans').doc(bean.id);
        batch.set(docRef, bean.toJson());
        operationCount++;
        await commitBatchIfNeeded();
      }

      // 2. Grinders
      for (var grinder in grinders) {
        if (grinder.id.isEmpty) continue;
        final docRef = userDocRef.collection('grinders').doc(grinder.id);
        batch.set(docRef, grinder.toJson());
        operationCount++;
        await commitBatchIfNeeded();
      }

      // 3. Drippers
      for (var dripper in drippers) {
        if (dripper.id.isEmpty) continue;
        final docRef = userDocRef.collection('drippers').doc(dripper.id);
        batch.set(docRef, dripper.toJson());
        operationCount++;
        await commitBatchIfNeeded();
      }

      // 4. Filters
      for (var filter in filters) {
        if (filter.id.isEmpty) continue;
        final docRef = userDocRef.collection('filters').doc(filter.id);
        batch.set(docRef, filter.toJson());
        operationCount++;
        await commitBatchIfNeeded();
      }

      // 5. Methods
      for (var method in methods) {
        if (method.id.isEmpty) continue;
        final docRef = userDocRef.collection('methods').doc(method.id);
        batch.set(docRef, method.toJson());
        operationCount++;
        await commitBatchIfNeeded();
      }

      // 6. Pouring Steps
      for (var step in pouringSteps) {
        if (step.id.isEmpty) continue;
        final docRef = userDocRef.collection('pouringSteps').doc(step.id);
        batch.set(docRef, step.toJson());
        operationCount++;
        await commitBatchIfNeeded();
      }

      // 7. Coffee Records
      for (var record in records) {
        if (record.id.isEmpty) continue;
        final docRef = userDocRef.collection('records').doc(record.id);
        batch.set(docRef, record.toJson());
        operationCount++;
        await commitBatchIfNeeded();
      }

      // Commit any remaining operations
      if (operationCount > 0) {
        await batch.commit();
      }

      debugPrint('=== Firestore Migration Completed Successfully ===');
    } catch (e, stack) {
      debugPrint('Error during migration: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }
}
