import 'package:flutter/material.dart';

import '../theme/status_colors.dart';

/// The chip of an InjuryClaim.claim_status (05-states.md), as in U1-5 and U2-1.
class ClaimStatusChip extends StatelessWidget {
  const ClaimStatusChip(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final StatusColors ok = StatusColors.of(context);
    final (IconData icon, Color bg, Color fg) = switch (status) {
      'Covered' => (Icons.verified, ok.successContainer, ok.success),
      'No treatment required' => (Icons.task_alt, ok.successContainer, ok.success),
      'Rejected' || 'Not covered' => (Icons.block, colors.errorContainer, colors.onErrorContainer),
      'Register unavailable' => (Icons.cloud_off, colors.tertiaryContainer, colors.onTertiaryContainer),
      _ => (Icons.hourglass_top, colors.secondaryContainer, colors.onSecondaryContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(status, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg)),
        ],
      ),
    );
  }
}
