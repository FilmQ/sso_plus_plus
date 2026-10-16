import 'package:sst_server/repository/treatment_repository.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../support/test_db.dart';

void main() {
  final db = useTestDb();
  final repo = TreatmentRepository(db);

  Future<String> status(int id) async => (await db.performQuery(
          'SELECT treatment_status FROM Treatment WHERE treatment_id = :id', {'id': id}))
      .rows
      .single['treatment_status'] as String;

  Future<int> insertFor155(String date) => repo.insertTreatment(
        claimId: 155,
        reportId: 86,
        officerId: 1,
        treatmentType: 'Physiotherapy',
        facilityName: 'SSO Rehabilitation Center',
        scheduledDate: date,
        scheduledTime: '10:00',
      );

  test('QU4.1 updateStatusAccepted: only a Pending treatment of the claim', () => inRollback(db, () async {
        expect(await repo.updateStatusAccepted(403, 143), 0);
        expect(await repo.updateStatusAccepted(403, 149), 1);
        expect(await status(403), 'Accepted');
        expect(await repo.updateStatusAccepted(401, 143), 0);
      }));

  test('QU4.2 updateScheduledDate: only a Pending treatment', () => inRollback(db, () async {
        expect(await repo.updateScheduledDate(403, 149, day(20)), 1);
        expect(await repo.updateScheduledDate(401, 143, day(20)), 0);
      }));

  test('QU4.3 cancelExpiredAndNotifyUser: cancels a Pending treatment on or before today', () => inRollback(db, () async {
        final late = await insertFor155(day(0));
        final early = await insertFor155(day(9));
        expect(await repo.cancelExpiredAndNotifyUser(), greaterThanOrEqualTo(1));
        expect(await status(late), 'Cancelled');
        expect(await status(early), 'Pending');
        final msg = await db.performQuery(
            "SELECT body FROM Notification WHERE claim_id = 155 AND subject = 'Treatment cancelled'");
        expect(msg.rows.single['body'], contains('was cancelled because it was not accepted in time.'));
      }));

  test('Q6.1 findUpcomingTreatments shows a future treatment of the user', () => inRollback(db, () async {
        await insertFor155(day(7));
        final rows = await repo.findUpcomingTreatments(105);
        expect(rows.single['treatment_status'], 'Pending');
        expect(rows.single['claim_no'], 'SST-2026-000155');
      }));

  test('QO5.1 findClaimsWithFiledReport: a claim without an open treatment', () => inRollback(db, () async {
        expect(await repo.findClaimsWithFiledReport(), isEmpty);
        await db.performQuery("UPDATE Treatment SET treatment_status = 'Cancelled' WHERE treatment_id = 403");
        final rows = await repo.findClaimsWithFiledReport();
        expect(rows.single['claim_no'], 'SST-2026-000149');
        expect(rows.single['report_id'], 86);
      }));

  test('QO5.2 findFacilitySlots: 8 hours a day; a booked hour is mine', () => inRollback(db, () async {
        await insertFor155(day(40));
        final rows = await repo.findFacilitySlots(
            facilityName: 'SSO Rehabilitation Center', dateFrom: day(40), dateTo: day(41), officerId: 1);
        expect(rows, hasLength(16));
        expect(rows.where((r) => r['slot_state'] == 'mine'), hasLength(1));
      }));

  test('QO5.3 insertTreatment: a Pending treatment', () => inRollback(db, () async {
        final id = await insertFor155(day(10));
        expect(await status(id), 'Pending');
      }));
}
