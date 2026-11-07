import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sso_plus_plus/routing/console_router.dart';

import 'fake_server.dart';

/// The session body of officer 1, as POST /auth/login gives it.
const Map<String, Object?> officerSession = <String, Object?>{
  'token': 't',
  'session': <String, Object?>{
    'account_id': 6,
    'role': 'OFFICER',
    'display_name': 'กัญญา วงศ์ศิริ',
    'first_name': 'กัญญา',
    'officer_id': 1,
  },
};

/// The session body of consultant 1, as POST /auth/login gives it.
const Map<String, Object?> consultantSession = <String, Object?>{
  'token': 't',
  'session': <String, Object?>{
    'account_id': 7,
    'role': 'CONSULTANT',
    'display_name': 'นพ. ธนา ศรีสุข',
    'first_name': 'ธนา',
    'consultant_id': 1,
  },
};

/// Starts the console in the Figma desktop frame (1440 x 900) and signs in
/// as officer 1, or with [session], in [language].
Future<void> signInToConsole(WidgetTester tester, FakeServer server,
    {Map<String, Object?> session = officerSession,
    List<Object> extra = const <Object>[],
    String language = 'en'}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1440, 900);
  addTearDown(tester.view.reset);
  server.json('POST /auth/login', session);
  await tester.pumpWidget(testApp(server, consoleRouterProvider, app: 'console', extra: extra, language: language));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('login_name')), 'kanya.w@sso.go.th');
  await tester.enterText(find.byKey(const Key('password')), 'Password123');
  await tester.tap(find.byKey(const Key('sign_in')));
  await tester.pumpAndSettle();
}

/// A 1 x 1 PNG image: a stored signature in the tests (R-048).
final Uint8List tinyPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');
