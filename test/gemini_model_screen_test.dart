import 'package:bean_base/screens/gemini_model_screen.dart';
import 'package:bean_base/services/ai_analysis_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('GeminiModelScreen (T3-39)', () {
    testWidgets('未設定時は「自動」が選択された状態で表示される', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: GeminiModelScreen())));
      await tester.pumpAndSettle();

      expect(find.text('自動(既定の優先順で試行)'), findsOneWidget);
      for (final model in kSelectableGeminiModels) {
        expect(find.text(model), findsOneWidget);
      }
    });

    testWidgets('モデルを選んで保存するとSharedPreferencesに保存される', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: GeminiModelScreen())));
      await tester.pumpAndSettle();

      await tester.tap(find.text(kSelectableGeminiModels.first));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('この設定を保存する'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('この設定を保存する'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('gemini_model'), kSelectableGeminiModels.first);
      expect(find.textContaining('を優先するように設定しました'), findsOneWidget);
    });

    testWidgets('既存の選択をロードし、「自動」に戻すとキーが削除される', (tester) async {
      SharedPreferences.setMockInitialValues({'gemini_model': kSelectableGeminiModels[1]});

      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: GeminiModelScreen())));
      await tester.pumpAndSettle();

      await tester.tap(find.text('自動(既定の優先順で試行)'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('この設定を保存する'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('この設定を保存する'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('gemini_model'), isNull);
      expect(find.text('自動(既定の優先順)に設定しました'), findsOneWidget);
    });
  });
}
