import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bean_base/screens/dashboard_screen.dart';
import 'package:bean_base/providers/data_providers.dart';

import 'package:bean_base/layout/main_layout.dart';
import 'package:bean_base/utils/nav_key.dart';

void main() {
  testWidgets('App starts and navigates to LogListScreen from NavigationRail', (WidgetTester tester) async {
    // Override provider to return empty list instantly to avoid loading state issues or network
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coffeeRecordsProvider.overrideWith((ref) async => []),
          beanMasterProvider.overrideWith((ref) async => []),
          methodMasterProvider.overrideWith((ref) async => []),
          grinderMasterProvider.overrideWith((ref) async => []),
          dripperMasterProvider.overrideWith((ref) async => []),
          filterMasterProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          builder: (context, child) => MainLayout(child: child ?? const SizedBox.shrink()), 
          home: const DashboardScreen(),
        ),
      ),
    );

    // Allow Future to complete
    await tester.pumpAndSettle();

    // Verify DashboardScreen (001) is displayed
    expect(find.text('001'), findsOneWidget);
    expect(find.text('ダッシュボード'), findsOneWidget);
    expect(find.text('在庫中の豆はありません'), findsOneWidget);
    expect(find.text('抽出履歴がありません'), findsOneWidget);

    // Find NavigationRail destination for Logs (Icon(Icons.coffee))
    final logsIcon = find.byIcon(Icons.coffee);
    expect(logsIcon, findsOneWidget);

    // Tap Logs
    await tester.tap(logsIcon);
    await tester.pumpAndSettle();

    // Verify we are on LogListScreen
    expect(find.text('抽出履歴(リスト)'), findsOneWidget);
    expect(find.text('抽出履歴がありません'), findsOneWidget);
  });

  testWidgets('Masters タブから新実装のMastersHubScreenへ遷移する(旧MasterListScreenではない)', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coffeeRecordsProvider.overrideWith((ref) async => []),
          beanMasterProvider.overrideWith((ref) async => []),
          methodMasterProvider.overrideWith((ref) async => []),
          grinderMasterProvider.overrideWith((ref) async => []),
          dripperMasterProvider.overrideWith((ref) async => []),
          filterMasterProvider.overrideWith((ref) async => []),
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

    // Masters タブのアイコン(Icons.list)をタップ(ダッシュボードの「在庫一覧を見る」ボタンにも
    // 同じアイコンがあるため、NavigationRail配下に絞り込む)
    final mastersIcon = find.descendant(
      of: find.byType(NavigationRail),
      matching: find.byIcon(Icons.list),
    );
    expect(mastersIcon, findsOneWidget);
    await tester.tap(mastersIcon);
    await tester.pumpAndSettle();

    // 新しいMastersHubScreen(5マスターへのハブ)が表示され、豆一覧項目をタップすると
    // 実装済みのBeanListScreen(010)へ遷移する
    expect(find.text('豆管理'), findsOneWidget);
    expect(find.text('ドリッパー管理'), findsOneWidget);

    await tester.tap(find.text('豆管理'));
    await tester.pumpAndSettle();

    expect(find.text('010'), findsOneWidget);
    expect(find.text('豆管理(カード)'), findsOneWidget);
  });
}
