/// The notice that tells the person why the claim failed (UC-03).
///
/// BR-07 says that every rejection carries a reason code and a reference to
/// the record it was decided from. BR-09 says that the notice must state the
/// appeal route and the period allowed for it.
class RejectionNotice {
  const RejectionNotice({
    required this.reasonCode,
    required this.reasonText,
    required this.decidedAt,
    required this.checkedAgainst,
    this.appealDays = 30,
    this.readAt,
  });

  /// The standard reason code, for example `E-33-02`.
  final String reasonCode;

  final String reasonText;
  final DateTime decidedAt;

  /// The register that supplied the evidence.
  final String checkedAgainst;

  /// The number of days allowed for an appeal (BR-09).
  final int appealDays;

  /// The moment the person opened the notice. It is null while unread.
  final DateTime? readAt;

  bool get isRead => readAt != null;

  /// The last day on which an appeal is accepted.
  DateTime get appealClosesOn => decidedAt.add(Duration(days: appealDays));

  RejectionNotice copyWith({
    String? reasonCode,
    String? reasonText,
    DateTime? decidedAt,
    String? checkedAgainst,
    int? appealDays,
    DateTime? readAt,
  }) {
    return RejectionNotice(
      reasonCode: reasonCode ?? this.reasonCode,
      reasonText: reasonText ?? this.reasonText,
      decidedAt: decidedAt ?? this.decidedAt,
      checkedAgainst: checkedAgainst ?? this.checkedAgainst,
      appealDays: appealDays ?? this.appealDays,
      readAt: readAt ?? this.readAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RejectionNotice &&
          other.reasonCode == reasonCode &&
          other.reasonText == reasonText &&
          other.decidedAt == decidedAt &&
          other.checkedAgainst == checkedAgainst &&
          other.appealDays == appealDays &&
          other.readAt == readAt;

  @override
  int get hashCode => Object.hash(
    reasonCode,
    reasonText,
    decidedAt,
    checkedAgainst,
    appealDays,
    readAt,
  );
}
