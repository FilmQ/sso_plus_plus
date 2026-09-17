/// What the appointment is for.
///
/// UC-11 says that the confirmation cycle of UC-05 also applies to a
/// treatment date. One entity with this field therefore covers both.
enum AppointmentKind {
  consultation('Consultation appointment'),
  treatment('Treatment appointment');

  const AppointmentKind(this.label);

  final String label;
}

/// The state of an appointment.
enum AppointmentStatus {
  awaitingConfirmation('Awaiting your confirmation'),
  confirmed('Confirmed'),
  anotherDateRequested('Another date requested'),
  declined('Declined'),
  expired('No reply'),
  rescheduled('Rescheduled'),
  escalated('Escalated');

  const AppointmentStatus(this.label);

  final String label;
}

/// Who entered the confirmation.
///
/// BR-13 says that a self-confirmation and an officer-recorded one must stay
/// different on the record.
enum ConfirmationChannel {
  selfService('Confirmed by you in the application'),
  telephone('Confirmed by telephone, recorded by an officer');

  const ConfirmationChannel(this.label);

  final String label;
}

/// A proposed or confirmed appointment against a claim.
class Appointment {
  const Appointment({
    required this.id,
    required this.claimNumber,
    required this.kind,
    required this.start,
    required this.end,
    required this.status,
    required this.replyBy,
    this.consultantName = '',
    this.specialty = '',
    this.facility = '',
    this.room = '',
    this.treatmentType,
    this.reportId,
    this.channel,
    this.confirmedAt,
    this.provisional = false,
    this.declineReason,
  });

  final String id;
  final String claimNumber;
  final AppointmentKind kind;
  final DateTime start;
  final DateTime end;
  final AppointmentStatus status;

  /// The end of the confirmation window (BR-14).
  final DateTime replyBy;

  final String consultantName;
  final String specialty;
  final String facility;
  final String room;

  /// The name of the treatment. It is null for a consultation.
  final String? treatmentType;

  /// The signed report that the treatment comes from (BR-31).
  /// It is null for a consultation.
  final String? reportId;

  final ConfirmationChannel? channel;
  final DateTime? confirmedAt;

  /// True while the date was set without the agreement of the patient
  /// (UC-07, BR-21).
  final bool provisional;

  final String? declineReason;

  bool get isConfirmed => status == AppointmentStatus.confirmed;

  bool get needsReply => status == AppointmentStatus.awaitingConfirmation;

  /// The title that the appointment card shows.
  String get title => treatmentType ?? kind.label;

  /// True if the confirmation window is closed at [now].
  bool hasExpiredAt(DateTime now) => now.isAfter(replyBy);

  Appointment copyWith({
    String? id,
    String? claimNumber,
    AppointmentKind? kind,
    DateTime? start,
    DateTime? end,
    AppointmentStatus? status,
    DateTime? replyBy,
    String? consultantName,
    String? specialty,
    String? facility,
    String? room,
    String? treatmentType,
    String? reportId,
    ConfirmationChannel? channel,
    DateTime? confirmedAt,
    bool? provisional,
    String? declineReason,
  }) {
    return Appointment(
      id: id ?? this.id,
      claimNumber: claimNumber ?? this.claimNumber,
      kind: kind ?? this.kind,
      start: start ?? this.start,
      end: end ?? this.end,
      status: status ?? this.status,
      replyBy: replyBy ?? this.replyBy,
      consultantName: consultantName ?? this.consultantName,
      specialty: specialty ?? this.specialty,
      facility: facility ?? this.facility,
      room: room ?? this.room,
      treatmentType: treatmentType ?? this.treatmentType,
      reportId: reportId ?? this.reportId,
      channel: channel ?? this.channel,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      provisional: provisional ?? this.provisional,
      declineReason: declineReason ?? this.declineReason,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Appointment &&
          other.id == id &&
          other.claimNumber == claimNumber &&
          other.kind == kind &&
          other.start == start &&
          other.end == end &&
          other.status == status &&
          other.replyBy == replyBy &&
          other.consultantName == consultantName &&
          other.specialty == specialty &&
          other.facility == facility &&
          other.room == room &&
          other.treatmentType == treatmentType &&
          other.reportId == reportId &&
          other.channel == channel &&
          other.confirmedAt == confirmedAt &&
          other.provisional == provisional &&
          other.declineReason == declineReason;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    id,
    claimNumber,
    kind,
    start,
    end,
    status,
    replyBy,
    consultantName,
    specialty,
    facility,
    room,
    treatmentType,
    reportId,
    channel,
    confirmedAt,
    provisional,
    declineReason,
  ]);
}
