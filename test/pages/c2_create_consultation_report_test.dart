import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sso_plus_plus/pages/console/consultant/signature_png.dart';
import 'package:sso_plus_plus/pages/user/injury_form/injury_form_data.dart';
import 'package:sso_plus_plus/pages/user/injury_form/upload_section.dart';

import '../support/console_app.dart';
import '../support/fake_server.dart';
import '../support/thai_check.dart';
import '../support/user_app.dart';

const String _base = '/c2/consultations/520';

/// A QC2.3 row of appointment 520 (claim 155) with the report [content] or [file].
Map<String, Object?> _page({String? content, String? file, bool signed = false, String? treatment}) =>
    <String, Object?>{
      'session_id': 310,
      'claim_no': 'SST-2026-000155',
      'user_name': 'ชัยวัฒน์ สุขเจริญ',
      'user_age': 41,
      'consultation_datetime': '16 October 2026 : 10:00',
      'consultant_name': 'นพ. ธนา ศรีสุข',
      'report_id': content == null && file == null ? null : 91,
      'recommended_treatment': treatment,
      'report_content': content,
      'report_file_uri': file,
      'signature_uri': signed ? '/reports/310/signature.png' : null,
      'signed_date': signed ? '18 October 2026' : null,
      'signature_status': signed ? 'Signature signed' : 'Signature pending',
    };

const Map<String, Object?> _consultations = <String, Object?>{
  'consultations': <Map<String, Object?>>[
    <String, Object?>{
      'appointment_id': 520,
      'claim_no': 'SST-2026-000155',
      'user_name': 'ชัยวัฒน์ สุขเจริญ',
      'consultation_datetime': '16 October 2026 : 10:00',
    },
  ],
};

FakeServer _server() => FakeServer()
  ..json('GET /c1/appointments', <String, Object?>{'appointments': <Object>[], 'recent_changes': <Object>[]})
  ..json('GET /c2/consultations', _consultations)
  ..on('GET $_base/signature',
      (_) async => http.Response.bytes(tinyPng, 200, headers: <String, String>{'content-type': 'image/png'}))
  ..json('POST $_base/open', <String, Object?>{'report': _page()})
  ..json('POST $_base/draft', <String, Object?>{'report': _page(content: 'Sprain of the right knee.')})
  ..json('POST $_base/sign', <String, Object?>{'report': _page(content: 'Sprain of the right knee.', signed: true)});

String _sentBody(FakeServer s, String path) =>
    String.fromCharCodes(s.requests.lastWhere((http.Request r) => r.url.path == path).bodyBytes);

Future<void> _openReport(WidgetTester tester, FakeServer server, {List<Object> extra = const <Object>[]}) async {
  await signInToConsole(tester, server, session: consultantSession, extra: extra);
  await tapText(tester, 'Create Consultation Report');
  expect(find.text('Consultation Report · SST-2026-000155'), findsOneWidget);
  expect(find.text('ชัยวัฒน์ สุขเจริญ · not signed yet'), findsOneWidget);
}

