import 'package:flutter/material.dart';

import '../../../l10n/tr.dart';

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
          // The language is in the key, so the field shows the label in that language.
          key: ValueKey<String>('recommended_treatment_${editing}_${value}_${Localizations.localeOf(context)}'),
          width: box.maxWidth,
          enabled: editing,
          initialSelection: value,
          label: Text(context.tr('Recommended treatment')),
          hintText: context.tr(editing ? 'Choose the treatment' : 'Choose after Amend the draft'),
          helperText: context.tr('Physiotherapy, Occupational therapy or None. Filing needs a choice.'),
          errorText: context.trMaybe(error),
          onSelected: onChanged,
          dropdownMenuEntries: <DropdownMenuEntry<String>>[
            for (final String c in choices) DropdownMenuEntry<String>(value: c, label: context.tr(c)),
          ],
        ),
      );
}
