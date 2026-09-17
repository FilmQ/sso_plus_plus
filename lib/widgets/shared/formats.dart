/// Turns dates and times into the words that the design shows.
///
/// The project adds no date library. These few forms are all that the nine
/// screens need.
abstract final class Formats {
  static const List<String> _days = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _monthsLong = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static String _two(int value) => value.toString().padLeft(2, '0');

  /// `Fri 18 September 2026`
  static String longDate(DateTime date) {
    final String day = _days[date.weekday - 1];
    final String month = _monthsLong[date.month - 1];
    return '$day ${date.day} $month ${date.year}';
  }

  /// `18 Sep 2026`
  static String shortDate(DateTime date) {
    final String month = _monthsLong[date.month - 1].substring(0, 3);
    return '${date.day} $month ${date.year}';
  }

  /// `Fri 18 Sep 2026`
  static String shortDateWithDay(DateTime date) {
    final String day = _days[date.weekday - 1];
    return '$day ${shortDate(date)}';
  }

  /// `10:30`
  static String time(DateTime moment) =>
      '${_two(moment.hour)}:${_two(moment.minute)}';

  /// `10:30 – 11:00`
  static String timeRange(DateTime start, DateTime end) =>
      '${time(start)} – ${time(end)}';

  /// `11 Sep 2026 · 09:14`
  static String dateAndTime(DateTime moment) =>
      '${shortDate(moment)} · ${time(moment)}';

  /// `Fri 18 Sep 2026 · 10:30`
  static String dayDateAndTime(DateTime moment) =>
      '${shortDateWithDay(moment)} · ${time(moment)}';

  /// `18 / 08 / 2026`, the form that the injury date field shows.
  static String slashDate(DateTime date) =>
      '${_two(date.day)} / ${_two(date.month)} / ${date.year}';
}
