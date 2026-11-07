import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../support/console_app.dart';
import '../support/fake_server.dart';
import '../support/thai_check.dart';
import '../support/user_app.dart';

const String _detail = '/o1/claims/143';

/// QO1.1 and QO1.2 with claim 143 (Awaiting verification).
const Map<String, Object?> _list = <String, Object?>{
  'claims': <Map<String, Object?>>[
    <String, Object?>{
      'claim_id': 143,
      'claim_no': 'SST-2026-000143',
      'claimant_name': 'นาย สมชาย ประเสริฐ',
      'injury': 'Fracture, right wrist',
      'injury_date': '28 September 2026',
      'submitted_date': '2 October 2026',
      'documents_sent': 1,
      'verification_status': 'Awaiting verification',
    },
  ],
  'counts': <String, int>{'awaiting_verification': 12, 'reviews_needed': 0, 'register_unavailable': 2},
};

/// QO1.3 to QO1.5 of claim 143.
const Map<String, Object?> _claim = <String, Object?>{
  'summary': <String, Object?>{
    'claim_no': 'SST-2026-000143',
    'user_name': 'สมชาย ประเสริฐ',
    'submitted_date': '2 October 2026',
    'national_id': '1103700123456',
    'employer_on_claim': 'Siam Precision Parts Co., Ltd.',
    'date_of_injury': '28 September 2026',
    'injury_place': 'Factory line 3, Bang Phli, Samut Prakan',
    'injury_cause': 'Hand caught in a conveyor roller',
    'body_part': 'Right wrist',
  },
  'documents': <Map<String, Object?>>[
    <String, Object?>{
      'document_id': 2002,
      'document_type': 'Medical Record File',
      'file_name': 'medical_record_rama.pdf',
      'file_size': '845 kB',
      'uploaded_at': '2 October 2026 : 14:30',
      'file_uri': '/claims/143/x.pdf',
    },
  ],
  'eligibility': <String, Object?>{
    'eligibility_status': 'Covered',
    'contribution_period': '1 June 2019 - present',
    'employer_in_register': 'Siam Precision Parts Co., Ltd.',
    'sso_account_no': '1000123456',
    'register_queried': '2 October 2026 : 14:32',
  },
};

FakeServer _server() => FakeServer()
  ..json('GET /o1/claims', _list)
  ..json('GET $_detail', _claim)
  ..json('GET /o3/rejection-reasons', <String, Object?>{
    'reasons': <Map<String, String>>[
      <String, String>{'reason_code': 'R01', 'name_th': 'ไม่พบข้อมูลในทะเบียนผู้ประกันตนมาตรา 33'},
      <String, String>{'reason_code': 'R02', 'name_th': 'ส่งเงินสมทบไม่ครบตามเงื่อนไข'},
    ],
  })
  ..json('POST /o2/claims/143/confirm', <String, Object?>{'claim_status': 'Covered', 'decided_at': '5 October 2026 : 09:15'})
  ..json('POST /o3/claims/143/reject', <String, Object?>{'claim_status': 'Rejected', 'decided_at': '6 October 2026 : 10:40'});

Map<String, Object?> _body(FakeServer s, String path) =>
    jsonDecode(s.requests.lastWhere((http.Request r) => r.url.path == path).body) as Map<String, Object?>;

bool _sent(FakeServer s, String path) => s.requests.any((http.Request r) => r.method == 'POST' && r.url.path == path);

/// O1 steps 1 to 4: the Verification Page, then "Open".
Future<void> _openClaim(WidgetTester tester, FakeServer server) async {
  await signInToConsole(tester, server);
  expect(find.text('Claims waiting for an eligibility decision'), findsOneWidget);
  await tapText(tester, 'Open');
  expect(find.text('SST-2026-000143 · สมชาย ประเสริฐ'), findsOneWidget);
}

