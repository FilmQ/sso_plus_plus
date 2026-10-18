import 'package:flutter/material.dart';

import '../verification/claim_cards.dart';

/// "Appointment to offer" (Figma O4-1, right side): the consultant, the
/// date and time, the location and the claim of the selected hour (O4 step
/// 2.2). "Add to waiting list" has no use case, so it is disabled (R-042).
class OfferPanel extends StatelessWidget {
  const OfferPanel({super.key, required this.slot, required this.claim, required this.busy, required this.onOffer});

  /// The selected QO4.2 row, or null.
  final Map<String, Object?>? slot;

  /// The selected QO4.1 row, or null.
  final Map<String, Object?>? claim;
  final bool busy;
  final VoidCallback onOffer;

  /// 'Building A, Floor 3, Room 305' as ('Building A', 'Floor 3, Room 305').
  static (String, String) splitOffice(String office) {
    final int comma = office.indexOf(', ');
    return comma < 0 ? (office, '-') : (office.substring(0, comma), office.substring(comma + 2));
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, Object?>? s = slot;
    final Map<String, Object?>? c = claim;
    final TextTheme text = Theme.of(context).textTheme;
    final Color heading = Theme.of(context).colorScheme.primary;
    Widget section(String title, List<(String, String)> rows) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: <Widget>[
            Text(title, style: text.titleSmall?.copyWith(color: heading)),
            for (final (String label, String value) in rows)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                SizedBox(width: 108, child: Text(label, style: text.bodyMedium)),
                Expanded(child: Text(value, style: text.bodyMedium)),
              ]),
          ],
        );
    final (String building, String room) = splitOffice('${s?['office_location'] ?? ''}');
    return ConsoleCard(
      title: 'Appointment to offer',
      children: <Widget>[
        if (s == null) const Text('Choose a free hour of a consultant.'),
        if (s != null) ...<Widget>[
          section('Consultant details', <(String, String)>[
            ('Name', '${s['consultant_name']}'),
            ('Office', '${s['office_location']}'),
          ]),
          const Divider(height: 1),
          section('Schedule details', <(String, String)>[
            ('Date', '${s['slot_date_text']}'),
            ('Time', '${s['slot_time_range']}'),
          ]),
          const Divider(height: 1),
          section('Location details', <(String, String)>[('Building', building), ('Floor and room', room)]),
          const Divider(height: 1),
        ],
        if (c != null)
          section('Claim', <(String, String)>[('Claim ID', '${c['claim_no']}'), ('User', '${c['user_name']}')]),
        FilledButton.icon(
          onPressed: s != null && c != null && !busy ? onOffer : null,
          icon: const Icon(Icons.send),
          label: const Text('Offer to the Consultant'),
        ),
        const OutlinedButton(onPressed: null, child: Text('Add to waiting list')),
      ],
    );
  }
}
