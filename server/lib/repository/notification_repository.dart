import 'repository.dart';
import 'sql/notification_sql.dart';

/// Table Notification (U2, U3, O2, O3, O4, O5).
class NotificationRepository extends Repository {
  NotificationRepository(super.db);

  final String table = 'Notification';

  // Q2.1 [U2] or Q3.1 [U3.1]: the two Query IDs have the same SQL (2.18:
  // countUnread {Q2.1, Q3.1}). [queryId] tells which use case asks.
  Future<int> countUnread(int insuredId, {String queryId = 'Q2.1'}) async =>
      (await query(queryId == 'Q3.1' ? NotificationSql.q3_1 : NotificationSql.q2_1, {'insured_id': insuredId}))
          .rows
          .single['unread'] as int;

  // Q2.2 [U2] Newest first.
  Future<List<Row>> findNotifications(int insuredId) async =>
      (await query(NotificationSql.q2_2, {'insured_id': insuredId})).rows;

  // Q2.3 [U2] Gives 0 when the message was already read or is not for this user.
  Future<int> markAsRead(int notificationId, int insuredId) =>
      execute(NotificationSql.q2_3, {'notification_id': notificationId, 'insured_id': insuredId});

  // Q3.7 [U3.1, U3.2, U3.3]
  Future<int> markRead(int notificationId, int insuredId) =>
      execute(NotificationSql.q3_7, {'notification_id': notificationId, 'insured_id': insuredId});

  // QN.1 [O2, O5.1]
  Future<int> insertNotification({
    required int claimId,
    required String subject,
    required String body,
  }) =>
      execute(NotificationSql.qN_1, {'claim_id': claimId, 'subject': subject, 'body': body});

  // QN.2 [O3]
  Future<int> insertRejectionNotice(int claimId) =>
      execute(NotificationSql.qN_2, {'claim_id': claimId});

  // QN.3 [O4] One message to the user and one to the consultant.
  Future<int> insertAppointmentNotices(int appointmentId) =>
      execute(NotificationSql.qN_3, {'appointment_id': appointmentId});

  // QN.4 [O5.2]
  Future<int> insertNoTreatmentNotice(int claimId) =>
      execute(NotificationSql.qN_4, {'claim_id': claimId});
}
