/// Texts of the U4 and U6 pages that the app makes from the query values.
abstract final class TreatmentText {
  /// Treatment.duration_minutes as '45 minutes'.
  static String duration(Object? minutes) => minutes == null ? '' : '$minutes minutes';

  /// The time 'HH:MI' at the end of a treatment_date of QU4.4 or Q6.1.
  static String time(String treatmentDate) =>
      treatmentDate.length < 5 ? '' : treatmentDate.substring(treatmentDate.length - 5);

  /// The U4-4 snackbar from a QU4.5 date_label ('Tue 27 October 2026') and
  /// the time: 'Treatment date changed to 27 October 2026 : 10:00'.
  static String dateChanged(String dateLabel, String time) =>
      'Treatment date changed to ${dateLabel.substring(dateLabel.indexOf(' ') + 1)} : $time';
}
