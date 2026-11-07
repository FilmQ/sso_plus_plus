import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../support/console_app.dart';
import '../support/fake_server.dart';
import '../support/thai_check.dart';
import '../support/user_app.dart';

/// One QO5.2 row of Friday 23 October 2026.
Map<String, Object?> _time(String time, String state) => <String, Object?>{
      'slot_at': '2026-10-23T$time:00.000',
      'slot_button': 'Fri 23 Oct - $time',
      'slot_state': state,
    };

FakeServer _server() => FakeServer()
  ..json('GET /o1/claims', <String, Object?>{'claims': <Object>[], 'counts': <String, int>{}})
  ..json('GET /o5/claims', <String, Object?>{
    'claims': <Map<String, Object?>>[
      <String, Object?>{
        'claim_id': 143,
        'claim_no': 'SST-2026-000143',
        'title_name': 'นาย',
        'user_name': 'สมชาย ประเสริฐ',
        'recommended_treatment': 'Physiotherapy',
        'report_id': 87,
        'signed_date': '16 October 2026',
        'report_author': 'นพ. ธนา ศรีสุข',
      },
    ],
  })
  ..json('GET /o5/available-times', <String, Object?>{
    'slots': <Map<String, Object?>>[_time('09:00', 'busy'), _time('13:00', 'free'), _time('14:00', 'mine')],
  })
  ..json('POST /o5/claims/143/treatment',
      <String, Object?>{'treatment_id': 404, 'treatment_date': '23 October 2026 : 13:00'})
  ..json('POST /o5/claims/143/no-treatment', <String, Object?>{'claim_status': 'No treatment required'});

Future<void> _choose(WidgetTester tester, String menu, String option) async {
  await tester.tap(find.byKey(Key(menu)));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(MenuItemButton, option).last);
  await tester.pumpAndSettle();
}

Future<void> _openTreatment(WidgetTester tester, FakeServer server) async {
  await signInToConsole(tester, server);
  await tapText(tester, 'Treatment');
  expect(find.text('Treatment · SST-2026-000143'), findsOneWidget);
  expect(find.text('สมชาย ประเสริฐ · report signed 16 October 2026'), findsOneWidget);
}