/// Chooses [choice] in the "Recommended treatment" field (R-050).
Future<void> _chooseTreatment(WidgetTester tester, String choice) async {
  await tester.tap(find.byType(DropdownMenu<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(choice).last);
  await tester.pumpAndSettle();
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
    expect(find.text('Physiotherapy, Occupational therapy or None. Filing needs a choice.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('report_text')), 'Sprain of the right knee.');
    await _chooseTreatment(tester, 'Occupational therapy');
    await tapText(tester, 'Finish the draft');

    final String body = _sentBody(server, '$_base/draft');
    expect(body, contains('Sprain of the right knee.'));
    expect(body, allOf(contains('name="recommended_treatment"'), contains('Occupational therapy')));
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
    await _openReport(tester, server, extra: <Object>[
      signatureEncoderProvider.overrideWithValue((_) async => tinyPng),
    ]);
    expect(find.text('User did not attend'), findsNothing, reason: 'the consultation has a report');
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

    expect(_sentBody(server, '$_base/sign'), contains('filename="signature.png"'));
    expect(find.text('Signature saved. The status is now Signed.'), findsOneWidget);
    expect(find.text('Signed'), findsOneWidget);
    expect(find.text('ชัยวัฒน์ สุขเจริญ · signed 18 October 2026'), findsOneWidget);
    expect(find.bySemanticsLabel('Signature of นพ. ธนา ศรีสุข'), findsOneWidget, reason: 'the stored image (R-048)');
  });

  testWidgets('C2.3: Validation Failed shows what is missing; then Report filed', (WidgetTester tester) async {
    int calls = 0;
    final FakeServer server = _server()
      ..json('POST $_base/open', <String, Object?>{'report': _page(content: 'Text')})
      ..on('POST $_base/file-report', (_) async => ++calls == 1
          ? FakeServer.reply(<String, Object?>{
              'error': 'validation_failed',
              'fields': <String, String>{
                'recommended_treatment': 'Choose the recommended treatment.',
                'signature': 'Sign the report.',
              },
            }, status: 422)
          : FakeServer.reply(<String, Object?>{'report': _page(content: 'Text', signed: true)}));
    await _openReport(tester, server);
    await tapText(tester, 'File the report');
    expect(
        find.text('The report cannot be filed yet: no recommended treatment is chosen and the signature status is '
            'Pending. Complete the report, then click File the report again.'),
        findsOneWidget);

    await tapText(tester, 'File the report');
    expect(find.text('Report filed'), findsOneWidget);
    expect(
        find.text('Consultation report CR-0091 for SST-2026-000155 has been filed. It now appears in the evaluation '
            "officer's Consultation Reports list, where the treatment is booked."),
        findsOneWidget);
    await tapText(tester, 'OK');
    expect(find.text('Filed'), findsOneWidget, reason: 'no message to the officer (R-049)');
  });

  testWidgets('C2.1 Alternate Case 3 [User did not attend]: Cancel, then Confirm (QC2.8); Marked as no show',
      (WidgetTester tester) async {
    bool marked = false;
    final FakeServer server = _server()
      ..on('GET /c2/consultations', (_) async => FakeServer.reply(
          marked ? <String, Object?>{'consultations': <Object>[]} : _consultations))
      ..on('POST $_base/no-show', (_) async {
        marked = true;
        return FakeServer.reply(<String, Object?>{
          'no_show': <String, Object?>{'appointment_id': 520, 'claim_id': 155},
        });
      });
    await _openReport(tester, server);
    const String question =
        'Do you confirm that ชัยวัฒน์ สุขเจริญ did not attend the consultation on 16 October 2026 : 10:00';

    await tapText(tester, 'User did not attend');
    expect(find.text(question), findsOneWidget); // C2.1-5
    await tapText(tester, 'Cancel');
    expect(find.text(question), findsNothing);
    expect(marked, isFalse);

    await tapText(tester, 'User did not attend');
    await tapText(tester, 'Confirm');
    expect(marked, isTrue);
    expect(find.text('Marked as no show'), findsOneWidget); // C2.1-6
    expect(find.textContaining('the claim is back on the Scheduling list'), findsOneWidget);
    await tapText(tester, 'OK');
    expect(find.text('There are no consultations waiting for a report.'), findsOneWidget);
  });

  testWidgets('C2 in Thai: the report page, the editor, the signature card and the missing message',
      (WidgetTester tester) async {
    final FakeServer server = _server()
      ..json('POST $_base/open', <String, Object?>{'report': _page(content: 'Text')})
      ..json('POST $_base/file-report', <String, Object?>{
        'error': 'validation_failed',
        'fields': <String, String>{'recommended_treatment': 'Choose the recommended treatment.', 'signature': 'Sign the report.'},
      }, status: 422);
    await signInToConsole(tester, server, session: consultantSession, language: 'th');
    await tapText(tester, th('Create Consultation Report'));
    expect(find.text('ชัยวัฒน์ สุขเจริญ · ยังไม่ได้ลงนาม'), findsOneWidget);
    expect(find.text('SST-2026-000155 · ชัยวัฒน์ สุขเจริญ · 16 ตุลาคม 2026 : 10:00'), findsOneWidget);
    expectNoEnglishLabels(tester, data: <String>['Text']);

    await tapText(tester, th('File the report'));
    final String list = th('{list} and {last}', <String, Object?>{
      'list': th('no recommended treatment is chosen'),
      'last': th('the signature status is Pending'),
    });
    expect(
        find.text(th('The report cannot be filed yet: {list}. Complete the report, then click File the report again.',
            <String, Object?>{'list': list})),
        findsOneWidget);

    await tapText(tester, th('Sign the signature'));
    expect(find.text(th('Draw your signature in the box')), findsOneWidget);
    expectNoEnglishLabels(tester, data: <String>['Text']);
    await tester.tapAt(const Offset(8, 8)); // closes the card
    await tester.pumpAndSettle();

    await tapText(tester, th('Amend the draft'));
    expect(find.text(th('Physiotherapy, Occupational therapy or None. Filing needs a choice.')), findsOneWidget);
    expectNoEnglishLabels(tester);
  });
}
