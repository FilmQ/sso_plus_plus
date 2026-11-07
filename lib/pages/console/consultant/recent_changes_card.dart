import 'package:flutter/material.dart';

import '../../../l10n/tr.dart';

/// "Recent changes" of the C1-1 Schedule Page (C1 step 2.1, QC1.2, R-052):
/// the messages of the last 14 days about appointments that users confirmed,
/// moved or cancelled (QN.5), the newest first.
class RecentChangesCard extends StatelessWidget {
  const RecentChangesCard({super.key, required this.messages, required this.loading});

  final List<Map<String, Object?>> messages;
  final bool loading;

  static IconData _icon(Object? subject) => switch ('$subject'.toLowerCase()) {
        final String s when s.contains('cancel') => Icons.event_busy,
        final String s when s.contains('reschedul') || s.contains('another date') => Icons.update,
        final String s when s.startsWith('new') => Icons.event,
        _ => Icons.event_available,
      };

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(spacing: 8, children: <Widget>[
            Icon(Icons.notifications, color: colors.primary),
            Expanded(child: Text(context.tr('Recent changes'), style: text.titleMedium)),
            Text(context.tr('Messages from the last 14 days'), style: text.bodySmall),
          ]),
        ),
        if (loading) const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
        if (!loading && messages.isEmpty)
          Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: Text(context.tr('No recent changes'))),
        for (final Map<String, Object?> m in messages) ...<Widget>[
          const Divider(height: 1),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: colors.secondaryContainer,
              foregroundColor: colors.onSecondaryContainer,
              child: Icon(_icon(m['subject']), size: 20),
            ),
            title: Text(context.tr('${m['subject']}'), style: text.titleSmall),
            subtitle: Text(context.tr('${m['body']}')),
            trailing: Text(context.tr('${m['sent_time']}'), style: text.bodySmall),
          ),
        ],
      ]),
    );
  }
}
