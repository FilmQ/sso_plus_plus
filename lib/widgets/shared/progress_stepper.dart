import 'package:flutter/material.dart';

import '../../models/claim_progress.dart';

/// The claim tracker of screen M1.
///
/// It shows the five stages of a claim. A done stage carries a filled check.
/// The active stage carries a ring. A stage that has not started is grey.
class ProgressStepper extends StatelessWidget {
  const ProgressStepper({super.key, required this.steps});

  final List<ProgressStep> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < steps.length; i++)
          _StepRow(step: steps[i], isLast: i == steps.length - 1),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.isLast});

  final ProgressStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    final bool isWaiting = step.state == ClaimStepState.waiting;
    final Color markColor = isWaiting ? colors.outline : colors.primary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Column(
            children: <Widget>[
              _Mark(state: step.state, color: markColor),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: colors.outlineVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    step.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: step.state == ClaimStepState.active
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isWaiting
                          ? colors.onSurfaceVariant
                          : colors.onSurface,
                    ),
                  ),
                  if (step.detail.isNotEmpty)
                    Text(
                      step.detail,
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
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({required this.state, required this.color});

  final ClaimStepState state;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: switch (state) {
        ClaimStepState.done => Icon(Icons.check_circle, size: 22, color: color),
        ClaimStepState.active => Icon(
          Icons.radio_button_checked,
          size: 22,
          color: color,
        ),
        ClaimStepState.waiting => Icon(
          Icons.radio_button_unchecked,
          size: 22,
          color: color,
        ),
      },
    );
  }
}
