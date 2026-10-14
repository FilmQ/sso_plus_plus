import 'package:flutter/material.dart';

import '../../../api/notification_api.dart';
import 'notification_style.dart';

/// U2-2 Notification pop-up (SA report figure 2-18, class PopUpController).
///
/// In the report PopUpController is between NotificationController and the
/// HomePage; here it is on the page side, because it only shows the window (D-023).
abstract final class PopUpController {
  /// Shows the list. Gives the message that the user selects, or null.
  static Future<NotificationItem?> showPopup(BuildContext context, List<NotificationItem> items) {
    return showDialog<NotificationItem>(
      context: context,
      barrierColor: Colors.black26,
      builder: (BuildContext dialog) => _NotificationPopUp(items: items),
    );
  }
}

class _NotificationPopUp extends StatelessWidget {
  const _NotificationPopUp({required this.items});

  final List<NotificationItem> items;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme colors = Theme.of(context).colorScheme;
    final int unread = items.where((NotificationItem n) => !n.isRead).length;
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 72, 16, 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 448),
          child: Material(
            color: colors.surfaceContainerLowest,
            elevation: 3,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: <Widget>[
                      Expanded(child: Text('Notifications', style: text.titleMedium)),
                      Text('$unread unread', style: text.labelMedium?.copyWith(color: colors.primary)),
                    ],
                  ),
                ),
                if (items.isEmpty)
                  const Padding(padding: EdgeInsets.all(24), child: Text('You have no messages.')),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (BuildContext context, int i) => _Row(item: items[i]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color muted = colors.onSurfaceVariant;
    return InkWell(
      onTap: () => Navigator.of(context).pop(item),
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
