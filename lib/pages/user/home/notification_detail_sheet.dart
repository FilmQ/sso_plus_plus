import 'package:flutter/material.dart';

import '../../../api/notification_api.dart';
import '../../../widgets/info_card.dart';

/// U2-3 Message opened (marked as read) and U2-4 Rejection message
/// (SA report figures 2-19 and 2-20).
/// [onOpen] adds "Open appointment" to a QN.3 message (U2-3) and "Open
/// treatment" to a "Treatment booked" message of QN.1 (U4).
Future<void> showNotificationDetail(BuildContext context, NotificationItem item, {VoidCallback? onOpen}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (BuildContext sheet) => _Detail(item: item, onOpen: onOpen),
  );
}

class _Detail extends StatelessWidget {
  const _Detail({required this.item, this.onOpen});

  final NotificationItem item;
  final VoidCallback? onOpen;

  /// QN.2 writes the reason and the officer message with an empty line between
  /// them (U2-4). Other messages show the body in one card (U2-3).
  List<Widget> _cards(BuildContext context) {
    if (item.subject != 'Application rejected') {
      return <Widget>[
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Text(item.body, style: Theme.of(context).textTheme.bodyLarge),
        ),
        if (item.isAppointment)
          Text('Please confirm, change or decline this appointment on the appointment page.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ];
    }
    final List<String> parts = item.body.split('\n\n');
    return <Widget>[
      _textCard(Icons.info, 'Reason', parts.first),
      if (parts.length > 1) _textCard(Icons.message, 'Message from the officer', parts.skip(1).join('\n\n')),
    ];
  }

  Widget _textCard(IconData icon, String title, String body) =>
      InfoCard(icon: icon, title: title, children: <Widget>[Text(body)]);

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: <Widget>[
                Text(item.subject, style: text.headlineSmall),
                Text(item.sentTime, style: text.bodySmall),
                ..._cards(context),
                if ((item.isAppointment || item.isTreatment) && onOpen != null) ...<Widget>[
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onOpen!();
                    },
                    child: Text(item.isAppointment ? 'Open appointment' : 'Open treatment'),
                  ),
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
                ] else
                  FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
