import 'package:flutter/material.dart';

import '../l10n/tr.dart';

/// A form section title with a short help line (U1-2: "General information").
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(context.tr(title), style: text.titleMedium),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(context.tr(subtitle!), style: text.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
      ],
    );
  }
}
