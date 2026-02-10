import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bean_base/screens/home_screen.dart';
import 'package:bean_base/providers/data_providers.dart';

import 'package:bean_base/layout/main_layout.dart';
import 'package:bean_base/utils/nav_key.dart';

void main() {
  testWidgets('App starts and navigates to CoffeeLogListScreen from NavigationRail', (WidgetTester tester) async {
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
          home: const HomeScreen(),
        ),
      ),
    );

    // Allow Future to complete
    await tester.pumpAndSettle();

    // Verify HomeScreen is displayed
    expect(find.text('BeanBase 2.0'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('No recent brews found.'), findsOneWidget);

    // Find NavigationRail destination for Logs (Icon(Icons.coffee))
    final logsIcon = find.byIcon(Icons.coffee);
    expect(logsIcon, findsOneWidget);

    // Tap Logs
    await tester.tap(logsIcon);
    await tester.pumpAndSettle();

    // Verify we are on CoffeeLogListScreen
    expect(find.text('All Coffee Logs'), findsOneWidget);
  });
}
