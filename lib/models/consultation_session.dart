/// How the consultation takes place.
///
/// UC-09 says that a tele-consultation and an in-person consultation are the
/// same use case. Only the way the session opens is different.
enum SessionFormat {
  inPerson('In person'),
  tele('Tele-consultation');

  const SessionFormat(this.label);

  final String label;
}

/// The state of a consultation session.
enum SessionStatus {
  prepared('Prepared'),
  inProgress('In progress'),
  completed('Completed'),
  notAttended('Patient did not attend');

  const SessionStatus(this.label);

  final String label;
}

/// What the consultant recorded at the session (UC-09).
///
/// BR-25 says that the attending consultant records the findings and that
/// nobody else does. The minimal guarantee says that anything recorded stays
/// as a draft, even if the session stops.
class ConsultationSession {
  const ConsultationSession({
    required this.id,
    required this.claimNumber,
    required this.appointmentId,
    required this.consultantId,
    required this.status,
    this.format = SessionFormat.inPerson,
    this.room = '',
    this.findings = '',
    this.diagnosis = '',
    this.recommendedTreatment = '',
    this.fitnessForWork = '',
    this.startedAt,
    this.completedAt,
    this.draftSavedAt,
    this.outcomeNote,
  });

  final String id;
  final String claimNumber;
  final String appointmentId;
  final String consultantId;
  final SessionStatus status;
  final SessionFormat format;
  final String room;

  final String findings;
  final String diagnosis;
  final String recommendedTreatment;

  /// What work the person may do now. Screens D6 and D7 show this field.
  /// The use-case deck does not name it, but the design demands it.
  final String fitnessForWork;

  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? draftSavedAt;

  /// The reason for a session that ended without a full record.
  final String? outcomeNote;

  /// The fields that UC-09 step 3 marks as mandatory.
  ///
  /// `Fitness for work` is not one of them. The design does not mark it with
  /// a star.
  List<String> get missingMandatoryFields => <String>[
    if (findings.trim().isEmpty) 'Findings',
    if (diagnosis.trim().isEmpty) 'Diagnosis',
    if (recommendedTreatment.trim().isEmpty) 'Recommended treatment',
  ];

  bool get isComplete => missingMandatoryFields.isEmpty;

  ConsultationSession copyWith({
    SessionStatus? status,
    SessionFormat? format,
    String? room,
    String? findings,
    String? diagnosis,
    String? recommendedTreatment,
    String? fitnessForWork,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? draftSavedAt,
    String? outcomeNote,
  }) {
    return ConsultationSession(
      id: id,
      claimNumber: claimNumber,
      appointmentId: appointmentId,
      consultantId: consultantId,
      status: status ?? this.status,
      format: format ?? this.format,
      room: room ?? this.room,
      findings: findings ?? this.findings,
      diagnosis: diagnosis ?? this.diagnosis,
      recommendedTreatment: recommendedTreatment ?? this.recommendedTreatment,
      fitnessForWork: fitnessForWork ?? this.fitnessForWork,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      draftSavedAt: draftSavedAt ?? this.draftSavedAt,
      outcomeNote: outcomeNote ?? this.outcomeNote,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConsultationSession &&
          other.id == id &&
          other.claimNumber == claimNumber &&
          other.appointmentId == appointmentId &&
          other.consultantId == consultantId &&
          other.status == status &&
          other.format == format &&
          other.room == room &&
          other.findings == findings &&
          other.diagnosis == diagnosis &&
          other.recommendedTreatment == recommendedTreatment &&
          other.fitnessForWork == fitnessForWork &&
          other.startedAt == startedAt &&
          other.completedAt == completedAt &&
          other.draftSavedAt == draftSavedAt &&
          other.outcomeNote == outcomeNote;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    id,
    claimNumber,
    appointmentId,
    consultantId,
    status,
    format,
    room,
    findings,
    diagnosis,
    recommendedTreatment,
    fitnessForWork,
    startedAt,
    completedAt,
    draftSavedAt,
    outcomeNote,
  ]);
}
