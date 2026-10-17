import 'package:flutter/material.dart';

import '../../../theme/status_colors.dart';
import '../../../widgets/info_card.dart';
import '../../../widgets/side_key_value.dart';
import 'treatment_text.dart';

/// The cards of U4-1 to U4-4 from the QU4.4 row: treatment and claim. The
/// facility has no address or picture in the schema (06-screens.md).
class TreatmentCards extends StatelessWidget {
  const TreatmentCards({super.key, required this.treatment});

  final Map<String, Object?> treatment;

  String _s(String key) => (treatment[key] as String?) ?? '';

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 12,
      children: <Widget>[
        InfoCard(icon: Icons.healing, title: 'Treatment', children: <Widget>[
          SideKeyValue('Date', _s('treatment_date'), strong: true),
          SideKeyValue('Type', _s('treatment_type')),
          SideKeyValue('Duration', TreatmentText.duration(treatment['duration_minutes'])),
          SideKeyValue('Facility', _s('facility_name')),
          // QU4.4 booked_by is an EvaluationOfficer name (Figma U4-1).
          SideKeyValue('Booked by', '${_s('booked_by')} (Evaluation Officer)'),
        ]),
        InfoCard(icon: Icons.assignment, title: 'Claim', children: <Widget>[
          SideKeyValue('Claim ID', _s('claim_no')),
          SideKeyValue('Injury', _s('injury')),
          SideKeyValue('Report', 'Signed ${_s('report_signed_date')} by ${_s('report_author')}'),
        ]),
      ],
    );
  }
}

/// The yellow note of U4-1: an unanswered treatment is cancelled and the
/// claim is closed (U4.3).
class AnswerBeforeNote extends StatelessWidget {
  const AnswerBeforeNote({super.key});

  @override
  Widget build(BuildContext context) {
    final StatusColors s = StatusColors.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: s.warningContainer, borderRadius: BorderRadius.circular(12)),
      child: Row(
        spacing: 12,
        children: <Widget>[
          Icon(Icons.info, color: s.warning),
          Expanded(
            child: Text(
              'Please answer before the treatment date. If you do not answer, the booking is cancelled '
              'automatically and your claim is closed.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: s.warning),
            ),
          ),
        ],
      ),
    );
  }
}
