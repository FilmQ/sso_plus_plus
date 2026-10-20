import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../support/console_app.dart';
import '../support/fake_server.dart';
import '../support/user_app.dart';

/// A QO6.2 row of report 87 with [view].
Map<String, Object?> _report(String view, {String? file}) => <String, Object?>{
      'claim_no': 'SST-2026-000143',
      'user_name': 'สมชาย ประเสริฐ',
      'signed_date': '16 October 2026',
      'signature_uri': '/reports/303/signature.png',
      'user_age': 38,
      'consultation_datetime': '16 October 2026 : 10:00',
      'submitted_date': '16 October 2026',
      'consultant_name': 'นพ. ธนา ศรีสุข',
      'report_content': file == null ? 'Closed fracture of the distal radius, right wrist. Physiotherapy is recommended.' : null,
      'report_file_uri': file,
      'signature_status': 'Signature signed',
      'view_status': view,
      'viewed_at': view == 'Viewed' ? '17 October 2026 : 09:05' : null,
    };

FakeServer _server() => FakeServer()
  ..json('GET /o1/claims', <String, Object?>{'claims': <Object>[], 'counts': <String, int>{}})
  ..json('GET /o6/reports', <String, Object?>{
    'reports': <Map<String, Object?>>[
      <String, Object?>{
        'report_id': 87,
        'claim_no': 'SST-2026-000143',
        'user_name': 'สมชาย ประเสริฐ',
        'signed_date': '16 October 2026',
        'view_status': 'Pending',
      },
      <String, Object?>{
        'report_id': 85,
        'claim_no': 'SST-2026-000147',
        'user_name': 'สุดา แก้วมณี',
        'signed_date': '15 October 2026',
        'view_status': 'Viewed',
      },
    ],
  })
  ..json('GET /o6/reports/87', <String, Object?>{'report': _report('Pending')})
  ..json('POST /o6/reports/87/view', <String, Object?>{'report': _report('Viewed')})
  ..on('GET /o6/reports/87/signature', (_) async => http.Response.bytes(tinyPng, 200, headers: <String, String>{'content-type': 'image/png'}));

void main() {
  testWidgets('O6 Normal Case: the list, Open, View; the report text and Viewed', (WidgetTester tester) async {
    final FakeServer server = _server();
    await signInToConsole(tester, server);
    await tapText(tester, 'Consultation Reports');
    expect(find.text('Reports filed by consultants'), findsOneWidget);
    expect(find.text('1 not viewed'), findsOneWidget);
    expect(find.text('CR-0087'), findsOneWidget);
    expect(find.text('Viewed'), findsOneWidget);

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Open').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Open').first);
    await tester.pumpAndSettle();
    expect(find.text('Consultation Report · SST-2026-000143'), findsOneWidget);
    expect(find.text('สมชาย ประเสริฐ · signed 16 October 2026'), findsOneWidget);
    expect(find.text('Version'), findsNothing, reason: 'one report, one version (R-055)');
    expect(find.text('38'), findsOneWidget);
    expect(find.text('Signed by นพ. ธนา ศรีสุข on 16 October 2026'), findsOneWidget);
    expect(find.bySemanticsLabel('Signature of นพ. ธนา ศรีสุข'), findsOneWidget, reason: 'the stored signature (R-048)');
    expect(server.requests.any((http.Request r) => r.url.path == '/o6/reports/87/signature'), isTrue);
    expect(find.text('You have not opened this report yet'), findsOneWidget);

    await tapText(tester, 'View');
    expect(server.requests.any((http.Request r) => r.url.path == '/o6/reports/87/view'), isTrue);
    expect(find.text('Report text'), findsWidgets);
    expect(find.text('16 October 2026 : 10:00 · นพ. ธนา ศรีสุข'), findsOneWidget);
    expect(find.textContaining('Physiotherapy is recommended.'), findsOneWidget);
    await tapText(tester, 'Close');
    expect(find.text('Viewed'), findsOneWidget);
    expect(find.text('Viewed on 17 October 2026 : 09:05'), findsOneWidget);
    expect(find.text('Go to Treatment'), findsOneWidget);
  });

  testWidgets('O6 Alternate Case 1 [File]: View opens the report file', (WidgetTester tester) async {
    final FakeServer server = _server()
      ..json('GET /o6/reports/87', <String, Object?>{'report': _report('Pending', file: '/claims/143/xray_right_wrist.pdf')})
      ..json('POST /o6/reports/87/view',
          <String, Object?>{'report': _report('Viewed', file: '/claims/143/xray_right_wrist.pdf')})
      ..on('GET /o6/reports/87/file', (_) async => http.Response.bytes(
          '%PDF'.codeUnits, 200, headers: <String, String>{'content-type': 'application/pdf'}));
    await signInToConsole(tester, server);
    await tapText(tester, 'Consultation Reports');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Open').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Open').first);
    await tester.pumpAndSettle();
    expect(find.text('Report file'), findsOneWidget);
    expect(find.text('xray_right_wrist.pdf'), findsOneWidget);
    await tapText(tester, 'View');
    expect(server.requests.any((http.Request r) => r.url.path == '/o6/reports/87/file'), isTrue);
    expect(find.text('Download'), findsOneWidget);
    await tapText(tester, 'Close');
  });
}
