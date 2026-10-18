import 'package:sst_server/repository/claim_repository.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../support/http.dart';
import '../support/test_db.dart';

/// O4 through the HTTP routes. The seed has no claim to schedule, so each test
/// approves a new claim of person 105 first (insertTestClaim, QO2.1).
void main() {
  final db = useTestDb();
  final claims = ClaimRepository(db);

  Future<int> coveredClaim() async {
    final id = await insertTestClaim(claims);
    await claims.saveResult(claimId: id, result: 'Covered', officerId: 1);
    return id;
  }

  Future<TestClient> officer() async {
    final c = TestClient(db);
    await c.login('kanya.w@sso.go.th', app: 'console'); // officer 1
    return c;
  }

  Future<Map> slot(TestClient c, String date, int consultantId, String time) async =>
      ((await c.get('/o4/availability?date=$date')).json['slots']! as List)
          .cast<Map>()
          .firstWhere((s) => s['consultant_id'] == consultantId && (s['slot_at'] as String).contains('T$time'));

  test('O4 Normal Case: the claim, the availability, then Offer; the user and the consultant are told', () =>
      inRollback(db, () async {
        final id = await coveredClaim();
        final c = await officer();
        final rows = ((await c.get('/o4/claims')).json['claims']! as List).cast<Map>(); // QO4.1
        final row = rows.firstWhere((r) => r['claim_id'] == id);
        expect(row['user_name'], isNotEmpty);
        expect(row['verified_date'], isNotNull);

        final date = weekday(30);
        final slots = ((await c.get('/o4/availability?date=$date')).json['slots']! as List).cast<Map>(); // QO4.2
        expect(slots.where((s) => s['consultant_id'] == 1), hasLength(6), reason: 'six bookable hours');
        final free = await slot(c, date, 1, '10:00');
        expect(free['slot_state'], 'free');
        expect(free['slot_time_range'], '10:00 - 11:00');

        final r = await c.post('/o4/claims/$id/appointment', {'consultant_id': 1, 'date': date, 'time': '10:00'});
        expect(r.status, 200);
        final d = DateTime.parse(date);
        const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September',
          'October', 'November', 'December'];
        expect(r.json['appointment_date'], '${d.day} ${months[d.month - 1]} ${d.year} : 10:00');
        final before = d.subtract(const Duration(days: 1));
        expect(r.json['confirm_by'], '${before.day} ${months[before.month - 1]} ${before.year} : 10:00');

        final appt = (await db.performQuery(
                'SELECT appointment_status, appointment_type, location FROM Appointment WHERE appointment_id = :id',
                {'id': r.json['appointment_id']}))
            .rows
            .single;
        expect(appt['appointment_status'], 'Pending');
        expect(appt['appointment_type'], 'Onsite');
        expect(appt['location'], free['office_location']);
        final notes = await db.performQuery(
            'SELECT subject FROM Notification WHERE claim_id = :id ORDER BY subject', {'id': id});
        expect([for (final n in notes.rows) n['subject']], ['Appointment scheduled', 'New appointment']); // QN.3
        expect((await slot(c, date, 1, '10:00'))['slot_state'], 'mine');
        expect(((await c.get('/o4/claims')).json['claims']! as List).cast<Map>().any((x) => x['claim_id'] == id),
            isFalse, reason: 'the claim has a Pending appointment now');
      }));

  test('O4: a taken hour or a claim that is not ready gives 409; a past date gives 422', () => inRollback(db, () async {
        final id = await coveredClaim();
        final other = await coveredClaim();
        final c = await officer();
        final date = weekday(30);
        await c.post('/o4/claims/$other/appointment', {'consultant_id': 1, 'date': date, 'time': '11:00'});
        expect((await c.post('/o4/claims/$id/appointment', {'consultant_id': 1, 'date': date, 'time': '11:00'})).status,
            409, reason: 'the hour is taken');
        expect((await c.post('/o4/claims/$id/appointment', {'consultant_id': 1, 'date': date, 'time': '12:00'})).status,
            409, reason: 'not a bookable hour');
        final again = await c.post('/o4/claims/$other/appointment', {'consultant_id': 2, 'date': date, 'time': '13:00'});
        expect(again.status, 409, reason: 'the claim already has a Pending appointment');
        final past = await c.post('/o4/claims/$id/appointment', {'consultant_id': 1, 'date': day(0), 'time': '15:00'});
        expect(past.status, 422);
        expect((past.json['fields']! as Map).keys, ['date']);
        final badDate = await c.post('/o4/claims/$id/appointment', {'consultant_id': 1, 'date': '1/1/2027', 'time': '09:00'});
        expect(badDate.status, 400);
        expect((await c.get('/o4/availability?date=tomorrow')).status, 400);
      }));

  test('O4 needs an Evaluation Officer (401)', () => inRollback(db, () async {
        final user = TestClient(db);
        await user.login('1100800345672');
        expect((await user.get('/o4/claims')).status, 401);
        expect((await user.get('/o4/availability?date=${weekday(3)}')).status, 401);
      }));
}
