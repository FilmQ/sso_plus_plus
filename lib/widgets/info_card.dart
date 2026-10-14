import 'package:flutter/material.dart';

/// A card with an icon and a title in the header (U1-1 "Before you start",
/// U1-5 claim card, U2-1 "Your claim" and "Next appointment").
class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
    this.trailing,
    this.tonal = false,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;
  final Widget? trailing;

  /// A filled card without a border (surface container), as "Before you start".
  final bool tonal;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tonal ? colors.surfaceContainerLow : colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: tonal ? null : Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 22, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
              ?trailing,
            ],
          ),
          for (final Widget child in children) ...<Widget>[const SizedBox(height: 12), child],
        ],
      ),
    );
  }
}

/// A check-mark line of the "Before you start" card.
class CheckLine extends StatelessWidget {
  const CheckLine(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Row(
        children: <Widget>[
          Icon(Icons.check, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      );
}
