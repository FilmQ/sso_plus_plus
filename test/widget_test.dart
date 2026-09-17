// A smoke test for the application shell.
//
// The screens are not built yet. This test makes sure that the application
// starts and that the Material 3 theme is applied. Replace it with the real
// screen tests in phase P3. Refer to IMPLEMENTATION.md.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sso_plus_plus/main.dart';

void main() {
  testWidgets('The application starts', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('The theme uses Material 3', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.theme?.useMaterial3, isTrue);
    expect(app.title, 'SSO Plus Plus');
  });
}
