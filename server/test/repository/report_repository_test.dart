import 'package:sst_server/repository/appointment_repository.dart';
import 'package:sst_server/repository/report_repository.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../support/test_db.dart';

void main() {
  final db = useTestDb();
  final repo = ReportRepository(db);
  final appointments = AppointmentRepository(db);

  /// A Confirmed appointment two days ago, with consultant 3: ready for a report.
  Future<int> pastConfirmed() async {
    final id = await insertTestAppointment(appointments, date: day(-2));
    await appointments.confirmAppointment(id);
    return id;
  }

  Future<int> draftFor(int appointmentId, [String text = 'Draft text']) async {
    await repo.insertSessionIfMissing(appointmentId, 3);
    final page = await repo.findReportPage(appointmentId);
    return (await repo.insertDraft(page!['session_id'] as int, 3,
        reportContent: text, recommendedTreatment: 'Physiotherapy'))!;
  }

  /// Some columns of a report and its session.
  Future<Map<String, Object?>> reportRow(int reportId) async => (await db.performQuery(
          'SELECT cr.signed_at, cr.signature_uri, cr.report_content, cr.report_file_uri, cs.recommended_treatment '
          'FROM ConsultationReport cr JOIN ConsultationSession cs ON cs.session_id = cr.session_id '
          'WHERE cr.report_id = :id',
          {'id': reportId}))
      .rows
      .single;

  Future<Object?> signedAt(int reportId) async => (await reportRow(reportId))['signed_at'];

  const sig = '/reports/1/signature.png';

  test('QO6.1 findFiledReports: 4 filed reports, the unread reports first', () async {
    final rows = await repo.findFiledReports();
    expect(rows.map((r) => r['report_id']), [87, 90, 86, 85]);
    expect(rows.first['view_status'], 'Pending');
  });

  test('QO6.2 findReport 87: header, content and status', () async {
    final row = await repo.findReport(87);
    expect(row, containsPair('claim_no', 'SST-2026-000143'));
    expect(row, containsPair('consultant_name', 'นพ. ธนา ศรีสุข'));
    expect(row, containsPair('consultation_datetime', '16 October 2026 : 10:00'));
    expect(row, containsPair('signature_status', 'Signature signed'));
  });

  test('QO6.3 updateReadAt: only the first time', () => inRollback(db, () async {
        expect(await repo.updateReadAt(87), 1);
        expect(await repo.updateReadAt(87), 0);
      }));

  test('QC2.1 findConsultationsAwaitingReport: a past Confirmed appointment without a filed report', () =>
      inRollback(db, () async {
        expect(await repo.findConsultationsAwaitingReport(3), isEmpty);
        final id = await pastConfirmed();
        expect((await repo.findConsultationsAwaitingReport(3)).single['appointment_id'], id);
      }));

  test('QC2.2 insertSessionIfMissing: one session for each appointment (ON CONFLICT), only by its consultant', () =>
      inRollback(db, () async {
        expect(await repo.insertSessionIfMissing(504, 1), 0);
        final id = await pastConfirmed();
        expect(await repo.insertSessionIfMissing(id, 1), 0, reason: 'consultant 3 has it');
        expect(await repo.insertSessionIfMissing(id, 3), 1);
        expect(await repo.insertSessionIfMissing(id, 3), 0);
      }));

  test('QC2.3 findReportPage of appointment 504: report 87, its signature and recommendation', () async {
    final row = await repo.findReportPage(504);
    expect(row, containsPair('report_id', 87));
    expect(row, containsPair('session_id', 303));
    expect(row, containsPair('signature_uri', '/reports/303/signature.png'));
    expect(row, contains('recommended_treatment'));
    expect(row, isNot(contains('version_no')));
  });

  test('QC2.4 insertDraft: a new report with the recommendation, not signed; text or one file', () =>
      inRollback(db, () async {
        final reportId = await draftFor(await pastConfirmed());
        expect(await reportRow(reportId),
            containsPair('recommended_treatment', 'Physiotherapy'));
        expect(await signedAt(reportId), isNull);
        expect(await repo.findReport(reportId), isNull, reason: 'QO6.2 reads only a filed report');
        final appointmentId = await pastConfirmed();
        await repo.insertSessionIfMissing(appointmentId, 3);
        final session = (await repo.findReportPage(appointmentId))!['session_id'] as int;
        final fileReport = await repo.insertDraft(session, 3, reportFileUri: '/reports/1/report.pdf');
        expect(await reportRow(fileReport!), allOf(containsPair('report_content', null),
            containsPair('report_file_uri', '/reports/1/report.pdf'), containsPair('recommended_treatment', null)));
      }));

  test('QC2.4 insertDraft: null when a draft is there, a wrong recommendation or another consultant', () =>
      inRollback(db, () async {
        final appointmentId = await pastConfirmed();
        await draftFor(appointmentId);
        final session = (await repo.findReportPage(appointmentId))!['session_id'] as int;
        expect(await repo.insertDraft(session, 3, reportContent: 'Again'), isNull, reason: 'ON CONFLICT');
        final other = await pastConfirmed();
        await repo.insertSessionIfMissing(other, 3);
        final otherSession = (await repo.findReportPage(other))!['session_id'] as int;
        expect(await repo.insertDraft(otherSession, 3, reportContent: 'x', recommendedTreatment: 'Surgery'), isNull);
        expect(await repo.insertDraft(otherSession, 1, reportContent: 'x'), isNull);
      }));

  test('QC2.5 updateDraft: changes a draft and the recommendation, removes the signature, not a filed report', () =>
      inRollback(db, () async {
        final reportId = await draftFor(await pastConfirmed());
        expect(await repo.updateSignedAt(reportId, 3, sig), 1);
        expect(await repo.updateDraft(reportId, 3, reportContent: 'New text', recommendedTreatment: 'None'), 1);
        expect(await reportRow(reportId), allOf(containsPair('signed_at', null), containsPair('signature_uri', null),
            containsPair('recommended_treatment', 'None')));
        expect(await repo.updateDraft(reportId, 3, reportContent: 'x', recommendedTreatment: 'Surgery'), 0);
        expect(await repo.updateDraft(87, 1, reportContent: 'New text'), 0);
      }));

  test('QC2.6 updateSignedAt: with a signature file, only once, and only by the author', () =>
      inRollback(db, () async {
        final reportId = await draftFor(await pastConfirmed());
        expect(await repo.updateSignedAt(reportId, 1, sig), 0);
        expect(await repo.updateSignedAt(reportId, 3, ''), 0, reason: 'no signature file');
        expect(await repo.updateSignedAt(reportId, 3, sig), 1);
        expect(await reportRow(reportId), containsPair('signature_uri', sig));
        expect(await repo.updateSignedAt(reportId, 3, sig), 0);
      }));

  test('QC2.7 updateDeliveredAt: null before signing or without the recommendation, report_id after', () =>
      inRollback(db, () async {
        final reportId = await draftFor(await pastConfirmed());
        expect(await repo.updateDeliveredAt(reportId, 3), isNull);
        await repo.updateDraft(reportId, 3, reportContent: 'Text');
        await repo.updateSignedAt(reportId, 3, sig);
        expect(await repo.updateDeliveredAt(reportId, 3), isNull, reason: 'no recommended_treatment');
        await repo.updateDraft(reportId, 3, reportContent: 'Text', recommendedTreatment: 'Physiotherapy');
        await repo.updateSignedAt(reportId, 3, sig);
        expect(await repo.updateDeliveredAt(reportId, 3), reportId);
      }));

  test('QC2.8 updateNoShow: a past Confirmed appointment of the consultant without a report', () =>
      inRollback(db, () async {
        Future<Map<String, Object?>> state(int id) async => (await db.performQuery(
                'SELECT a.appointment_status, cs.attendance, cs.session_status FROM Appointment a '
                'LEFT JOIN ConsultationSession cs ON cs.appointment_id = a.appointment_id WHERE a.appointment_id = :id',
                {'id': id}))
            .rows
            .single;
        final id = await pastConfirmed();
        expect(await repo.updateNoShow(id, 1), isNull, reason: 'consultant 3 has it');
        expect(await repo.updateNoShow(id, 3), {'appointment_id': id, 'claim_id': 155});
        expect(await state(id), {'appointment_status': 'No show', 'attendance': 'No show', 'session_status': 'Cancelled'});
        expect(await repo.findConsultationsAwaitingReport(3), isEmpty);

        final opened = await pastConfirmed();
        await repo.insertSessionIfMissing(opened, 3);
        expect(await repo.updateNoShow(opened, 3), isNotNull, reason: 'ON CONFLICT: the open session becomes No show');
        expect(await state(opened), containsPair('attendance', 'No show'));

        final drafted = await pastConfirmed();
        await draftFor(drafted);
        expect(await repo.updateNoShow(drafted, 3), isNull, reason: 'it has a report');
        final future = await insertTestAppointment(appointments, date: day(3));
        await appointments.confirmAppointment(future);
        expect(await repo.updateNoShow(future, 3), isNull, reason: 'not started');
      }));
}
