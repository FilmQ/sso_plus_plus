import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/tr.dart';

/// U1-4 National ID already registered (SA report figure 2-12).
Future<void> showAlreadyRegisteredDialog(BuildContext context, String nationalId) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialog) => AlertDialog(
      icon: Icon(Icons.person_off, color: Theme.of(dialog).colorScheme.error),
      title: Text(dialog.tr('National ID already registered')),
      content: Text(dialog.tr(
        'An account with national ID {id} already exists, so a new one cannot be created. '
        'Sign in to follow your existing claim.',
        {'id': nationalId},
      )),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(dialog).pop(), child: Text(dialog.tr('Edit form'))),
        TextButton(
          onPressed: () {
            Navigator.of(dialog).pop();
            context.go('/login');
          },
          child: Text(dialog.tr('Sign in')),
        ),
      ],
    ),
  );
}
