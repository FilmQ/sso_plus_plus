import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../support/fake_server.dart';
import '../support/user_app.dart';

const String _base = '/u4/treatments/401';

/// A Q6.1 row of treatment 401 (the Treatments tab).
const Map<String, Object?> _scheduleRow = <String, Object?>{
  'treatment_id': 401,
  'facility_name': 'SSO Rehabilitation Center',
  'treatment_type': 'Physiotherapy',
  'duration_minutes': 60,
  'treatment_date': '23 October 2026 : 13:00',
  'treatment_status': 'Pending',
  'claim_id': 143,
  'claim_no': 'SST-2026-000143',
  'injury': 'Fracture, right wrist',
  'injury_date': '28 September 2026',
};

/// A QU4.4 row of treatment 401 with [status] (the Confirm Treatment page).
Map<String, Object?> _treatment(String status, {String date = '23 / 10 / 2026 : 13:00'}) => <String, Object?>{
      'treatment_id': 401,
      'claim_id': 143,
      'treatment_status': status,
      'treatment_date': date,
      'treatment_type': 'Physiotherapy',
      'duration_minutes': 60,
      'facility_name': 'SSO Rehabilitation Center',
      'booked_by': 'กัญญา วงศ์ศิริ',
      'claim_no': 'SST-2026-000143',
      'injury': 'Fracture, right wrist',
      'report_signed_date': '15 October 2026',
      'report_author': 'นพ. ธนา ศรีสุข',
    };

FakeServer _server() => FakeServer()
  ..json('POST /auth/login', FakeServer.session())
  ..json('GET /u2/unread-count', <String, int>{'unread': 0})
  ..json('GET /u2/home-claim', <String, Object?>{'claim': null})
  ..json('GET /u3/unread-count', <String, int>{'unread': 0})
  ..json('GET /u5/appointments', <String, Object?>{'appointments': <Object>[]})
  ..json('GET /u6/treatments', <String, Object?>{'treatments': <Object>[_scheduleRow]})
  ..json('GET $_base', <String, Object?>{'treatment': _treatment('Pending')})
  ..json('POST $_base/accept', <String, Object?>{'treatment': _treatment('Accepted')})
  ..json('GET $_base/available-dates', <String, Object?>{
    'dates': <Map<String, String>>[
      <String, String>{'slot_date': '2026-10-26', 'date_label': 'Mon 26 October 2026'},
      <String, String>{'slot_date': '2026-10-27', 'date_label': 'Tue 27 October 2026'},
    ],
  })
  ..json('POST $_base/change-date',
      <String, Object?>{'treatment': _treatment('Accepted', date: '27 / 10 / 2026 : 13:00')});

bool _sent(FakeServer s, String path) => s.requests.any((http.Request r) => r.method == 'POST' && r.url.path == path);

/// U4.1 step 1: the Schedule Page, the Treatments tab, the treatment card.
Future<void> _openTreatment(WidgetTester tester, FakeServer server) async {
  await signInToUserApp(tester, server);
  await tapText(tester, 'Schedule');
  await tapText(tester, 'Treatments');
  await tapText(tester, 'SSO Rehabilitation Center');
  expect(find.text('Confirm Treatment'), findsOneWidget);
  expect(find.text('Waiting for your answer'), findsOneWidget);
  expect(find.text('23 / 10 / 2026 : 13:00'), findsOneWidget);
  expect(find.text('60 minutes'), findsOneWidget);
  expect(find.text('กัญญา วงศ์ศิริ (Evaluation Officer)'), findsOneWidget);
  expect(find.text('Signed 15 October 2026 by นพ. ธนา ศรีสุข'), findsOneWidget);
  expect(find.textContaining('cancelled automatically and your claim is closed'), findsOneWidget);
}

