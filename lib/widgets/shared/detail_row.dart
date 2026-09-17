import 'package:flutter/material.dart';

/// One line of detail: an icon, a value and an explanation below it.
///
/// The appointment cards, the report card and the console claim detail all
/// use this row.
class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.icon,
    required this.label,
    this.detail,
    this.dense = false,
  });

  final IconData icon;

  /// The first line. It carries the value.
  final String label;

  /// The second line. It explains the value. It may be absent.
  final String? detail;

  /// True to remove the space below the row.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: dense ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: colors.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: theme.textTheme.bodyMedium),
                if (detail != null && detail!.isNotEmpty)
                  Text(
                    detail!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
