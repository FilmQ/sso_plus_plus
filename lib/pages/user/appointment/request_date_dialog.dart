import 'package:flutter/material.dart';

import '../../../widgets/date_text.dart';
import '../../../widgets/picker_field.dart';

/// Loads the free hours of a date ('yyyy-MM-dd') with Q3.4.
typedef SlotLoader = Future<List<String>> Function(String date);

/// The bookable hours of Q3.4 (data dictionary, Appointment.schedule_time).
const List<String> consultationHours = <String>['09:00', '10:00', '11:00', '13:00', '14:00', '15:00'];

/// U3-4 Request Another Date pop-up (SA report figure 2-29, U3.2 steps 5 and 6).
/// Gives (date, time) for "Confirm Date", or null for "Cancel"
/// (Alternate Case 1 [Cancel]).
Future<(DateTime, String)?> showRequestDateDialog(BuildContext context,
    {required String consultantName, required SlotLoader loadSlots}) {
  return showDialog<(DateTime, String)>(
    context: context,
    builder: (BuildContext dialog) => _RequestDateDialog(consultantName: consultantName, loadSlots: loadSlots),
  );
}

class _RequestDateDialog extends StatefulWidget {
  const _RequestDateDialog({required this.consultantName, required this.loadSlots});

  final String consultantName;
  final SlotLoader loadSlots;

  @override
  State<_RequestDateDialog> createState() => _RequestDateDialogState();
}

class _RequestDateDialogState extends State<_RequestDateDialog> {
  DateTime? _date;
  List<String>? _free;
  String? _time;

  /// AppointmentPage.showDatePicker() and selectDate(slot_date): Q3.4 for the date.
  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? d = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 90)),
      helpText: 'New date',
    );
    if (d == null) return;
    setState(() {
      _date = d;
      _free = null;
      _time = null;
    });
    final List<String> free = await widget.loadSlots(DateText.iso(d));
    if (mounted && _date == d) setState(() => _free = free);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AlertDialog(
      icon: Icon(Icons.edit_calendar, color: colors.primary),
      title: const Text('Request another date'),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: <Widget>[
              Text('Choose a new date and time with ${widget.consultantName}.'),
              PickerField(
                key: const ValueKey<String>('new_date'),
                label: 'New date',
                value: _date == null ? null : DateText.slashed(_date!),
                icon: Icons.calendar_today,
                onTap: _pickDate,
              ),
              if (_date != null) ...<Widget>[
                Text('Free times on this date', style: text.titleSmall?.copyWith(color: colors.onSurfaceVariant)),
                if (_free == null)
                  const Center(child: CircularProgressIndicator())
                else if (_free!.isEmpty)
                  const Text('There are no free times on this date. Choose another date.')
                else
                  _slotGrid(),
                Text('Grey: taken     Purple: your choice', style: text.bodySmall),
              ],
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: _time == null ? null : () => Navigator.of(context).pop((_date!, _time!)),
          child: const Text('Confirm Date'),
        ),
      ],
    );
  }

  /// The six bookable hours: free hours (Q3.4) can be chosen, the others are grey.
  Widget _slotGrid() => GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.4,
        physics: const NeverScrollableScrollPhysics(),
        children: <Widget>[
          for (final String hour in consultationHours)
            if (!_free!.contains(hour))
              FilledButton.tonal(key: ValueKey<String>('slot:$hour'), onPressed: null, child: Text(hour))
            else if (hour == _time)
              FilledButton(key: ValueKey<String>('slot:$hour'), onPressed: () {}, child: Text(hour))
            else
              OutlinedButton(
                  key: ValueKey<String>('slot:$hour'), onPressed: () => setState(() => _time = hour), child: Text(hour)),
        ],
      );
}
