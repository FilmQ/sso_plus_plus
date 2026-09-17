/// An insured worker who lodges a claim.
///
/// The Social Security Office holds the Section 33 registration. The
/// application copies the parts it must show to the person.
class InsuredPerson {
  const InsuredPerson({
    required this.id,
    required this.fullName,
    required this.nationalId,
    required this.employer,
    required this.telephone,
    this.section33 = true,
  });

  final String id;
  final String fullName;

  /// The 13-digit national identification number (BR-02).
  final String nationalId;

  final String employer;
  final String telephone;

  /// True if the person is insured under Section 33.
  final bool section33;

  /// Hides the middle digits of the national identification number.
  ///
  /// The design shows this masked form on the home screen.
  String get maskedNationalId {
    final String plain = nationalId.replaceAll('-', '');
    if (plain.length < 13) {
      return nationalId;
    }
    return '${plain.substring(0, 1)}-${plain.substring(1, 5)}-xxxxx-'
        '${plain.substring(10, 12)}-${plain.substring(12)}';
  }

  InsuredPerson copyWith({
    String? id,
    String? fullName,
    String? nationalId,
    String? employer,
    String? telephone,
    bool? section33,
  }) {
    return InsuredPerson(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      nationalId: nationalId ?? this.nationalId,
      employer: employer ?? this.employer,
      telephone: telephone ?? this.telephone,
      section33: section33 ?? this.section33,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InsuredPerson &&
          other.id == id &&
          other.fullName == fullName &&
          other.nationalId == nationalId &&
          other.employer == employer &&
          other.telephone == telephone &&
          other.section33 == section33;

  @override
  int get hashCode =>
      Object.hash(id, fullName, nationalId, employer, telephone, section33);
}
