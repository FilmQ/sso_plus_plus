import 'package:flutter/material.dart';

/// A small label over a value (U1-5 "Submitted", U2-1 "Date").
class KeyValue extends StatelessWidget {
  const KeyValue(this.label, this.value, {super.key, this.large = false});

  final String label;
  final String value;

  /// The value in body large (U2-1 "Date"), else body medium.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: text.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value, style: large ? text.bodyLarge : text.bodyMedium),
      ],
    );
  }
}
