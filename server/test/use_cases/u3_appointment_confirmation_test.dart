import 'package:sst_server/repository/appointment_repository.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../support/http.dart';
import '../support/test_db.dart';

/// U3.1 to U3.3 through the HTTP routes, with the seed demo of the 2026-10-15
/// evening pack: person 106 (อรทัย), claim 160, Pending appointment 510 with
/// consultant 2, and the QN.3 message 907.
void main() {
  final db = useTestDb();
  const base = '/u3/claims/160/appointment';
  const message = 907;

  Future<TestClient> signedIn() async {
    final c = TestClient(db);
    await c.login('1350100678904');
    return c;
  }

  Future<Map<String, Object?>> row(String sql, [Map<String, Object?> p = const {}]) async =>
      (await db.performQuery(sql, p)).rows.single;

  /// The newest QN.5 message to consultant 2 about claim 160, or null.
  Future<Map<String, Object?>?> consultantMessage() async => (await db.performQuery('''
SELECT subject, body FROM Notification
WHERE claim_id = 160 AND consultant_id = 2 AND subject LIKE 'Appointment %'
ORDER BY notification_id DESC LIMIT 1''')).firstOrNull;

  test('U3.1 Normal Case: red dot, messages, Appointment Page, Confirm, consultant told, message read', () =>
      inRollback(db, () async {
        final c = await signedIn();
        expect((await c.get('/u3/unread-count')).json['unread'], 2); // Q3.1
        final list = (await c.get('/u3/notifications')).json['notifications'] as List; // Q2.2
        expect((list.first as Map)['notification_id'], message);

        final page = (await c.get(base)).json['appointment'] as Map; // Q3.2
        expect(page['appointment_id'], 510);
        expect(page['appointment_status'], 'Pending');
        expect(page['consultant_name'], 'พญ. มาลี ใจดี');

        final r = await c.post('$base/confirm', {'notification_id': message}); // Q3.3, QN.5, Q3.7
        expect((r.json['appointment'] as Map)['appointment_status'], 'Confirmed');
        expect((await consultantMessage())!['subject'], 'Appointment confirmed');
        expect((await row('SELECT read_at FROM Notification WHERE notification_id = :id', {'id': message}))['read_at'],
            isNotNull);
      }));

  test('U3.1: a Confirmed appointment cannot be confirmed again (409, nothing added)', () => inRollback(db, () async {
        final c = await signedIn();
        await c.post('$base/confirm');
        expect((await c.post('$base/confirm')).status, 409);
        final n = await row('SELECT COUNT(*) AS n FROM AppointmentConfirmation WHERE appointment_id = 510');
        expect(n['n'], 1);
      }));

  test('U3.2 Normal Case: six free hours, the new time, consultant told', () => inRollback(db, () async {
        final c = await signedIn();
        final slots = (await c.get('$base/free-slots?date=${day(30)}')).json['slots'] as List; // Q3.4
        expect(slots, ['09:00', '10:00', '11:00', '13:00', '14:00', '15:00']);

        final r = await c.post('$base/reschedule', {'new_date': day(30), 'new_time': '13:00', 'notification_id': message});
        final a = r.json['appointment'] as Map; // Q3.5, QN.5, Q3.7
        expect(a['appointment_status'], 'Confirmed');
        expect(a['appointment_id'], isNot(510));
        expect((await row('SELECT appointment_status FROM Appointment WHERE appointment_id = 510'))['appointment_status'],
            'Rescheduled');
        final told = await consultantMessage();
        expect(told!['subject'], 'Appointment rescheduled');
        expect(told['body'], contains('13:00'));
      }));

  test('U3.2: a taken hour or a time in the past is refused by Q3.5 (409)', () => inRollback(db, () async {
        await insertTestAppointment(AppointmentRepository(db), claimId: 149, consultantId: 2, date: day(30), time: '14:00');
        final c = await signedIn();
        expect((await c.post('$base/reschedule', {'new_date': day(30), 'new_time': '14:00'})).status, 409);
        expect((await c.post('$base/reschedule', {'new_date': day(-1), 'new_time': '10:00'})).status, 409);
        expect((await row('SELECT appointment_status FROM Appointment WHERE appointment_id = 510'))['appointment_status'],
            'Pending');
      }));

  test('U3.2: an hour that cannot be booked (12:30, 12:00, 16:00) gives 422', () => inRollback(db, () async {
        final c = await signedIn();
        for (final t in ['12:30', '12:00', '16:00']) {
          final r = await c.post('$base/reschedule', {'new_date': day(30), 'new_time': t});
          expect(r.status, 422, reason: t);
          expect((r.json['fields'] as Map).keys, ['new_time']);
        }
      }));

  test('U3.2 Alternate Case 1 [Cancel]: looking at free times changes nothing', () => inRollback(db, () async {
        final c = await signedIn();
        await c.get('$base/free-slots?date=${day(31)}');
        expect((await c.get(base)).json['appointment'], containsPair('appointment_status', 'Pending'));
        expect((await row('SELECT read_at FROM Notification WHERE notification_id = :id', {'id': message}))['read_at'],
            isNull);
      }));

  test('U3.3 Normal Case: I cannot attend; appointment Cancelled, claim Withdrawn, consultant told', () =>
      inRollback(db, () async {
        final c = await signedIn();
        final r = await c.post('$base/cancel', {'notification_id': message}); // Q3.6, QN.5, Q3.7
        expect((r.json['appointment'] as Map)['appointment_status'], 'Cancelled');
        expect((await row('SELECT claim_status FROM InjuryClaim WHERE claim_id = 160'))['claim_status'], 'Withdrawn');
        final history = await row('''
SELECT from_status, to_status, officer_id FROM ClaimStatusHistory
WHERE claim_id = 160 ORDER BY history_id DESC LIMIT 1''');
        expect(history, {'from_status': 'Covered', 'to_status': 'Withdrawn', 'officer_id': null});
        expect((await consultantMessage())!['subject'], 'Appointment cancelled');
        expect((await c.get(base)).status, 404, reason: 'Q3.2 does not read a Cancelled appointment');
        expect((await c.get('/u2/home-claim')).json['claim'], containsPair('claim_status', 'Withdrawn'));
      }));

  test('U3.3 Alternate Case 1 [Go Back]: the appointment stays Pending, the claim Covered', () => inRollback(db, () async {
        final c = await signedIn();
        expect((await c.get(base)).json['appointment'], containsPair('appointment_status', 'Pending'));
        expect((await row('SELECT claim_status FROM InjuryClaim WHERE claim_id = 160'))['claim_status'], 'Covered');
      }));

  test('U3: a user cannot read or change the appointment of another claim (404)', () => inRollback(db, () async {
        final c = TestClient(db);
        await c.login('1103700123456'); // person 101, not the owner of claim 160
        expect((await c.get(base)).status, 404);
        expect((await c.post('$base/cancel')).status, 404);
        expect((await c.get('/u3/claims/143/appointment')).json['appointment'], containsPair('appointment_id', 504));
      }));
}
