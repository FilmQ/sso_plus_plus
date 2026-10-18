import 'package:flutter/material.dart';

import '../../../widgets/date_text.dart';
import '../verification/claim_cards.dart';
import 'report_card.dart';

/// "Booking Summary" (Figma O5.1-1, O5.1 step 2.2): the treatment, the date
/// and time of the chosen hour, the facility and the report, with "Book
/// treatment" and "No treatment require".
class BookingSummary extends StatelessWidget {
  const BookingSummary({
    super.key,
    required this.claim,
    required this.type,
    required this.duration,
    required this.facility,
    required this.slot,
    required this.busy,
    required this.onBook,
    required this.onNoTreatment,
  });

  final Map<String, Object?>? claim;
  final String? type;
  final int? duration;
  final String? facility;
  final Map<String, Object?>? slot;
  final bool busy;
  final VoidCallback onBook;
  final VoidCallback onNoTreatment;

  /// The start of the chosen hour (slot_at is the wall-clock time).
  static DateTime startOf(Map<String, Object?> slot) => DateTime.parse('${slot['slot_at']}'.substring(0, 19));

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Color heading = Theme.of(context).colorScheme.primary;
    final Map<String, Object?>? c = claim;
    final Map<String, Object?>? s = slot;
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
    final DateTime? start = s == null ? null : startOf(s);
    return ConsoleCard(
      title: 'Booking Summary',
      children: <Widget>[
        if (type != null || duration != null)
          section('Treatment details', <(String, String)>[
            ('Type', type ?? '-'),
            ('Duration', duration == null ? '-' : '$duration minutes'),
          ]),
        if (start != null) ...<Widget>[
          const Divider(height: 1),
          section('Schedule details', <(String, String)>[
            ('Date', DateText.fullDay(start)),
            ('Time', '${DateText.time(start)} - ${DateText.time(start.add(Duration(minutes: duration ?? 60)))}'),
          ]),
        ],
        if (facility != null) ...<Widget>[
          const Divider(height: 1),
          section('Location details', <(String, String)>[('Facility', facility!)]),
        ],
        if (c != null) ...<Widget>[
          const Divider(height: 1),
          section('Report details', <(String, String)>[
            ('Report', ReportShortcutCard.reportNo(c['report_id'])),
            ('Signed', '${c['signed_date']} - ${c['report_author']}'),
          ]),
        ],
        FilledButton.icon(
          onPressed: c != null && s != null && type != null && duration != null && !busy ? onBook : null,
          icon: const Icon(Icons.event_available),
          label: const Text('Book treatment'),
        ),
        OutlinedButton.icon(
          onPressed: c != null && !busy ? onNoTreatment : null,
          icon: const Icon(Icons.block),
          label: const Text('No treatment require'),
        ),
      ],
    );
  }
}
