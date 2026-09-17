import 'package:flutter/material.dart';

/// The rounded card that every screen uses.
///
/// The design calls these `Card · <name>`. One widget serves all of them.
class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.tone = InfoCardTone.plain,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final InfoCardTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    final Color background = switch (tone) {
      InfoCardTone.plain => colors.surfaceContainerLow,
      InfoCardTone.highlighted => colors.primaryContainer.withValues(
        alpha: 0.45,
      ),
    };

    return Card(
      color: background,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// How much attention the card asks for.
enum InfoCardTone {
  /// The usual card.
  plain,

  /// The card that carries the next action of the person.
  highlighted,
}
