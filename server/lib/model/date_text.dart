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

  /// Reads a [dateTime] text again, for example '26 October 2026 : 10:00'.
  /// Gives null for another format.
  static DateTime? parseDateTime(String text) {
    final m = RegExp(r'^(\d{1,2}) (\w+) (\d{4}) : (\d{2}):(\d{2})$').firstMatch(text);
    final month = m == null ? -1 : _months.indexOf(m.group(2)!);
    if (m == null || month < 0) return null;
    int g(int i) => int.parse(m.group(i)!);
    return DateTime(g(3), month + 1, g(1), g(4), g(5));
  }

  /// 'yyyy-MM-dd', the date format of the SQL parameters.
  static String iso(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }
}
