import 'package:flutter/material.dart';

import '../../../widgets/form_text_field.dart';
import '../../../widgets/picker_field.dart';
import '../../../widgets/section_header.dart';
import 'injury_form_data.dart';

/// "Injury details". Not on frame U1-2, but Q1.6 needs these values
/// (docs/DECISIONS.md, R-003).
class InjurySection extends StatelessWidget {
  const InjurySection({super.key, required this.data, required this.errors, required this.onChanged});

  final InjuryFormData data;
  final Map<String, String> errors;
  final ValueChanged<String> onChanged;

  Future<void> _pickDateTime(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? day = await showDatePicker(
      context: context,
      initialDate: data.injuryDateTime ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      helpText: 'Date of the injury',
    );
    if (day == null || !context.mounted) return;
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(data.injuryDateTime ?? now),
      helpText: 'Time of the injury',
    );
    if (time == null) return;
    data.injuryDateTime = DateTime(day.year, day.month, day.day, time.hour, time.minute);
    onChanged('injury_datetime');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: <Widget>[
        const SectionHeader(title: 'Injury details', subtitle: 'The accident at work, as on the injury form (Kor Thor 16)'),
        PickerField(
          key: const ValueKey<String>('injury_datetime'),
          label: 'Date and time of the injury',
          value: data.injuryDateTime == null ? null : InjuryFormData.showDateTime(data.injuryDateTime!),
          icon: Icons.event,
          error: errors['injury_datetime'],
          onTap: () => _pickDateTime(context),
        ),
        _text('injury_place', 'Place of the injury', data.injuryPlace),
        _text('injury_cause', 'Cause of the injury', data.injuryCause, maxLines: 2),
        _text('body_part', 'Injured body part', data.bodyPart),
        DropdownButtonFormField<String>(
          initialValue: data.injuryCategory,
          decoration: InputDecoration(labelText: 'Injury category', errorText: errors['injury_category']),
          items: <DropdownMenuItem<String>>[
            for (final String c in InjuryFormData.categories) DropdownMenuItem<String>(value: c, child: Text(c)),
          ],
          onChanged: (String? v) {
            data.injuryCategory = v;
            onChanged('injury_category');
          },
        ),
      ],
    );
  }

  Widget _text(String field, String label, TextEditingController c, {int maxLines = 1}) => FormTextField(
        key: ValueKey<String>(field),
        label: label,
        controller: c,
        maxLines: maxLines,
        error: errors[field],
        onChanged: (_) => onChanged(field),
      );
}