void main() {
  testWidgets('O5.1 Normal Case: type, duration, facility, a free time, Book treatment; Treatment Booked',
      (WidgetTester tester) async {
    final FakeServer server = _server();
    await _openTreatment(tester, server);
    expect(find.text('Consultation report CR-0087'), findsOneWidget);
    expect(find.text('Signed'), findsWidgets);
    expect(find.text('Choose a treatment type, duration and facility first.'), findsOneWidget);

    await _choose(tester, 'treatment_type', 'Physiotherapy');
    await _choose(tester, 'duration', '90 minutes');
    await _choose(tester, 'facility', 'SSO Rehabilitation Center');
    expect(tester.widget<ButtonStyleButton>(find.byKey(const ValueKey<String>('time:2026-10-23T09:00:00.000'))).enabled,
        isFalse);
    await tester.tap(find.text('Fri 23 Oct - 13:00'));
    await tester.pumpAndSettle();
    expect(find.text('Friday 23 October 2026'), findsOneWidget);
    expect(find.text('13:00 - 14:30'), findsOneWidget, reason: 'the end is the start plus 90 minutes');
    expect(find.text('16 October 2026 - นพ. ธนา ศรีสุข'), findsOneWidget);
    expect(find.text('Recommended'), findsOneWidget);
    final http.Request times = server.requests.lastWhere((http.Request r) => r.url.path == '/o5/available-times');
    expect(times.url.queryParameters['duration'], '90');
    expect(find.text('Busy or does not fit before 12:00 or 17:00, not clickable'), findsOneWidget);

    await tapText(tester, 'Book treatment');
    expect(find.text('Do you confirm to book this treatment at SSO Rehabilitation Center : 23 October 2026 - 13:00'),
        findsOneWidget);
    expect(find.text('Physiotherapy, 90 minutes, for นาย สมชาย ประเสริฐ (SST-2026-000143).'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
    await tester.pumpAndSettle();

    final http.Request sent = server.requests.lastWhere((http.Request r) => r.method == 'POST');
    expect(jsonDecode(sent.body), <String, Object?>{
      'report_id': 87,
      'treatment_type': 'Physiotherapy',
      'duration_minutes': 90,
      'facility_name': 'SSO Rehabilitation Center',
      'date': '2026-10-23',
      'time': '13:00',
    });
    expect(find.text('Treatment Booked'), findsOneWidget);
    expect(
        find.text('Physiotherapy on 23 October 2026 : 13:00 at SSO Rehabilitation Center is booked. นาย สมชาย ประเสริฐ '
            'has been notified and can accept or ask for another date.'),
        findsOneWidget);
    await tapText(tester, 'OK');
  });

  testWidgets('O5.2 Normal Case: No treatment require, Confirm; No Treatment Required', (WidgetTester tester) async {
    final FakeServer server = _server();
    await _openTreatment(tester, server);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Book treatment')).enabled, isFalse);
    await tapText(tester, 'No treatment require');
    expect(find.text('Do you confirm that no treatment require for user นาย สมชาย ประเสริฐ'), findsOneWidget);
    expect(find.text('Claim SST-2026-000143 will be closed with the status No treatment required.'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
    await tester.pumpAndSettle();
    expect(server.requests.any((http.Request r) => r.url.path == '/o5/claims/143/no-treatment'), isTrue);
    expect(find.text('No Treatment Required'), findsOneWidget);
    expect(
        find.text('Claim SST-2026-000143 is closed. นาย สมชาย ประเสริฐ has been notified that no treatment is required.'),
        findsOneWidget);
  });

  testWidgets('O5.2 Alternate Case [Cancel]: the card closes and nothing is saved', (WidgetTester tester) async {
    final FakeServer server = _server();
    await _openTreatment(tester, server);
    await tapText(tester, 'No treatment require');
    await tapText(tester, 'Cancel');
    expect(server.requests.where((http.Request r) => r.method == 'POST' && r.url.path.startsWith('/o5')), isEmpty);
  });

  testWidgets('O5.2: a report that recommends no treatment says so in the summary', (WidgetTester tester) async {
    final FakeServer server = _server()
      ..json('GET /o5/claims', <String, Object?>{
        'claims': <Map<String, Object?>>[
          <String, Object?>{
            'claim_id': 147,
            'claim_no': 'SST-2026-000147',
            'title_name': 'นาง',
            'user_name': 'สุดา แก้วมณี',
            'recommended_treatment': 'None',
            'report_id': 85,
                'signed_date': '15 October 2026',
            'report_author': 'พญ. มาลี ใจดี',
          },
        ],
      });
    await signInToConsole(tester, server);
    await tapText(tester, 'Treatment');
    expect(find.text('Recommended treatment in the report from พญ. มาลี ใจดี: None. No treatment is required for this claim.'),
        findsOneWidget);
    expect(find.text('Recommended'), findsNothing);
  });

  testWidgets('O5.1 in Thai: the menus, a free time and Treatment Booked', (WidgetTester tester) async {
    await signInToConsole(tester, _server(), language: 'th');
    await tapText(tester, th('Treatment'));
    expect(find.text(th('Treatment · {claim}', <String, Object?>{'claim': 'SST-2026-000143'})), findsOneWidget);
    await _choose(tester, 'treatment_type', th('Physiotherapy'));
    await _choose(tester, 'duration', th('{n} minutes', <String, Object?>{'n': 90}));
    await _choose(tester, 'facility', th('SSO Rehabilitation Center'));
    await tester.tap(find.text('ศ. 23 ต.ค. - 13:00'));
    await tester.pumpAndSettle();
    expect(find.text('วันศุกร์ 23 ตุลาคม 2026'), findsOneWidget);
    expectNoEnglishLabels(tester);

    // A new language changes the label of a chosen menu entry too.
    String field(String menu) => tester
        .widget<EditableText>(find.descendant(of: find.byKey(Key(menu)), matching: find.byType(EditableText)))
        .controller
        .text;
    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();
    expect(field('duration'), '90 minutes');
    await tester.tap(find.text('ไทย'));
    await tester.pumpAndSettle();
    expect(field('duration'), '90 นาที');

    await tapText(tester, th('Book treatment'));
    expectNoEnglishLabels(tester);
    await tester.tap(find.widgetWithText(FilledButton, th('Confirm')));
    await tester.pumpAndSettle();
    expect(find.text(th('Treatment Booked')), findsOneWidget);
    expect(find.textContaining('นัดกายภาพบำบัด วันที่ 23 ตุลาคม 2026 : 13:00'), findsOneWidget);
    expectNoEnglishLabels(tester);
  });
}
