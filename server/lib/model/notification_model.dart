import '../repository/notification_repository.dart';
import 'model.dart';

/// Notification (SA report 2.18, used in U3, O2, O3, O4, O5).
class NotificationModel extends Model {
  NotificationModel(this.notifications);

  final NotificationRepository notifications;

  /// Q3.1: U3.1 step 1, the red dot of the Notification Page (2.18:
  /// NotificationModel.countUnread, NotificationRepository.countUnread {Q2.1, Q3.1}).
  Future<int> countUnread(int insuredId) => notifications.countUnread(insuredId, queryId: 'Q3.1');

  /// Q2.2: U3.1 step 1, the list of the Notification Page.
  Future<List<Map<String, Object?>>> getNotifications(int insuredId) => notifications.findNotifications(insuredId);

  /// QN.5: U3.1 to U3.3, the consultant is told about the user's choice.
  Future<int> notifyConsultant(int appointmentId) => notifications.insertConsultantMessage(appointmentId);

  /// Q3.7: U3.1 step 6, U3.2 step 8, U3.3 step 8. Gives 0 when the message was
  /// already read (for example, opened in U2) or is not for this user.
  Future<int> markRead(int notificationId, int insuredId) => notifications.markRead(notificationId, insuredId);
}
