/// The result of the Section 33 check (UC-02).
enum EligibilityResult {
  covered('Covered'),
  notCovered('Not covered'),
  needsReview('Needs review');

  const EligibilityResult(this.label);

  final String label;
}

/// The stored result of the Section 33 check.
///
/// BR-05 says to store this result and to use it again for the life of the
/// claim. The application must not check Section 33 a second time.
class EligibilityVerification {
  const EligibilityVerification({
    required this.result,
    required this.decidedAt,
    this.officerName,
    this.evidence,
    this.overrideReason,
  });

  final EligibilityResult result;
  final DateTime decidedAt;

  /// The officer who confirmed the result. It is null while nobody has.
  final String? officerName;

  /// The record that the result came from (BR-07).
  final String? evidence;

  /// The written reason for an officer override (BR-06).
  final String? overrideReason;

  bool get isConfirmed => officerName != null;

  EligibilityVerification copyWith({
    EligibilityResult? result,
    DateTime? decidedAt,
    String? officerName,
    String? evidence,
    String? overrideReason,
  }) {
    return EligibilityVerification(
      result: result ?? this.result,
      decidedAt: decidedAt ?? this.decidedAt,
      officerName: officerName ?? this.officerName,
      evidence: evidence ?? this.evidence,
      overrideReason: overrideReason ?? this.overrideReason,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EligibilityVerification &&
          other.result == result &&
          other.decidedAt == decidedAt &&
          other.officerName == officerName &&
          other.evidence == evidence &&
          other.overrideReason == overrideReason;

  @override
  int get hashCode =>
      Object.hash(result, decidedAt, officerName, evidence, overrideReason);
}
