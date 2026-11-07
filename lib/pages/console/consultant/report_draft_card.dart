import 'package:flutter/material.dart';

import '../../../l10n/tr.dart';
import '../../../theme/status_colors.dart';
import '../verification/claim_cards.dart';
import 'recommended_treatment_field.dart';

/// "Report" of the report page (Figma C2.1-1 to C2.1-4): the saved text, the
/// attached file, or the editor after "Amend the draft" with "Attach", and
/// the "Recommended treatment" field (R-050).
class ReportDraftCard extends StatelessWidget {
  const ReportDraftCard({
    super.key,
    required this.content,
    required this.fileName,
    required this.editing,
    required this.controller,
    required this.error,
    required this.onAttach,
    required this.onRemoveFile,
    required this.onViewFile,
    required this.treatment,
    required this.onTreatmentChanged,
    required this.treatmentError,
  });

  /// The saved report text (QC2.3), or null.
  final String? content;

  /// The name of the attached file: the saved one, or the one chosen while
  /// editing. Null for a text report.
  final String? fileName;
  final bool editing;
  final TextEditingController controller;
  final String? error;
  final VoidCallback onAttach;
  final VoidCallback onRemoveFile;
  final VoidCallback? onViewFile;

  /// The recommended treatment: the saved one, or the one chosen while editing.
  final String? treatment;
  final ValueChanged<String?> onTreatmentChanged;
  final String? treatmentError;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return ConsoleCard(
      title: 'Report',
      trailing: editing
          ? OutlinedButton.icon(onPressed: onAttach, icon: const Icon(Icons.attach_file), label: Text(context.tr('Attach')))
          : null,
      children: <Widget>[
        if (fileName != null) _fileAttached(context),
        if (fileName == null && editing)
          TextField(
            key: const Key('report_text'),
            controller: controller,
            minLines: 4,
            maxLines: 10,
            autofocus: true,
            decoration: InputDecoration(
              labelText: context.tr('Report text (editing)'),
              border: const OutlineInputBorder(),
              errorText: context.trMaybe(error),
            ),
          ),
        if (fileName == null && !editing)
          InputDecorator(
            decoration: InputDecoration(
              labelText: context.tr('Report text'),
              filled: true,
              fillColor: colors.surfaceContainerLow,
              border: const OutlineInputBorder(),
              errorText: context.trMaybe(error),
            ),
            child: Text(content ??
                context.tr('No report yet. Click Amend the draft to start writing, or attach a report file.')),
          ),
        RecommendedTreatmentField(
          value: treatment,
          editing: editing,
          onChanged: onTreatmentChanged,
          error: treatmentError,
        ),
      ],
    );
  }

  /// The green "File Attached" row (Figma C2.1-4).
  Widget _fileAttached(BuildContext context) {
    final StatusColors s = StatusColors.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: s.successContainer, borderRadius: BorderRadius.circular(8)),
      child: Row(spacing: 12, children: <Widget>[
        Icon(Icons.attach_file, color: s.success),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Text(context.tr('File Attached'), style: Theme.of(context).textTheme.titleSmall?.copyWith(color: s.success)),
            Text(fileName!, style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
        if (onViewFile != null && !editing)
          TextButton.icon(onPressed: onViewFile, icon: const Icon(Icons.visibility), label: Text(context.tr('View'))),
        if (editing)
          IconButton(tooltip: context.tr('Remove the file'), onPressed: onRemoveFile, icon: const Icon(Icons.close)),
      ]),
    );
  }
}
