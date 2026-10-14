import 'package:flutter/material.dart';

import '../../../api/notification_api.dart';
import '../../../widgets/info_card.dart';

/// U2-3 Message opened (marked as read) and U2-4 Rejection message
/// (SA report figures 2-19 and 2-20).
Future<void> showNotificationDetail(BuildContext context, NotificationItem item) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (BuildContext sheet) => _Detail(item: item),
  );
}

class _Detail extends StatelessWidget {
  const _Detail({required this.item});

  final NotificationItem item;

  /// QN.2 writes the reason and the officer message with an empty line between them.
  List<Widget> _cards() {
    if (item.subject != 'Application rejected') {
      return <Widget>[_textCard(Icons.mail, 'Message', item.body)];
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
                ..._cards(),
                FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
