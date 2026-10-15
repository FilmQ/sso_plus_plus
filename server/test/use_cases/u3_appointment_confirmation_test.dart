import 'package:sst_server/db/db_connector.dart';
import 'package:sst_server/repository/appointment_repository.dart';
import 'package:sst_server/repository/notification_repository.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../support/http.dart';
import '../support/test_db.dart';

/// U3.1 to U3.3 through the HTTP routes. The fixture is what O4 leaves: a
/// Pending appointment for claim 155 (person 105, ชัยวัฒน์) with consultant 3,
/// and the QN.3 messages.
void main() {
  final db = useTestDb();
  const base = '/u3/claims/155/appointment';

  /// Gives the appointment_id and the id of the message to the user.
  Future<(int, int)> offerAppointment(DBConnector db) async {
    final id = await insertTestAppointment(AppointmentRepository(db), date: day(6), time: '11:00');
    await NotificationRepository(db).insertAppointmentNotices(id);
    final n = await db.performQuery(
        "SELECT MAX(notification_id) AS id FROM Notification WHERE insured_id = 105 AND subject = 'Appointment scheduled'");
    return (id, n.rows.single['id']! as int);
  }

  Future<TestClient> signedIn() async {
    final c = TestClient(db);
    await c.login('1101500567893');
    return c;
  }

  Future<Map<String, Object?>> row(String sql, [Map<String, Object?> p = const {}]) async =>
      (await db.performQuery(sql, p)).rows.single;

  test('U3.1 Normal Case: red dot, Appointment Page, Confirm, the message is read', () => inRollback(db, () async {
        final (apptId, msgId) = await offerAppointment(db);
        final c = await signedIn();
        expect((await c.get('/u3/unread-count')).json['unread'], 1); // Q3.1

        final page = (await c.get(base)).json['appointment'] as Map; // Q3.2
        expect(page['appointment_id'], apptId);
        expect(page['appointment_status'], 'Pending');
        expect(page['scheduled_by'], 'กัญญา วงศ์ศิริ');
        expect(page['claim_no'], 'SST-2026-000155');

        final r = await c.post('$base/confirm', {'notification_id': msgId}); // Q3.3, Q3.7
        expect((r.json['appointment'] as Map)['appointment_status'], 'Confirmed');
        expect((await row('SELECT outcome FROM AppointmentConfirmation WHERE appointment_id = :id', {'id': apptId}))['outcome'],
            'Confirmed');
        expect((await c.get('/u3/unread-count')).json['unread'], 0);
      }));

  test('U3.1: a Confirmed appointment cannot be confirmed again (409, nothing added)', () => inRollback(db, () async {
        final (apptId, _) = await offerAppointment(db);
        final c = await signedIn();
        await c.post('$base/confirm');
        expect((await c.post('$base/confirm')).status, 409);
        final n = await row('SELECT COUNT(*) AS n FROM AppointmentConfirmation WHERE appointment_id = :id', {'id': apptId});
        expect(n['n'], 1);
      }));

  test('U3.2 Normal Case: free times, then the new time; old row Rescheduled, new row Confirmed', () => inRollback(db, () async {
        final (apptId, msgId) = await offerAppointment(db);
        final c = await signedIn();
        final slots = (await c.get('$base/free-slots?date=${day(6)}')).json['slots'] as List; // Q3.4
        expect(slots, isNot(contains('11:00')), reason: 'the current appointment takes 11:00');
        expect(slots, contains('13:00'));

        final r = await c.post('$base/reschedule', {'new_date': day(6), 'new_time': '13:00', 'notification_id': msgId});
        final a = r.json['appointment'] as Map; // Q3.5, Q3.7
        expect(a['appointment_status'], 'Confirmed');
        expect(a['appointment_id'], isNot(apptId));
        expect((await row('SELECT appointment_status FROM Appointment WHERE appointment_id = :id', {'id': apptId}))
            ['appointment_status'], 'Rescheduled');
        expect((await row('SELECT read_at FROM Notification WHERE notification_id = :id', {'id': msgId}))['read_at'],
            isNotNull);
      }));

  test('U3.2: a time that is not free is refused (409)', () => inRollback(db, () async {
        await offerAppointment(db);
        await insertTestAppointment(AppointmentRepository(db), claimId: 149, date: day(6), time: '14:00');
        final c = await signedIn();
        expect((await c.post('$base/reschedule', {'new_date': day(6), 'new_time': '14:00'})).status, 409);
        expect((await c.post('$base/reschedule', {'new_date': day(6), 'new_time': '12:30'})).status, 409);
      }));

  test('U3.2 Alternate Case 1 [Cancel]: looking at free times changes nothing', () => inRollback(db, () async {
        final (apptId, msgId) = await offerAppointment(db);
        final c = await signedIn();
        await c.get('$base/free-slots?date=${day(7)}');
        expect((await c.get(base)).json['appointment'], containsPair('appointment_id', apptId));
        expect((await row('SELECT read_at FROM Notification WHERE notification_id = :id', {'id': msgId}))['read_at'],
            isNull);
      }));

  test('U3.3 Normal Case: I cannot attend, Confirm Cancel Appointment', () => inRollback(db, () async {
        final (apptId, msgId) = await offerAppointment(db);
        final c = await signedIn();
        final r = await c.post('$base/cancel', {'notification_id': msgId}); // Q3.6, Q3.7
        expect((r.json['appointment'] as Map)['appointment_status'], 'Cancelled');
        expect((await row('SELECT outcome FROM AppointmentConfirmation WHERE appointment_id = :id', {'id': apptId}))['outcome'],
            'Cannot attend');
        expect((await c.get(base)).status, 404, reason: 'Q3.2 does not read a Cancelled appointment');
      }));

  test('U3.3 Alternate Case 1 [Go Back]: the appointment stays Pending', () => inRollback(db, () async {
        final (apptId, _) = await offerAppointment(db);
        final c = await signedIn();
        expect((await c.get(base)).json['appointment'], containsPair('appointment_status', 'Pending'));
        expect((await row('SELECT appointment_status FROM Appointment WHERE appointment_id = :id', {'id': apptId}))
            ['appointment_status'], 'Pending');
      }));

  test('U3: a user cannot read or change the appointment of another claim (404)', () => inRollback(db, () async {
        await offerAppointment(db);
        final c = TestClient(db);
        await c.login('1103700123456'); // person 101, not the owner of claim 155
        expect((await c.get(base)).status, 404);
        expect((await c.post('$base/cancel')).status, 404);
        expect((await c.get('/u3/claims/143/appointment')).json['appointment'], containsPair('appointment_id', 504));
      }));
}
