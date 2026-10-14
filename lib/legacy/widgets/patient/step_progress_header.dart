import 'package:flutter/material.dart';

/// The step counter above the claim form.
///
/// Screens M2 and M3 show `Step 1 of 3` with a bar that fills.
class StepProgressHeader extends StatelessWidget {
  const StepProgressHeader({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.title,
  });

  final int step;
  final int totalSteps;
  final String title;

  double get _fraction => step / totalSteps;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Step $step of $totalSteps · $title',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              '${(_fraction * 100).round()}%',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: _fraction, minHeight: 6),
        ),
      ],
    );
  }
}
