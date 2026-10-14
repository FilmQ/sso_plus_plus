import 'package:sst_server/repository/appointment_repository.dart';
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

  test('Q3.4 findFreeSlots: 8 hours on a free day, 7 when one hour is taken', () => inRollback(db, () async {
        expect(await repo.findFreeSlots(3, day(10)), hasLength(8));
        await insertTestAppointment(repo, date: day(10), time: '11:00');
        final slots = (await repo.findFreeSlots(3, day(10))).map((r) => r['slot_time']);
        expect(slots, hasLength(7));
        expect(slots, isNot(contains('11:00')));
      }));

  test('Q3.5 rescheduleAppointment: old row Rescheduled, new row Confirmed', () => inRollback(db, () async {
        final newId = await repo.rescheduleAppointment(504, day(12), '14:00');
        expect((await appt(504))['appointment_status'], 'Rescheduled');
        final row = await appt(newId);
        expect(row['appointment_status'], 'Confirmed');
        expect(row['supersedes_appt_id'], 504);
        await expectLater(repo.rescheduleAppointment(504, day(12), '15:00'), throwsA(isA<NoRowChangedException>()));
      }));

  test('Q3.6 cancelAppointment: Confirmed to Cancelled; not twice', () => inRollback(db, () async {
        await repo.cancelAppointment(504);
        expect((await appt(504))['appointment_status'], 'Cancelled');
        await expectLater(repo.cancelAppointment(504), throwsA(isA<NoRowChangedException>()));
      }));

  test('QU5.1 findUpcomingAppointments shows a future appointment of the user', () => inRollback(db, () async {
        await insertTestAppointment(repo, date: day(5));
        final rows = await repo.findUpcomingAppointments(105);
        expect(rows.single['claim_no'], 'SST-2026-000155');
        expect(rows.single['consultant_name'], 'นพ. วีระ ทองดี');
      }));

  test('QO4.1 findClaimsToSchedule: claim 155 (its appointment is Cancelled)', () async {
    final rows = await repo.findClaimsToSchedule();
    expect(rows.map((r) => r['claim_no']), ['SST-2026-000155']);
  });

  test('QO4.2 findConsultantSlots: 5 consultants x 8 hours, with slot_state', () => inRollback(db, () async {
        await insertTestAppointment(repo, date: day(10), time: '11:00');
        final rows = await repo.findConsultantSlots(day(10), 1);
        expect(rows, hasLength(40));
        final mine = rows.where((r) => r['slot_state'] == 'mine');
        expect(mine.single['consultant_id'], 3);
        expect(await repo.findConsultantSlots(day(10), 2).then((r) => r.where((x) => x['slot_state'] == 'busy')),
            hasLength(1));
      }));

  test('QO4.3 insertAppointment: Pending, deadline 24 hours before', () => inRollback(db, () async {
        final id = await insertTestAppointment(repo, date: day(10), time: '11:00');
        final row = await appt(id);
        expect(row['appointment_status'], 'Pending');
        final deadline = row['confirm_deadline'] as DateTime;
        expect('${deadline.hour}:${deadline.minute}', '11:0');
      }));

  test('QC1.1 findConfirmedAppointments: only Confirmed and not in the past', () => inRollback(db, () async {
        final id = await insertTestAppointment(repo, date: day(6));
        expect(await repo.findConfirmedAppointments(3), isEmpty);
        await repo.confirmAppointment(id);
        final rows = await repo.findConfirmedAppointments(3);
        expect(rows.single['appointment_id'], id);
        expect(rows.single['user_name'], 'นาย ชัยวัฒน์ สุขเจริญ');
      }));
}
