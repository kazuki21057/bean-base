// T5-B2(E-2): enabledScreens/showDebugScreens をscreen_registry・main_layout・
// settings_screenへ接続するホワイトリスト方式の受入テスト。
// 仕様の正本: docs/android_monetization/コードベース構成方針.md §9.3(6番の表)。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bean_base/config/app_edition.dart';
import 'package:bean_base/routing/app_screen.dart';
import 'package:bean_base/routing/screen_registry.dart';
import 'package:bean_base/layout/main_layout.dart';
import 'package:bean_base/providers/data_providers.dart';
import 'package:bean_base/screens/dashboard_screen.dart';
import 'package:bean_base/screens/settings_screen.dart';
import 'package:bean_base/utils/nav_key.dart';

import '../helpers/fake_master_notifiers.dart';

/// enabledScreens から統計(statistics)だけを外したテスト専用エディション。
/// フィルタが実際に効いていることを確認するためのケース5専用。
final AppEdition _editionWithoutStatistics = AppEdition(
  kind: Edition.public,
  enabledScreens: kAllAppScreens.difference({AppScreen.statistics}),
  useLocalDb: false,
  useLocalImages: false,
  aiKeyMode: AiKeyMode.ownKey,
  showAds: false,
  enableSubscription: false,
  showDebugScreens: false,
);

List<Override> _dataOverrides() => [
      coffeeRecordsProvider.overrideWith((ref) async => []),
      beanMasterProvider.overrideWith(() => FakeBeanMasterNotifier(() async => [])),
      methodMasterProvider.overrideWith(() => FakeMethodMasterNotifier(() async => [])),
      grinderMasterProvider.overrideWith(() => FakeGrinderMasterNotifier(() async => [])),
      dripperMasterProvider.overrideWith(() => FakeDripperMasterNotifier(() async => [])),
      filterMasterProvider.overrideWith(() => FakeFilterMasterNotifier(() async => [])),
    ];

void main() {
  // ケース1: kPersonalEdition は全画面を許可し、デバッグ画面も出す。
  test('ケース1: kPersonalEditionはenabledScreensが全画面・showDebugScreensがtrue', () {
    expect(kPersonalEdition.enabledScreens.length, AppScreen.values.length);
    expect(kPersonalEdition.showDebugScreens, true);
  });

  // ケース2: kPublicEdition も現時点ではenabledScreensは全画面(§9.2 D2)だが、
  // デバッグ画面は隠す。
  test('ケース2: kPublicEditionはenabledScreensが全画面・showDebugScreensがfalse', () {
    expect(kPublicEdition.enabledScreens.length, AppScreen.values.length);
    expect(kPublicEdition.showDebugScreens, false);
  });

  // ケース3: visibleScreens()はenumの宣言順を保ったままフィルタする。
  test('ケース3: visibleScreens(kPublicEdition)はAppScreen.valuesと同一(順序込み)', () {
    expect(visibleScreens(kPublicEdition), AppScreen.values);
  });

  group('ケース4: MainLayoutのdestinationsがpublicで5件のまま', () {
    testWidgets('モバイル幅(NavigationBar)', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._dataOverrides(),
            appEditionProvider.overrideWithValue(kPublicEdition),
          ],
          child: MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            builder: (context, child) => MainLayout(child: child ?? const SizedBox.shrink()),
            home: const DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.destinations.length, 5);
      for (final label in ['ホーム', '履歴', 'マスター', 'レシピ', '統計']) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('デスクトップ幅(NavigationRail)', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._dataOverrides(),
            appEditionProvider.overrideWithValue(kPublicEdition),
          ],
          child: MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            builder: (context, child) => MainLayout(child: child ?? const SizedBox.shrink()),
            home: const DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.destinations.length, 5);
      for (final label in ['ホーム', '履歴', 'マスター', 'レシピ', '統計']) {
        expect(find.text(label), findsOneWidget);
      }
    });
  });

  group('ケース5: enabledScreensを絞るとdestinationsが実際に減る', () {
    testWidgets('モバイル幅(NavigationBar): 統計タブが消え、selectedIndexを4にしても落ちない', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer(
        overrides: [
          ..._dataOverrides(),
          appEditionProvider.overrideWithValue(_editionWithoutStatistics),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            builder: (context, child) => MainLayout(child: child ?? const SizedBox.shrink()),
            home: const DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.destinations.length, 4);
      expect(find.text('統計'), findsNothing);

      // navIndexProviderの値が範囲外(4)になっても safeIndex でクランプされ、
      // NavigationBar/NavigationRailのassertに触れない。
      container.read(navIndexProvider.notifier).state = 4;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('ケース6: SettingsScreenのデバッグセクションはpublicで隠れる', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('personalではデバッグ導線が表示される', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appEditionProvider.overrideWithValue(kPersonalEdition)],
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('画面一覧 (Cycle 20 T1-1b)'), findsOneWidget);
      expect(find.text('Firebaseストレージ動作確認'), findsOneWidget);
    });

    testWidgets('publicではデバッグ導線が表示されない', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appEditionProvider.overrideWithValue(kPublicEdition)],
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('画面一覧 (Cycle 20 T1-1b)'), findsNothing);
      expect(find.text('Firebaseストレージ動作確認'), findsNothing);
    });
  });
}
