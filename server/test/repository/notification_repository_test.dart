import 'package:sst_server/repository/notification_repository.dart';
import 'package:test/test.dart';

import '../support/test_db.dart';

void main() {
  final db = useTestDb();
  final repo = NotificationRepository(db);

  Future<int> countFor(int claimId) async => (await db.performQuery(
          'SELECT COUNT(*) AS n FROM Notification WHERE claim_id = :id', {'id': claimId}))
      .rows
      .single['n'] as int;

  test('Q2.1 countUnread: person 101 has 0, person 103 has 1', () async {
    expect(await repo.countUnread(101), 0);
    expect(await repo.countUnread(103), 1);
  });

  test('Q2.2 findNotifications: newest first, with sent_time and is_read', () async {
    final rows = await repo.findNotifications(101);
    expect(rows.map((r) => r['notification_id']), [902, 901]);
    expect(rows.first['sent_time'], '5 October 2026 : 10:30');
    expect(rows.first['is_read'], true);
  });

  test('Q2.3 markAsRead: only once, and only for the owner', () => inRollback(db, () async {
        expect(await repo.markAsRead(905, 101), 0);
        expect(await repo.markAsRead(905, 103), 1);
        expect(await repo.markAsRead(905, 103), 0);
        expect(await repo.countUnread(103), 0);
      }));

  test('Q3.1 countUnread (U3.1): same count as Q2.1', () async {
    expect(await repo.countUnread(103, queryId: 'Q3.1'), 1);
  });

  test('Q3.7 markRead marks an unread message', () => inRollback(db, () async {
        expect(await repo.markRead(905, 103), 1);
      }));

  test('QN.1 insertNotification sends one message to the claim owner', () => inRollback(db, () async {
        expect(await repo.insertNotification(claimId: 143, subject: 'Claim confirmed', body: 'Test'), 1);
        expect(await repo.countUnread(101), 1);
      }));

  test('QN.2 insertRejectionNotice: reason text and officer message', () => inRollback(db, () async {
        expect(await repo.insertRejectionNotice(151), 1);
        final newest = (await repo.findNotifications(104)).first;
        expect(newest['subject'], 'Application rejected');
        expect(newest['body'], contains('The register shows your contributions ended in May 2026.'));
      }));

  test('QN.3 insertAppointmentNotices: one to the user, one to the consultant', () => inRollback(db, () async {
        final before = await countFor(143);
        expect(await repo.insertAppointmentNotices(504), 2);
        expect(await countFor(143), before + 2);
      }));

  test('QN.5 insertConsultantMessage: confirmed, rescheduled or cancelled, to the consultant', () =>
      inRollback(db, () async {
        Future<String> newest() async => (await db.performQuery(
                'SELECT subject FROM Notification WHERE consultant_id IS NOT NULL ORDER BY notification_id DESC LIMIT 1'))
            .rows
            .single['subject']! as String;
        expect(await repo.insertConsultantMessage(504), 1); // Confirmed, not a reschedule
        expect(await newest(), 'Appointment confirmed');
        expect(await repo.insertConsultantMessage(503), 1); // supersedes 502
        expect(await newest(), 'Appointment rescheduled');
        expect(await repo.insertConsultantMessage(505), 1); // Cancelled
        expect(await newest(), 'Appointment cancelled');
      }));

  test('QN.4 insertNoTreatmentNotice: only for a claim with No treatment required', () => inRollback(db, () async {
        expect(await repo.insertNoTreatmentNotice(147), 1);
        expect(await repo.insertNoTreatmentNotice(143), 0);
      }));
}
