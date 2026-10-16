import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sso_plus_plus/routing/user_router.dart';

import '../support/fake_server.dart';

Map<String, Object?> _message(int id, String subject, String body, {bool read = false}) => <String, Object?>{
      'notification_id': id,
      'claim_id': 143,
      'subject': subject,
      'body': body,
      'sent_time': '5 October 2026 : 09:20',
      'is_read': read,
    };

/// A fake server for U2. [messages] is the Q2.2 list; opening one marks it read.
FakeServer _server(List<Map<String, Object?>> messages, {String status = 'Covered'}) {
  final FakeServer s = FakeServer()..json('POST /auth/login', FakeServer.session());
  s.on('GET /u2/unread-count', (_) async =>
      FakeServer.reply(<String, int>{'unread': messages.where((Map<String, Object?> m) => m['is_read'] == false).length}));
  s.on('GET /u2/notifications', (_) async => FakeServer.reply(<String, Object>{'notifications': messages}));
  s.on('GET /u2/home-claim', (_) async => FakeServer.reply(<String, Object?>{
        'claim': <String, Object?>{
          'claim_id': 143,
          'claim_no': 'SST-2026-000143',
          'first_name': 'สมชาย',
          'injury': 'Fracture, right wrist',
          'claim_status': status,
          'submitted_time': '2 October 2026 : 14:32',
          'officer_checked_time': '5 October 2026 : 09:15',
          'appointment_status': status == 'Covered' ? 'Pending' : null,
          'appointment_time': status == 'Covered' ? '16 October 2026 : 10:00' : null,
          'consultant_name': status == 'Covered' ? 'นพ. ธนา ศรีสุข' : null,
          'office_location': status == 'Covered' ? 'Building A, Floor 3, Room 305' : null,
          'treatment_status': null,
        },
      }));
  for (final Map<String, Object?> m in messages) {
    s.on('POST /u2/notifications/${m['notification_id']}/read', (http.Request _) async {
      m['is_read'] = true;
      return FakeServer.reply(<String, Object?>{'notification': m});
    });
  }
  return s;
}

Future<void> _signIn(WidgetTester tester, FakeServer server) async {
  await tester.pumpWidget(testApp(server, userRouterProvider));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Already registered? Sign in'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('login_name')), '1103700123456');
  await tester.enterText(find.byKey(const Key('password')), 'Password123');
  await tester.tap(find.byKey(const Key('sign_in')));
  await tester.pumpAndSettle();
}

bool _redDot(WidgetTester tester) => tester
    .widget<Badge>(find.descendant(of: find.byKey(const Key('bell')), matching: find.byType(Badge)))
    .isLabelVisible;

void main() {
  testWidgets('U2 Normal Case: red dot, pop-up, the opened message is marked read', (WidgetTester tester) async {
    final FakeServer server = _server(<Map<String, Object?>>[
      _message(902, 'Appointment scheduled', 'Your appointment with นพ. ธนา ศรีสุข is on 16 October 2026 : 10:00.'),
      _message(901, 'Claim confirmed', 'Your claim SST-2026-000143 is covered under Section 33.', read: true),
    ]);
    await _signIn(tester, server);

    // U2-1: home page with the claim card and a red dot.
    expect(find.text('สวัสดี คุณสมชาย'), findsOneWidget);
    expect(find.text('Claim SST-2026-000143 · Fracture, right wrist'), findsOneWidget);
    expect(find.text('Covered'), findsOneWidget);
    expect(find.text('Next appointment'), findsOneWidget);
    expect(find.text('Waiting for your confirmation'), findsOneWidget);
    expect(find.text('นพ. ธนา ศรีสุข · Building A, Floor 3, Room 305'), findsOneWidget);
    expect(_redDot(tester), isTrue);

    // U2-2: the pop-up lists the messages, 1 unread.
    await tester.tap(find.byKey(const Key('bell')));
    await tester.pumpAndSettle();
    expect(find.text('1 unread'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('unread:902')), findsOneWidget);

    // U2-3: opening the message (Q2.3) shows it, and the red dot goes away.
    await tester.tap(find.text('Appointment scheduled'));
    await tester.pumpAndSettle();
    expect(server.requests.any((http.Request r) => r.url.path == '/u2/notifications/902/read'), isTrue);
    expect(find.text('Please confirm, change or decline this appointment on the appointment page.'), findsOneWidget);
    expect(find.text('Open appointment'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(_redDot(tester), isFalse);
  });

  testWidgets('U2 Alternate Case 1 [unread = 0]: no red dot', (WidgetTester tester) async {
    await _signIn(tester, _server(<Map<String, Object?>>[
      _message(901, 'Claim confirmed', 'Your claim SST-2026-000143 is covered under Section 33.', read: true),
    ]));
    expect(_redDot(tester), isFalse);
  });

  testWidgets('U2-4 Rejection message: the reason and the officer message', (WidgetTester tester) async {
    await _signIn(
      tester,
      _server(<Map<String, Object?>>[
        _message(904, 'Application rejected',
            'การส่งเงินสมทบไม่ครอบคลุมวันที่ประสบอันตรายตามเงื่อนไขมาตรา 33\n\nThe register shows your contributions ended in May 2026.'),
      ], status: 'Rejected'),
    );
    expect(find.text('Rejected'), findsOneWidget);
    expect(find.text('Checked by the officer'), findsOneWidget);
    await tester.tap(find.byKey(const Key('bell')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Application rejected'));
    await tester.pumpAndSettle();
    expect(find.text('Reason'), findsOneWidget);
    expect(find.text('การส่งเงินสมทบไม่ครอบคลุมวันที่ประสบอันตรายตามเงื่อนไขมาตรา 33'), findsOneWidget);
    expect(find.text('Message from the officer'), findsOneWidget);
    expect(find.text('The register shows your contributions ended in May 2026.'), findsOneWidget);
  });

  testWidgets('U2-1 Home after U3.3: the Withdrawn chip and the stopped consultation step', (WidgetTester tester) async {
    await _signIn(tester, _server(<Map<String, Object?>>[], status: 'Withdrawn'));
    expect(find.text('Withdrawn'), findsOneWidget);
    expect(find.text('You could not attend; the claim is withdrawn'), findsOneWidget);
    expect(find.text('Treatment'), findsNothing);
    expect(find.text('Next appointment'), findsNothing);
  });
}
