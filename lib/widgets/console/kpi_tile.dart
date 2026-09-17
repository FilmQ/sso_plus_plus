import 'package:flutter/material.dart';

/// How much attention the figure asks for.
enum KpiTone { plain, warning, alert, good }

/// One figure at the head of a worklist.
///
/// Screen D1 shows four of them: awaiting verification, needs review,
/// register unavailable and verified this week.
class KpiTile extends StatelessWidget {
  const KpiTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.tone = KpiTone.plain,
  });

  final String label;
  final int value;
  final IconData icon;
  final KpiTone tone;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    // The design gives each tile its own colour. Two red tiles beside each
    // other read as one alarm, so `warning` uses the tertiary colour.
    final (Color background, Color foreground) = switch (tone) {
      KpiTone.plain => (colors.surfaceContainerLow, colors.onSurface),
      KpiTone.warning => (colors.tertiaryContainer, colors.onTertiaryContainer),
      KpiTone.alert => (colors.errorContainer, colors.onErrorContainer),
      KpiTone.good => (colors.primaryContainer, colors.onPrimaryContainer),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$value',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
