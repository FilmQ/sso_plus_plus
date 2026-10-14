import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sso_plus_plus/routing/console_router.dart';
import 'package:sso_plus_plus/routing/user_router.dart';

import '../support/fake_server.dart';

void main() {
  testWidgets('Login: a wrong password shows the server message', (WidgetTester tester) async {
    final FakeServer server = FakeServer()
      ..json('POST /auth/login', <String, String>{'error': 'The login name or the password is not correct.'},
          status: 401);
    await tester.pumpWidget(testApp(server, userRouterProvider));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Already registered? Sign in'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('login_name')), '1103700123456');
    await tester.enterText(find.byKey(const Key('password')), 'Wrong1234');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('The login name or the password is not correct.'), findsOneWidget);
  });

  testWidgets('Login: the user app sends app=user and opens Home', (WidgetTester tester) async {
    final FakeServer server = FakeServer()..json('POST /auth/login', FakeServer.session());
    await tester.pumpWidget(testApp(server, userRouterProvider));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Already registered? Sign in'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('login_name')), '1103700123456');
    await tester.enterText(find.byKey(const Key('password')), 'Password123');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    final Map<String, Object?> sent = jsonDecode(server.requests.first.body) as Map<String, Object?>;
    expect(sent['app'], 'user');
    expect(find.text('Home'), findsWidgets);
  });

  testWidgets('Login: the console sends app=console and shows the officer name', (WidgetTester tester) async {
    final FakeServer server = FakeServer()
      ..json('POST /auth/login', <String, Object?>{
        'token': 't',
        'session': <String, Object?>{
          'account_id': 6,
          'role': 'OFFICER',
          'display_name': 'กัญญา วงศ์ศิริ',
          'first_name': 'กัญญา',
          'officer_id': 1,
        },
      });
    await tester.pumpWidget(testApp(server, consoleRouterProvider, app: 'console'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('login_name')), 'kanya.w@sso.go.th');
    await tester.enterText(find.byKey(const Key('password')), 'Password123');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect((jsonDecode(server.requests.first.body) as Map<String, Object?>)['app'], 'console');
    expect(find.text('กัญญา วงศ์ศิริ'), findsOneWidget);
    expect(find.text('Evaluation Officer'), findsOneWidget);
  });
}
