import 'package:test/test.dart';

import '../support/http.dart';
import '../support/test_db.dart';

/// U2 View Notify Message, through the HTTP routes that the HomePage calls.
/// Seed: person 103 (มานพ) has one unread message (905); person 101 (สมชาย) has none.
void main() {
  final db = useTestDb();

  test('U2 Normal Case: red dot, list of the pop-up, opening marks the message read', () => inRollback(db, () async {
        final c = TestClient(db);
        await c.login('1100800345672');

        // Step 2 (Q2.1): one unread message, so the bell has a red dot.
        expect((await c.get('/u2/unread-count')).json['unread'], 1);

        // Step 4 (Q2.2): the list, newest first, with the sent time and the read flag.
        final list = (await c.get('/u2/notifications')).json['notifications'] as List;
        final first = list.first as Map;
        expect(first['notification_id'], 905);
        expect(first['subject'], 'Treatment cancelled');
        expect(first['sent_time'], '19 October 2026 : 00:05');
        expect(first['is_read'], false);

        // Step 6 (Q2.3): opening the message marks it read and gives its detail.
        final opened = await c.post('/u2/notifications/905/read');
        expect(opened.status, 200);
        expect((opened.json['notification'] as Map)['is_read'], true);
        expect((await c.get('/u2/unread-count')).json['unread'], 0);
      }));

  test('U2 Alternate Case 1 [unread = 0]: no red dot', () async {
    final c = TestClient(db);
    await c.login('1103700123456');
    expect((await c.get('/u2/unread-count')).json['unread'], 0);
    expect((await c.get('/u2/notifications')).json['notifications'], hasLength(2));
  });

  test('U2: a user cannot open the message of another user', () => inRollback(db, () async {
        final c = TestClient(db);
        await c.login('1103700123456');
        expect((await c.post('/u2/notifications/905/read')).status, 404);
        final unread = await db.performQuery('SELECT read_at FROM Notification WHERE notification_id = 905');
        expect(unread.rows.single['read_at'], isNull);
      }));

  test('U2: the routes need a user session', () async {
    final c = TestClient(db);
    expect((await c.get('/u2/unread-count')).status, 401);
    await c.login('kanya.w@sso.go.th', app: 'console');
    expect((await c.get('/u2/notifications')).status, 401);
  });

  test('U2 Normal Case (Q2.4): the claim card of the Home page', () => inRollback(db, () async {
        final c = TestClient(db);
        await c.login('1209800456789');
        final claim = (await c.get('/u2/home-claim')).json['claim'] as Map;
        expect(claim['claim_no'], 'SST-2026-000151');
        expect(claim['first_name'], 'วิภา');
        expect(claim['claim_status'], 'Rejected');
        expect(claim['injury'], 'Sprain, left ankle');
        expect(claim['submitted_time'], '3 October 2026 : 11:05');
        expect(claim['officer_checked_time'], '6 October 2026 : 10:40');
        expect(claim['appointment_status'], isNull);
        expect(claim['treatment_status'], isNull);
      }));
}
