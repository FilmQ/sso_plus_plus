import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sso_plus_plus/routing/user_router.dart';

import '../support/fake_server.dart';

void main() {
  testWidgets('P-1 Profile Page: name, national ID, phone, address, then Sign out', (WidgetTester tester) async {
    final FakeServer server = FakeServer()
      ..json('POST /auth/login', FakeServer.session())
      ..json('GET /u2/unread-count', <String, int>{'unread': 0})
      ..json('GET /u2/home-claim', <String, Object?>{'claim': null})
      ..json('GET /auth/profile', <String, Object?>{
        'profile': <String, Object?>{
          'national_id': '1103700123456',
          'full_name': 'นาย สมชาย ประเสริฐ',
          'phone_no': '0812345678',
          'address': '88/5 ถ.เทพารักษ์ ต.บางพลีใหญ่ อ.บางพลี จ.สมุทรปราการ 10540',
        },
      });
    await tester.pumpWidget(testApp(server, userRouterProvider));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Already registered? Sign in'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('login_name')), '1103700123456');
    await tester.enterText(find.byKey(const Key('password')), 'Password123');
    await tester.tap(find.byKey(const Key('sign_in')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('นาย สมชาย ประเสริฐ'), findsOneWidget);
    expect(find.text('Signed in with national ID 1103700123456'), findsOneWidget);
    expect(find.text('081 234 5678'), findsOneWidget);
    expect(find.byKey(const Key('bell')), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Before you start'), findsOneWidget);
  });
}
