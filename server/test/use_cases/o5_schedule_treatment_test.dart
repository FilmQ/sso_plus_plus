import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../support/http.dart';
import '../support/test_db.dart';

/// O5.1 and O5.2 through the HTTP routes, with the seed demo claim 162 (filed
/// report 90, no treatment).
void main() {
  final db = useTestDb();
  const facility = 'SSO Rehabilitation Center';

  Future<TestClient> officer() async {
    final c = TestClient(db);
    await c.login('kanya.w@sso.go.th', app: 'console'); // officer 1
    return c;
  }

  Map<String, Object?> booking(String date, String time, {int duration = 60}) => {
        'report_id': 90,
        'treatment_type': 'Physiotherapy',
        'duration_minutes': duration,
        'facility_name': facility,
        'date': date,
        'time': time,
      };

  Future<List<Map>> times(TestClient c, String date, int duration) async =>
      ((await c.get('/o5/available-times?facility=$facility&duration=$duration&from=$date&to=$date')).json['slots']!
              as List)
          .cast<Map>();

  Future<String> claimStatus(int id) async => (await db.performQuery(
          'SELECT claim_status FROM InjuryClaim WHERE claim_id = :id', {'id': id}))
      .rows
      .single['claim_status']! as String;

  test('O5.1 Normal Case: the claim, the free hours, then Book treatment; the user is told', () =>
      inRollback(db, () async {
        final c = await officer();
        final row = ((await c.get('/o5/claims')).json['claims']! as List).cast<Map>().single; // QO5.1
        expect(row['claim_no'], 'SST-2026-000162');
        expect(row['report_id'], 90);
        expect(row['recommended_treatment'], 'Physiotherapy');
        expect(row['title_name'], isNotEmpty);

        final date = weekday(20);
        final slots = await times(c, date, 60); // QO5.2
        expect(slots, hasLength(7), reason: '09:00 to 11:00 and 13:00 to 16:00');
        expect(slots.every((s) => s['slot_state'] == 'free'), isTrue);

        final r = await c.post('/o5/claims/162/treatment', booking(date, '13:00', duration: 90));
        expect(r.status, 200);
        final t = (await db.performQuery(
                'SELECT treatment_status, duration_minutes, officer_id FROM Treatment WHERE treatment_id = :id',
                {'id': r.json['treatment_id']}))
            .rows
            .single;
        expect(t, {'treatment_status': 'Pending', 'duration_minutes': 90, 'officer_id': 1});
        final msg = (await db.performQuery("SELECT body FROM Notification WHERE claim_id = 162 "
                "AND subject = 'Treatment booked' ORDER BY notification_id DESC LIMIT 1"))
            .rows
            .single;
        expect(msg['body'], 'Physiotherapy on ${r.json['treatment_date']}. Please accept or choose another date.');
        final after = {
          for (final s in await times(c, date, 60)) (s['slot_at'] as String).substring(11, 16): s['slot_state'],
        };
        expect(after['13:00'], 'mine');
        expect(after['14:00'], 'busy', reason: 'the 90-minute treatment covers 14:00');
        expect((await c.get('/o5/claims')).json['claims'], isEmpty, reason: 'the claim has a Pending treatment now');
      }));

  test('O5.1: a taken or too long hour or a booked claim gives 409; a field not in the lists gives 422', () =>
      inRollback(db, () async {
        final c = await officer();
        final date = weekday(20);
        final bad = await c.post('/o5/claims/162/treatment', {...booking(date, '10:00'), 'treatment_type': 'Massage'});
        expect(bad.status, 422);
        expect((bad.json['fields']! as Map).keys, ['treatment_type']);
        final badDuration = await c.post('/o5/claims/162/treatment', booking(date, '10:00', duration: 50));
        expect((badDuration.json['fields']! as Map).keys, ['duration_minutes']);
        expect((await c.post('/o5/claims/162/treatment', booking(date, '12:30'))).status, 409, reason: 'not an hour');
        expect((await c.post('/o5/claims/162/treatment', booking(date, '11:00', duration: 90))).status, 409,
            reason: 'it would end after 12:00');
        expect((await c.post('/o5/claims/162/treatment', {...booking(date, '10:00'), 'report_id': 87})).status, 409,
            reason: 'report 87 is not the report of claim 162');
        expect((await c.post('/o5/claims/162/treatment', booking(date, '10:00'))).status, 200);
        expect((await c.post('/o5/claims/162/treatment', booking(date, '14:00'))).status, 409,
            reason: 'the claim is booked now');
        expect((await c.post('/o5/claims/162/treatment', {...booking(date, '10:00'), 'date': 'today'})).status, 400);
        expect((await c.get('/o5/available-times?facility=$facility&from=$date&to=$date')).status, 400,
            reason: 'the duration is necessary');
      }));

  test('O5.2 Normal Case: No treatment require closes the claim and tells the user', () => inRollback(db, () async {
        final c = await officer();
        final r = await c.post('/o5/claims/162/no-treatment');
        expect(r.json, {'claim_status': 'No treatment required'});
        expect(await claimStatus(162), 'No treatment required');
        final msg = (await db.performQuery("SELECT body FROM Notification WHERE claim_id = 162 "
                "AND subject = 'No treatment required'"))
            .rows
            .single;
        expect(msg['body'], contains('says no treatment is required, so your claim is now closed.'));
        expect((await c.post('/o5/claims/162/no-treatment')).status, 409, reason: 'not in QO5.1 any more');
        expect((await c.post('/o5/claims/143/no-treatment')).status, 409, reason: 'claim 143 has a treatment');
        expect(await claimStatus(143), 'Covered');
      }));

  test('O5.1 and O5.2 need an Evaluation Officer (401)', () => inRollback(db, () async {
        final user = TestClient(db);
        await user.login('1100800345672');
        expect((await user.get('/o5/claims')).status, 401);
        expect((await user.post('/o5/claims/162/no-treatment')).status, 401);
      }));
}
