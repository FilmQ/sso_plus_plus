import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sso_plus_plus/pages/user/injury_form/injury_form_data.dart';
import 'package:sso_plus_plus/pages/user/injury_form/upload_section.dart';
import 'package:sso_plus_plus/routing/user_router.dart';

import '../support/fake_server.dart';

/// Opens U1-1, clicks Register, attaches one file and submits U1-2.
Future<void> _submit(WidgetTester tester, FakeServer server) async {
  await tester.pumpWidget(testApp(server, userRouterProvider, extra: <Object>[
    fileChooserProvider.overrideWithValue(() async => PickedFile('id_card_front.jpg', Uint8List(1258291))),
  ]));
  await tester.pumpAndSettle();
  expect(find.text('Before you start'), findsOneWidget);

  await tester.tap(find.text('Register'));
  await tester.pumpAndSettle();
  expect(find.text('Fill in Injury Forms'), findsOneWidget);

  await tester.enterText(find.byKey(const ValueKey<String>('first_name')), 'Somchai');
  final Finder upload = find.descendant(
      of: find.byKey(const ValueKey<String>('upload:id_card')), matching: find.text('Upload'));
  await tester.ensureVisible(upload);
  await tester.tap(upload);
  await tester.pumpAndSettle();
  expect(find.text('id_card_front.jpg · 1.2 MB'), findsOneWidget);

  await tester.ensureVisible(find.text('Submit Injury Forms'));
  await tester.tap(find.text('Submit Injury Forms'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('U1 Normal Case: U1-1, U1-2, then U1-5 with the claim number', (WidgetTester tester) async {
    final FakeServer server = FakeServer()
      ..on('POST /u1/injury-forms', (http.Request r) async {
        expect(r.body, contains('name="form"'));
        expect(r.body, contains('"first_name":"Somchai"'));
        expect(r.body, contains('name="id_card"; filename="id_card_front.jpg"'));
        return FakeServer.reply(<String, Object?>{
          ...FakeServer.session(),
          'claim': <String, Object?>{
            'claim_no': 'SST-2026-000156',
            'claim_status': 'Awaiting verification',
            'submitted_time': '14 October 2026 : 19:30',
            'claimant_name': 'นาย สมชาย ประเสริฐ',
            'files_received': <int>[1, 2, 3],
          },
        }, status: 201);
      });
    await _submit(tester, server);

    expect(find.text('Injury forms submitted'), findsOneWidget);
    expect(find.text('Claim SST-2026-000156'), findsOneWidget);
    expect(find.text('Awaiting verification'), findsOneWidget);
    expect(find.text('National ID card, medical record, injury form'), findsOneWidget);
    await tester.ensureVisible(find.text('Go to Home'));
    await tester.tap(find.text('Go to Home'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsWidgets);
  });

  testWidgets('U1 Alternate Case 1 [Validation Failed]: U1-3 banner and field errors', (WidgetTester tester) async {
    final FakeServer server = FakeServer()
      ..json('POST /u1/injury-forms', <String, Object?>{
        'error': 'validation_failed',
        'already_registered': false,
        'fields': <String, String>{
          'first_name': 'Use Thai characters only, as on your national ID card',
          'national_id': 'National ID must be exactly 13 digits',
          'phone_no': 'Enter a valid phone number, for example 081 234 5678',
          'confirm_password': 'Passwords do not match',
        },
      }, status: 422);
    await _submit(tester, server);

    expect(find.text('4 fields need your attention. Correct them and press Submit Injury Forms again.'), findsOneWidget);
    expect(find.text('Use Thai characters only, as on your national ID card'), findsOneWidget);
    expect(find.text('National ID must be exactly 13 digits'), findsOneWidget);
    expect(find.text('Fill in Injury Forms'), findsOneWidget);
  });

  testWidgets('U1 Alternate Case 1 [Validation Failed]: U1-4 national ID already registered', (WidgetTester tester) async {
    final FakeServer server = FakeServer()
      ..json('POST /u1/injury-forms', <String, Object?>{
        'error': 'validation_failed',
        'already_registered': true,
        'fields': <String, String>{'national_id': 'This national ID is already registered'},
      }, status: 422);
    await _submit(tester, server);

    expect(find.text('National ID already registered'), findsOneWidget);
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('New user? Register'), findsOneWidget);
  });
}
