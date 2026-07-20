import 'package:bean_base/models/analysis_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnalysisSnapshot', () {
    test('json round-trip', () {
      final snapshot = AnalysisSnapshot(
        id: 'snap_1234567890',
        createdAt: DateTime(2026, 7, 21, 10, 30),
        type: 'preference',
        dataCount: 42,
        payloadJson: '{"groups":[]}',
      );

      final json = snapshot.toJson();
      final restored = AnalysisSnapshot.fromJson(json);

      expect(restored.id, snapshot.id);
      expect(restored.createdAt, snapshot.createdAt);
      expect(restored.type, snapshot.type);
      expect(restored.dataCount, snapshot.dataCount);
      expect(restored.payloadJson, snapshot.payloadJson);
    });

    test('文字列型の件数もintにパースされる(Sheets由来の緩い型を想定)', () {
      final restored = AnalysisSnapshot.fromJson({
        'id': 'snap_1',
        'createdAt': '2026-07-21T10:30:00',
        'type': 'regression',
        'dataCount': '42',
        'payloadJson': '{}',
      });
      expect(restored.dataCount, 42);
    });
  });
}
