import 'package:flutter/material.dart';

import '../../../l10n/tr.dart';

/// U3-3 Confirm Appointment reminder (SA report figure 2-25, U3.1 step 5):
/// "สิ่งที่ต้องเตรียม", "บัตรประชาชนตัวจริง" (the Thai labels of the table) and the
/// appointment date.
Future<void> showReminderDialog(BuildContext context, String appointmentDate) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialog) {
      final ColorScheme colors = Theme.of(dialog).colorScheme;
      Widget line(IconData icon, String text) => Row(
            children: <Widget>[
              Icon(icon, color: colors.primary),
              const SizedBox(width: 12),
              Expanded(child: Text(dialog.tr(text), style: Theme.of(dialog).textTheme.bodyLarge)),
            ],
          );
      return AlertDialog(
        icon: Icon(Icons.checklist, color: colors.primary),
        title: Text(dialog.tr('What to bring')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(dialog.tr('Your appointment is confirmed. Please bring:')),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12)),
              child: Column(spacing: 12, children: <Widget>[
                line(Icons.badge, 'Your original national ID card'),
                line(Icons.event, appointmentDate),
              ]),
            ),
          ],
        ),
        actions: <Widget>[TextButton(onPressed: () => Navigator.of(dialog).pop(), child: Text(dialog.tr('OK')))],
      );
    },
  );
}
