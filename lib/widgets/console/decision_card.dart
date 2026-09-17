import 'package:flutter/material.dart';

/// One choice in a decision card.
class DecisionOption<T> {
  const DecisionOption({
    required this.value,
    required this.label,
    required this.detail,
  });

  final T value;
  final String label;

  /// The line that says what follows from this choice.
  final String detail;
}

/// The panel where an officer records a decision.
///
/// Screen D2 uses it for the Section 33 result. The reason field appears
/// because BR-06 demands a written reason for an override.
class DecisionCard<T> extends StatelessWidget {
  const DecisionCard({
    super.key,
    required this.heading,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.reasonController,
    required this.reasonLabel,
    required this.reasonHelper,
    required this.primaryLabel,
    required this.onPrimary,
    this.dangerLabel,
    this.onDanger,
    this.busy = false,
  });

  final String heading;
  final List<DecisionOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final TextEditingController reasonController;
  final String reasonLabel;
  final String reasonHelper;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? dangerLabel;
  final VoidCallback? onDanger;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          heading,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        // A `RadioGroup` ancestor carries the value and the callback. The
        // same fields on `Radio` are deprecated in this Flutter version.
        RadioGroup<T>(
          groupValue: selected,
          onChanged: (T? value) {
            if (value != null && !busy) {
              onChanged(value);
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final DecisionOption<T> option in options)
                InkWell(
                  onTap: busy ? null : () => onChanged(option.value),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Radio<T>(value: option.value),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  option.label,
                                  style: theme.textTheme.bodyMedium,
                                ),
                                Text(
                                  option.detail,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: reasonController,
          maxLines: 2,
          enabled: !busy,
          decoration: InputDecoration(
            labelText: reasonLabel,
            hintText: reasonHelper,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: busy ? null : onPrimary,
          icon: const Icon(Icons.check),
          label: Text(primaryLabel),
        ),
        if (dangerLabel != null) ...<Widget>[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: busy ? null : onDanger,
            icon: Icon(Icons.cancel_outlined, color: colors.error),
            label: Text(dangerLabel!, style: TextStyle(color: colors.error)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colors.error),
            ),
          ),
        ],
      ],
    );
  }
}
