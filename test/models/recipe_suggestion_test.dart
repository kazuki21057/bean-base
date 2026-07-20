import 'package:bean_base/models/recipe_suggestion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecipeSuggestion', () {
    test('json round-trip', () {
      final suggestion = RecipeSuggestion(
        id: '1700000000000',
        createdAt: DateTime(2026, 7, 21, 9, 0),
        beanId: 'bean_1',
        originId: 'origin_1',
        roastLevel: '中煎り',
        temperature: 92.0,
        brewRatio: 15.5,
        totalTimeSec: 180,
        rationale: 'gp_mean',
        accepted: '',
        resultRecordId: '',
      );

      final json = suggestion.toJson();
      final restored = RecipeSuggestion.fromJson(json);

      expect(restored.id, suggestion.id);
      expect(restored.createdAt, suggestion.createdAt);
      expect(restored.beanId, suggestion.beanId);
      expect(restored.originId, suggestion.originId);
      expect(restored.roastLevel, suggestion.roastLevel);
      expect(restored.temperature, suggestion.temperature);
      expect(restored.brewRatio, suggestion.brewRatio);
      expect(restored.totalTimeSec, suggestion.totalTimeSec);
      expect(restored.rationale, suggestion.rationale);
      expect(restored.accepted, suggestion.accepted);
      expect(restored.resultRecordId, suggestion.resultRecordId);
    });

    test('数値が文字列で渡された場合もパースされる(Sheets由来の緩い型を想定)', () {
      final restored = RecipeSuggestion.fromJson({
        'id': '1',
        'createdAt': '2026-07-21T09:00:00',
        'beanId': 'bean_1',
        'originId': 'origin_1',
        'roastLevel': '中煎り',
        'temperature': '92.5',
        'brewRatio': '15.5',
        'totalTimeSec': '180',
        'rationale': 'group_best',
        'accepted': 'yes',
        'resultRecordId': 'r1',
      });
      expect(restored.temperature, 92.5);
      expect(restored.brewRatio, 15.5);
      expect(restored.totalTimeSec, 180);
    });
  });
}
