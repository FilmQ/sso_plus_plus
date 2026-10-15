import 'package:flutter/material.dart';

/// U3-3 Confirm Appointment reminder (SA report figure 2-25, U3.1 step 5):
/// "สิ่งที่ต้องเตรียม", "บัตรประชาชนตัวจริง" and the appointment date.
Future<void> showReminderDialog(BuildContext context, String appointmentDate) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialog) {
      final ColorScheme colors = Theme.of(dialog).colorScheme;
      Widget line(IconData icon, String text) => Row(
            children: <Widget>[
              Icon(icon, color: colors.primary),
              const SizedBox(width: 12),
              Expanded(child: Text(text, style: Theme.of(dialog).textTheme.bodyLarge)),
            ],
          );
      return AlertDialog(
        icon: Icon(Icons.checklist, color: colors.primary),
        title: const Text('สิ่งที่ต้องเตรียม'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Your appointment is confirmed. Please bring:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12)),
              child: Column(spacing: 12, children: <Widget>[
                line(Icons.badge, 'บัตรประชาชนตัวจริง'),
                line(Icons.event, appointmentDate),
              ]),
            ),
          ],
        ),
        actions: <Widget>[TextButton(onPressed: () => Navigator.of(dialog).pop(), child: const Text('OK'))],
      );
    },
  );
}
