import 'package:flutter/material.dart';

import '../../../widgets/info_card.dart';

/// A label and a value side by side (U3-2 cards: "Date", "Scheduled by").
class SideKeyValue extends StatelessWidget {
  const SideKeyValue(this.label, this.value, {super.key, this.strong = false});

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 112,
          child: Text(label, style: text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(value, style: strong ? text.titleSmall : text.bodyMedium)),
      ],
    );
  }
}

/// The three cards of U3-2 from one Q3.2 row: appointment, consultant, claim.
class AppointmentCards extends StatelessWidget {
  const AppointmentCards({super.key, required this.appointment});

  final Map<String, Object?> appointment;

  String _s(String key) => (appointment[key] as String?) ?? '';

  /// U3.1 step 3: Onsite is at the rehabilitation center, in the consultant's room (R-014).
  String get _type =>
      _s('appointment_type') == 'Onsite' ? 'Onsite (at the rehabilitation center)' : _s('appointment_type');

  /// The first letter of the first name and of the last name (avatar of U3-2).
  /// Q3.2 gives the title first ("นพ. ธนา ศรีสุข"), so the last two words are used.
  String get _initials {
    final List<String> words = _s('consultant_name').split(' ').where((String w) => w.isNotEmpty).toList();
    return words.skip(words.length > 2 ? words.length - 2 : 0).map((String w) => w[0]).join();
  }

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
              CircleAvatar(
                backgroundColor: colors.primaryContainer,
                child: Text(_initials, style: text.titleSmall?.copyWith(color: colors.onPrimaryContainer)),
              ),
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
