import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bean_base/screens/calculator_screen.dart';
import 'package:bean_base/providers/data_providers.dart';
import 'package:bean_base/models/method_master.dart';
import 'package:bean_base/models/pouring_step.dart';


void main() {
  testWidgets('CalculatorScreen displays steps and allows save', (WidgetTester tester) async {
    final mockMethod = MethodMaster(
      id: 'M1', 
      name: 'V60 Test', 
      author: 'Test', 
      baseBeanWeight: 15.0, 
      baseWaterAmount: 250.0, 
      description: 'Desc', 
      recommendedEquipment: 'V60'
    );
    
    final mockSteps = [
      PouringStep(id: 'S1', methodId: 'M1', stepOrder: 1, duration: 30, waterAmount: 30, waterReference: 15.0, description: 'Bloom'),
      PouringStep(id: 'S2', methodId: 'M1', stepOrder: 2, duration: 30, waterAmount: 120, waterReference: 15.0, description: 'Pour'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          methodMasterProvider.overrideWith((ref) async => [mockMethod]),
          pouringStepsProvider.overrideWith((ref) async => mockSteps),
          beanMasterProvider.overrideWith((ref) async => []),
          grinderMasterProvider.overrideWith((ref) async => []),
          dripperMasterProvider.overrideWith((ref) async => []),
          filterMasterProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(
          home: CalculatorScreen(),
        ),
      ),
    );

    // Initial load
    await tester.pumpAndSettle();
    expect(find.text('Select Method'), findsOneWidget);

    // Select Method
    await tester.tap(find.text('Select Method'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('V60 Test').last);
    await tester.pumpAndSettle();

    // Verify inputs filled
    expect(find.text('15.0'), findsOneWidget); // Bean weight

    // Verify Table displayed
    // Table headers
    expect(find.text('Time (Start)'), findsOneWidget);
    expect(find.text('Total Weight (g)'), findsOneWidget); 
    // Rows
    expect(find.text('Bloom'), findsOneWidget);
    expect(find.text('Pour'), findsOneWidget);
    
    // Check initial values (Start Time)
    // S1 duration 30 -> Start 0:00
    // S2 duration 30 (Start 0:30)
    expect(find.text('0:00'), findsOneWidget);
    expect(find.text('0:30'), findsOneWidget);

    // Verify Add Step
    // Wait, need to find Add Step button
    final addStepBtn = find.text('Add Step');
    await tester.scrollUntilVisible(addStepBtn, 500);
    await tester.tap(addStepBtn);
    await tester.pumpAndSettle();
    
    // Should have 3 rows now (2 original + 1 new)
    // Finding DataRows is tricky, but we can verify by counting Delete icons or cells
    expect(find.byIcon(Icons.delete), findsNWidgets(3));

    // verify Save button enabled
    final saveBtn = find.text('Save');
    // Ensure we scroll to the save button (it's near add step, so should be visible but safe to scroll)
    await tester.scrollUntilVisible(saveBtn, 500);
    expect(saveBtn, findsOneWidget);
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();

    // Dialog
    expect(find.text('Save Method'), findsOneWidget);
    expect(find.text('Overwrite'), findsOneWidget);
    expect(find.text('Save as New'), findsOneWidget);
  });
}
