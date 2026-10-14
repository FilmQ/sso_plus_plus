import 'package:flutter/material.dart';

import '../../../theme/status_colors.dart';
import '../../../widgets/info_card.dart';
import '../../../widgets/status_chip.dart';

enum _Step { done, current, later }

/// "Your claim" of U2-1: the status chip and the four steps of the process
/// (01-business-process.md): forms, officer check, consultation, treatment.
class ClaimProgressCard extends StatelessWidget {
  const ClaimProgressCard({super.key, required this.claim, this.nextAppointment});

  final Map<String, Object?> claim;
  final String? nextAppointment;

  @override
  Widget build(BuildContext context) {
    final String status = claim['claim_status']! as String;
    final bool waiting = status == 'Awaiting verification' || status == 'Register unavailable';
    final bool rejected = status == 'Rejected' || status == 'Not covered';
    final bool closed = status == 'No treatment required';
    return InfoCard(
      icon: Icons.assignment,
      title: 'Your claim',
      trailing: ClaimStatusChip(status),
      children: <Widget>[
        _StepRow(_Step.done, 'Injury forms submitted', claim['submitted_time'] as String? ?? ''),
        if (waiting)
          const _StepRow(_Step.current, 'Eligibility check by the officer', 'Waiting for the officer')
        else
          _StepRow(_Step.done, rejected ? 'Checked by the officer' : 'Eligibility confirmed by the officer',
              claim['checked_time'] as String? ?? ''),
        if (!rejected) ...<Widget>[
          _StepRow(
            closed ? _Step.done : (waiting ? _Step.later : _Step.current),
            'Consultation with a consultant',
            closed
                ? 'Consultation finished'
                : nextAppointment != null
                    ? 'Appointment on $nextAppointment'
                    : waiting
                        ? 'After the officer confirms your claim'
                        : 'The officer books an appointment',
          ),
          _StepRow(closed ? _Step.done : _Step.later, 'Treatment',
              closed ? 'No treatment required' : 'Booked after the consultation report'),
        ],
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow(this.step, this.title, this.subtitle);

  final _Step step;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final ColorScheme c = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final (IconData icon, Color color) = switch (step) {
      _Step.done => (Icons.check_circle, StatusColors.of(context).success),
      _Step.current => (Icons.pending, c.primary),
      _Step.later => (Icons.radio_button_unchecked, c.outline),
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title,
                  style: (step == _Step.current ? text.titleSmall : text.bodyMedium)
                      ?.copyWith(color: step == _Step.later ? c.onSurfaceVariant : null)),
              if (subtitle.isNotEmpty) Text(subtitle, style: text.bodySmall?.copyWith(color: c.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}
