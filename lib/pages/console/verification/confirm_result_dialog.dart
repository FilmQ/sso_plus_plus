import 'package:flutter/material.dart';

/// The confirmation card of O2-2 and O3-2 (O2 and O3 steps 4 to 5). Gives
/// true for "Confirm", false or null for "Cancel".
Future<bool?> showConfirmResultDialog(BuildContext context,
    {required String claim, required bool covered, String? reason}) {
  final TextTheme text = Theme.of(context).textTheme;
  Widget row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          SizedBox(width: 92, child: Text(label, style: text.bodyMedium)),
          Expanded(child: Text(value, style: text.titleSmall)),
        ]),
      );
  return showDialog<bool>(
    context: context,
    builder: (BuildContext dialog) => AlertDialog(
      icon: Icon(Icons.help, color: Theme.of(dialog).colorScheme.primary),
      title: const Text('Do you confirm the result'),
      content: SizedBox(
        width: 400,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 16,
            children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(dialog).colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: <Widget>[
              row('Claim', claim),
              row('Result', covered ? 'Confirm: covered under Section 33' : 'Not Covered'),
              if (reason != null) row('Reason', reason),
            ]),
          ),
          Text(covered
              ? 'The user will be notified and the claim moves to scheduling.'
              : 'The claim will be rejected and the user receives the reason and your message.'),
        ]),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(dialog).pop(false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.of(dialog).pop(true), child: const Text('Confirm')),
      ],
    ),
  );
}
