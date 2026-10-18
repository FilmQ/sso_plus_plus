import 'package:flutter/material.dart';

import '../../../theme/status_colors.dart';
import '../verification/claim_cards.dart';

/// "Report" of the report page (Figma C2.1-1 to C2.1-4): the saved text, the
/// attached file, or the editor after "Amend the draft" with "Attach".
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

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return ConsoleCard(
      title: 'Report',
      trailing: editing
          ? OutlinedButton.icon(onPressed: onAttach, icon: const Icon(Icons.attach_file), label: const Text('Attach'))
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
              labelText: 'Report text (editing)',
              border: const OutlineInputBorder(),
              errorText: error,
            ),
          ),
        if (fileName == null && !editing)
          InputDecorator(
            decoration: InputDecoration(
              labelText: 'Report text',
              filled: true,
              fillColor: colors.surfaceContainerLow,
              border: const OutlineInputBorder(),
              errorText: error,
            ),
            child: Text(content ?? 'No report yet. Click Amend the draft to start writing, or attach a report file.'),
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
            Text('File Attached', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: s.success)),
            Text(fileName!, style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
        if (onViewFile != null && !editing)
          TextButton.icon(onPressed: onViewFile, icon: const Icon(Icons.visibility), label: const Text('View')),
        if (editing)
          IconButton(tooltip: 'Remove the file', onPressed: onRemoveFile, icon: const Icon(Icons.close)),
      ]),
    );
  }
}
