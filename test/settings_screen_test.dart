import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bean_base/providers/theme_provider.dart';
import 'package:bean_base/screens/settings_screen.dart';

/// Cycle 20 T2-7: 090(設定)の本実装(メインカラー・APIキー保存)の検証。
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SettingsScreen: メインカラーを選択するとSharedPreferencesに保存される', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // デフォルトはプリセットの1色目
    expect(container.read(mainColorProvider), mainColorPresets.first);

    // 2色目(黒板グリーン)の中心をタップ
    final circles = find.byWidgetPredicate((w) => w is Container && w.decoration is BoxDecoration && (w.decoration as BoxDecoration).shape == BoxShape.circle);
    expect(circles, findsNWidgets(mainColorPresets.length));
    await tester.tap(circles.at(1));
    await tester.pumpAndSettle();

    expect(container.read(mainColorProvider), mainColorPresets[1]);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(kMainColorPrefsKey), mainColorPresets[1].toARGB32());
  });

  testWidgets('SettingsScreen: APIキーを入力して保存するとSharedPreferencesに保存される', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'test-api-key-123');
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.text('設定を保存する'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('gemini_api_key'), 'test-api-key-123');
    expect(find.text('設定を保存しました'), findsOneWidget);
  });
}
