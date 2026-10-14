import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/notification_api.dart';
import '../../../session/session_providers.dart';

final Provider<NotificationApi> notificationApiProvider =
    Provider<NotificationApi>((Ref ref) => NotificationApi(ref.watch(apiClientProvider)));

/// U2 step 2 (Q2.1): the number of unread messages, for the red dot.
final FutureProvider<int> unreadCountProvider = FutureProvider<int>((Ref ref) {
  ref.watch(sessionProvider);
  return ref.read(notificationApiProvider).checkUnreadNotifications();
});

/// The claim card and the next appointment of U2-1.
final FutureProvider<Map<String, Object?>> homeProvider = FutureProvider<Map<String, Object?>>((Ref ref) {
  ref.watch(sessionProvider);
  return ref.read(notificationApiProvider).getHome();
});
