import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../controller/home_controller.dart';
import '../controller/notification_controller.dart';
import 'json.dart';

/// U2 View Notify Message, and the Home page cards.
void addU2Routes(
  Router router,
  NotificationController Function(Request) notifications,
  HomeController Function(Request) home,
) {
  router
    ..get('/home', (Request r) async => jsonOk(await home(r).getHome()))
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
