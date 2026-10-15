import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../controller/appointment_controller.dart';
import 'json.dart';

/// U3.1 to U3.3 Appointment Confirmation. `notification_id` in a POST body is
/// the message that opened the page (for Q3.7); it can be left out.
void addU3Routes(
  Router router,
  AppointmentController Function(Request) appointments,
) {
  const base = '/u3/claims/<claim|[0-9]+>/appointment';
  int? notificationOf(Map<String, Object?> body) => body['notification_id'] as int?;

  router
    // Q3.1: the red dot of the Notification Page.
    ..get('/u3/unread-count', (Request r) async =>
        jsonOk({'unread': await appointments(r).checkUnreadNotifications()}))
    // Q3.2
    ..get(base, (Request r, String claim) async =>
        jsonOk({'appointment': await appointments(r).getAppointment(int.parse(claim))}))
    // Q3.3, Q3.7
    ..post('$base/confirm', (Request r, String claim) async {
      final body = await readJson(r);
      return jsonOk({
        'appointment': await appointments(r).confirmAppointment(int.parse(claim), notificationId: notificationOf(body)),
      });
    })
    // Q3.4
    ..get('$base/free-slots', (Request r, String claim) async => jsonOk({
          'slots': await appointments(r).getFreeSlots(int.parse(claim), r.url.queryParameters['date'] ?? ''),
        }))
    // Q3.5, Q3.7
    ..post('$base/reschedule', (Request r, String claim) async {
      final body = await readJson(r);
      return jsonOk({
        'appointment': await appointments(r).reschedule(
          int.parse(claim),
          (body['new_date'] as String?) ?? '',
          (body['new_time'] as String?) ?? '',
          notificationId: notificationOf(body),
        ),
      });
    })
    // Q3.6, Q3.7
    ..post('$base/cancel', (Request r, String claim) async {
      final body = await readJson(r);
      return jsonOk({
        'appointment': await appointments(r).cancelAppointment(int.parse(claim), notificationId: notificationOf(body)),
      });
    });
}
