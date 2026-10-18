import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../support/console_app.dart';
import '../support/fake_server.dart';
import '../support/user_app.dart';

/// One QO4.2 row of 16 October 2026.
Map<String, Object?> _slot(int consultant, String name, String office, String time, String state) =>
    <String, Object?>{
      'consultant_id': consultant,
      'consultant_name': name,
      'office_location': office,
      'slot_at': '2026-10-16T$time:00.000',
      'slot_button': 'Fri $time',
      'slot_date_text': 'Fri 16 October 2026',
      'slot_time_range': '$time - ${(int.parse(time.substring(0, 2)) + 1).toString().padLeft(2, '0')}:00',
      'slot_state': state,
    };

FakeServer _server() => FakeServer()
  ..json('GET /o1/claims', <String, Object?>{'claims': <Object>[], 'counts': <String, int>{}})
  ..json('GET /o4/claims', <String, Object?>{
    'claims': <Map<String, Object?>>[
      <String, Object?>{
        'claim_id': 143,
        'claim_no': 'SST-2026-000143',
        'user_name': 'สมชาย ประเสริฐ',
        'verified_date': '5 October 2026',
      },
      <String, Object?>{
        'claim_id': 149,
        'claim_no': 'SST-2026-000149',
        'user_name': 'มานพ ศรีทอง',
        'verified_date': '6 October 2026',
      },
    ],
  })
  ..json('GET /o4/availability', <String, Object?>{
    'slots': <Map<String, Object?>>[
      _slot(1, 'นพ. ธนา ศรีสุข', 'Building A, Floor 3, Room 305', '09:00', 'busy'),
      _slot(1, 'นพ. ธนา ศรีสุข', 'Building A, Floor 3, Room 305', '10:00', 'free'),
      _slot(1, 'นพ. ธนา ศรีสุข', 'Building A, Floor 3, Room 305', '13:00', 'mine'),
    ],
  })
  ..json('POST /o4/claims/143/appointment', <String, Object?>{
    'appointment_id': 520,
    'appointment_date': '16 October 2026 : 10:00',
    'confirm_by': '15 October 2026 : 10:00',
  });

ButtonStyleButton _button(WidgetTester tester, String key) =>
    tester.widget<ButtonStyleButton>(find.byKey(ValueKey<String>(key)));

Future<void> _openScheduling(WidgetTester tester, FakeServer server) async {
  await signInToConsole(tester, server);
  await tapText(tester, 'Scheduling');
  expect(find.text('SST-2026-000143 · สมชาย ประเสริฐ · verified 5 October 2026'), findsOneWidget);
}

void main() {
  testWidgets('O4 Normal Case: choose a free hour, Offer, Confirm; Appointment Scheduled', (WidgetTester tester) async {
    final FakeServer server = _server();
    await _openScheduling(tester, server);
    expect(find.text('2 claims'), findsOneWidget);
    expect(find.text('2'), findsOneWidget, reason: 'the count in the navigation');
    expect(find.text('Choose a free hour of a consultant.'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Offer to the Consultant')).enabled, isFalse);
    expect(_button(tester, 'slot:1:09:00').enabled, isFalse, reason: 'busy');
    expect(_button(tester, 'slot:1:13:00').enabled, isFalse, reason: 'scheduled by you, pending');

    await tester.tap(find.byKey(const ValueKey<String>('slot:1:10:00')));
    await tester.pumpAndSettle();
    expect(find.text('Fri 16 October 2026'), findsWidgets);
    expect(find.text('10:00 - 11:00'), findsOneWidget);
    expect(find.text('Onsite'), findsOneWidget);
    expect(find.text("Consultant's office, Building A, Floor 3, Room 305"), findsOneWidget);
    expect(find.text('Add to waiting list'), findsNothing, reason: 'R-042');

    await tapText(tester, 'Offer to the Consultant');
    expect(find.text('Do you confirm to make an appointment at 16 October 2026 and 10:00 - 11:00'), findsOneWidget);
    expect(find.text('With นพ. ธนา ศรีสุข for สมชาย ประเสริฐ (SST-2026-000143), Building A, Floor 3, Room 305.'),
        findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
    await tester.pumpAndSettle();

    final http.Request sent = server.requests.lastWhere((http.Request r) => r.method == 'POST');
    expect(jsonDecode(sent.body), <String, Object?>{'consultant_id': 1, 'date': '2026-10-16', 'time': '10:00'});
    expect(find.text('Appointment Scheduled'), findsOneWidget);
    expect(
        find.text('The appointment on 16 October 2026 : 10:00 is reserved. สมชาย ประเสริฐ and นพ. ธนา ศรีสุข have been '
            'notified. The user must confirm it by 15 October 2026 : 10:00.'),
        findsOneWidget);
    await tapText(tester, 'OK');
    expect(find.text('Appointment Scheduled'), findsNothing);
  });

  testWidgets('O4 Alternate Case [Cancel]: the card closes and nothing is saved', (WidgetTester tester) async {
    final FakeServer server = _server();
    await _openScheduling(tester, server);
    await tester.tap(find.byKey(const ValueKey<String>('slot:1:10:00')));
    await tester.pumpAndSettle();
    await tapText(tester, 'Offer to the Consultant');
    await tapText(tester, 'Cancel');
    expect(server.requests.where((http.Request r) => r.method == 'POST' && r.url.path.startsWith('/o4')), isEmpty);
  });

  testWidgets('O4: another claim can be chosen; a taken hour (409) shows the message', (WidgetTester tester) async {
    final FakeServer server = _server()
      ..json('POST /o4/claims/149/appointment',
          <String, String>{'error': 'This time is not free any more. Choose another time.'},
          status: 409);
    await _openScheduling(tester, server);
    await tapText(tester, 'SST-2026-000149 · มานพ ศรีทอง');
    expect(find.text('SST-2026-000149 · มานพ ศรีทอง · verified 6 October 2026'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('slot:1:10:00')));
    await tester.pumpAndSettle();
    await tapText(tester, 'Offer to the Consultant');
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
    await tester.pumpAndSettle();
    expect(find.text('This time is not free any more. Choose another time.'), findsOneWidget);
  });
}
