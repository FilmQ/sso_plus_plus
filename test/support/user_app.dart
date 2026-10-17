import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sso_plus_plus/routing/user_router.dart';

import 'fake_server.dart';

/// Starts the user app in the Figma phone frame (390 x 844) and signs in.
Future<void> signInToUserApp(WidgetTester tester, FakeServer server) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(testApp(server, userRouterProvider));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Already registered? Sign in'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('login_name')), '1103700123456');
  await tester.enterText(find.byKey(const Key('password')), 'Password123');
  await tester.tap(find.byKey(const Key('sign_in')));
  await tester.pumpAndSettle();
}

/// Scrolls [text] into view and taps it.
Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}
