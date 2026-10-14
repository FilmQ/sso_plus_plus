import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// U1-4 National ID already registered (SA report figure 2-12).
Future<void> showAlreadyRegisteredDialog(BuildContext context, String nationalId) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialog) => AlertDialog(
      icon: Icon(Icons.person_off, color: Theme.of(dialog).colorScheme.error),
      title: const Text('National ID already registered'),
      content: Text(
        'An account with national ID $nationalId already exists, so a new one cannot be created. '
        'Sign in to follow your existing claim.',
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(dialog).pop(), child: const Text('Edit form')),
        TextButton(
          onPressed: () {
            Navigator.of(dialog).pop();
            context.go('/login');
          },
          child: const Text('Sign in'),
        ),
      ],
    ),
  );
}
