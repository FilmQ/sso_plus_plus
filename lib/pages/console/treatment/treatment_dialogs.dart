import 'package:flutter/material.dart';

import '../../../theme/status_colors.dart';

/// The confirmation cards of O5.1-2 and O5.2-1. Gives true for "Confirm".
Future<bool?> showTreatmentConfirmDialog(BuildContext context, {required String title, required String text}) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext dialog) => AlertDialog(
      icon: Icon(Icons.help, color: Theme.of(dialog).colorScheme.primary),
      title: Text(title),
      content: SizedBox(width: 400, child: Text(text)),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(dialog).pop(false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.of(dialog).pop(true), child: const Text('Confirm')),
      ],
    ),
  );
}

/// The results O5.1-3 "Treatment Booked" and O5.2-2 "No Treatment Required".
Future<void> showTreatmentResultDialog(BuildContext context,
    {required IconData icon, required String title, required String text}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialog) => AlertDialog(
      icon: Icon(icon, color: StatusColors.of(dialog).success),
      title: Text(title),
      content: SizedBox(width: 400, child: Text(text)),
      actions: <Widget>[FilledButton(onPressed: () => Navigator.of(dialog).pop(), child: const Text('OK'))],
    ),
  );
}
