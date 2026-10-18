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

  /// QN.1: O2 step 6.1 and O5.1, a message to the user of the claim.
  Future<int> notifyUser(int claimId, String subject, String body) =>
      notifications.insertNotification(claimId: claimId, subject: subject, body: body);

  /// QN.3: O4 step 6.1, a message to the user and one to the consultant.
  Future<int> notifyUserAndConsultant(int appointmentId) => notifications.insertAppointmentNotices(appointmentId);

  /// QN.4: O5.2 step 6.1, the claim is closed because no treatment is required.
  Future<int> notifyNoTreatment(int claimId) => notifications.insertNoTreatmentNotice(claimId);

  /// QN.2: O3 step 6.1, the rejection message with the reason and the
  /// officer's message.
  Future<int> notifyRejection(int claimId) => notifications.insertRejectionNotice(claimId);

  /// Q3.7: U3.1 step 6, U3.2 step 8, U3.3 step 8. Gives 0 when the message was
  /// already read (for example, opened in U2) or is not for this user.
  Future<int> markRead(int notificationId, int insuredId) => notifications.markRead(notificationId, insuredId);
}
