import 'package:flutter/material.dart';

import '../../../theme/status_colors.dart';

/// U4-2 Treatment accepted (SA report figure 2-39, U4.1 step 3), from the
/// QU4.4 row after QU4.1.
Future<void> showAcceptedDialog(BuildContext context, Map<String, Object?> treatment) {
  final String type = (treatment['treatment_type']! as String).toLowerCase();
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialog) => AlertDialog(
      icon: Icon(Icons.check_circle, color: StatusColors.of(dialog).success),
      title: const Text('Treatment accepted'),
      content: Text('Your $type is booked at ${treatment['facility_name']} on ${treatment['treatment_date']}. '
          'It is now on your Schedule Page.'),
      actions: <Widget>[TextButton(onPressed: () => Navigator.of(dialog).pop(), child: const Text('OK'))],
    ),
  );
}
