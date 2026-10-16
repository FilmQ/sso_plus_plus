import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sso_plus_plus/routing/user_router.dart';
import 'package:sso_plus_plus/widgets/date_text.dart';

import '../support/fake_server.dart';

const String _base = '/u3/claims/143/appointment';

/// A Q3.2 row of appointment 504 with [status].
Map<String, Object?> _appointment(String status, {String date = '16 / 10 / 2026 : 10:00'}) => <String, Object?>{
      'appointment_id': 504,
      'consultant_id': 1,
      'appointment_status': status,
      'appointment_date': date,
      'scheduled_by': 'กัญญา วงศ์ศิริ',
      'appointment_type': 'Onsite',
      'consultant_name': 'นพ. ธนา ศรีสุข',
      'office_location': 'Building A, Floor 3, Room 305',
      'claim_no': 'SST-2026-000143',
      'injury': 'Fracture, right wrist',
      'injury_date': '28 September 2026',
    };

FakeServer _server() => FakeServer()
  ..json('POST /auth/login', FakeServer.session())
  ..json('GET /u2/unread-count', <String, int>{'unread': 1})
  ..json('GET /u2/home-claim', <String, Object?>{'claim': null})
  ..json('GET /u3/unread-count', <String, int>{'unread': 1})
  ..json('GET /u3/notifications', <String, Object?>{
    'notifications': <Map<String, Object?>>[
      <String, Object?>{
        'notification_id': 902,
        'claim_id': 143,
        'subject': 'Appointment scheduled',
        'body': 'Your appointment with นพ. ธนา ศรีสุข is on 16 October 2026 : 10:00.',
        'sent_time': '5 October 2026 : 10:30',
        'is_read': false,
      },
    ],
  })
  ..json('GET $_base', <String, Object?>{'appointment': _appointment('Pending')})
  ..json('POST $_base/confirm', <String, Object?>{'appointment': _appointment('Confirmed')})
  ..json('GET $_base/free-slots', <String, Object?>{'slots': <String>['13:00', '14:00']})
  ..json('POST $_base/cancel', <String, Object?>{'appointment': _appointment('Cancelled')});

Map<String, Object?> _body(FakeServer s, String path) =>
    jsonDecode(s.requests.lastWhere((http.Request r) => r.url.path == path).body) as Map<String, Object?>;

bool _sent(FakeServer s, String path) => s.requests.any((http.Request r) => r.method == 'POST' && r.url.path == path);

/// U3.1 steps 1 to 3: sign in, the red dot, the Notification Page, the message.
Future<void> _openAppointment(WidgetTester tester, FakeServer server) async {
  // The Figma phone frame: 390 x 844.
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

  expect(tester.widget<Badge>(find.byKey(const Key('notifications_dot'))).isLabelVisible, isTrue);
  await tester.tap(find.text('Notifications'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Appointment scheduled'));
  await tester.pumpAndSettle();
  expect(find.text('Awaiting your confirmation'), findsOneWidget);
  expect(find.text('กัญญา วงศ์ศิริ (Evaluation Officer)'), findsOneWidget);
  expect(find.text('Onsite (at the rehabilitation center)'), findsOneWidget);
  expect(find.text('นพ. ธนา ศรีสุข'), findsOneWidget);
  expect(find.text('ธศ'), findsOneWidget); // avatar letters without the title
}

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('U3.1 Normal Case: Confirm Appointment, the reminder, the message is read', (WidgetTester tester) async {
    final FakeServer server = _server();
    await _openAppointment(tester, server);

    await _tap(tester, 'Confirm Appointment');
    expect(_body(server, '$_base/confirm')['notification_id'], 902);
    expect(find.text('สิ่งที่ต้องเตรียม'), findsOneWidget);
    expect(find.text('บัตรประชาชนตัวจริง'), findsOneWidget);
    await _tap(tester, 'OK');
    expect(find.text('Confirmed'), findsOneWidget);
    expect(find.text('Confirm Appointment'), findsNothing);
  });

  testWidgets('U3.2 Normal Case: a new date and time, then the date-changed message', (WidgetTester tester) async {
    final DateTime today = DateTime.now();
    final FakeServer server = _server()
      ..json('POST $_base/reschedule', <String, Object?>{'appointment': _appointment('Confirmed', date: 'new')});
    await _openAppointment(tester, server);

    await _tap(tester, 'Request Another Date');
    expect(find.text('Request another date'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('new_date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Free times on this date'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('slot:12:00')), findsNothing);
    expect(find.byKey(const ValueKey<String>('slot:16:00')), findsNothing);
    expect(tester.widget<ButtonStyleButton>(find.byKey(const ValueKey<String>('slot:09:00'))).enabled, isFalse);
    await tester.tap(find.byKey(const ValueKey<String>('slot:13:00')));
    await tester.pumpAndSettle();
    await _tap(tester, 'Confirm Date');

    final Map<String, Object?> sent = _body(server, '$_base/reschedule');
    expect(sent, containsPair('new_date', DateText.iso(today)));
    expect(sent, containsPair('new_time', '13:00'));
    expect(find.text('เวลานัดหมายถูกเปลี่ยนเป็น ${DateText.long(today)} : 13:00'), findsOneWidget);
  });

  testWidgets('U3.2 Alternate Case 1 [Cancel]: back to the page without a change', (WidgetTester tester) async {
    final FakeServer server = _server();
    await _openAppointment(tester, server);
    await _tap(tester, 'Request Another Date');
    await _tap(tester, 'Cancel');
    expect(_sent(server, '$_base/reschedule'), isFalse);
    expect(find.text('Awaiting your confirmation'), findsOneWidget);
  });

  testWidgets('U3.3 Normal Case: I cannot attend, Confirm Cancel Appointment', (WidgetTester tester) async {
    final FakeServer server = _server();
    await _openAppointment(tester, server);
    await _tap(tester, 'I cannot attend');
    expect(find.text('คุณแน่ใจที่จะยกเลิกการนัดหมายหรือไม่'), findsOneWidget);
    expect(find.text('If you cancel, your claim will be withdrawn and the consultant will be informed.'), findsOneWidget);
    await _tap(tester, 'Confirm Cancel Appointment');
    expect(_body(server, '$_base/cancel')['notification_id'], 902);
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('เวลานัดหมายถูกยกเลิกแล้ว'), findsOneWidget);
    expect(find.text('I cannot attend'), findsNothing);
  });

  testWidgets('U3.3 Alternate Case 1 [Go Back]: back to the page without a change', (WidgetTester tester) async {
    final FakeServer server = _server();
    await _openAppointment(tester, server);
    await _tap(tester, 'I cannot attend');
    await _tap(tester, 'Go Back');
    expect(_sent(server, '$_base/cancel'), isFalse);
    expect(find.text('Awaiting your confirmation'), findsOneWidget);
  });

  testWidgets('U3: a 409 answer shows the server message and reloads the page', (WidgetTester tester) async {
    final FakeServer server = _server()
      ..json('POST $_base/confirm', <String, String>{'error': 'The data changed. Open the page again.'}, status: 409);
    await _openAppointment(tester, server);
    await _tap(tester, 'Confirm Appointment');
    expect(find.text('The data changed. Open the page again.'), findsOneWidget);
    expect(find.text('สิ่งที่ต้องเตรียม'), findsNothing);
  });
}
