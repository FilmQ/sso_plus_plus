import 'package:flutter/material.dart';

/// A column of choices, the strongest at the top.
///
/// Screens M6 and M9 use it: confirm, ask for another date, and refuse.
class ActionStack extends StatelessWidget {
  const ActionStack({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.primaryIcon,
    this.secondaryLabel,
    this.onSecondary,
    this.tertiaryLabel,
    this.onTertiary,
    this.caption,
    this.busy = false,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final IconData? primaryIcon;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final String? tertiaryLabel;
  final VoidCallback? onTertiary;

  /// The sentence below the buttons that says what happens if the person
  /// does nothing.
  final String? caption;

  /// True while an action runs. The buttons then do nothing.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FilledButton.icon(
          onPressed: busy ? null : onPrimary,
          icon: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(primaryIcon ?? Icons.check),
          label: Text(primaryLabel),
        ),
        if (secondaryLabel != null) ...<Widget>[
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: busy ? null : onSecondary,
            child: Text(secondaryLabel!),
          ),
        ],
        if (tertiaryLabel != null) ...<Widget>[
          const SizedBox(height: 4),
          TextButton(
            onPressed: busy ? null : onTertiary,
            child: Text(tertiaryLabel!),
          ),
        ],
        if (caption != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            caption!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
