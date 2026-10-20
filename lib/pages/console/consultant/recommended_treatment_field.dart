import 'package:flutter/material.dart';

/// "Recommended treatment" of the Report card (Figma component
/// `Field · Recommended treatment`, C2.1, R-050). The consultant chooses
/// while editing; filing needs a choice (QC2.7).
class RecommendedTreatmentField extends StatelessWidget {
  const RecommendedTreatmentField({
    super.key,
    required this.value,
    required this.editing,
    required this.onChanged,
    this.error,
  });

  /// The choices, as ConsultationSession.recommended_treatment keeps them.
  static const List<String> choices = <String>['Physiotherapy', 'Occupational therapy', 'None'];

  final String? value;
  final bool editing;
  final ValueChanged<String?> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints box) => DropdownMenu<String>(
          key: ValueKey<String>('recommended_treatment_${editing}_$value'),
          width: box.maxWidth,
          enabled: editing,
          initialSelection: value,
          label: const Text('Recommended treatment'),
          hintText: editing ? 'Choose the treatment' : 'Choose after Amend the draft',
          helperText: 'Physiotherapy, Occupational therapy or None. Filing needs a choice.',
          errorText: error,
          onSelected: onChanged,
          dropdownMenuEntries: <DropdownMenuEntry<String>>[
            for (final String c in choices) DropdownMenuEntry<String>(value: c, label: c),
          ],
        ),
      );
}
