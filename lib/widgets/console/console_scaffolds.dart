import 'package:flutter/material.dart';

import 'console_top_bar.dart';

/// The body of a worklist screen: a row of figures, then one panel.
///
/// Screens D1 and D4 use it.
class WorklistBody extends StatelessWidget {
  const WorklistBody({
    super.key,
    this.kpis = const <Widget>[],
    required this.panels,
  });

  final List<Widget> kpis;
  final List<Widget> panels;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 32),
      children: <Widget>[
        if (kpis.isNotEmpty) ...<Widget>[
          Row(
            children: <Widget>[
              for (int i = 0; i < kpis.length; i++) ...<Widget>[
                Expanded(child: kpis[i]),
                if (i < kpis.length - 1) const SizedBox(width: 16),
              ],
            ],
          ),
          const SizedBox(height: 22),
        ],
        for (final Widget panel in panels) ...<Widget>[
          panel,
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

/// The body of a detail screen: a breadcrumb, then two columns.
///
/// The left column is the context and it is the wider one. The right column
/// is the action. Screens D2, D3, D5, D6, D7 and D8 use it.
class DetailBody extends StatelessWidget {
  const DetailBody({
    super.key,
    required this.breadcrumb,
    required this.context_,
    required this.action,
    this.onBack,
  });

  /// The two parts of the breadcrumb, for example
  /// `Verification › CLM-2569-0143`.
  final List<String> breadcrumb;

  /// The left column. The trailing underscore avoids a clash with
  /// `BuildContext context`.
  final List<Widget> context_;

  /// The right column.
  final List<Widget> action;

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 32),
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              onPressed: onBack,
              tooltip: 'Back',
            ),
            for (int i = 0; i < breadcrumb.length; i++) ...<Widget>[
              Text(
                breadcrumb[i],
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: i == breadcrumb.length - 1
                      ? colors.onSurface
                      : colors.onSurfaceVariant,
                  fontWeight: i == breadcrumb.length - 1
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
              if (i < breadcrumb.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (final Widget widget in context_) ...<Widget>[
                    widget,
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (final Widget widget in action) ...<Widget>[
                    widget,
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The frame of every console screen: a top bar and a body.
///
/// The rail belongs to the shell, because the shell keeps it while the
/// screen changes.
class ConsoleScreen extends StatelessWidget {
  const ConsoleScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
    this.searchHint,
    this.trailing = const <Widget>[],
  });

  final String title;
  final String subtitle;
  final Widget body;
  final String? searchHint;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ConsoleTopBar(
          title: title,
          subtitle: subtitle,
          searchHint: searchHint,
          trailing: trailing,
        ),
        Expanded(child: body),
      ],
    );
  }
}
