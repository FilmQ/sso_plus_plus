import 'package:flutter/material.dart';

import '../../../theme/status_colors.dart';
import '../../../widgets/status_chip.dart';

/// The shortcut to the consultation report of the claim (Figma O5.1-1, O5.1
/// step 2), from the QO5.1 row. QO5.1 lists only filed reports, and a report
/// is filed only after it is signed (C2.3), so the chip is always "Signed".
class ReportShortcutCard extends StatelessWidget {
  const ReportShortcutCard({super.key, required this.claim, required this.onView});

  final Map<String, Object?> claim;
  final VoidCallback onView;

  /// report_id 87 as 'CR-0087' (Figma O5.1-1, O6-1).
  static String reportNo(Object? reportId) => 'CR-${'$reportId'.padLeft(4, '0')}';

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final StatusColors s = StatusColors.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(spacing: 12, children: <Widget>[
        Icon(Icons.description, color: colors.primary),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Text('Consultation report ${reportNo(claim['report_id'])}', style: text.titleSmall),
            Text('By ${claim['report_author']} · signed ${claim['signed_date']}', style: text.bodySmall),
          ]),
        ),
        StatusPill(icon: Icons.draw, label: 'Signed', background: s.successContainer, foreground: s.success),
        FilledButton.tonalIcon(
            onPressed: onView, icon: const Icon(Icons.open_in_new), label: const Text('View Consultant Report')),
      ]),
    );
  }
}
