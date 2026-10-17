import 'package:sst_server/job/auto_cancel_job.dart';
import 'package:sst_server/repository/treatment_repository.dart';
import 'package:test/test.dart';

import '../support/http.dart';
import '../support/fixtures.dart';
import '../support/test_db.dart';

/// U4.1 to U4.3 through the HTTP routes and the job. The tests book their own
/// treatments for claim 149 (person 103, report 86) near today, because the
/// seed treatments have fixed dates.
void main() {
  final db = useTestDb();
  final repo = TreatmentRepository(db);
  const facility = 'SSO Rehabilitation Center';

  Future<int> book(String date, {int claimId = 149, String time = '13:00'}) => repo.insertTreatment(
        claimId: claimId,
        reportId: 86,
        officerId: 2,
        treatmentType: 'Occupational therapy',
        facilityName: facility,
        scheduledDate: date,
        scheduledTime: time,
      );

  Future<TestClient> signedIn() async {
    final c = TestClient(db);
    await c.login('1100800345672'); // person 103, owner of claim 149
    return c;
  }

  Future<String> status(int id) async => (await db.performQuery(
          'SELECT treatment_status FROM Treatment WHERE treatment_id = :id', {'id': id}))
      .rows
      .single['treatment_status']! as String;

  String dayText(int offset) {
    final d = DateTime.parse(day(offset));
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September',
      'October', 'November', 'December'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  test('U4.1 Normal Case: Accept; the treatment becomes Accepted', () => inRollback(db, () async {
        final id = await book(day(20));
        final c = await signedIn();
        final page = (await c.get('/u4/treatments/$id')).json['treatment'] as Map; // Q6.1
        expect(page['treatment_status'], 'Pending');
        expect(page['claim_no'], 'SST-2026-000149');

        final r = await c.post('/u4/treatments/$id/accept'); // QU4.1
        expect((r.json['treatment'] as Map)['treatment_status'], 'Accepted');
        expect(await status(id), 'Accepted');
      }));

  test('U4.1: an Accepted treatment cannot be accepted or changed again (409)', () => inRollback(db, () async {
        final id = await book(day(20));
        final c = await signedIn();
        await c.post('/u4/treatments/$id/accept');
        expect((await c.post('/u4/treatments/$id/accept')).status, 409);
        expect((await c.post('/u4/treatments/$id/change-date', {'new_date': day(21)})).status, 409);
      }));

  test('U4.2 Normal Case: free dates at the same hour; the new date is saved, the time stays', () =>
      inRollback(db, () async {
        final id = await book(day(20));
        await book(day(22), claimId: 155); // another user has 13:00 on day 22
        final c = await signedIn();
        final dates = ((await c.get('/u4/treatments/$id/available-dates')).json['dates'] as List).cast<String>();
        expect(dates, contains(day(1)));
        expect(dates, contains(day(21)));
        expect(dates, contains(day(34)));
        expect(dates, isNot(contains(day(0))));
        expect(dates, isNot(contains(day(20))), reason: 'the booked date');
        expect(dates, isNot(contains(day(22))), reason: 'the facility is busy at 13:00');
        expect(dates, isNot(contains(day(35))), reason: 'more than 14 days after the booked date');

        final r = await c.post('/u4/treatments/$id/change-date', {'new_date': day(21)}); // QU4.2
        final t = r.json['treatment'] as Map;
        expect(t['treatment_date'], '${dayText(21)} : 13:00');
        expect(t['treatment_status'], 'Pending');
      }));

  test('U4.2: a date that is not available gives 422 and changes nothing', () => inRollback(db, () async {
        final id = await book(day(20));
        await book(day(22), claimId: 155);
        final c = await signedIn();
        for (final d in [day(22), day(-1), day(40)]) {
          final r = await c.post('/u4/treatments/$id/change-date', {'new_date': d});
          expect(r.status, 422, reason: d);
          expect((r.json['fields'] as Map).keys, ['new_date']);
        }
        expect((await c.post('/u4/treatments/$id/change-date', {'new_date': '21/10/2026'})).status, 400);
        final t = (await c.get('/u4/treatments/$id')).json['treatment'] as Map;
        expect(t['treatment_date'], '${dayText(20)} : 13:00');
      }));

  test('U4: a user cannot read or change the treatment of another claim (404)', () => inRollback(db, () async {
        final id = await book(day(20));
        final c = TestClient(db);
        await c.login('1350100678904'); // person 106
        expect((await c.get('/u4/treatments/$id')).status, 404);
        expect((await c.post('/u4/treatments/$id/accept')).status, 404);
        expect((await c.get('/u4/treatments/$id/available-dates')).status, 404);
        expect(await status(id), 'Pending');
      }));

  test('U4.3 Normal Case: the job cancels a Pending treatment on its date and tells the user', () =>
      inRollback(db, () async {
        final due = await book(day(0), time: '09:00');
        final later = await book(day(3));
        final accepted = await book(day(0), time: '10:00');
        await repo.updateStatusAccepted(accepted, 149);
        final logs = <String>[];
        final job = AutoCancelJob(() => TestClient.app(db).treatmentController(), log: logs.add);

        expect(await job.onDeadlineReached(), greaterThanOrEqualTo(1)); // QU4.3
        expect(job.lastRunAt, isNotNull);
        expect(logs.single, startsWith('AutoCancelJob: QU4.3 cancelled'));
        expect(await status(due), 'Cancelled');
        expect(await status(later), 'Pending');
        expect(await status(accepted), 'Accepted');
        final msg = (await db.performQuery('''
SELECT insured_id, body FROM Notification
WHERE claim_id = 149 AND subject = 'Treatment cancelled' ORDER BY notification_id DESC LIMIT 1''')).rows.single;
        expect(msg['insured_id'], 103);
        expect(msg['body'], 'Your treatment at $facility on ${dayText(0)} was cancelled because it was not accepted in time.');

        final c = await signedIn();
        expect((await c.get('/u4/treatments/$due')).status, 404, reason: 'Q6.1 does not show a Cancelled treatment');
      }));

  test('U4.3: the job runs every day at 00:05 Asia/Bangkok', () {
    expect(AutoCancelJob.nextRunDelay(DateTime.utc(2026, 10, 17, 16)), const Duration(hours: 1, minutes: 5));
    expect(AutoCancelJob.nextRunDelay(DateTime.utc(2026, 10, 16, 17, 5)), const Duration(days: 1));
    expect(AutoCancelJob.nextRunDelay(DateTime.utc(2026, 10, 16, 17, 4)), const Duration(minutes: 1));
  });
}
