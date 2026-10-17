import 'package:flutter/material.dart';

/// U4-3 Available dates window (SA report figure 2-42, U4.2 steps 2 and 3).
/// [loadDates] gives the QU4.5 rows (slot_date, date_label). Gives the chosen
/// row for "Save date", or null for "Cancel".
Future<Map<String, Object?>?> showAvailableDates(BuildContext context,
    {required String time, required Future<List<Map<String, Object?>>> Function() loadDates}) {
  return showDialog<Map<String, Object?>>(
    context: context,
    builder: (BuildContext dialog) => _AvailableDatesDialog(time: time, loadDates: loadDates),
  );
}

class _AvailableDatesDialog extends StatefulWidget {
  const _AvailableDatesDialog({required this.time, required this.loadDates});

  final String time;
  final Future<List<Map<String, Object?>>> Function() loadDates;

  @override
  State<_AvailableDatesDialog> createState() => _AvailableDatesDialogState();
}

class _AvailableDatesDialogState extends State<_AvailableDatesDialog> {
  late final Future<List<Map<String, Object?>>> _dates = widget.loadDates();
  String? _chosen;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AlertDialog(
      icon: Icon(Icons.edit_calendar, color: colors.primary),
      title: const Text('Choose another date'),
      content: SizedBox(
        width: 320,
        child: FutureBuilder<List<Map<String, Object?>>>(
          future: _dates,
          builder: (BuildContext context, AsyncSnapshot<List<Map<String, Object?>>> snap) {
            final List<Map<String, Object?>>? dates = snap.data;
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: <Widget>[
                  Text('Free weekdays at the same facility, up to 7 days after the booked date. '
                      'The time stays ${widget.time}.'),
                  const SizedBox(height: 4),
                  if (snap.hasError) const Text('The dates cannot be shown now. Try again later.'),
                  if (dates == null && !snap.hasError) const Center(child: CircularProgressIndicator()),
                  if (dates != null && dates.isEmpty) const Text('There are no free dates. Try again later.'),
                  if (dates != null && dates.isNotEmpty)
                    RadioGroup<String>(
                      groupValue: _chosen,
                      onChanged: (String? d) => setState(() => _chosen = d),
                      child: Column(spacing: 8, children: <Widget>[
                        for (final Map<String, Object?> d in dates) _option(d, colors),
                      ]),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: _chosen == null ? null : () => _save(context),
          child: const Text('Save date'),
        ),
      ],
    );
  }

  /// "Save date": gives the chosen QU4.5 row.
  Future<void> _save(BuildContext context) async {
    final List<Map<String, Object?>> dates = await _dates;
    if (!context.mounted) return;
    Navigator.of(context).pop(dates.firstWhere((Map<String, Object?> d) => d['slot_date'] == _chosen));
  }

  /// One date as an outlined row; the chosen row is filled (Figma U4-3).
  Widget _option(Map<String, Object?> row, ColorScheme colors) {
    final String date = row['slot_date']! as String;
    final bool chosen = date == _chosen;
    return Material(
      color: chosen ? colors.secondaryContainer : colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: chosen ? colors.primary : colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: RadioListTile<String>(
        key: ValueKey<String>('date:$date'),
        value: date,
        dense: true,
        title: Text(row['date_label']! as String, style: Theme.of(context).textTheme.bodyLarge),
      ),
    );
  }
}
