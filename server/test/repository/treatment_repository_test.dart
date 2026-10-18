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

  Future<int> insertFor155(String date) =>
      insertTestTreatment(db, claimId: 155, date: date, time: '10:00', duration: 60, type: 'Physiotherapy');

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
        final seed = await repo.findClaimsWithFiledReport();
        expect(seed.single['claim_no'], 'SST-2026-000162', reason: 'the seed demo claim');
        expect(seed.single['report_id'], 90);
        expect(seed.single['title_name'], isNotEmpty);
        expect(seed.single['recommended_treatment'], 'Physiotherapy');
        await db.performQuery("UPDATE Treatment SET treatment_status = 'Cancelled' WHERE treatment_id = 403");
        final rows = await repo.findClaimsWithFiledReport();
        expect([for (final r in rows) r['claim_no']], containsAll(['SST-2026-000149', 'SST-2026-000162']));
      }));

  Future<Map<String, Object?>> states(String date, int duration) async => {
        for (final r in await repo.findFacilitySlots(
            facilityName: 'SSO Rehabilitation Center',
            durationMinutes: duration,
            dateFrom: date,
            dateTo: date,
            officerId: 2))
          DateText.dateTime(r['slot_at']! as DateTime).split(' : ').last: r['slot_state'],
      };

  test('QO5.2 findFacilitySlots: the start hours of each weekday; a treatment blocks every hour it covers', () =>
      inRollback(db, () async {
        final week = await repo.findFacilitySlots(
            facilityName: 'SSO Rehabilitation Center',
            durationMinutes: 60,
            dateFrom: weekday(40),
            dateTo: addDays(weekday(40), 6),
            officerId: 2);
        expect(week, hasLength(35), reason: '7 start hours on 5 weekdays, no Saturday or Sunday');

        final date = weekday(40);
        await insertTestTreatment(db, date: date, time: '13:00', duration: 90); // officer 2, until 14:30
        expect(await states(date, 60), {
          '09:00': 'free', '10:00': 'free', '11:00': 'free', '13:00': 'mine', '14:00': 'busy', '15:00': 'free',
          '16:00': 'free',
        });
        expect(await states(date, 90), {
          '09:00': 'free', '10:00': 'free', '11:00': 'busy', '13:00': 'mine', '14:00': 'busy', '15:00': 'free',
          '16:00': 'busy',
        }, reason: '11:00 and 16:00 would end after 12:00 and 17:00');
      }));

  test('QO5.3 insertTreatment: only a claim with a filed report, the lists, a weekday and no overlap', () =>
      inRollback(db, () async {
        Future<int> book({String time = '10:00', int duration = 60, String type = 'Physiotherapy', String? date}) =>
            repo.insertTreatment(
              claimId: 162,
              reportId: 90,
              officerId: 1,
              treatmentType: type,
              durationMinutes: duration,
              facilityName: 'SSO Rehabilitation Center',
              scheduledDate: date ?? weekday(10),
              scheduledTime: time,
            );
        final saturday = [for (var i = 10; i < 17; i++) day(i)].firstWhere((d) => !isWeekday(d));
        for (final refused in [
          () => book(time: '11:00', duration: 90),
          () => book(date: saturday),
          () => book(type: 'Massage'),
          () => book(duration: 50),
          () => book(time: '12:00'),
        ]) {
          await expectLater(refused(), throwsA(isA<NoRowChangedException>()));
        }
        final id = await book();
        expect(await status(id), 'Pending');
        await expectLater(book(time: '14:00'), throwsA(isA<NoRowChangedException>()),
            reason: 'the claim has an open treatment now');
      }));
}