void main() {
  testWidgets('O1 Normal Case: the Verification Page, the Eligibility Decision Page and a document',
      (WidgetTester tester) async {
    final FakeServer server = _server()
      ..on('GET $_detail/documents/medical_record_rama.pdf',
          (_) async => http.Response.bytes(utf8.encode('%PDF'), 200, headers: <String, String>{'content-type': 'application/pdf'}));
    await signInToConsole(tester, server);
    expect(find.text('12'), findsNWidgets(2), reason: 'the count card and the navigation');
    expect(find.text('Register unavailable'), findsOneWidget);
    expect(find.text('Showing 1 of 1'), findsOneWidget);
    expect(find.text('นาย สมชาย ประเสริฐ'), findsOneWidget);
    expect(find.text('1 files'), findsOneWidget);

    await tapText(tester, 'Open');
    expect(find.text('Verification · submitted 2 October 2026'), findsOneWidget);
    expect(find.text('Hand caught in a conveyor roller'), findsOneWidget);
    expect(find.text('Awaiting verification'), findsOneWidget, reason: 'the QO1.1 status in the summary');
    expect(find.text('Siam Precision Parts Co., Ltd. · SSO account 1000123456'), findsOneWidget);
    expect(find.text('Confirm Result'), findsOneWidget);

    expect(find.text('Medical Record File'), findsOneWidget);
    expect(find.text('medical_record_rama.pdf · 845 kB'), findsOneWidget);
    await tapText(tester, 'View');
    expect(find.text('845 kB · uploaded 2 October 2026 : 14:30'), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);
    expect(find.textContaining('cannot show a preview'), findsOneWidget);
    await tapText(tester, 'Close');
    expect(find.text('Download'), findsNothing);
  });

  testWidgets('O2 Normal Case: Confirm, Confirm Result, Confirm; the result is saved', (WidgetTester tester) async {
    final FakeServer server = _server();
    await _openClaim(tester, server);
    final Finder confirmResult = find.widgetWithText(FilledButton, 'Confirm Result');
    expect(tester.widget<FilledButton>(confirmResult).enabled, isFalse);
    await tapText(tester, 'Confirm');
    expect(tester.widget<FilledButton>(confirmResult).enabled, isTrue);
    await tapText(tester, 'Confirm Result');

    expect(find.text('Do you confirm the result'), findsOneWidget); // O2-2
    expect(find.text('Confirm: covered under Section 33'), findsOneWidget);
    expect(find.text('The user will be notified and the claim moves to scheduling.'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
    await tester.pumpAndSettle();

    expect(_body(server, '/o2/claims/143/confirm'), <String, Object?>{'override_reason': null});
    expect(find.text('Result confirmed: Covered'), findsOneWidget); // O2-3
    expect(find.text('By กัญญา วงศ์ศิริ · 5 October 2026 : 09:15'), findsOneWidget);
    expect(find.text('Result saved. สมชาย ประเสริฐ has been notified.'), findsOneWidget);
    expect(find.text('Go to Scheduling'), findsOneWidget);
    expect(find.text('Confirm Result'), findsNothing);
  });

  testWidgets('O2 Alternate Case [Cancel]: the card closes and nothing is saved', (WidgetTester tester) async {
    final FakeServer server = _server();
    await _openClaim(tester, server);
    await tapText(tester, 'Confirm');
    await tapText(tester, 'Confirm Result');
    await tapText(tester, 'Cancel');
    expect(find.text('Do you confirm the result'), findsNothing);
    expect(_sent(server, '/o2/claims/143/confirm'), isFalse);
  });

  testWidgets('O3 Normal Case: Not Covered with a reason and a message; the claim is rejected',
      (WidgetTester tester) async {
    final FakeServer server = _server();
    await _openClaim(tester, server);
    await tapText(tester, 'Not Covered');
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Confirm Result')).enabled, isFalse);
    await tester.tap(find.byKey(const Key('rejection_reason')));
    await tester.pumpAndSettle();
    await tapText(tester, 'R02 · Contributions do not meet the conditions');
    await tester.enterText(find.widgetWithText(TextField, 'Message to the user'), 'Please send the receipt.');
    await tapText(tester, 'Confirm Result');

    expect(find.text('Not Covered'), findsWidgets); // O3-2
    expect(find.text('The claim will be rejected and the user receives the reason and your message.'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
    await tester.pumpAndSettle();

    expect(_body(server, '/o3/claims/143/reject'), <String, Object?>{
      'reason_code': 'R02',
      'officer_message': 'Please send the receipt.',
      'override_reason': null,
    });
    expect(find.text('Result confirmed: Not covered, claim rejected'), findsOneWidget); // O3-3
    expect(find.text('Reason: R02 · Contributions do not meet the conditions'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);
    expect(find.text('Claim rejected. สมชาย ประเสริฐ has been sent the reason and your message.'), findsOneWidget);
  });

  testWidgets('O2: a decided claim (409) shows the server message', (WidgetTester tester) async {
    final FakeServer server = _server()
      ..json('POST /o2/claims/143/confirm', <String, String>{'error': 'The claim is already decided.'}, status: 409);
    await _openClaim(tester, server);
    await tapText(tester, 'Confirm');
    await tapText(tester, 'Confirm Result');
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
    await tester.pumpAndSettle();
    expect(find.text('The claim is already decided.'), findsOneWidget);
    expect(find.text('Confirm Result'), findsOneWidget);
  });

  testWidgets('R-037: a missing override reason shows the field error of the server (422)', (WidgetTester tester) async {
    final FakeServer server = _server()
      ..json('POST /o3/claims/143/reject', <String, Object?>{
        'error': 'validation_failed',
        'fields': <String, String>{
          'override_reason': 'Give a reason, because your decision differs from the automatic result.',
        },
      }, status: 422);
    await _openClaim(tester, server);
    expect(find.text('Override reason (required if your decision differs)'), findsOneWidget);
    await tapText(tester, 'Not Covered');
    await tester.tap(find.byKey(const Key('rejection_reason')));
    await tester.pumpAndSettle();
    await tapText(tester, 'R02 · Contributions do not meet the conditions');
    await tapText(tester, 'Confirm Result');
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
    await tester.pumpAndSettle();
    expect(find.text('Give a reason, because your decision differs from the automatic result.'), findsOneWidget);
    expect(find.text('Confirm Result'), findsOneWidget);
  });

  testWidgets('O1 to O3 in Thai: the list, the claim, Not Covered and the result', (WidgetTester tester) async {
    const List<String> data = <String>[
      'right wrist',
      'Right wrist',
      'Siam Precision Parts Co., Ltd.',
      'Factory line 3, Bang Phli, Samut Prakan',
      'Hand caught in a conveyor roller',
      'medical_record_rama.pdf',
      'kB',
    ];
    final FakeServer server = _server();
    await signInToConsole(tester, server, language: 'th');
    expect(find.text(th('Claims waiting for an eligibility decision')), findsOneWidget);
    expect(find.text('กระดูกหัก, right wrist'), findsOneWidget);
    expectNoEnglishLabels(tester, data: data);

    await tapText(tester, th('Open'));
    expect(find.text('1 มิถุนายน 2019 - ปัจจุบัน'), findsOneWidget);
    expect(find.text(th('Medical Record File')), findsOneWidget);
    expectNoEnglishLabels(tester, data: data);

    await tapText(tester, th('Not Covered'));
    await tester.tap(find.byKey(const Key('rejection_reason')));
    await tester.pumpAndSettle();
    await tapText(tester, 'R02 · ส่งเงินสมทบไม่ครบตามเงื่อนไข');
    await tapText(tester, th('Confirm Result'));
    expect(find.text(th('Do you confirm the result')), findsOneWidget);
    expectNoEnglishLabels(tester, data: data);
    await tester.tap(find.widgetWithText(FilledButton, th('Confirm')));
    await tester.pumpAndSettle();

    expect(_body(server, '/o3/claims/143/reject')['reason_code'], 'R02');
    expect(find.text(th('Result confirmed: Not covered, claim rejected')), findsOneWidget);
    expect(find.text('เหตุผล: R02 · ส่งเงินสมทบไม่ครบตามเงื่อนไข'), findsOneWidget);
    expect(find.text('โดย กัญญา วงศ์ศิริ · 6 ตุลาคม 2026 : 10:40'), findsOneWidget);
    expectNoEnglishLabels(tester, data: data);
  });
}
