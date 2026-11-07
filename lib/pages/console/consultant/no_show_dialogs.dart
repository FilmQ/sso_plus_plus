import 'package:flutter/material.dart';

import '../../../l10n/tr.dart';

/// C2.1-5 "User did not attend" (C2.1 steps 10 to 11): true for "Confirm".
Future<bool> showNoShowConfirmation(BuildContext context, Map<String, Object?> page) async =>
    await showDialog<bool>(
      context: context,
      builder: (BuildContext dialog) => AlertDialog(
        icon: const Icon(Icons.person_off),
        title: Text(context.tr('Do you confirm that {user} did not attend the consultation on {time}',
            <String, Object?>{'user': page['user_name'], 'time': page['consultation_datetime']})),
        content: Text(context.tr(
            'The appointment becomes No show and the claim {claim} goes back to the Scheduling list of the '
            'evaluation officer for a new appointment.',
            <String, Object?>{'claim': page['claim_no']})),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(dialog).pop(false), child: Text(context.tr('Cancel'))),
          FilledButton(onPressed: () => Navigator.of(dialog).pop(true), child: Text(context.tr('Confirm'))),
        ],
      ),
    ) ??
    false;

/// C2.1-6 "Marked as no show" (C2.1 step 12.1, after QC2.8).
Future<void> showMarkedAsNoShow(BuildContext context, Map<String, Object?> page) => showDialog<void>(
      context: context,
      builder: (BuildContext dialog) => AlertDialog(
        icon: const Icon(Icons.person_off),
        title: Text(context.tr('Marked as no show')),
        content: Text(context.tr(
            '{user} ({claim}) did not attend the consultation on {time}. The appointment is now No show, and the '
            'claim is back on the Scheduling list of the evaluation officer for a new appointment.',
            <String, Object?>{'user': page['user_name'], 'claim': page['claim_no'], 'time': page['consultation_datetime']})),
        actions: <Widget>[FilledButton(onPressed: () => Navigator.of(dialog).pop(), child: Text(context.tr('OK')))],
      ),
    );
