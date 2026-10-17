import 'package:flutter/material.dart';

/// A label and a value side by side (U3-2 and U4-1 cards: "Date", "Type").
class SideKeyValue extends StatelessWidget {
  const SideKeyValue(this.label, this.value, {super.key, this.strong = false, this.labelWidth = 112});

  final String label;
  final String value;
  final bool strong;
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: labelWidth,
          child: Text(label, style: text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(value, style: strong ? text.titleSmall : text.bodyMedium)),
      ],
    );
  }
}
