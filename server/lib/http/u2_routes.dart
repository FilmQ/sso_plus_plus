import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../controller/notification_controller.dart';
import 'json.dart';

/// U2 View Notify Message: the Home page claim card and the messages.
void addU2Routes(
  Router router,
  NotificationController Function(Request) notifications,
) {
  router
    // Q2.4
    ..get('/u2/home-claim', (Request r) async => jsonOk({'claim': await notifications(r).getHomeClaim()}))
    // Q2.1
    ..get('/u2/unread-count', (Request r) async =>
        jsonOk({'unread': await notifications(r).checkUnreadNotifications()}))
    // Q2.2
    ..get('/u2/notifications', (Request r) async =>
        jsonOk({'notifications': await notifications(r).getNotifications()}))
    // Q2.3
    ..post('/u2/notifications/<id|[0-9]+>/read', (Request r, String id) async =>
        jsonOk({'notification': await notifications(r).markAsRead(int.parse(id))}));
}
