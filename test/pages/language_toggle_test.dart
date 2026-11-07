import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sso_plus_plus/l10n/language_provider.dart';
import 'package:sso_plus_plus/routing/console_router.dart';
import 'package:sso_plus_plus/routing/user_router.dart';

import '../support/console_app.dart';
import '../support/fake_server.dart';
import '../support/user_app.dart';

final Finder _toggle = find.byKey(const Key('language_toggle'));

String _appLanguage(WidgetTester tester) => Localizations.localeOf(tester.element(_toggle)).languageCode;

Future<void> _chooseThai(WidgetTester tester) async {
  await tester.ensureVisible(_toggle);
  await tester.pumpAndSettle();
  await tester.tap(find.text('ไทย'));
  await tester.pumpAndSettle();
}

Future<String?> _kept() async => (await SharedPreferences.getInstance()).getString(LanguageNotifier.storeKey);

void main() {
  late FakeServer server;

  setUp(() {
    server = FakeServer();
    server.json('POST /auth/login', FakeServer.session());
    server.json('GET /u2/unread-count', <String, int>{'unread': 0});
    server.json('GET /u2/home-claim', <String, Object?>{'claim': null});
    server.json('GET /o1/claims', <String, Object?>{'claims': <Object>[], 'counts': <String, int>{}});
    server.json('GET /auth/profile', <String, Object?>{
      'profile': <String, Object?>{
        'national_id': '1103700123456',
        'full_name': 'นาย สมชาย ประเสริฐ',
        'phone_no': '0812345678',
        'address': '88/5 ถ.เทพารักษ์ ต.บางพลีใหญ่ อ.บางพลี จ.สมุทรปราการ 10540',
      },
    });
  });

  testWidgets('First launch is English; the Register Page toggle changes to Thai and keeps it', (WidgetTester tester) async {
    await tester.pumpWidget(testApp(server, userRouterProvider));
    await tester.pumpAndSettle();
    expect(_appLanguage(tester), 'en');
    await _chooseThai(tester);
    expect(_appLanguage(tester), 'th');
    expect(await _kept(), 'th');
    expect(MaterialLocalizations.of(tester.element(_toggle)).okButtonLabel, 'ตกลง', reason: 'Material labels change');
    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();
    expect(_appLanguage(tester), 'en');
    expect(await _kept(), 'en');
  });

  testWidgets('A kept language shows at the next start', (WidgetTester tester) async {
    await tester.pumpWidget(testApp(server, userRouterProvider, language: 'th'));
    await tester.pumpAndSettle();
    expect(_appLanguage(tester), 'th');
  });

  testWidgets('The Login Page has the toggle', (WidgetTester tester) async {
    await tester.pumpWidget(testApp(server, userRouterProvider));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Already registered? Sign in'));
    await tester.pumpAndSettle();
    await _chooseThai(tester);
    expect(_appLanguage(tester), 'th');
  });

  testWidgets('The Profile Page has the toggle and its label', (WidgetTester tester) async {
    await signInToUserApp(tester, server);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsOneWidget);
    await _chooseThai(tester);
    expect(find.text('ภาษา'), findsOneWidget);
    expect(await _kept(), 'th');
  });

  testWidgets('The Console Login Page has the toggle', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(server, consoleRouterProvider, app: 'console'));
    await tester.pumpAndSettle();
    await _chooseThai(tester);
    expect(_appLanguage(tester), 'th');
  });

  testWidgets('The console navigation has the toggle, also in the drawer of a narrow screen', (WidgetTester tester) async {
    await signInToConsole(tester, server);
    await _chooseThai(tester);
    expect(_appLanguage(tester), 'th');
    tester.view.physicalSize = const Size(800, 900);
    await tester.pumpAndSettle();
    expect(_toggle, findsNothing);
    final ScaffoldState scaffold = tester.state<ScaffoldState>(find.byType(Scaffold).first);
    scaffold.openDrawer();
    await tester.pumpAndSettle();
    expect(_toggle, findsOneWidget);
  });
}
