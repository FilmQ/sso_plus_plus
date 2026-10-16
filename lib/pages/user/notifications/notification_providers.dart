import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/appointment_api.dart';
import '../../../api/notification_api.dart';
import '../../../session/session_providers.dart';
import '../home/home_providers.dart';

final Provider<AppointmentApi> appointmentApiProvider =
    Provider<AppointmentApi>((Ref ref) => AppointmentApi(ref.watch(apiClientProvider)));

/// U3.1 step 1 (Q3.1): the red dot of the Notifications destination.
final FutureProvider<int> unreadOnNotificationPageProvider = FutureProvider<int>((Ref ref) {
  ref.watch(sessionProvider);
  return ref.read(appointmentApiProvider).checkUnreadNotifications();
});

/// The list of U3-1 Notification Page (U3.1 step 1, Q2.2).
final FutureProvider<List<NotificationItem>> notificationsProvider = FutureProvider<List<NotificationItem>>((Ref ref) {
  ref.watch(sessionProvider);
  return ref.read(appointmentApiProvider).getNotifications();
});

/// Reloads every value that a read message or an appointment change can alter.
void refreshUserData(WidgetRef ref) {
  ref.invalidate(unreadCountProvider);
  ref.invalidate(unreadOnNotificationPageProvider);
  ref.invalidate(notificationsProvider);
  ref.invalidate(homeClaimProvider);
}
