import 'package:flutter/material.dart';

/// The bar of two buttons at the foot of a screen.
///
/// Screens M2, M3 and M5 use it: a text button on the left and a filled
/// button on the right.
class ActionBar extends StatelessWidget {
  const ActionBar({
    super.key,
    required this.secondaryLabel,
    required this.primaryLabel,
    this.onSecondary,
    this.onPrimary,
  });

  final String secondaryLabel;
  final String primaryLabel;
  final VoidCallback? onSecondary;

  /// The main action. A null callback makes the button inactive, as screen
  /// M3 shows while a document is absent.
  final VoidCallback? onPrimary;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: <Widget>[
            Expanded(
              child: TextButton(
                onPressed: onSecondary,
                child: Text(secondaryLabel),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: onPrimary,
                child: Text(primaryLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
