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
    await repo.insertSessionIfMissing(appointmentId);
    final page = await repo.findReportPage(appointmentId);
    return repo.insertDraft(page!['session_id'] as int, 3, text);
  }

  test('QO6.1 findFiledReports: 3 filed reports, the unread report first', () async {
    final rows = await repo.findFiledReports();
    expect(rows.map((r) => r['report_id']), [87, 86, 85]);
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

  test('QC2.2 insertSessionIfMissing: one session for each appointment', () => inRollback(db, () async {
        expect(await repo.insertSessionIfMissing(504), 0);
        final id = await pastConfirmed();
        expect(await repo.insertSessionIfMissing(id), 1);
        expect(await repo.insertSessionIfMissing(id), 0);
      }));

  test('QC2.3 findReportPage of appointment 504: report 87', () async {
    final row = await repo.findReportPage(504);
    expect(row, containsPair('report_id', 87));
    expect(row, containsPair('session_id', 303));
  });

  test('QC2.4 insertDraft: a new report, not signed', () => inRollback(db, () async {
        final reportId = await draftFor(await pastConfirmed());
        final page = await repo.findReport(reportId);
        expect(page, containsPair('signature_status', 'Signature pending'));
      }));

  test('QC2.5 updateDraft: changes a draft, removes the signature, not a filed report', () => inRollback(db, () async {
        final reportId = await draftFor(await pastConfirmed());
        expect(await repo.updateSignedAt(reportId, 3), 1);
        expect(await repo.updateDraft(reportId, 3, 'New text'), 1);
        expect((await repo.findReport(reportId))!['signature_status'], 'Signature pending');
        expect(await repo.updateDraft(87, 1, 'New text'), 0);
      }));

  test('QC2.6 updateSignedAt: only once, and only by the author', () => inRollback(db, () async {
        final reportId = await draftFor(await pastConfirmed());
        expect(await repo.updateSignedAt(reportId, 1), 0);
        expect(await repo.updateSignedAt(reportId, 3), 1);
        expect(await repo.updateSignedAt(reportId, 3), 0);
      }));

  test('QC2.7 updateDeliveredAt: null before signing, report_id after', () => inRollback(db, () async {
        final reportId = await draftFor(await pastConfirmed());
        expect(await repo.updateDeliveredAt(reportId, 3), isNull);
        await repo.updateSignedAt(reportId, 3);
        expect(await repo.updateDeliveredAt(reportId, 3), reportId);
      }));
}
