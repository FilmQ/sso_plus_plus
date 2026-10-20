import 'package:flutter/material.dart';

/// C2.1-5 "User did not attend" (C2.1 steps 10 to 11): true for "Confirm".
Future<bool> showNoShowConfirmation(BuildContext context, Map<String, Object?> page) async =>
    await showDialog<bool>(
      context: context,
      builder: (BuildContext dialog) => AlertDialog(
        icon: const Icon(Icons.person_off),
        title: Text('Do you confirm that ${page['user_name']} did not attend the consultation on '
            '${page['consultation_datetime']}'),
        content: Text('The appointment becomes No show and the claim ${page['claim_no']} goes back to the '
            'Scheduling list of the evaluation officer for a new appointment.'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(dialog).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialog).pop(true), child: const Text('Confirm')),
        ],
      ),
    ) ??
    false;

/// C2.1-6 "Marked as no show" (C2.1 step 12.1, after QC2.8).
Future<void> showMarkedAsNoShow(BuildContext context, Map<String, Object?> page) => showDialog<void>(
      context: context,
      builder: (BuildContext dialog) => AlertDialog(
        icon: const Icon(Icons.person_off),
        title: const Text('Marked as no show'),
        content: Text('${page['user_name']} (${page['claim_no']}) did not attend the consultation on '
            '${page['consultation_datetime']}. The appointment is now No show, and the claim is back on the '
            'Scheduling list of the evaluation officer for a new appointment.'),
        actions: <Widget>[FilledButton(onPressed: () => Navigator.of(dialog).pop(), child: const Text('OK'))],
      ),
    );
