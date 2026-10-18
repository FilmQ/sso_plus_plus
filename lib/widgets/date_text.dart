/// Date texts in the formats of the report's SQL (TO_CHAR).
abstract final class DateText {
  static const List<String> _months = <String>[
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// 'FMDD FMMonth YYYY', for example '20 October 2026'.
  static String long(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  /// 'FMDD / FMMM / YYYY', for example '20 / 10 / 2026' (Q3.2).
  static String slashed(DateTime d) => '${d.day} / ${d.month} / ${d.year}';

  /// 'Dy FMDD FMMonth YYYY', for example 'Fri 16 October 2026' (QO4.2).
  static String withDay(DateTime d) =>
      '${const <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1]} ${long(d)}';

  /// 'FMDay FMDD FMMonth YYYY', for example 'Friday 23 October 2026' (O5.1-1).
  static String fullDay(DateTime d) => '${const <String>[
        'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
      ][d.weekday - 1]} ${long(d)}';

  /// 'HH:mm', for example '13:00'.
  static String time(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

  /// 'yyyy-MM-dd', for the server.
  static String iso(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';
}
