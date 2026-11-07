import 'package:flutter/widgets.dart';

import '../../../l10n/tr.dart';

/// Texts of the U4 and U6 pages that the app makes from the query values.
abstract final class TreatmentText {
  /// Treatment.duration_minutes as '45 minutes'.
  static String duration(BuildContext context, Object? minutes) =>
      minutes == null ? '' : context.tr('{n} minutes', {'n': minutes});

  /// The time 'HH:MI' at the end of a treatment_date of QU4.4 or Q6.1.
  static String time(String treatmentDate) =>
      treatmentDate.length < 5 ? '' : treatmentDate.substring(treatmentDate.length - 5);

  /// The date of the U4-4 snackbar, from a QU4.5 date_label ('Tue 27 October
  /// 2026') and the time: '27 October 2026 : 10:00'.
  static String changedDate(String dateLabel, String time) =>
      '${dateLabel.substring(dateLabel.indexOf(' ') + 1)} : $time';
}
