import 'package:flutter/material.dart';

import '../../../theme/status_colors.dart';

/// The round icon of a message in the pop-up (U2-2), from its subject.
/// The subjects are the texts of QN.1 to QN.4 and QU4.3.
class NotificationIcon extends StatelessWidget {
  const NotificationIcon(this.subject, {super.key});

  final String subject;

  @override
  Widget build(BuildContext context) {
    final ColorScheme c = Theme.of(context).colorScheme;
    final StatusColors ok = StatusColors.of(context);
    final (IconData icon, Color bg, Color fg) = switch (subject) {
      'Appointment scheduled' || 'New appointment' => (Icons.event, c.secondaryContainer, c.onSecondaryContainer),
      'Claim confirmed' => (Icons.verified, ok.successContainer, ok.success),
      'No treatment required' => (Icons.task_alt, ok.successContainer, ok.success),
      'Application rejected' => (Icons.block, c.errorContainer, c.onErrorContainer),
      'Treatment cancelled' => (Icons.event_busy, c.errorContainer, c.onErrorContainer),
      _ => (Icons.mark_email_read, c.secondaryContainer, c.onSecondaryContainer),
    };
    return CircleAvatar(radius: 20, backgroundColor: bg, child: Icon(icon, size: 22, color: fg));
  }
}
