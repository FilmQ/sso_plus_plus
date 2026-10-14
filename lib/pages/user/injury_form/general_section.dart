import 'package:flutter/material.dart';

import '../../../widgets/form_text_field.dart';
import '../../../widgets/picker_field.dart';
import '../../../widgets/section_header.dart';
import 'injury_form_data.dart';

/// U1-2 "General information": the person fields of U1 step 3.
class GeneralSection extends StatelessWidget {
  const GeneralSection({super.key, required this.data, required this.errors, required this.onChanged});

  final InjuryFormData data;
  final Map<String, String> errors;

  /// Called with the field name when the user changes a field.
  final ValueChanged<String> onChanged;

  Future<void> _pickBirthDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? d = await showDatePicker(
      context: context,
      initialDate: data.birthDate ?? DateTime(now.year - 30),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Birth date',
    );
    if (d != null) {
      data.birthDate = d;
      onChanged('date_of_birth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: <Widget>[
        const SectionHeader(title: 'General information', subtitle: 'Name must be written in Thai, as on your national ID card'),
        DropdownButtonFormField<String>(
          initialValue: data.title,
          decoration: InputDecoration(
            labelText: 'Title',
            helperText: 'Choose one of the provided titles: นาย, นาง, นางสาว',
            errorText: errors['title_name'],
          ),
          items: <DropdownMenuItem<String>>[
            for (final String t in InjuryFormData.titles) DropdownMenuItem<String>(value: t, child: Text(t)),
          ],
          onChanged: (String? v) {
            data.title = v ?? data.title;
            onChanged('title_name');
          },
        ),
        _text('first_name', 'First name', data.firstName),
        _text('last_name', 'Last name', data.lastName),
        _text('address', 'Address', data.address, maxLines: 3),
        _text('national_id', 'National ID', data.nationalId,
            helper: '13 digits, numbers only', keyboard: TextInputType.number),
        PickerField(
          key: const ValueKey<String>('date_of_birth'),
          label: 'Birth date',
          value: data.birthDate == null ? null : InjuryFormData.showDate(data.birthDate!),
          icon: Icons.calendar_today,
          error: errors['date_of_birth'],
          onTap: () => _pickBirthDate(context),
        ),
        _text('phone_no', 'Phone number', data.phone, icon: Icons.call, keyboard: TextInputType.phone),
        _GenderField(data: data, error: errors['gender'], onChanged: () => onChanged('gender')),
      ],
    );
  }

  Widget _text(String field, String label, TextEditingController c,
          {String? helper, int maxLines = 1, IconData? icon, TextInputType? keyboard}) =>
      FormTextField(
        key: ValueKey<String>(field),
        label: label,
        controller: c,
        helper: helper,
        error: errors[field],
        maxLines: maxLines,
        prefixIcon: icon,
        keyboardType: keyboard,
        onChanged: (_) => onChanged(field),
      );
}

/// Gender: Male, Female or Others (U1 step 3).
class _GenderField extends StatelessWidget {
  const _GenderField({required this.data, required this.onChanged, this.error});

  final InjuryFormData data;
  final VoidCallback onChanged;
  final String? error;

  static const List<(String, String)> _options = <(String, String)>[('M', 'Male'), ('F', 'Female'), ('O', 'Others')];

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Gender', style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
        RadioGroup<String>(
          groupValue: data.gender,
          onChanged: (String? v) {
            data.gender = v ?? data.gender;
            onChanged();
          },
          child: Wrap(
            spacing: 12,
            children: <Widget>[
              for (final (String value, String label) in _options)
                Row(mainAxisSize: MainAxisSize.min, children: <Widget>[Radio<String>(value: value), Text(label)]),
            ],
          ),
        ),
        if (error != null) Text(error!, style: text.bodySmall?.copyWith(color: colors.error)),
      ],
    );
  }
}
