import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../support/http.dart';
import '../support/test_db.dart';

/// O5.1 and O5.2 through the HTTP routes. Claim 149 has the filed report 86;
/// each test cancels its treatment 403 first, so that QO5.1 lists the claim.
void main() {
  final db = useTestDb();
  const facility = 'SSO Rehabilitation Center';

  Future<TestClient> officer() async {
    await db.performQuery("UPDATE Treatment SET treatment_status = 'Cancelled' WHERE treatment_id = 403");
    final c = TestClient(db);
    await c.login('kanya.w@sso.go.th', app: 'console'); // officer 1
    return c;
  }

  Map<String, Object?> booking(String date, String time) => {
        'report_id': 86,
        'treatment_type': 'Physiotherapy',
        'duration_minutes': 60,
        'facility_name': facility,
        'date': date,
        'time': time,
      };

  Future<String> claimStatus(int id) async => (await db.performQuery(
          'SELECT claim_status FROM InjuryClaim WHERE claim_id = :id', {'id': id}))
      .rows
      .single['claim_status']! as String;

  test('O5.1 Normal Case: the claim, the free hours, then Book treatment; the user is told', () =>
      inRollback(db, () async {
        final c = await officer();
        final claims = ((await c.get('/o5/claims')).json['claims']! as List).cast<Map>(); // QO5.1
        final row = claims.single;
        expect(row['claim_no'], 'SST-2026-000149');
        expect(row['report_id'], 86);
        expect(row['report_author'], isNotEmpty);

        final date = weekday(20);
        final slots = ((await c.get('/o5/available-times?facility=$facility&from=$date&to=$date')).json['slots']!
                as List)
            .cast<Map>(); // QO5.2
        expect(slots, hasLength(8), reason: '09:00 to 16:00');
        expect(slots.every((s) => s['slot_state'] == 'free'), isTrue);

        final r = await c.post('/o5/claims/149/treatment', booking(date, '13:00'));
        expect(r.status, 200);
        final t = (await db.performQuery(
                'SELECT treatment_status, duration_minutes, officer_id FROM Treatment WHERE treatment_id = :id',
                {'id': r.json['treatment_id']}))
            .rows
            .single;
        expect(t, {'treatment_status': 'Pending', 'duration_minutes': 60, 'officer_id': 1});
        final msg = (await db.performQuery("SELECT body FROM Notification WHERE claim_id = 149 "
                "AND subject = 'Treatment booked' ORDER BY notification_id DESC LIMIT 1"))
            .rows
            .single;
        expect(msg['body'], 'Physiotherapy on ${r.json['treatment_date']}. Please accept or choose another date.');
        final after = ((await c.get('/o5/available-times?facility=$facility&from=$date&to=$date')).json['slots']!
                as List)
            .cast<Map>();
        expect(after.firstWhere((s) => (s['slot_at'] as String).contains('T13:00'))['slot_state'], 'mine');
        expect((await c.get('/o5/claims')).json['claims'], isEmpty, reason: 'the claim has a Pending treatment now');
      }));

  test('O5.1: a taken hour or a booked claim gives 409; an empty field gives 422', () => inRollback(db, () async {
        final c = await officer();
        final date = weekday(20);
        final bad = await c.post('/o5/claims/149/treatment', {...booking(date, '10:00'), 'treatment_type': ''});
        expect(bad.status, 422);
        expect((bad.json['fields']! as Map).keys, ['treatment_type']);
        expect((await c.post('/o5/claims/149/treatment', booking(date, '12:30'))).status, 409, reason: 'not an hour');
        expect((await c.post('/o5/claims/149/treatment', {...booking(date, '10:00'), 'report_id': 87})).status, 409,
            reason: 'report 87 is not the report of claim 149');
        expect((await c.post('/o5/claims/149/treatment', booking(date, '10:00'))).status, 200);
        expect((await c.post('/o5/claims/149/treatment', booking(date, '11:00'))).status, 409,
            reason: 'the claim is booked now');
        expect((await c.post('/o5/claims/149/treatment', {...booking(date, '10:00'), 'date': 'today'})).status, 400);
      }));

  test('O5.2 Normal Case: No treatment require closes the claim and tells the user', () => inRollback(db, () async {
        final c = await officer();
        final r = await c.post('/o5/claims/149/no-treatment');
        expect(r.json, {'claim_status': 'No treatment required'});
        expect(await claimStatus(149), 'No treatment required');
        final msg = (await db.performQuery("SELECT body FROM Notification WHERE claim_id = 149 "
                "AND subject = 'No treatment required'"))
            .rows
            .single;
        expect(msg['body'], contains('says no treatment is required, so your claim is now closed.'));
        expect((await c.post('/o5/claims/149/no-treatment')).status, 409, reason: 'not in QO5.1 any more');
        expect((await c.post('/o5/claims/143/no-treatment')).status, 409, reason: 'claim 143 has a treatment');
        expect(await claimStatus(143), 'Covered');
      }));

  test('O5.1 and O5.2 need an Evaluation Officer (401)', () => inRollback(db, () async {
        final user = TestClient(db);
        await user.login('1100800345672');
        expect((await user.get('/o5/claims')).status, 401);
        expect((await user.post('/o5/claims/149/no-treatment')).status, 401);
      }));
}
