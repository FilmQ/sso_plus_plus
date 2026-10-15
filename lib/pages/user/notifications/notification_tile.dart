import 'package:flutter/material.dart';

import '../../../api/notification_api.dart';
import '../home/notification_style.dart';

/// One message row: U2-2 pop-up and U3-1 Notification Page. An unread
/// message has a tinted background and a red dot.
class NotificationTile extends StatelessWidget {
  const NotificationTile({super.key, required this.item, required this.onTap});

  final NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color muted = colors.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: item.isRead ? null : colors.primaryContainer.withValues(alpha: 0.35),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            NotificationIcon(item.subject),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: <Widget>[
                  Text(item.subject, style: item.isRead ? text.bodyLarge : text.titleSmall),
                  Text(item.body, maxLines: 3, overflow: TextOverflow.ellipsis, style: text.bodyMedium?.copyWith(color: muted)),
                  Text(item.sentTime, style: text.bodySmall?.copyWith(color: muted)),
                ],
              ),
            ),
            if (!item.isRead)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Badge(key: ValueKey<String>('unread:${item.id}'), smallSize: 10),
              ),
          ],
        ),
      ),
    );
  }
}
