import 'package:flutter/material.dart';

import '../theme/status_colors.dart';

/// The small status pill of the Figma frames: an icon and a label.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.icon, required this.label, required this.background, required this.foreground});

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: foreground)),
          ),
        ],
      ),
    );
  }
}

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
      'Withdrawn' => (Icons.do_not_disturb_on, colors.surfaceContainerHighest, colors.onSurfaceVariant),
      _ => (Icons.hourglass_top, colors.secondaryContainer, colors.onSecondaryContainer),
    };
    return StatusPill(icon: icon, label: status, background: bg, foreground: fg);
  }
}

/// The chip of an Appointment.appointment_status (05-states.md), as in U3-2,
/// U3-5 and U3-7. 'Pending' shows as "Awaiting your confirmation" (U3.1 step 3).
class AppointmentStatusChip extends StatelessWidget {
  const AppointmentStatusChip(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final StatusColors s = StatusColors.of(context);
    final (IconData icon, String label, Color bg, Color fg) = switch (status) {
      'Pending' => (Icons.schedule, 'Awaiting your confirmation', s.warningContainer, s.warning),
      'Confirmed' => (Icons.event_available, 'Confirmed', s.successContainer, s.success),
      'Cancelled' => (Icons.event_busy, 'Cancelled', colors.errorContainer, colors.onErrorContainer),
      _ => (Icons.update, status, colors.secondaryContainer, colors.onSecondaryContainer),
    };
    return StatusPill(icon: icon, label: label, background: bg, foreground: fg);
  }
}

/// The chip of a Treatment.treatment_status (05-states.md), as in U4-1, U4-2
/// and U6-1. 'Pending' shows as "Waiting for your answer" (U4-1), or as
/// "Awaiting you" when [short] (U6-1).
class TreatmentStatusChip extends StatelessWidget {
  const TreatmentStatusChip(this.status, {super.key, this.short = false});

  final String status;
  final bool short;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final StatusColors s = StatusColors.of(context);
    final (IconData icon, String label, Color bg, Color fg) = switch (status) {
      'Pending' => (Icons.schedule, short ? 'Awaiting you' : 'Waiting for your answer', s.warningContainer, s.warning),
      'Accepted' => (Icons.event_available, 'Accepted', s.successContainer, s.success),
      'Cancelled' => (Icons.event_busy, 'Cancelled', colors.errorContainer, colors.onErrorContainer),
      _ => (Icons.update, status, colors.secondaryContainer, colors.onSecondaryContainer),
    };
    return StatusPill(icon: icon, label: label, background: bg, foreground: fg);
  }
}
