import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api_exception.dart';
import '../../../api/notification_api.dart';
import '../notifications/notification_providers.dart';
import '../treatment/open_treatment.dart';
import 'home_providers.dart';
import 'notification_detail_sheet.dart';
import 'pop_up_controller.dart';

/// The bell icon of U2 with the red dot (Q2.1). The report puts clickBellIcon
/// and selectNotification on HomePage; they are here so that P-1 Profile Page
/// can show the same bell (Figma).
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  /// U2 step 3: the user clicks the bell icon; step 4 shows the pop-up (Q2.2).
  Future<void> clickBellIcon(BuildContext context, WidgetRef ref) async {
    try {
      final List<NotificationItem> items = await ref.read(notificationApiProvider).getNotifications();
      if (!context.mounted) return;
      final NotificationItem? chosen = await PopUpController.showPopup(context, items);
      if (chosen != null && context.mounted) await selectNotification(context, ref, chosen.id);
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// U2 steps 5 and 6: the message is marked read (Q2.3) and shown.
  Future<void> selectNotification(BuildContext context, WidgetRef ref, int notificationId) async {
    final NotificationItem item = await ref.read(notificationApiProvider).markAsRead(notificationId);
    refreshUserData(ref);
    if (context.mounted) {
      await showNotificationDetail(context, item,
          onOpen: () => item.isTreatment
              ? openTreatmentOfClaim(context, ref, item.claimId)
              : context.push('/appointment/${item.claimId}?n=${item.id}'));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int unread = ref.watch(unreadCountProvider).value ?? 0;
    return IconButton(
      key: const Key('bell'),
      tooltip: unread > 0 ? 'Notifications, $unread unread' : 'Notifications',
      onPressed: () => clickBellIcon(context, ref),
      icon: Badge(isLabelVisible: unread > 0, smallSize: 10, child: const Icon(Icons.notifications)),
    );
  }
}
