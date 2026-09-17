import 'package:flutter/material.dart';

/// One column of a worklist table.
class WorklistColumn {
  const WorklistColumn(this.label, {this.flex = 2});

  final String label;
  final int flex;
}

/// The panel that holds a worklist table.
///
/// It carries a heading, filter chips, the rows, and a footer that says how
/// many rows are shown.
class WorklistPanel extends StatelessWidget {
  const WorklistPanel({
    super.key,
    required this.heading,
    required this.columns,
    required this.rows,
    this.chips = const <Widget>[],
    this.footer,
  });

  final String heading;
  final List<WorklistColumn> columns;

  /// Each row holds one cell for each column.
  final List<List<Widget>> rows;

  final List<Widget> chips;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    heading,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ...chips,
              ],
            ),
          ),
          Divider(height: 1, color: colors.outlineVariant),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(
              children: <Widget>[
                for (final WorklistColumn column in columns)
                  Expanded(
                    flex: column.flex,
                    child: Text(
                      column.label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.outlineVariant),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'Nothing waits here.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            for (int i = 0; i < rows.length; i++) ...<Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    for (int c = 0; c < columns.length; c++)
                      Expanded(
                        flex: columns[c].flex,
                        child: c < rows[i].length
                            ? rows[i][c]
                            : const SizedBox.shrink(),
                      ),
                  ],
                ),
              ),
              if (i < rows.length - 1)
                Divider(height: 1, color: colors.outlineVariant),
            ],
          if (footer != null) ...<Widget>[
            Divider(height: 1, color: colors.outlineVariant),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
              child: Text(
                footer!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
