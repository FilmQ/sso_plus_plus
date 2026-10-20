import 'package:sst_server/repository/appointment_repository.dart';
import 'package:sst_server/repository/claim_repository.dart';
import 'package:sst_server/repository/repository.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../support/test_db.dart';

void main() {
  final db = useTestDb();
  final repo = AppointmentRepository(db);

  Future<Row> appt(int id) async => (await db.performQuery(
          'SELECT * FROM Appointment WHERE appointment_id = :id', {'id': id}))
      .rows
      .single;

  test('Q3.2 findLatestAppointment of claim 143 for person 101', () async {
    final row = await repo.findLatestAppointment(143, 101);
    expect(row, containsPair('appointment_id', 504));
    expect(row, containsPair('appointment_date', '16 / 10 / 2026 : 10:00'));
    expect(row, containsPair('scheduled_by', 'กัญญา วงศ์ศิริ'));
    expect(await repo.findLatestAppointment(143, 102), isNull);
  });

  test('Q3.3 confirmAppointment: Pending to Confirmed; not twice', () => inRollback(db, () async {
        final id = await insertTestAppointment(repo, date: day(10));
        await repo.confirmAppointment(id);
        expect((await appt(id))['appointment_status'], 'Confirmed');
        await expectLater(repo.confirmAppointment(id), throwsA(isA<NoRowChangedException>()));
      }));

  test('Q3.4 findFreeSlots: the 6 bookable hours on a free day, 5 when one hour is taken', () => inRollback(db, () async {
        expect((await repo.findFreeSlots(3, day(10))).map((r) => r['slot_time']),
            ['09:00', '10:00', '11:00', '13:00', '14:00', '15:00']);
        await insertTestAppointment(repo, date: day(10), time: '11:00');
        final slots = (await repo.findFreeSlots(3, day(10))).map((r) => r['slot_time']);
        expect(slots, hasLength(5));
        expect(slots, isNot(contains('11:00')));
      }));

  test('Q3.5 rescheduleAppointment: old row Rescheduled, new row Confirmed', () => inRollback(db, () async {
        await expectLater(repo.rescheduleAppointment(504, weekday(12), '12:30'), throwsA(isA<NoRowChangedException>()),
            reason: 'only the six hours of Q3.4');
        final newId = await repo.rescheduleAppointment(504, weekday(12), '14:00');
        expect((await appt(504))['appointment_status'], 'Rescheduled');
        final row = await appt(newId);
        expect(row['appointment_status'], 'Confirmed');
        expect(row['supersedes_appt_id'], 504);
        await expectLater(repo.rescheduleAppointment(504, weekday(12), '15:00'), throwsA(isA<NoRowChangedException>()));
      }));

  test('Q3.6 cancelAppointment: Confirmed to Cancelled, claim Withdrawn; not twice', () => inRollback(db, () async {
        await repo.cancelAppointment(504);
        expect((await appt(504))['appointment_status'], 'Cancelled');
        final claim = await db.performQuery('SELECT claim_status FROM InjuryClaim WHERE claim_id = 143');
        expect(claim.rows.single['claim_status'], 'Withdrawn', reason: 'Q3.6 withdraws a Covered claim');
        await expectLater(repo.cancelAppointment(504), throwsA(isA<NoRowChangedException>()));
      }));

  test('QU5.1 findUpcomingAppointments shows a future appointment of the user', () => inRollback(db, () async {
        await insertTestAppointment(repo, date: day(5));
        final rows = await repo.findUpcomingAppointments(105);
        expect(rows.single['claim_no'], 'SST-2026-000155');
        expect(rows.single['claim_id'], 155);
        expect(rows.single['appointment_status'], 'Pending');
        expect(rows.single['consultant_name'], 'นพ. วีระ ทองดี');
      }));

  test('QO4.1 findClaimsToSchedule: only a Covered claim without an open appointment', () => inRollback(db, () async {
        // Seed: 143, 149 and 160 have an open appointment; 155 is Withdrawn.
        expect(await repo.findClaimsToSchedule(), isEmpty);
        await db.performQuery("UPDATE Appointment SET appointment_status = 'Cancelled' WHERE appointment_id = 510");
        expect((await repo.findClaimsToSchedule()).map((r) => r['claim_no']), ['SST-2026-000160']);
      }));

  test('QO4.2 findConsultantSlots: 5 consultants x 6 hours, with slot_state', () => inRollback(db, () async {
        await insertTestAppointment(repo, date: day(10), time: '11:00');
        final rows = await repo.findConsultantSlots(day(10), 1);
        expect(rows, hasLength(30));
        expect(rows.map((r) => (r['slot_at']! as DateTime).hour).toSet(), {9, 10, 11, 13, 14, 15});
        final mine = rows.where((r) => r['slot_state'] == 'mine');
        expect(mine.single['consultant_id'], 3);
        expect(await repo.findConsultantSlots(day(10), 2).then((r) => r.where((x) => x['slot_state'] == 'busy')),
            hasLength(1));
      }));

  test('QO4.3 insertAppointment: Onsite at the office, Pending, deadline 24 hours before; refusals', () =>
      inRollback(db, () async {
        final claims = ClaimRepository(db);
        final claimId = await insertTestClaim(claims);
        await claims.saveResult(claimId: claimId, result: 'Covered', officerId: 1);
        Future<int> offer({String? date, String time = '11:00', int consultant = 3}) => repo.insertAppointment(
            claimId: claimId, officerId: 1, consultantId: consultant, scheduleDate: date ?? weekday(10), scheduleTime: time);
        final saturday = [for (var i = 10; i < 17; i++) day(i)].firstWhere((d) => !isWeekday(d));
        await insertTestAppointment(repo, claimId: 149, consultantId: 4, date: weekday(10), time: '13:00');
        for (final refused in [
          () => offer(date: saturday),
          () => offer(date: day(0)),
          () => offer(time: '12:00'),
          () => offer(consultant: 4, time: '13:00'), // consultant 4 has 13:00
        ]) {
          await expectLater(refused(), throwsA(isA<NoRowChangedException>()));
        }
        final id = await offer();
        final row = await appt(id);
        expect(row['appointment_status'], 'Pending');
        expect(row['appointment_type'], 'Onsite');
        expect(row['location'], 'Building C, Floor 1, Room 104');
        final deadline = row['confirm_deadline'] as DateTime;
        expect('${deadline.hour}:${deadline.minute}', '11:0');
        await expectLater(offer(time: '14:00'), throwsA(isA<NoRowChangedException>()),
            reason: 'the claim has a Pending appointment now');
      }));

  test('QC1.1 findConfirmedAppointments: only Confirmed and not in the past', () => inRollback(db, () async {
        final id = await insertTestAppointment(repo, date: day(6));
        expect(await repo.findConfirmedAppointments(3), isEmpty);
        await repo.confirmAppointment(id);
        final rows = await repo.findConfirmedAppointments(3);
        expect(rows.single['appointment_id'], id);
        expect(rows.single['user_name'], 'นาย ชัยวัฒน์ สุขเจริญ');
      }));

  test('QC1.2 findRecentChanges: the QN.5 messages to the consultant of the last 14 days, the newest first', () =>
      inRollback(db, () async {
        final rows = await repo.findRecentChanges(1);
        expect(rows.first['notification_id'], 909);
        expect(rows.first['subject'], 'Appointment confirmed');
        expect(rows.first['sent_time'], matches(RegExp(r'^\d{1,2} [A-Z][a-z]+ \d{4} : \d{2}:\d{2}$')));
        await db.performQuery("UPDATE Notification SET sent_at = NOW() - INTERVAL '15 days' WHERE notification_id = 909");
        expect((await repo.findRecentChanges(1)).any((r) => r['notification_id'] == 909), isFalse);
        expect((await repo.findRecentChanges(2)).any((r) => r['notification_id'] == 909), isFalse);
      }));
}
