/// What the SSO insured register answers about one person (UC-02).
///
/// Screen D2 shows every field of this record as the evidence behind the
/// automatic result. BR-07 says that a decision must name the record it came
/// from.
class RegisterRecord {
  const RegisterRecord({
    required this.available,
    this.found = false,
    this.coverFrom,
    this.coverTo,
    this.employerInRegister = '',
    this.unbroken = true,
    this.responseTime = Duration.zero,
    this.queriedAt,
  });

  /// The register did not answer (UC-02, flow \*a).
  const RegisterRecord.unavailable()
    : available = false,
      found = false,
      coverFrom = null,
      coverTo = null,
      employerInRegister = '',
      unbroken = false,
      responseTime = Duration.zero,
      queriedAt = null;

  /// False if the register could not be reached.
  final bool available;

  /// True if an active Section 33 record covers the date of the injury.
  final bool found;

  final DateTime? coverFrom;

  /// The end of the cover. Null means that the cover continues.
  final DateTime? coverTo;

  final String employerInRegister;

  /// False if the contributions lapsed (UC-02, flow 2b).
  final bool unbroken;

  final Duration responseTime;
  final DateTime? queriedAt;

  /// `01 Jun 2019 — present · unbroken`, as screen D2 shows it.
  String get coverSummary {
    if (!available) {
      return 'The register did not answer.';
    }
    if (coverFrom == null) {
      return 'No contribution record';
    }
    final String end = coverTo == null ? 'present' : _short(coverTo!);
    final String state = unbroken ? 'unbroken' : 'lapsed';
    return '${_short(coverFrom!)} — $end · $state';
  }

  static String _short(DateTime date) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final String day = date.day.toString().padLeft(2, '0');
    return '$day ${months[date.month - 1]} ${date.year}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegisterRecord &&
          other.available == available &&
          other.found == found &&
          other.coverFrom == coverFrom &&
          other.coverTo == coverTo &&
          other.employerInRegister == employerInRegister &&
          other.unbroken == unbroken &&
          other.responseTime == responseTime &&
          other.queriedAt == queriedAt;

  @override
  int get hashCode => Object.hash(
    available,
    found,
    coverFrom,
    coverTo,
    employerInRegister,
    unbroken,
    responseTime,
    queriedAt,
  );
}
