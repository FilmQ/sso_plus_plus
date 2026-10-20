import 'dart:convert';

import 'package:sst_server/repository/appointment_repository.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../support/http.dart';
import '../support/test_db.dart';

/// C1 and C2.1 to C2.3 through the HTTP routes, as consultant 1
/// (thana.s@ssorehab.go.th). The seed gives consultant 1 appointment 512 (in
/// the future, C1), appointment 513 (in the past without a session, C2) and
/// the QN.5 message 909 (R-047). Some tests add appointments for claim 155.
void main() {
  final db = useTestDb();
  final appointments = AppointmentRepository(db);
  const storageDir = 'build/test-storage';

  /// A 1 x 1 PNG image: the drawn signature of C2.2.
  final signature = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');

  Future<TestClient> consultant() async {
    final c = TestClient(db, storageDir: storageDir);
    await c.login('thana.s@ssorehab.go.th', app: 'console'); // consultant 1
    return c;
  }

  Future<TestClient> officer() async {
    final c = TestClient(db, storageDir: storageDir);
    await c.login('kanya.w@sso.go.th', app: 'console');
    return c;
  }

  /// A Confirmed appointment of consultant 1 on [date] (a past date: ready for a report).
  Future<int> confirmed(String date, {String time = '10:00', int claimId = 155}) async {
    final id = await insertTestAppointment(appointments, date: date, time: time, claimId: claimId, consultantId: 1);
    await appointments.confirmAppointment(id);
    return id;
  }

  Future<Map<String, Object?>> row(int reportId) async => (await db.performQuery(
          'SELECT report_content, report_file_uri, signed_at IS NOT NULL AS signed, delivered_at IS NOT NULL AS filed '
          'FROM ConsultationReport WHERE report_id = :id',
          {'id': reportId}))
      .rows
      .single;

  Future<TestResponse> draft(TestClient c, int id, String text, [String treatment = 'Physiotherapy']) =>
      c.postMultipart('/c2/consultations/$id/draft',
          fields: {'report_content': text, 'recommended_treatment': treatment});

  Future<TestResponse> sign(TestClient c, int id) =>
      c.postMultipart('/c2/consultations/$id/sign', files: {'signature': ('signature.png', signature)});

  List<Object?> ids(TestResponse r, String key, String id) => [for (final x in r.json[key]! as List) (x as Map)[id]];

  test('C1 Normal Case: the Confirmed appointments from today on and the Recent changes card', () =>
      inRollback(db, () async {
        final future = await confirmed(weekday(5), time: '09:00');
        await confirmed(day(-3)); // in the past: not shown
        final pending = await insertTestAppointment(appointments, date: weekday(6), claimId: 160, consultantId: 1);
        final c = await consultant();
        final r = await c.get('/c1/appointments');
        expect(ids(r, 'appointments', 'appointment_id'), [512, future]); // QC1.1
        final rows = (r.json['appointments']! as List).cast<Map>();
        expect(rows.last['user_name'], 'นาย ชัยวัฒน์ สุขเจริญ');
        expect(rows.last['claim_no'], 'SST-2026-000155');
        expect(rows.any((r) => r['appointment_id'] == pending), isFalse, reason: 'a Pending appointment is not shown');
        final changes = (r.json['recent_changes']! as List).cast<Map>(); // QC1.2
        expect(changes.first['notification_id'], 909);
        expect(changes.first['subject'], 'Appointment confirmed');
        expect(changes.first['body'], contains('SST-2026-000163'));
      }));

  test('C1: no message of the last 14 days gives an empty Recent changes card', () => inRollback(db, () async {
        await db.performQuery("UPDATE Notification SET sent_at = NOW() - INTERVAL '15 days' WHERE consultant_id = 1");
        final c = await consultant();
        expect((await c.get('/c1/appointments')).json['recent_changes'], isEmpty);
      }));

  test('C2.1 Normal Case: open, Finish the draft with text and the recommendation, then again (QC2.4, QC2.5)', () =>
      inRollback(db, () async {
        final c = await consultant();
        expect(ids(await c.get('/c2/consultations'), 'consultations', 'appointment_id'), [513]); // QC2.1

        final open = (await c.post('/c2/consultations/513/open')).json['report'] as Map; // QC2.2, QC2.3
        expect(open['report_id'], isNull);
        expect(open['claim_no'], 'SST-2026-000164');
        expect(open['signature_status'], 'Signature pending');
        expect(open['recommended_treatment'], isNull);
        expect(open['user_age'], isA<int>());
        expect(open, isNot(contains('version_no')), reason: 'one report, one version (R-055)');

        final first = (await draft(c, 513, 'First text', 'Occupational therapy')).json['report'] as Map; // QC2.4
        final reportId = first['report_id'] as int;
        expect(first['report_content'], 'First text');
        expect(first['recommended_treatment'], 'Occupational therapy');
        final second = (await draft(c, 513, 'Second text')).json['report'] as Map;
        expect(second['report_id'], reportId, reason: 'QC2.5 changes the same draft');
        expect(second['recommended_treatment'], 'Physiotherapy');
        expect(await row(reportId),
            {'report_content': 'Second text', 'report_file_uri': null, 'signed': false, 'filed': false});
      }));

  test('C2.1 Alternate Case 1 [Attach file]: a file replaces the text, and the consultant can open it', () =>
      inRollback(db, () async {
        final id = await confirmed(day(-2));
        final c = await consultant();
        await c.post('/c2/consultations/$id/open');
        await draft(c, id, 'Text first');
        final r = await c.postMultipart('/c2/consultations/$id/draft',
            fields: {'recommended_treatment': 'None'}, files: {'file': ('xray_left_knee.pdf', '%PDF-1.4'.codeUnits)});
        final page = r.json['report'] as Map;
        expect(page['report_content'], isNull);
        expect(page['recommended_treatment'], 'None');
        // A file of an earlier test run can have the same name: the store adds a number.
        expect(page['report_file_uri'], matches(RegExp(r'^/reports/\d+/xray_left_knee(_\d+)?\.pdf$')));
        final (code, type, bytes) = await c.getBytes('/c2/consultations/$id/draft-file');
        expect(code, 200);
        expect(type, 'application/pdf');
        expect(String.fromCharCodes(bytes), '%PDF-1.4');
      }));

  test('C2.1: only a new recommendation keeps the saved file of the draft', () => inRollback(db, () async {
        final c = await consultant();
        await c.post('/c2/consultations/513/open');
        final first = (await c.postMultipart('/c2/consultations/513/draft',
                fields: {'recommended_treatment': 'None'}, files: {'file': ('knee.pdf', '%PDF-1.4'.codeUnits)}))
            .json['report'] as Map;
        final second = (await c.postMultipart('/c2/consultations/513/draft',
                fields: {'recommended_treatment': 'Physiotherapy'}))
            .json['report'] as Map;
        expect(second['report_file_uri'], first['report_file_uri']);
        expect(second['recommended_treatment'], 'Physiotherapy');
      }));

  test('C2.1: a report file named signature.png does not take the name of the signature file', () =>
      inRollback(db, () async {
        final c = await consultant();
        await c.post('/c2/consultations/513/open');
        final r = await c.postMultipart('/c2/consultations/513/draft', files: {'file': ('signature.png', signature)});
        expect((r.json['report'] as Map)['report_file_uri'], isNot(endsWith('/signature.png')));
      }));

  test('C2.1: no text and no file, both, a wrong file type or a wrong recommendation gives 422', () =>
      inRollback(db, () async {
        final c = await consultant();
        Future<Object?> fields(TestResponse r) async => (r.json['fields']! as Map).keys.toList();
        expect(await fields(await c.postMultipart('/c2/consultations/513/draft', fields: {'report_content': '  '})),
            ['report']);
        expect(
            await fields(await c.postMultipart('/c2/consultations/513/draft',
                fields: {'report_content': 'Text'}, files: {'file': ('a.pdf', [1])})),
            ['report']);
        expect(await fields(await c.postMultipart('/c2/consultations/513/draft', files: {'file': ('a.docx', [1])})),
            ['file']);
        expect(await fields(await draft(c, 513, 'Text', 'Surgery')), ['recommended_treatment']);
      }));

  test('C2.1 Alternate Case 3 [User did not attend]: No show; the claim goes back to the Scheduling list', () =>
      inRollback(db, () async {
        final o = await officer();
        expect(ids(await o.get('/o4/claims'), 'claims', 'claim_id'), isNot(contains(164)));
        final c = await consultant();
        await c.post('/c2/consultations/513/open'); // the page made the session (QC2.2)
        final r = await c.post('/c2/consultations/513/no-show'); // QC2.8
        expect(r.status, 200);
        expect(r.json['no_show'], {'appointment_id': 513, 'claim_id': 164});
        final state = (await db.performQuery(
                'SELECT a.appointment_status, cs.attendance, cs.session_status, ic.claim_status FROM Appointment a '
                'JOIN ConsultationSession cs ON cs.appointment_id = a.appointment_id '
                'JOIN InjuryClaim ic ON ic.claim_id = a.claim_id WHERE a.appointment_id = 513'))
            .rows
            .single;
        expect(state, {
          'appointment_status': 'No show',
          'attendance': 'No show',
          'session_status': 'Cancelled',
          'claim_status': 'Covered',
        });
        expect((await c.get('/c2/consultations')).json['consultations'], isEmpty);
        expect((await c.post('/c2/consultations/513/no-show')).status, 404, reason: 'no longer in QC2.1');
        expect(ids(await o.get('/o4/claims'), 'claims', 'claim_id'), contains(164), reason: 'QO4.1 lists it again');
      }));

  test('C2.1 Alternate Case 3: not for a future appointment (404) or a consultation with a draft (409)', () =>
      inRollback(db, () async {
        final c = await consultant();
        expect((await c.post('/c2/consultations/512/no-show')).status, 404, reason: 'it has not started');
        await c.post('/c2/consultations/513/open');
        await draft(c, 513, 'Report text');
        expect((await c.post('/c2/consultations/513/no-show')).status, 409, reason: 'it has a report');
      }));

  test('C2.2 and C2.3 Normal Case: sign with the drawn image, then file; the officer sees the report', () =>
      inRollback(db, () async {
        final c = await consultant();
        await c.post('/c2/consultations/513/open');
        final reportId = ((await draft(c, 513, 'Report text')).json['report'] as Map)['report_id'] as int;

        final signed = (await sign(c, 513)).json['report'] as Map; // QC2.6
        expect(signed['signature_status'], 'Signature signed');
        expect(signed['signature_uri'], matches(RegExp(r'^/reports/\d+/signature\.png$')));
        final (code, type, bytes) = await c.getBytes('/c2/consultations/513/signature');
        expect((code, type), (200, 'image/png'));
        expect(bytes, signature);
        expect((await sign(c, 513)).status, 409, reason: 'already signed');

        final filed = await c.post('/c2/consultations/513/file-report'); // QC2.7
        expect(filed.status, 200);
        expect(await row(reportId), containsPair('filed', true));
        expect((await c.get('/c2/consultations')).json['consultations'], isEmpty);
        expect((await c.post('/c2/consultations/513/open')).status, 404, reason: 'the report is filed');

        final o = await officer();
        final list = await o.get('/o6/reports'); // QO6.1, no message (R-049)
        expect(ids(list, 'reports', 'report_id'), contains(reportId));
        expect((list.json['reports']! as List).cast<Map>().first, isNot(contains('version_no')));
        final report = (await o.get('/o6/reports/$reportId')).json['report'] as Map; // QO6.2
        expect(report['signature_uri'], signed['signature_uri']);
        expect(report, isNot(contains('version_no')));
        expect((await o.getBytes('/o6/reports/$reportId/signature')).$3, signature);
      }));

  test('C2.2: no drawing or not a PNG image gives 422', () => inRollback(db, () async {
        final c = await consultant();
        await c.post('/c2/consultations/513/open');
        await draft(c, 513, 'Report text');
        final none = await c.postMultipart('/c2/consultations/513/sign', fields: {'x': 'y'});
        expect(none.status, 422);
        expect((none.json['fields']! as Map).keys, ['signature']);
        final pdf = await c.postMultipart('/c2/consultations/513/sign', files: {'signature': ('s.png', '%PDF'.codeUnits)});
        expect(pdf.status, 422);
      }));

  test('C2.3 Alternate Case 1 [Validation Failed]: what is missing; a change removes the signature', () =>
      inRollback(db, () async {
        final c = await consultant();
        await c.post('/c2/consultations/513/open');
        final empty = await c.post('/c2/consultations/513/file-report');
        expect(empty.status, 422);
        expect((empty.json['fields']! as Map).keys, ['report', 'recommended_treatment', 'signature']);
        expect((await sign(c, 513)).status, 422, reason: 'no draft to sign');

        await c.postMultipart('/c2/consultations/513/draft', fields: {'report_content': 'Report text'});
        final unsigned = await c.post('/c2/consultations/513/file-report');
        expect((unsigned.json['fields']! as Map).keys, ['recommended_treatment', 'signature']);

        await sign(c, 513);
        final noTreatment = await c.post('/c2/consultations/513/file-report');
        expect((noTreatment.json['fields']! as Map).keys, ['recommended_treatment']);

        final changed = (await draft(c, 513, 'New text')).json['report'] as Map;
        expect(changed['signature_status'], 'Signature pending', reason: 'QC2.5 removes it');
        expect(changed['signature_uri'], isNull);
      }));

  test('C1 and C2 need a consultant; another consultant cannot open the consultation (404)', () =>
      inRollback(db, () async {
        final id = await insertTestAppointment(appointments, date: day(-2), claimId: 155, consultantId: 2);
        await appointments.confirmAppointment(id);
        final c = await consultant();
        expect((await c.post('/c2/consultations/$id/open')).status, 404, reason: 'consultant 2 has it');
        expect((await c.post('/c2/consultations/$id/no-show')).status, 404, reason: 'consultant 2 has it');
        final o = await officer();
        expect((await o.get('/c1/appointments')).status, 401);
        expect((await o.get('/c2/consultations')).status, 401);
      }));
}
