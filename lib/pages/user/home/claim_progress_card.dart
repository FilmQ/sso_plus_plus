import 'package:flutter/material.dart';

import '../../../theme/status_colors.dart';
import '../../../widgets/info_card.dart';
import '../../../widgets/status_chip.dart';

enum _Step { done, current, later }

/// "Your claim" of U2-1, from one Q2.4 row: the status chip and the four steps
/// of the process (01-business-process.md): forms, officer check,
/// consultation, treatment.
class ClaimProgressCard extends StatelessWidget {
  const ClaimProgressCard({super.key, required this.claim});

  final Map<String, Object?> claim;

  String? _s(String key) => claim[key] as String?;

  @override
  Widget build(BuildContext context) {
    final String status = _s('claim_status') ?? '';
    final bool waiting = status == 'Awaiting verification' || status == 'Register unavailable';
    final bool rejected = status == 'Rejected' || status == 'Not covered';
    final bool closed = status == 'No treatment required';
    final String? treatment = _s('treatment_status');
    return InfoCard(
      icon: Icons.assignment,
      title: 'Your claim',
      trailing: ClaimStatusChip(status),
      children: <Widget>[
        _StepRow(_Step.done, 'Injury forms submitted', _s('submitted_time') ?? ''),
        if (waiting)
          const _StepRow(_Step.current, 'Eligibility check by the officer', 'Waiting for the officer')
        else
          _StepRow(_Step.done, rejected ? 'Checked by the officer' : 'Eligibility confirmed by the officer',
              _s('officer_checked_time') ?? ''),
        if (!rejected) ...<Widget>[
          _consultation(waiting: waiting, finished: closed || treatment != null),
          _treatment(closed: closed, treatment: treatment),
        ],
      ],
    );
  }

  /// The consultation step, from the status of the next appointment (Q2.4).
  Widget _consultation({required bool waiting, required bool finished}) {
    const String title = 'Consultation with a consultant';
    if (finished) return const _StepRow(_Step.done, title, 'Consultation finished');
    if (waiting) return const _StepRow(_Step.later, title, 'After the officer confirms your claim');
    return switch (_s('appointment_status')) {
      'Pending' => const _StepRow(_Step.current, title, 'Waiting for your confirmation'),
      'Confirmed' => _StepRow(_Step.current, title, 'Confirmed for ${_s('appointment_time')}'),
      _ => const _StepRow(_Step.current, title, 'The officer books an appointment'),
    };
  }

  /// The treatment step, from the newest Treatment row (Q2.4).
  Widget _treatment({required bool closed, required String? treatment}) {
    const String title = 'Treatment';
    if (closed) return const _StepRow(_Step.done, title, 'No treatment required');
    return switch (treatment) {
      'Pending' => const _StepRow(_Step.current, title, 'Waiting for you to accept the date'),
      'Accepted' => const _StepRow(_Step.done, title, 'Treatment date accepted'),
      'Cancelled' => const _StepRow(_Step.current, title, 'Treatment cancelled'),
      _ => const _StepRow(_Step.later, title, 'Booked after the consultation report'),
    };
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
