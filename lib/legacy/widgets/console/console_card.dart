import 'package:flutter/material.dart';

/// A titled card. Most console cards have this shape.
///
/// The design gives each one a heading, an optional badge at the right, a
/// divider, and then its content.
class ConsoleCard extends StatelessWidget {
  const ConsoleCard({
    super.key,
    this.title,
    this.trailing,
    required this.children,
    this.showDivider = true,
  });

  final String? title;

  /// A badge or a button at the right of the heading.
  final Widget? trailing;

  final List<Widget> children;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title != null) ...<Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            if (showDivider)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1),
              )
            else
              const SizedBox(height: 12),
          ],
          ...children,
        ],
      ),
    );
  }
}

/// A label above a value. The console uses it inside a grid of facts.
class FactCell extends StatelessWidget {
  const FactCell({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(value, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

/// A grid of `FactCell`s, three to a row.
class FactGrid extends StatelessWidget {
  const FactGrid({super.key, required this.cells, this.perRow = 3});

  final List<FactCell> cells;
  final int perRow;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < cells.length; i += perRow) {
      final List<FactCell> slice = cells.sublist(
        i,
        (i + perRow) > cells.length ? cells.length : i + perRow,
      );
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + perRow < cells.length ? 16 : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (int c = 0; c < perRow; c++)
                Expanded(
                  child: c < slice.length ? slice[c] : const SizedBox.shrink(),
                ),
            ],
          ),
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }
}
