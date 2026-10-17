import 'package:flutter/material.dart';

import '../../../widgets/info_card.dart';
import '../../../widgets/person_avatar.dart';
import '../../../widgets/side_key_value.dart';

/// The three cards of U3-2 from one Q3.2 row: appointment, consultant, claim.
class AppointmentCards extends StatelessWidget {
  const AppointmentCards({super.key, required this.appointment});

  final Map<String, Object?> appointment;

  String _s(String key) => (appointment[key] as String?) ?? '';

  /// U3.1 step 3: Onsite is at the rehabilitation center, in the consultant's room (R-014).
  String get _type =>
      _s('appointment_type') == 'Onsite' ? 'Onsite (at the rehabilitation center)' : _s('appointment_type');

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      spacing: 12,
      children: <Widget>[
        InfoCard(icon: Icons.event, title: 'Consultation appointment', children: <Widget>[
          SideKeyValue('Date', _s('appointment_date'), strong: true),
          SideKeyValue('Scheduled by', '${_s('scheduled_by')} (Evaluation Officer)'),
          SideKeyValue('Type', _type),
        ]),
        InfoCard(icon: Icons.medical_services, title: 'Consultant', children: <Widget>[
          Row(
            children: <Widget>[
              PersonAvatar(_s('consultant_name')),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(_s('consultant_name'), style: text.titleSmall),
                    Text('Office: ${_s('office_location')}',
                        style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        ]),
        InfoCard(icon: Icons.assignment, title: 'Claim', children: <Widget>[
          SideKeyValue('Claim ID', _s('claim_no')),
          SideKeyValue('Injury', _s('injury')),
          SideKeyValue('Injury date', _s('injury_date')),
        ]),
      ],
    );
  }
}
