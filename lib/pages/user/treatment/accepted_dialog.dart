import 'package:flutter/material.dart';

import '../../../l10n/tr.dart';
import '../../../theme/status_colors.dart';

/// U4-2 Treatment accepted (SA report figure 2-39, U4.1 step 3), from the
/// QU4.4 row after QU4.1.
Future<void> showAcceptedDialog(BuildContext context, Map<String, Object?> treatment) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialog) => AlertDialog(
      icon: Icon(Icons.check_circle, color: StatusColors.of(dialog).success),
      title: Text(dialog.tr('Treatment accepted')),
      content: Text(dialog.tr(
          'Your {type} is booked at {facility} on {date}. It is now on your Schedule Page.', {
        'type': dialog.tr(treatment['treatment_type']! as String).toLowerCase(),
        'facility': treatment['facility_name'],
        'date': treatment['treatment_date'],
      })),
      actions: <Widget>[TextButton(onPressed: () => Navigator.of(dialog).pop(), child: Text(dialog.tr('OK')))],
    ),
  );
}
