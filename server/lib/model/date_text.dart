/// Dates in the formats of the report's SQL (TO_CHAR), for values that the
/// server formats itself.
abstract final class DateText {
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  /// 'FMDD FMMonth YYYY" : "HH24:MI', for example '14 October 2026 : 19:23'.
  /// [d] is a database value: the wall-clock time is in its fields.
  static String dateTime(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.day} ${_months[d.month - 1]} ${d.year} : ${two(d.hour)}:${two(d.minute)}';
  }
}
