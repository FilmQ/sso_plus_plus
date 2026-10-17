import 'package:sst_server/model/date_text.dart';
import 'package:sst_server/repository/repository.dart';
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
        durationMinutes: 60,
        facilityName: 'SSO Rehabilitation Center',
        scheduledDate: date,
        scheduledTime: '10:00',
      );

  Future<String> bookedDate(int id) async => DateText.iso((await db.performQuery(
          'SELECT scheduled_date FROM Treatment WHERE treatment_id = :id', {'id': id}))
      .rows
      .single['scheduled_date']! as DateTime);

  test('QU4.4 findTreatmentDetail: one treatment of the user with the page data', () => inRollback(db, () async {
        final t = (await repo.findTreatmentDetail(403, 103))!;
        expect(t['claim_id'], 149);
        expect(t['duration_minutes'], 45);
        expect(t['booked_by'], isNotEmpty);
        expect(t['report_author'], isNotEmpty);
        expect(await repo.findTreatmentDetail(403, 101), isNull, reason: 'another user');
      }));

  test('QU4.1 updateStatusAccepted: only a Pending treatment of the claim and the user', () =>
      inRollback(db, () async {
        await expectLater(repo.updateStatusAccepted(403, 143, 103), throwsA(isA<NoRowChangedException>()));
        await expectLater(repo.updateStatusAccepted(403, 149, 101), throwsA(isA<NoRowChangedException>()));
        await repo.updateStatusAccepted(403, 149, 103);
        expect(await status(403), 'Accepted');
        await expectLater(repo.updateStatusAccepted(401, 143, 101), throwsA(isA<NoRowChangedException>()));
      }));

  test('QU4.5 findAvailableDates: weekdays from tomorrow to the booked date + 7', () => inRollback(db, () async {
        final booked = await bookedDate(403);
        final dates = [for (final r in await repo.findAvailableDates(403, 103)) DateText.iso(r['slot_date']! as DateTime)];
        expect(dates, isNotEmpty);
        expect(dates.every(isWeekday), isTrue);
        expect(dates, isNot(contains(booked)));
        expect(dates.first.compareTo(day(1)), greaterThanOrEqualTo(0));
        expect(dates.last.compareTo(addDays(booked, 7)), lessThanOrEqualTo(0));
        expect(await repo.findAvailableDates(403, 101), isEmpty, reason: 'another user');
      }));

  test('QU4.2 updateScheduledDate: a free weekday sets Accepted; else no row changes', () => inRollback(db, () async {
        final booked = await bookedDate(403);
        final next = [for (var i = 1; i <= 7; i++) addDays(booked, i)].firstWhere(isWeekday);
        final saturday = [for (var i = 1; i <= 7; i++) addDays(booked, i)].firstWhere((d) => !isWeekday(d));
        for (final bad in [saturday, addDays(booked, 8), booked]) {
          await expectLater(repo.updateScheduledDate(403, 149, bad, 103), throwsA(isA<NoRowChangedException>()),
              reason: bad);
        }
        await expectLater(repo.updateScheduledDate(403, 149, next, 101), throwsA(isA<NoRowChangedException>()));
        await repo.updateScheduledDate(403, 149, next, 103);
        expect(await status(403), 'Accepted');
        expect(await bookedDate(403), next);
        await expectLater(repo.updateScheduledDate(401, 143, next, 101), throwsA(isA<NoRowChangedException>()));
      }));

  test('QU4.3 cancelExpiredAndNotifyUser: cancels a Pending treatment on or before today', () => inRollback(db, () async {
        final late = await insertFor155(day(0));
        final early = await insertFor155(day(9));
        expect(await repo.cancelExpiredAndNotifyUser(), greaterThanOrEqualTo(1));
        expect(await status(late), 'Cancelled');
        expect(await status(early), 'Pending');
        final msg = await db.performQuery(
            "SELECT body FROM Notification WHERE claim_id = 155 AND subject = 'Treatment cancelled'");
        expect(msg.rows.single['body'], endsWith('was cancelled because it was not accepted in time.'
            ' Your claim SST-2026-000155 is now closed.'));
      }));

  test('QU4.3 cancelExpiredAndNotifyUser: a Covered claim becomes Withdrawn', () => inRollback(db, () async {
        await db.performQuery("UPDATE Treatment SET scheduled_date = CURRENT_DATE WHERE treatment_id = 403");
        await repo.cancelExpiredAndNotifyUser();
        expect(await status(403), 'Cancelled');
        final claim = await db.performQuery('SELECT claim_status FROM InjuryClaim WHERE claim_id = 149');
        expect(claim.rows.single['claim_status'], 'Withdrawn');
        final history = await db.performQuery(
            "SELECT from_status, change_reason FROM ClaimStatusHistory WHERE claim_id = 149 AND to_status = 'Withdrawn'");
        expect(history.rows.single, {'from_status': 'Covered', 'change_reason': 'Treatment not accepted in time'});
      }));

  test('Q6.1 findUpcomingTreatments shows a future treatment of the user', () => inRollback(db, () async {
        await insertFor155(day(7));
        final rows = await repo.findUpcomingTreatments(105);
        expect(rows.single['treatment_status'], 'Pending');
        expect(rows.single['claim_no'], 'SST-2026-000155');
        expect(rows.single['duration_minutes'], 60);
      }));

  test('QO5.1 findClaimsWithFiledReport: a claim without an open treatment', () => inRollback(db, () async {
        expect(await repo.findClaimsWithFiledReport(), isEmpty);
        await db.performQuery("UPDATE Treatment SET treatment_status = 'Cancelled' WHERE treatment_id = 403");
        final rows = await repo.findClaimsWithFiledReport();
        expect(rows.single['claim_no'], 'SST-2026-000149');
        expect(rows.single['report_id'], 86);
      }));

  test('QO5.2 findFacilitySlots: 8 hours of each weekday; a booked hour is mine', () => inRollback(db, () async {
        await insertFor155(weekday(40));
        final rows = await repo.findFacilitySlots(
            facilityName: 'SSO Rehabilitation Center', dateFrom: weekday(40), dateTo: addDays(weekday(40), 6),
            officerId: 1);
        expect(rows, hasLength(40), reason: '5 weekdays, no Saturday or Sunday');
        expect(rows.where((r) => r['slot_state'] == 'mine'), hasLength(1));
      }));

  test('QO5.3 insertTreatment: a Pending treatment', () => inRollback(db, () async {
        final id = await insertFor155(day(10));
        expect(await status(id), 'Pending');
      }));
}
