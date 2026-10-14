import 'api_client.dart';

/// One row of Q2.2 (Notification).
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.subject,
    required this.body,
    required this.sentTime,
    required this.isRead,
  });

  final int id;
  final String subject;
  final String body;

  /// 'FMDD FMMonth YYYY : HH24:MI', for example '5 October 2026 : 09:15'.
  final String sentTime;
  final bool isRead;

  factory NotificationItem.fromJson(Map<String, Object?> j) => NotificationItem(
        id: j['notification_id']! as int,
        subject: j['subject']! as String,
        body: j['body']! as String,
        sentTime: j['sent_time']! as String,
        isRead: j['is_read']! as bool,
      );
}

/// The page side of server NotificationController (U2) and HomeController (D-002).
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

  /// The claim card and the next appointment of U2-1 (R-006).
  Future<Map<String, Object?>> getHome() => api.get('/home');
}
