import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api_exception.dart';
import '../../../api/notification_api.dart';
import '../../../widgets/centered_body.dart';
import '../home/home_providers.dart';
import '../home/notification_detail_sheet.dart';
import 'notification_providers.dart';
import 'notification_tile.dart';

/// U3-1 Notification Page (red dot) (SA report figure 2-23, U3.1 steps 1 and 2).
class NotificationPage extends ConsumerWidget {
  const NotificationPage({super.key});

  /// U3.1 step 2: a message of QN.3 opens the Appointment Page; Q3.7 marks it
  /// read after the user's choice. Other messages open as in U2 (Q2.3).
  Future<void> clickNotification(BuildContext context, WidgetRef ref, NotificationItem item) async {
    if (item.isAppointment) {
      await context.push('/appointment/${item.claimId}?n=${item.id}');
      refreshUserData(ref);
      return;
    }
    try {
      final NotificationItem opened = await ref.read(notificationApiProvider).markAsRead(item.id);
      refreshUserData(ref);
      if (context.mounted) await showNotificationDetail(context, opened);
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<NotificationItem>> list = ref.watch(notificationsProvider);
    final List<NotificationItem> items = list.value ?? const <NotificationItem>[];
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: RefreshIndicator(
        onRefresh: () async {
          refreshUserData(ref);
          await ref.read(notificationsProvider.future);
        },
        child: ListView(
          children: <Widget>[
            CenteredBody(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (list.isLoading) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
                  if (list.hasError) const Padding(padding: EdgeInsets.all(24), child: Text('The messages cannot be shown now.')),
                  if (list.hasValue && items.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('You have no messages.')),
                  for (final NotificationItem item in items) ...<Widget>[
                    NotificationTile(item: item, onTap: () => clickNotification(context, ref, item)),
                    const Divider(height: 1),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
