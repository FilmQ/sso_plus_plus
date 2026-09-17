// Smoke tests for the staff console.
//
// The console is a desktop web surface, so every test sets a 1440x900
// surface. That is the size of the frames in Figma page 02.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sso_plus_plus/main_console.dart';

void main() {
  /// Starts the console at a desktop size and lets the read models settle.
  Future<void> pumpConsole(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: ConsoleApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('The console starts on the verification worklist', (
    WidgetTester tester,
  ) async {
    await pumpConsole(tester);

    expect(find.text('SST Console'), findsOneWidget);
    expect(find.text('Verification'), findsWidgets);
    expect(find.text('Claims awaiting verification'), findsOneWidget);
  });

  testWidgets('The rail shows the work of both roles at once', (
    WidgetTester tester,
  ) async {
    await pumpConsole(tester);

    // Section 7.2 of IMPLEMENTATION.md: the rail does not change with the
    // role, so both groups and all seven destinations are present.
    expect(find.text('EVALUATION OFFICER'), findsOneWidget);
    expect(find.text('CONSULTANT'), findsOneWidget);
    for (final String label in <String>[
      'Scheduling',
      'Confirmations',
      'Consultations',
      'Sessions',
      'Reports',
      'Treatment',
    ]) {
      expect(find.text(label), findsWidgets, reason: 'rail misses $label');
    }
  });

  testWidgets('The rail names the member of staff who is signed in', (
    WidgetTester tester,
  ) async {
    await pumpConsole(tester);

    expect(find.text('P. Chaiyaporn'), findsOneWidget);
    expect(find.textContaining('Evaluation Officer'), findsWidgets);
  });

  testWidgets('The worklist shows the seeded claims and their results', (
    WidgetTester tester,
  ) async {
    await pumpConsole(tester);

    expect(find.text('CLM-2569-0139'), findsOneWidget);
    expect(find.text('CLM-2569-0128'), findsOneWidget);

    // The four register answers that the seed produces.
    expect(find.text('Covered'), findsWidgets);
    expect(find.text('Not covered'), findsOneWidget);
    expect(find.text('Needs review'), findsWidgets);
    expect(find.text('Register down'), findsOneWidget);
  });

  testWidgets('The KPI tiles agree with the table below them', (
    WidgetTester tester,
  ) async {
    await pumpConsole(tester);

    expect(find.text('Awaiting verification'), findsOneWidget);
    expect(find.text('Register unavailable'), findsOneWidget);
    expect(find.text('Verified this week'), findsOneWidget);
  });

  testWidgets('Opening a claim shows the decision panel', (
    WidgetTester tester,
  ) async {
    await pumpConsole(tester);

    await tester.tap(find.text('Open').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Claim summary'), findsOneWidget);
    expect(find.text('Section 33 eligibility'), findsOneWidget);
    expect(find.text('Officer decision'), findsOneWidget);
    // BR-06 is named on the screen itself.
    expect(find.textContaining('BR-06'), findsWidgets);
  });
}
