/// The signed record of a consultation (UC-10).
///
/// BR-28 says that a signed report is immutable. A correction is a new
/// version, and the earlier version stays as superseded.
class ConsultationReport {
  const ConsultationReport({
    required this.id,
    required this.claimNumber,
    required this.version,
    required this.findings,
    required this.diagnosis,
    required this.recommendedTreatment,
    required this.consultantName,
    required this.specialty,
    this.fitnessForWork = '',
    this.consultedOn,
    this.signedAt,
    this.superseded = false,
    this.treatmentRequired = true,
  });

  final String id;
  final String claimNumber;

  /// The version number. The first signed report is version 1.
  final int version;

  final String findings;
  final String diagnosis;
  final String recommendedTreatment;
  final String consultantName;
  final String specialty;

  /// What work the person may do now. Screen D7 shows this part of the
  /// report. The use-case deck does not name it; the design demands it.
  final String fitnessForWork;

  /// The date of the consultation that the report describes.
  final DateTime? consultedOn;

  /// The moment the consultant signed the report (BR-29).
  /// It is null while the report is a draft.
  final DateTime? signedAt;

  final bool superseded;

  /// False if the consultant recorded "no treatment required" (UC-11, 1a).
  final bool treatmentRequired;

  bool get isSigned => signedAt != null;

  /// The words that the badge shows, for example `Signed · v1`.
  String get versionLabel =>
      isSigned ? 'Signed · v$version' : 'Draft · v$version';

  ConsultationReport copyWith({
    String? id,
    String? claimNumber,
    int? version,
    String? findings,
    String? diagnosis,
    String? recommendedTreatment,
    String? consultantName,
    String? specialty,
    String? fitnessForWork,
    DateTime? consultedOn,
    DateTime? signedAt,
    bool? superseded,
    bool? treatmentRequired,
  }) {
    return ConsultationReport(
      id: id ?? this.id,
      claimNumber: claimNumber ?? this.claimNumber,
      version: version ?? this.version,
      findings: findings ?? this.findings,
      diagnosis: diagnosis ?? this.diagnosis,
      recommendedTreatment: recommendedTreatment ?? this.recommendedTreatment,
      consultantName: consultantName ?? this.consultantName,
      specialty: specialty ?? this.specialty,
      fitnessForWork: fitnessForWork ?? this.fitnessForWork,
      consultedOn: consultedOn ?? this.consultedOn,
      signedAt: signedAt ?? this.signedAt,
      superseded: superseded ?? this.superseded,
      treatmentRequired: treatmentRequired ?? this.treatmentRequired,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConsultationReport &&
          other.id == id &&
          other.claimNumber == claimNumber &&
          other.version == version &&
          other.findings == findings &&
          other.diagnosis == diagnosis &&
          other.recommendedTreatment == recommendedTreatment &&
          other.consultantName == consultantName &&
          other.specialty == specialty &&
          other.fitnessForWork == fitnessForWork &&
          other.consultedOn == consultedOn &&
          other.signedAt == signedAt &&
          other.superseded == superseded &&
          other.treatmentRequired == treatmentRequired;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    id,
    claimNumber,
    version,
    findings,
    diagnosis,
    recommendedTreatment,
    consultantName,
    specialty,
    fitnessForWork,
    consultedOn,
    signedAt,
    superseded,
    treatmentRequired,
  ]);
}
