import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sso_plus_plus/pages/user/injury_form/injury_form_data.dart';
import 'package:sso_plus_plus/pages/user/injury_form/upload_section.dart';

import '../support/console_app.dart';
import '../support/fake_server.dart';
import '../support/user_app.dart';

const String _base = '/c2/consultations/520';

/// A QC2.3 row of appointment 520 (claim 155) with the report [content] or [file].
Map<String, Object?> _page({String? content, String? file, bool signed = false}) => <String, Object?>{
      'session_id': 310,
      'claim_no': 'SST-2026-000155',
      'user_name': 'ชัยวัฒน์ สุขเจริญ',
      'user_age': 41,
      'consultation_datetime': '16 October 2026 : 10:00',
      'consultant_name': 'นพ. ธนา ศรีสุข',
      'report_id': content == null && file == null ? null : 91,
      'version_no': 1,
      'report_content': content,
      'report_file_uri': file,
      'signed_date': signed ? '18 October 2026' : null,
      'signature_status': signed ? 'Signature signed' : 'Signature pending',
    };

FakeServer _server() => FakeServer()
  ..json('GET /c1/appointments', <String, Object?>{'appointments': <Object>[]})
  ..json('GET /c2/consultations', <String, Object?>{
    'consultations': <Map<String, Object?>>[
      <String, Object?>{
        'appointment_id': 520,
        'claim_no': 'SST-2026-000155',
        'user_name': 'ชัยวัฒน์ สุขเจริญ',
        'consultation_datetime': '16 October 2026 : 10:00',
      },
    ],
  })
  ..json('POST $_base/open', <String, Object?>{'report': _page()})
  ..json('POST $_base/draft', <String, Object?>{'report': _page(content: 'Sprain of the right knee.')})
  ..json('POST $_base/sign', <String, Object?>{'report': _page(content: 'Sprain of the right knee.', signed: true)});

String _sentBody(FakeServer s, String path) =>
    String.fromCharCodes(s.requests.lastWhere((http.Request r) => r.url.path == path).bodyBytes);

Future<void> _openReport(WidgetTester tester, FakeServer server, {List<Object> extra = const <Object>[]}) async {
  await signInToConsole(tester, server, session: consultantSession, extra: extra);
  await tapText(tester, 'Create Consultation Report');
  expect(find.text('Consultation Report · SST-2026-000155'), findsOneWidget);
  expect(find.text('ชัยวัฒน์ สุขเจริญ · version 1 · not signed yet'), findsOneWidget);
}

void main() {
  testWidgets('C2.1 Normal Case: Amend the draft, type, Finish the draft (QC2.4)', (WidgetTester tester) async {
    final FakeServer server = _server();
    await _openReport(tester, server);
    expect(find.text('SST-2026-000155 · ชัยวัฒน์ สุขเจริญ · 16 October 2026 : 10:00'), findsOneWidget);
    expect(find.text('1 waiting'), findsOneWidget);
    expect(find.text('41'), findsOneWidget);
    expect(find.textContaining('No report yet.'), findsOneWidget);
    expect(find.text('Not filed'), findsOneWidget);

    await tapText(tester, 'Amend the draft');
    expect(find.text('Finish the draft'), findsOneWidget);
    expect(find.text('Attach'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('report_text')), 'Sprain of the right knee.');
    await tapText(tester, 'Finish the draft');

    expect(_sentBody(server, '$_base/draft'), contains('Sprain of the right knee.'));
    expect(find.text('Draft saved.'), findsOneWidget);
    expect(find.text('Sprain of the right knee.'), findsOneWidget);
    expect(find.text('Amend the draft'), findsOneWidget);
  });

  testWidgets('C2.1 Alternate Case 1 [Attach file]: the file is attached instead of the text',
      (WidgetTester tester) async {
    final FakeServer server = _server()
      ..json('POST $_base/draft', <String, Object?>{'report': _page(file: '/reports/310/xray_right_knee.pdf')});
    await _openReport(tester, server, extra: <Object>[
      fileChooserProvider.overrideWithValue(
          () async => PickedFile('xray_right_knee.pdf', Uint8List.fromList('%PDF'.codeUnits))),
    ]);
    await tapText(tester, 'Amend the draft');
    await tapText(tester, 'Attach');
    expect(find.text('File Attached'), findsOneWidget);
    await tapText(tester, 'Finish the draft');

    final String body = _sentBody(server, '$_base/draft');
    expect(body, contains('filename="xray_right_knee.pdf"'));
    expect(body, isNot(contains('name="report_content"')));
    expect(find.text('Draft saved. The report file is attached.'), findsOneWidget);
    expect(find.text('xray_right_knee.pdf'), findsOneWidget);
    expect(find.text('View'), findsOneWidget);
  });

  testWidgets('C2.2 Normal Case: draw, Delete, draw again, Confirm; the status is Signed (QC2.6)',
      (WidgetTester tester) async {
    final FakeServer server = _server()..json('POST $_base/open', <String, Object?>{'report': _page(content: 'Text')});
    await _openReport(tester, server);
    await tapText(tester, 'Sign the signature');
    expect(find.text('Sign the report'), findsOneWidget);
    final Finder confirm = find.widgetWithText(FilledButton, 'Confirm');
    expect(tester.widget<FilledButton>(confirm).enabled, isFalse);

    Future<void> draw() async {
      await tester.drag(find.byKey(const Key('signature_pad')), const Offset(120, 20));
      await tester.pumpAndSettle();
    }

    await draw();
    expect(tester.widget<FilledButton>(confirm).enabled, isTrue);
    await tapText(tester, 'Delete'); // Alternate Case 1 [Delete]
    expect(tester.widget<FilledButton>(confirm).enabled, isFalse);
    await draw();
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(server.requests.any((http.Request r) => r.url.path == '$_base/sign'), isTrue);
    expect(find.text('Signature saved. The status is now Signed.'), findsOneWidget);
    expect(find.text('Signed'), findsOneWidget);
    expect(find.text('ชัยวัฒน์ สุขเจริญ · version 1 · signed 18 October 2026'), findsOneWidget);
  });

  testWidgets('C2.3: Validation Failed shows what is missing; then Report filed', (WidgetTester tester) async {
    int calls = 0;
    final FakeServer server = _server()
      ..json('POST $_base/open', <String, Object?>{'report': _page(content: 'Text')})
      ..on('POST $_base/file-report', (_) async => ++calls == 1
          ? FakeServer.reply(<String, Object?>{
              'error': 'validation_failed',
              'fields': <String, String>{'signature': 'Sign the report.'},
            }, status: 422)
          : FakeServer.reply(<String, Object?>{'report': _page(content: 'Text', signed: true)}));
    await _openReport(tester, server);
    await tapText(tester, 'File the report');
    expect(
        find.text('The report cannot be filed yet: the signature status is Pending. Sign the report, then click '
            'File the report again.'),
        findsOneWidget);

    await tapText(tester, 'File the report');
    expect(find.text('Report filed'), findsOneWidget);
    expect(
        find.text('Consultation report CR-0091 for SST-2026-000155 has been filed. The evaluation officer has been '
            'notified and can now book the treatment.'),
        findsOneWidget);
    await tapText(tester, 'OK');
    expect(find.text('Filed · officer notified'), findsOneWidget);
  });
}
