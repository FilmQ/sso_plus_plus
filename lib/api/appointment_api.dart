import 'api_client.dart';
import 'notification_api.dart';

/// The page side of server AppointmentController (U3.1 to U3.3, D-002, D-032).
/// [notificationId] is the message that opened the Appointment Page (Q3.7).
class AppointmentApi {
  const AppointmentApi(this.api);

  final ApiClient api;

  String _base(int claimId) => '/u3/claims/$claimId/appointment';

  Map<String, Object?> _row(Map<String, Object?> body) => body['appointment']! as Map<String, Object?>;

  /// Q3.1: the red dot of the Notification Page (checkUnreadNotifications).
  Future<int> checkUnreadNotifications() async => (await api.get('/u3/unread-count'))['unread']! as int;

  /// Q2.2 through AppointmentController.getNotifications (U3.1 step 1).
  Future<List<NotificationItem>> getNotifications() async {
    final List<Object?> rows = (await api.get('/u3/notifications'))['notifications']! as List<Object?>;
    return <NotificationItem>[for (final Object? r in rows) NotificationItem.fromJson(r! as Map<String, Object?>)];
  }

  /// Q3.2
  Future<Map<String, Object?>> getAppointment(int claimId) async => _row(await api.get(_base(claimId)));

  /// Q3.3, Q3.7
  Future<Map<String, Object?>> confirmAppointment(int claimId, int? notificationId) async =>
      _row(await api.post('${_base(claimId)}/confirm', <String, Object?>{'notification_id': notificationId}));

  /// Q3.4: the free hours on [date] ('yyyy-MM-dd').
  Future<List<String>> getFreeSlots(int claimId, String date) async =>
      ((await api.get('${_base(claimId)}/free-slots?date=$date'))['slots']! as List<Object?>).cast<String>();

  /// Q3.5, Q3.7
  Future<Map<String, Object?>> reschedule(int claimId, String newDate, String newTime, int? notificationId) async =>
      _row(await api.post('${_base(claimId)}/reschedule', <String, Object?>{
        'new_date': newDate,
        'new_time': newTime,
        'notification_id': notificationId,
      }));

  /// Q3.6, Q3.7
  Future<Map<String, Object?>> cancelAppointment(int claimId, int? notificationId) async =>
      _row(await api.post('${_base(claimId)}/cancel', <String, Object?>{'notification_id': notificationId}));
}
