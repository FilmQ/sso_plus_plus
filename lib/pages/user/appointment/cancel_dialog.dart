import 'package:flutter/material.dart';

/// U3-6 I cannot attend warning (SA report figure 2-34, U3.3 step 5). The claim
/// becomes Withdrawn (Q3.6) and the consultant gets a message (QN.5).
/// Gives true for "Confirm Cancel Appointment", false for "Go Back"
/// (Alternate Case 1 [Go Back]).
Future<bool> showCancelWarning(BuildContext context) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialog) {
      final ColorScheme colors = Theme.of(dialog).colorScheme;
      return AlertDialog(
        icon: Icon(Icons.warning, color: colors.error),
        title: const Text('คุณแน่ใจที่จะยกเลิกการนัดหมายหรือไม่'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: <Widget>[
            const Text('If you cancel, your claim will be withdrawn and the consultant will be informed.'),
            const SizedBox(height: 4),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: colors.error, foregroundColor: colors.onError),
              onPressed: () => Navigator.of(dialog).pop(true),
              child: const Text('Confirm Cancel Appointment'),
            ),
            OutlinedButton(onPressed: () => Navigator.of(dialog).pop(false), child: const Text('Go Back')),
          ],
        ),
      );
    },
  );
  return confirmed ?? false;
}
