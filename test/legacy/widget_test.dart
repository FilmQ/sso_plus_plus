// Smoke tests for the patient application.
//
// These tests make sure that the application starts, that the navigation bar
// carries its four destinations, and that the home screen shows the seeded
// claim. The use-case tests hold the rules. Refer to IMPLEMENTATION.md.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sso_plus_plus/legacy/main_patient_legacy.dart';

void main() {
  /// Starts the application and lets the read models settle.
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PatientApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('The application starts on the home screen', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('SST Claims'), findsOneWidget);
  });

  testWidgets('The theme uses the deep purple seed', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.theme?.useMaterial3, isTrue);
    expect(app.darkTheme, isNotNull);
  });

  testWidgets('The navigation bar carries the four destinations', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    for (final String label in <String>[
      'Home',
      'Claims',
      'Appointments',
      'Inbox',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('The home screen shows the person and the next action', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Somchai Prasert'), findsOneWidget);
    expect(find.text('Action needed'), findsOneWidget);
    expect(find.text('Confirm your appointment'), findsOneWidget);
    expect(find.text('Claim progress'), findsOneWidget);
  });

  testWidgets('The claims destination lists the seeded claims', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Claims'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Your claims'), findsOneWidget);
    expect(find.text('CLM-2569-0143'), findsOneWidget);
    expect(find.text('CLM-2569-0118'), findsOneWidget);
    expect(find.text('CLM-2569-0091'), findsOneWidget);
  });
}
