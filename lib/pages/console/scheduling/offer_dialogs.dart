import 'package:flutter/material.dart';

import '../../../theme/status_colors.dart';

/// O4-2 confirmation card (O4 steps 4 to 5). Gives true for "Confirm".
Future<bool?> showOfferConfirmDialog(BuildContext context,
    {required String date, required String time, required String details}) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext dialog) => AlertDialog(
      icon: Icon(Icons.help, color: Theme.of(dialog).colorScheme.primary),
      title: Text('Do you confirm to make an appointment at $date and $time'),
      content: SizedBox(width: 400, child: Text(details)),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(dialog).pop(false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.of(dialog).pop(true), child: const Text('Confirm')),
      ],
    ),
  );
}

/// O4-3 Appointment Scheduled (O4 step 6.1).
Future<void> showAppointmentScheduledDialog(BuildContext context, String text) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialog) => AlertDialog(
      icon: Icon(Icons.event_available, color: StatusColors.of(dialog).success),
      title: const Text('Appointment Scheduled'),
      content: SizedBox(width: 400, child: Text(text)),
      actions: <Widget>[FilledButton(onPressed: () => Navigator.of(dialog).pop(), child: const Text('OK'))],
    ),
  );
}
