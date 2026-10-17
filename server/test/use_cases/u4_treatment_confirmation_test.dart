import 'package:sst_server/job/auto_cancel_job.dart';
import 'package:sst_server/repository/treatment_repository.dart';
import 'package:test/test.dart';

import '../support/http.dart';
import '../support/fixtures.dart';
import '../support/test_db.dart';

/// U4.1 to U4.3 through the HTTP routes and the job. The tests book their own
/// treatments for claim 149 (person 103, report 86) on weekdays near today.
void main() {
  final db = useTestDb();
  final repo = TreatmentRepository(db);
  const facility = 'SSO Rehabilitation Center';

  Future<int> book(String date, {int claimId = 149, String time = '15:00'}) => repo.insertTreatment(
        claimId: claimId,
        reportId: 86,
        officerId: 2,
        treatmentType: 'Occupational therapy',
        durationMinutes: 45,
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

  /// QU4.4 'FMDD / FMMM / YYYY" : "HH24:MI', for example '26 / 10 / 2026 : 15:00'.
  String pageDate(String date, String time) {
    final d = DateTime.parse(date);
    return '${d.day} / ${d.month} / ${d.year} : $time';
  }

  /// Every day from tomorrow to [booked] + 7.
  List<String> window(String booked) => [
        for (var d = day(1); d.compareTo(addDays(booked, 7)) <= 0; d = addDays(d, 1)) d,
      ];

  /// The weekdays of [window] without [booked]: the dates that QU4.5 can give.
  List<String> allowed(String booked) => [for (final d in window(booked)) if (isWeekday(d) && d != booked) d];

  test('U4.1 Normal Case: open the page, Accept; the treatment becomes Accepted', () => inRollback(db, () async {
        final booked = weekday(20);
        final id = await book(booked);
        final c = await signedIn();
        final page = (await c.get('/u4/treatments/$id')).json['treatment'] as Map; // QU4.4
        expect(page, containsPair('treatment_status', 'Pending'));
        expect(page, containsPair('treatment_date', pageDate(booked, '15:00')));
        expect(page, containsPair('duration_minutes', 45));
        expect(page, containsPair('facility_name', facility));
        expect(page, containsPair('claim_no', 'SST-2026-000149'));
        expect(page['booked_by'], isNotEmpty);
        expect(page['report_signed_date'], isNotEmpty);
        expect(page['report_author'], isNotEmpty);

        final r = await c.post('/u4/treatments/$id/accept'); // QU4.1
        expect((r.json['treatment'] as Map)['treatment_status'], 'Accepted');
        expect(await status(id), 'Accepted');
      }));

  test('U4.1: an Accepted treatment cannot be accepted or changed again (409)', () => inRollback(db, () async {
        final booked = weekday(20);
        final id = await book(booked);
        final c = await signedIn();
        await c.post('/u4/treatments/$id/accept');
        expect((await c.post('/u4/treatments/$id/accept')).status, 409);
        expect((await c.post('/u4/treatments/$id/change-date', {'new_date': allowed(booked).last})).status, 409);
        expect((await c.get('/u4/treatments/$id/available-dates')).json['dates'], isEmpty);
      }));

  test('U4.2 Normal Case: free weekdays at the same hour; Save date sets the new date and Accepted', () =>
      inRollback(db, () async {
        final booked = weekday(20);
        final id = await book(booked);
        final busy = allowed(booked).last;
        await book(busy, claimId: 155); // another user has 15:00 on that day (the seed has no 15:00)
        final c = await signedIn();
        final rows = ((await c.get('/u4/treatments/$id/available-dates')).json['dates'] as List).cast<Map>(); // QU4.5
        expect([for (final r in rows) r['slot_date']], [for (final d in allowed(booked)) if (d != busy) d],
            reason: 'weekdays from tomorrow to the booked date + 7, not the booked date, not a busy day');
        expect(rows.first['date_label'], matches(RegExp(r'^(Mon|Tue|Wed|Thu|Fri) \d{1,2} [A-Z][a-z]+ \d{4}$')));

        final newDate = rows.last['slot_date']! as String;
        final r = await c.post('/u4/treatments/$id/change-date', {'new_date': newDate}); // QU4.2
        final t = r.json['treatment'] as Map;
        expect(t['treatment_date'], pageDate(newDate, '15:00'));
        expect(t['treatment_status'], 'Accepted', reason: 'a new date counts as accepting (R-030)');
      }));

  test('U4.2: a date that is not available gives 422 and changes nothing', () => inRollback(db, () async {
        final booked = weekday(20);
        final id = await book(booked);
        final busy = allowed(booked).last;
        await book(busy, claimId: 155);
        final weekend = window(booked).firstWhere((d) => !isWeekday(d));
        var late = addDays(booked, 8);
        while (!isWeekday(late)) {
          late = addDays(late, 1);
        }
        final c = await signedIn();
        for (final d in [busy, weekend, booked, day(-1), late]) {
          final r = await c.post('/u4/treatments/$id/change-date', {'new_date': d});
          expect(r.status, 422, reason: d);
          expect((r.json['fields'] as Map).keys, ['new_date']);
        }
        expect((await c.post('/u4/treatments/$id/change-date', {'new_date': '21/10/2026'})).status, 400);
        final t = (await c.get('/u4/treatments/$id')).json['treatment'] as Map;
        expect(t['treatment_date'], pageDate(booked, '15:00'));
        expect(t['treatment_status'], 'Pending');
      }));

  test('U4: a user cannot read or change the treatment of another claim (404)', () => inRollback(db, () async {
        final booked = weekday(20);
        final id = await book(booked);
        final c = TestClient(db);
        await c.login('1350100678904'); // person 106
        expect((await c.get('/u4/treatments/$id')).status, 404);
        expect((await c.post('/u4/treatments/$id/accept')).status, 404);
        expect((await c.get('/u4/treatments/$id/available-dates')).status, 404);
        expect((await c.post('/u4/treatments/$id/change-date', {'new_date': allowed(booked).first})).status, 404);
        expect(await status(id), 'Pending');
      }));

  test('U4.3 Normal Case: the job cancels a Pending treatment on its date, tells the user and closes the claim', () =>
      inRollback(db, () async {
        final due = await book(day(0), time: '09:00');
        final accepted = await book(day(0), claimId: 143, time: '10:00');
        await repo.updateStatusAccepted(accepted, 143, 101);
        final logs = <String>[];
        final job = AutoCancelJob(() => TestClient.app(db).treatmentController(), log: logs.add);

        expect(await job.onDeadlineReached(), greaterThanOrEqualTo(1)); // QU4.3
        expect(job.lastRunAt, isNotNull);
        expect(logs.single, startsWith('AutoCancelJob: QU4.3 cancelled'));
        expect(await status(due), 'Cancelled');
        expect(await status(403), 'Pending', reason: 'the seed treatment is 7 days or more after the load day');
        expect(await status(accepted), 'Accepted');
        final msg = (await db.performQuery("SELECT insured_id, body FROM Notification "
                "WHERE claim_id = 149 AND subject = 'Treatment cancelled' ORDER BY notification_id DESC LIMIT 1"))
            .rows
            .single;
        expect(msg['insured_id'], 103);
        expect(msg['body'], 'Your treatment at $facility on ${dayText(0)} was cancelled because it was not accepted'
            ' in time. Your claim SST-2026-000149 is now closed.');
        final claims = await db.performQuery(
            'SELECT claim_status FROM InjuryClaim WHERE claim_id IN (143, 149) ORDER BY claim_id');
        expect([for (final r in claims.rows) r['claim_status']], ['Covered', 'Withdrawn']);

        final c = await signedIn();
        final page = (await c.get('/u4/treatments/$due')).json['treatment'] as Map;
        expect(page['treatment_status'], 'Cancelled', reason: 'QU4.4 also reads a Cancelled treatment (U4-5)');
      }));

  test('U4.3: the job runs every day at 00:05 Asia/Bangkok', () {
    expect(AutoCancelJob.nextRunDelay(DateTime.utc(2026, 10, 17, 16)), const Duration(hours: 1, minutes: 5));
    expect(AutoCancelJob.nextRunDelay(DateTime.utc(2026, 10, 16, 17, 5)), const Duration(days: 1));
    expect(AutoCancelJob.nextRunDelay(DateTime.utc(2026, 10, 16, 17, 4)), const Duration(minutes: 1));
  });
}
