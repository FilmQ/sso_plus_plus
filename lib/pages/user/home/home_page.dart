import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api_exception.dart';
import '../../../api/notification_api.dart';
import '../../../session/session_providers.dart';
import '../../../widgets/centered_body.dart';
import '../../../widgets/info_card.dart';
import '../../../widgets/key_value.dart';
import 'claim_progress_card.dart';
import 'home_providers.dart';
import 'notification_detail_sheet.dart';
import 'pop_up_controller.dart';

/// U2-1 Home page (SA report figure 2-17), with the bell icon of U2.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  /// U2 step 3: the user clicks the bell icon; step 4 shows the pop-up (Q2.2).
  Future<void> clickBellIcon(BuildContext context, WidgetRef ref) async {
    final NotificationApi api = ref.read(notificationApiProvider);
    try {
      final List<NotificationItem> items = await api.getNotifications();
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
    ref.invalidate(unreadCountProvider);
    if (context.mounted) await showNotificationDetail(context, item);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int unread = ref.watch(unreadCountProvider).value ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: <Widget>[
          IconButton(
            key: const Key('bell'),
            tooltip: unread > 0 ? 'Notifications, $unread unread' : 'Notifications',
            onPressed: () => clickBellIcon(context, ref),
            icon: Badge(isLabelVisible: unread > 0, smallSize: 10, child: const Icon(Icons.notifications)),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(unreadCountProvider);
          ref.invalidate(homeProvider);
          await ref.read(homeProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: <Widget>[CenteredBody(child: _HomeBody(firstName: ref.watch(sessionProvider).value?.firstName ?? ''))],
        ),
      ),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.firstName});

  final String firstName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;
    final AsyncValue<Map<String, Object?>> home = ref.watch(homeProvider);
    final Map<String, Object?>? claim = home.value?['claim'] as Map<String, Object?>?;
    final Map<String, Object?>? next = home.value?['next_appointment'] as Map<String, Object?>?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: <Widget>[
        Text('สวัสดี คุณ$firstName', style: text.headlineSmall),
        if (home.hasError) Text('The claim cannot be shown now. Pull down to try again.', style: text.bodyMedium),
        if (home.isLoading) const Center(child: CircularProgressIndicator()),
        if (claim != null) ...<Widget>[
          Text('Claim ${claim['claim_no']} · ${claim['injury']}',
              style: text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ClaimProgressCard(claim: claim, nextAppointment: next?['appointment_date'] as String?),
        ],
        if (next != null)
          InfoCard(
            icon: Icons.event,
            title: 'Next appointment',
            tonal: true,
            children: <Widget>[
              KeyValue('Date', next['appointment_date']! as String, large: true),
              KeyValue('Consultant', '${next['consultant_name']} · ${next['office_location']}'),
            ],
          ),
      ],
    );
  }
}
