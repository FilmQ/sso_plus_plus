import 'package:flutter/material.dart';

import '../../../l10n/tr.dart';

/// O6-3 Report opened (SA report figure 2-92, O6 step 4.1): the report text
/// of QO6.2, under the consultation time and the consultant.
Future<void> showReportTextDialog(BuildContext context, Map<String, Object?> report) {
  final ColorScheme colors = Theme.of(context).colorScheme;
  final TextTheme text = Theme.of(context).textTheme;
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialog) => AlertDialog(
      icon: Icon(Icons.notes, color: colors.primary),
      title: Text(context.tr('Report text')),
      content: SizedBox(
        width: 600,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            border: Border.all(color: colors.outlineVariant),
            borderRadius: BorderRadius.circular(4),
          ),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 12, children: <Widget>[
              Text(context.tr('${report['consultation_datetime']} · ${report['consultant_name']}'), style: text.bodySmall),
              const Divider(height: 1),
              SelectableText('${report['report_content'] ?? ''}', style: text.bodyMedium),
            ]),
          ),
        ),
      ),
      actions: <Widget>[FilledButton(onPressed: () => Navigator.of(dialog).pop(), child: Text(context.tr('Close')))],
    ),
  );
}
