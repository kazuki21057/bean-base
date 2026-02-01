import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bean_base/screens/home_screen.dart';
import 'package:bean_base/providers/data_providers.dart';
import 'package:bean_base/models/coffee_record.dart';

void main() {
  testWidgets('App starts and navigates to CoffeeLogListScreen from NavigationRail', (WidgetTester tester) async {
    // Override provider to return empty list instantly to avoid loading state issues or network
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coffeeRecordsProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    // Allow Future to complete
    await tester.pumpAndSettle();

    // Verify HomeScreen is displayed
    expect(find.text('BeanBase 2.0'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('No coffee logs found. Start brewing!'), findsOneWidget);

    // Find NavigationRail destination for Logs (Icon(Icons.list))
    final logsIcon = find.byIcon(Icons.list);
    expect(logsIcon, findsOneWidget);

    // Tap Logs
    await tester.tap(logsIcon);
    await tester.pumpAndSettle();

    // Verify we are on CoffeeLogListScreen
    expect(find.text('All Coffee Logs'), findsOneWidget);
  });
}
