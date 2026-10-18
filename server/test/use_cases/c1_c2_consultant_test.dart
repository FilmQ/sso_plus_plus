import 'package:sst_server/repository/appointment_repository.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../support/http.dart';
import '../support/test_db.dart';

/// C1 and C2.1 to C2.3 through the HTTP routes, as consultant 1
/// (thana.s@ssorehab.go.th). The seed has no consultation of consultant 1
/// without a filed report, so the tests add one for claim 155.
void main() {
  final db = useTestDb();
  final appointments = AppointmentRepository(db);
  const storageDir = 'build/test-storage';

  Future<TestClient> consultant() async {
    final c = TestClient(db, storageDir: storageDir);
    await c.login('thana.s@ssorehab.go.th', app: 'console'); // consultant 1
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

  test('C1 Normal Case: the Confirmed appointments of the consultant from today on', () => inRollback(db, () async {
        final future = await confirmed(weekday(5), time: '09:00');
        await confirmed(day(-3)); // in the past: not shown
        final pending = await insertTestAppointment(appointments, date: weekday(6), claimId: 160, consultantId: 1);
        final c = await consultant();
        final rows = ((await c.get('/c1/appointments')).json['appointments']! as List).cast<Map>(); // QC1.1
        expect([for (final r in rows) r['appointment_id']], [future]);
        expect(rows.single['user_name'], 'นาย ชัยวัฒน์ สุขเจริญ');
        expect(rows.single['claim_no'], 'SST-2026-000155');
        expect(rows.any((r) => r['appointment_id'] == pending), isFalse, reason: 'a Pending appointment is not shown');
      }));

  test('C2.1 Normal Case: open, Finish the draft with text, then again (QC2.4, QC2.5)', () => inRollback(db, () async {
        final id = await confirmed(day(-2));
        final c = await consultant();
        final list = ((await c.get('/c2/consultations')).json['consultations']! as List).cast<Map>(); // QC2.1
        expect([for (final r in list) r['appointment_id']], [id]);

        final open = (await c.post('/c2/consultations/$id/open')).json['report'] as Map; // QC2.2, QC2.3
        expect(open['report_id'], isNull);
        expect(open['signature_status'], 'Signature pending');
        expect(open['user_age'], isA<int>());

        final first = await c.postMultipart('/c2/consultations/$id/draft', fields: {'report_content': 'First text'});
        final reportId = (first.json['report'] as Map)['report_id'] as int; // QC2.4
        expect((first.json['report'] as Map)['report_content'], 'First text');
        final second = await c.postMultipart('/c2/consultations/$id/draft', fields: {'report_content': 'Second text'});
        expect((second.json['report'] as Map)['report_id'], reportId, reason: 'QC2.5 changes the same draft');
        expect(await row(reportId),
            {'report_content': 'Second text', 'report_file_uri': null, 'signed': false, 'filed': false});
      }));

  test('C2.1 Alternate Case 1 [Attach file]: a file replaces the text, and the consultant can open it', () =>
      inRollback(db, () async {
        final id = await confirmed(day(-2));
        final c = await consultant();
        await c.post('/c2/consultations/$id/open');
        await c.postMultipart('/c2/consultations/$id/draft', fields: {'report_content': 'Text first'});
        final r = await c.postMultipart('/c2/consultations/$id/draft',
            files: {'file': ('xray_left_knee.pdf', '%PDF-1.4'.codeUnits)});
        final page = r.json['report'] as Map;
        expect(page['report_content'], isNull);
        // A file of an earlier test run can have the same name: the store adds a number.
        expect(page['report_file_uri'], matches(RegExp(r'^/reports/\d+/xray_left_knee(_\d+)?\.pdf$')));
        final (code, type, bytes) = await c.getBytes('/c2/consultations/$id/draft-file');
        expect(code, 200);
        expect(type, 'application/pdf');
        expect(String.fromCharCodes(bytes), '%PDF-1.4');
      }));

  test('C2.1: no text and no file, both, or a wrong file type gives 422', () => inRollback(db, () async {
        final id = await confirmed(day(-2));
        final c = await consultant();
        Future<Object?> fields(TestResponse r) async => (r.json['fields']! as Map).keys.toList();
        expect(await fields(await c.postMultipart('/c2/consultations/$id/draft', fields: {'report_content': '  '})),
            ['report']);
        expect(
            await fields(await c.postMultipart('/c2/consultations/$id/draft',
                fields: {'report_content': 'Text'}, files: {'file': ('a.pdf', [1])})),
            ['report']);
        expect(await fields(await c.postMultipart('/c2/consultations/$id/draft', files: {'file': ('a.docx', [1])})),
            ['file']);
      }));

  test('C2.2 and C2.3 Normal Case: sign, then file; the officer sees the report (QO6.1)', () =>
      inRollback(db, () async {
        final id = await confirmed(day(-2));
        final c = await consultant();
        await c.post('/c2/consultations/$id/open');
        final draft = await c.postMultipart('/c2/consultations/$id/draft', fields: {'report_content': 'Report text'});
        final reportId = (draft.json['report'] as Map)['report_id'] as int;

        final signed = (await c.post('/c2/consultations/$id/sign')).json['report'] as Map; // QC2.6
        expect(signed['signature_status'], 'Signature signed');
        expect((await c.post('/c2/consultations/$id/sign')).status, 409, reason: 'already signed');

        final filed = await c.post('/c2/consultations/$id/file-report'); // QC2.7
        expect(filed.status, 200);
        expect(await row(reportId), containsPair('filed', true));
        expect((await c.get('/c2/consultations')).json['consultations'], isEmpty);
        expect((await c.post('/c2/consultations/$id/open')).status, 404, reason: 'the report is filed');

        final officer = TestClient(db);
        await officer.login('kanya.w@sso.go.th', app: 'console');
        final reports = ((await officer.get('/o6/reports')).json['reports']! as List).cast<Map>();
        expect(reports.any((r) => r['report_id'] == reportId), isTrue);
      }));

  test('C2.3 Alternate Case 1 [Validation Failed]: what is missing; a change removes the signature', () =>
      inRollback(db, () async {
        final id = await confirmed(day(-2));
        final c = await consultant();
        await c.post('/c2/consultations/$id/open');
        final empty = await c.post('/c2/consultations/$id/file-report');
        expect(empty.status, 422);
        expect((empty.json['fields']! as Map).keys, ['report', 'signature']);
        expect((await c.post('/c2/consultations/$id/sign')).status, 422, reason: 'no draft to sign');

        await c.postMultipart('/c2/consultations/$id/draft', fields: {'report_content': 'Report text'});
        final unsigned = await c.post('/c2/consultations/$id/file-report');
        expect((unsigned.json['fields']! as Map).keys, ['signature']);

        await c.post('/c2/consultations/$id/sign');
        final changed = await c.postMultipart('/c2/consultations/$id/draft', fields: {'report_content': 'New text'});
        expect((changed.json['report'] as Map)['signature_status'], 'Signature pending', reason: 'QC2.5 removes it');
      }));

  test('C1 and C2 need a consultant; another consultant cannot open the consultation (404)', () =>
      inRollback(db, () async {
        final id = await insertTestAppointment(appointments, date: day(-2), claimId: 155, consultantId: 2);
        await appointments.confirmAppointment(id);
        final c = await consultant();
        expect((await c.post('/c2/consultations/$id/open')).status, 404, reason: 'consultant 2 has it');
        final officer = TestClient(db);
        await officer.login('kanya.w@sso.go.th', app: 'console');
        expect((await officer.get('/c1/appointments')).status, 401);
        expect((await officer.get('/c2/consultations')).status, 401);
      }));
}
