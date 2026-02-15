// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bean_base/main.dart';
import 'package:bean_base/providers/data_providers.dart';

void main() {
  testWidgets('App launch smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
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
        child: const MyApp(),
      ),
    );

    // Verify that the app launches and shows the title or some initial content.
    // Since data loading might be async, we just check if it pumps without error.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
