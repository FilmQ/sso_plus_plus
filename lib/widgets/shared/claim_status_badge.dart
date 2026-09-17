import 'package:flutter/material.dart';

/// How urgent the badge is.
enum BadgeTone { neutral, action, good, bad }

/// The small pill that shows the state of a claim or an appointment.
class ClaimStatusBadge extends StatelessWidget {
  const ClaimStatusBadge({
    super.key,
    required this.label,
    this.tone = BadgeTone.neutral,
    this.icon,
  });

  final String label;
  final BadgeTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    final (Color background, Color foreground) = switch (tone) {
      BadgeTone.neutral => (colors.surfaceContainerHighest, colors.onSurface),
      BadgeTone.action => (colors.errorContainer, colors.onErrorContainer),
      BadgeTone.good => (colors.primaryContainer, colors.onPrimaryContainer),
      BadgeTone.bad => (colors.errorContainer, colors.onErrorContainer),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 6),
          ],
          // A badge sits inside a table column, so the label must be able to
          // shrink instead of overflowing the row.
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
