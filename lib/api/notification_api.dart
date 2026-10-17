import 'api_client.dart';

/// One row of Q2.2 (Notification).
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.claimId,
    required this.subject,
    required this.body,
    required this.sentTime,
    required this.isRead,
  });

  final int id;
  final int claimId;
  final String subject;
  final String body;

  /// 'FMDD FMMonth YYYY : HH24:MI', for example '5 October 2026 : 09:15'.
  final String sentTime;
  final bool isRead;

  factory NotificationItem.fromJson(Map<String, Object?> j) => NotificationItem(
        id: j['notification_id']! as int,
        claimId: j['claim_id']! as int,
        subject: j['subject']! as String,
        body: j['body']! as String,
        sentTime: j['sent_time']! as String,
        isRead: j['is_read']! as bool,
      );

  /// QN.3 writes this subject. Its message leads to the Appointment Page (U3).
  bool get isAppointment => subject == 'Appointment scheduled';

  /// QN.1 of O5.1 writes this subject. Its message leads to the Confirm Treatment page (U4).
  bool get isTreatment => subject == 'Treatment booked';
}

/// The page side of server NotificationController (U2, D-002).
class NotificationApi {
  const NotificationApi(this.api);

  final ApiClient api;

  /// Q2.1
  Future<int> checkUnreadNotifications() async => (await api.get('/u2/unread-count'))['unread']! as int;

  /// Q2.2
  Future<List<NotificationItem>> getNotifications() async {
    final List<Object?> rows = (await api.get('/u2/notifications'))['notifications']! as List<Object?>;
    return <NotificationItem>[for (final Object? r in rows) NotificationItem.fromJson(r! as Map<String, Object?>)];
  }

  /// Q2.3. Gives the opened message.
  Future<NotificationItem> markAsRead(int notificationId) async => NotificationItem.fromJson(
      (await api.post('/u2/notifications/$notificationId/read'))['notification']! as Map<String, Object?>);

  /// Q2.4: the claim card of U2-1 (with the next appointment), or null.
  Future<Map<String, Object?>?> getHomeClaim() async =>
      (await api.get('/u2/home-claim'))['claim'] as Map<String, Object?>?;

  /// The Profile page (P-1, D-003): national ID, name, phone and address.
  Future<Map<String, Object?>> getProfile() async => (await api.get('/auth/profile'))['profile']! as Map<String, Object?>;
}
