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

/// U2 step 2 (Q2.4): the claim card of U2-1, or null when there is no claim.
final FutureProvider<Map<String, Object?>?> homeClaimProvider = FutureProvider<Map<String, Object?>?>((Ref ref) {
  ref.watch(sessionProvider);
  return ref.read(notificationApiProvider).getHomeClaim();
});

/// The data of P-1 Profile Page (D-003).
final FutureProvider<Map<String, Object?>> profileProvider = FutureProvider<Map<String, Object?>>((Ref ref) {
  ref.watch(sessionProvider);
  return ref.read(notificationApiProvider).getProfile();
});
