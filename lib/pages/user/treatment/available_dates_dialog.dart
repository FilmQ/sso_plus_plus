import 'package:flutter/material.dart';

/// U4-3 Available dates window (SA report figure 2-42, U4.2 steps 2 and 3).
/// [loadDates] gives the dates ('yyyy-MM-dd'). Gives the chosen date for
/// "Save date", or null for "Cancel".
Future<String?> showAvailableDates(BuildContext context,
    {required String time, required Future<List<String>> Function() loadDates}) {
  return showDialog<String>(
    context: context,
    builder: (BuildContext dialog) => _AvailableDatesDialog(time: time, loadDates: loadDates),
  );
}

class _AvailableDatesDialog extends StatefulWidget {
  const _AvailableDatesDialog({required this.time, required this.loadDates});

  final String time;
  final Future<List<String>> Function() loadDates;

  @override
  State<_AvailableDatesDialog> createState() => _AvailableDatesDialogState();
}

class _AvailableDatesDialogState extends State<_AvailableDatesDialog> {
  static const List<String> _days = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const List<String> _months = <String>[
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  late final Future<List<String>> _dates = widget.loadDates();
  String? _chosen;

  /// '2026-10-26' as 'Mon 26 October 2026' (Figma U4-3).
  static String label(String iso) {
    final DateTime d = DateTime.parse(iso);
    return '${_days[d.weekday - 1]} ${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AlertDialog(
      icon: Icon(Icons.edit_calendar, color: colors.primary),
      title: const Text('Choose another date'),
      content: SizedBox(
        width: 320,
        child: FutureBuilder<List<String>>(
          future: _dates,
          builder: (BuildContext context, AsyncSnapshot<List<String>> snap) {
            final List<String>? dates = snap.data;
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: <Widget>[
                  Text('Available dates at the same facility. The time stays ${widget.time}.'),
                  const SizedBox(height: 4),
                  if (snap.hasError) const Text('The dates cannot be shown now. Try again later.'),
                  if (dates == null && !snap.hasError) const Center(child: CircularProgressIndicator()),
                  if (dates != null && dates.isEmpty) const Text('There are no free dates. Try again later.'),
                  if (dates != null && dates.isNotEmpty)
                    RadioGroup<String>(
                      groupValue: _chosen,
                      onChanged: (String? d) => setState(() => _chosen = d),
                      child: Column(spacing: 8, children: <Widget>[for (final String d in dates) _option(d, colors)]),
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
          onPressed: _chosen == null ? null : () => Navigator.of(context).pop(_chosen),
          child: const Text('Save date'),
        ),
      ],
    );
  }

  /// One date as an outlined row; the chosen row is filled (Figma U4-3).
  Widget _option(String date, ColorScheme colors) {
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
        title: Text(label(date), style: Theme.of(context).textTheme.bodyLarge),
      ),
    );
  }
}