void main() {
  testWidgets('U4.1 Normal Case: Accept, then the Treatment accepted pop-up', (WidgetTester tester) async {
    final FakeServer server = _server();
    await _openTreatment(tester, server);
    await tapText(tester, 'Accept');
    expect(_sent(server, '$_base/accept'), isTrue);
    expect(find.text('Treatment accepted'), findsOneWidget);
    expect(
        find.text('Your physiotherapy is booked at SSO Rehabilitation Center on 23 / 10 / 2026 : 13:00. '
            'It is now on your Schedule Page.'),
        findsOneWidget);
    await tapText(tester, 'OK');
    expect(find.text('Accepted'), findsOneWidget);
    expect(find.text('Request Another Date'), findsNothing);
  });

  testWidgets('U4.2 Normal Case: choose a free weekday; the new date is Accepted', (WidgetTester tester) async {
    final FakeServer server = _server();
    await _openTreatment(tester, server);
    await tapText(tester, 'Request Another Date');
    expect(find.text('Choose another date'), findsOneWidget);
    expect(
        find.text('Free weekdays at the same facility, up to 7 days after the booked date. The time stays 13:00.'),
        findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Save date')).enabled, isFalse);
    await tapText(tester, 'Tue 27 October 2026');
    await tapText(tester, 'Save date');

    final http.Request sent = server.requests.lastWhere((http.Request r) => r.url.path == '$_base/change-date');
    expect(jsonDecode(sent.body), <String, String>{'new_date': '2026-10-27'});
    expect(find.text('Treatment date changed to 27 October 2026 : 13:00'), findsOneWidget);
    expect(find.text('Accepted'), findsOneWidget, reason: 'a new date counts as accepting (R-030)');
    expect(find.text('27 / 10 / 2026 : 13:00'), findsOneWidget);
    expect(find.text('Accept'), findsNothing);
    expect(find.text('Request Another Date'), findsNothing);
  });

  testWidgets('U4.2: Cancel in the dates window changes nothing', (WidgetTester tester) async {
    final FakeServer server = _server();
    await _openTreatment(tester, server);
    await tapText(tester, 'Request Another Date');
    await tapText(tester, 'Cancel');
    expect(_sent(server, '$_base/change-date'), isFalse);
    expect(find.text('23 / 10 / 2026 : 13:00'), findsOneWidget);
  });

  testWidgets('U4: a 409 answer shows the server message and reloads the page', (WidgetTester tester) async {
    final FakeServer server = _server()
      ..json('POST $_base/accept', <String, String>{'error': 'The data changed. Open the page again.'}, status: 409);
    await _openTreatment(tester, server);
    await tapText(tester, 'Accept');
    expect(find.text('The data changed. Open the page again.'), findsOneWidget);
    expect(find.text('Treatment accepted'), findsNothing);
  });

  testWidgets('U4: a "Treatment booked" message opens the Confirm Treatment page', (WidgetTester tester) async {
    final FakeServer server = _server()
      ..json('GET /u3/notifications', <String, Object?>{
        'notifications': <Map<String, Object?>>[
          <String, Object?>{
            'notification_id': 911,
            'claim_id': 143,
            'subject': 'Treatment booked',
            'body': 'Physiotherapy on 23 October 2026 : 13:00. Please accept or choose another date.',
            'sent_time': '17 October 2026 : 11:30',
            'is_read': false,
          },
        ],
      })
      ..json('POST /u2/notifications/911/read', <String, Object?>{
        'notification': <String, Object?>{
          'notification_id': 911,
          'claim_id': 143,
          'subject': 'Treatment booked',
          'body': 'Physiotherapy on 23 October 2026 : 13:00. Please accept or choose another date.',
          'sent_time': '17 October 2026 : 11:30',
          'is_read': true,
        },
      });
    await signInToUserApp(tester, server);
    await tapText(tester, 'Notifications');
    expect(find.byIcon(Icons.healing), findsOneWidget, reason: 'the icon of a "Treatment booked" message');
    await tapText(tester, 'Treatment booked');
    await tapText(tester, 'Open treatment');
    expect(find.text('Confirm Treatment'), findsOneWidget);
    expect(find.text('Waiting for your answer'), findsOneWidget);
  });
}
