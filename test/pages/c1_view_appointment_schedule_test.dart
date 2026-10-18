import 'package:flutter_test/flutter_test.dart';

import '../support/console_app.dart';
import '../support/fake_server.dart';

FakeServer _server({List<Object> appointments = const <Object>[]}) => FakeServer()
  ..json('GET /c1/appointments', <String, Object?>{'appointments': appointments})
  ..json('GET /c2/consultations', <String, Object?>{
    'consultations': <Map<String, Object?>>[
      <String, Object?>{
        'appointment_id': 520,
        'claim_no': 'SST-2026-000155',
        'user_name': 'ชัยวัฒน์ สุขเจริญ',
        'consultation_datetime': '16 October 2026 : 10:00',
      },
    ],
  });

void main() {
  testWidgets('C1 Normal Case: the consultant starts on the Schedule Page with the confirmed appointments',
      (WidgetTester tester) async {
    await signInToConsole(
        tester,
        _server(appointments: <Object>[
          <String, Object?>{
            'appointment_id': 504,
            'user_name': 'นาย สมชาย ประเสริฐ',
            'appointment_date': '21 October 2026 : 10:00',
            'claim_no': 'SST-2026-000143',
            'injury': 'Fracture, right wrist',
            'injury_date': '28 September 2026',
          },
        ]),
        session: consultantSession);
    expect(find.text('Schedule Page'), findsWidgets);
    expect(find.text('Confirmed appointments from today'), findsOneWidget);
    expect(find.text('CONSULTANT'), findsOneWidget);
    expect(find.text('Create Consultation Report'), findsOneWidget);
    expect(find.text('Verification'), findsNothing, reason: 'the officer pages are not in the navigation');
    expect(find.text('Consultant'), findsOneWidget);
    expect(find.text('1 confirmed'), findsOneWidget);
    expect(find.text('นาย สมชาย ประเสริฐ'), findsOneWidget);
    expect(find.text('21 October 2026 : 10:00'), findsOneWidget);
    expect(find.text('SST-2026-000143'), findsOneWidget);
    expect(find.text('Fracture, right wrist'), findsOneWidget);
  });

  testWidgets('C1: no confirmed appointments', (WidgetTester tester) async {
    await signInToConsole(tester, _server(), session: consultantSession);
    expect(find.text('You have no confirmed appointments.'), findsOneWidget);
    expect(find.text('0 confirmed'), findsOneWidget);
  });
}
