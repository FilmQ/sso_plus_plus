import 'package:flutter_test/flutter_test.dart';

import '../support/fake_server.dart';
import '../support/user_app.dart';

FakeServer _server({List<Object> appointments = const <Object>[], List<Object> treatments = const <Object>[]}) =>
    FakeServer()
      ..json('POST /auth/login', FakeServer.session())
      ..json('GET /u2/unread-count', <String, int>{'unread': 0})
      ..json('GET /u2/home-claim', <String, Object?>{'claim': null})
      ..json('GET /u3/unread-count', <String, int>{'unread': 0})
      ..json('GET /u5/appointments', <String, Object?>{'appointments': appointments})
      ..json('GET /u6/treatments', <String, Object?>{'treatments': treatments});

const Map<String, Object?> _claim = <String, Object?>{
  'claim_no': 'SST-2026-000143',
  'injury': 'Fracture, right wrist',
  'injury_date': '28 September 2026',
};

void main() {
  testWidgets('U5 Normal Case: the Schedule Page shows the upcoming appointments', (WidgetTester tester) async {
    await signInToUserApp(
        tester,
        _server(appointments: <Object>[
          <String, Object?>{
            'consultant_name': 'นพ. ธนา ศรีสุข',
            'office_location': 'Building A, Floor 3, Room 305',
            'appointment_date': '16 October 2026 : 10:00',
            'appointment_status': 'Pending',
            'claim_id': 143,
            ..._claim,
          },
          <String, Object?>{
            'consultant_name': 'พญ. มาลี ใจดี',
            'office_location': 'Building A, Floor 2, Room 210',
            'appointment_date': '22 October 2026 : 09:00',
            'appointment_status': 'Confirmed',
            'claim_id': 160,
            ..._claim,
          },
        ]));
    await tapText(tester, 'Schedule');
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Awaiting you'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Confirmed'), 200);
    expect(find.text('Confirmed'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('นพ. ธนา ศรีสุข'), -200);
    expect(find.text('นพ. ธนา ศรีสุข'), findsOneWidget);
    expect(find.text('ธศ'), findsOneWidget);
    expect(find.text('Building A, Floor 3, Room 305'), findsOneWidget);
    expect(find.text('16 October 2026 : 10:00'), findsOneWidget);
    expect(find.text('SST-2026-000143'), findsWidgets);
  });

  testWidgets('U5: an appointment card opens the Appointment Page of its claim', (WidgetTester tester) async {
    final FakeServer server = _server(appointments: <Object>[
      <String, Object?>{
        'consultant_name': 'นพ. ธนา ศรีสุข',
        'office_location': 'Building A, Floor 3, Room 305',
        'appointment_date': '16 October 2026 : 10:00',
        'appointment_status': 'Confirmed',
        'claim_id': 143,
        ..._claim,
      },
    ])
      ..json('GET /u3/claims/143/appointment', <String, Object?>{
        'appointment': <String, Object?>{
          'appointment_id': 504,
          'consultant_id': 1,
          'appointment_status': 'Confirmed',
          'appointment_date': '16 / 10 / 2026 : 10:00',
          'scheduled_by': 'กัญญา วงศ์ศิริ',
          'appointment_type': 'Onsite',
          'consultant_name': 'นพ. ธนา ศรีสุข',
          'office_location': 'Building A, Floor 3, Room 305',
          ..._claim,
        },
      });
    await signInToUserApp(tester, server);
    await tapText(tester, 'Schedule');
    await tapText(tester, 'นพ. ธนา ศรีสุข');
    expect(find.text('Appointment'), findsOneWidget);
    expect(find.text('16 / 10 / 2026 : 10:00'), findsOneWidget);
  });

  testWidgets('U6 Normal Case: the Treatments tab shows the upcoming treatments', (WidgetTester tester) async {
    await signInToUserApp(
        tester,
        _server(treatments: <Object>[
          <String, Object?>{
            'treatment_id': 401,
            'facility_name': 'SSO Rehabilitation Center',
            'treatment_type': 'Physiotherapy',
            'duration_minutes': 60,
            'treatment_date': '23 October 2026 : 13:00',
            'treatment_status': 'Accepted',
            'claim_id': 143,
            ..._claim,
          },
          <String, Object?>{
            'treatment_id': 406,
            'facility_name': 'SSO Rehabilitation Center',
            'treatment_type': 'Physiotherapy',
            'duration_minutes': 45,
            'treatment_date': '10 November 2026 : 13:00',
            'treatment_status': 'Pending',
            'claim_id': 143,
            ..._claim,
          },
        ]));
    await tapText(tester, 'Schedule');
    expect(find.text('You have no upcoming appointments.'), findsOneWidget);
    await tapText(tester, 'Treatments');
    expect(find.text('23 October 2026 : 13:00'), findsOneWidget);
    expect(find.text('Accepted'), findsOneWidget);
    expect(find.text('Physiotherapy · 60 minutes'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Awaiting you'), 200);
    expect(find.text('Awaiting you'), findsOneWidget);
  });

  testWidgets('U6: no upcoming treatments', (WidgetTester tester) async {
    await signInToUserApp(tester, _server());
    await tapText(tester, 'Schedule');
    await tapText(tester, 'Treatments');
    expect(find.text('You have no upcoming treatments.'), findsOneWidget);
  });
}
