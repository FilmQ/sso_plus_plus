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

  /// 'yyyy-MM-dd', for the server.
  static String iso(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';
}
