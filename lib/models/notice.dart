/// The kind of message in the inbox of the person.
enum NoticeKind {
  claimReceived('Claim received'),
  eligibilityResult('Eligibility result'),
  rejection('Decision'),
  appointmentProposed('Appointment proposed'),
  appointmentConfirmed('Appointment confirmed'),
  reportAvailable('Consultation report'),
  treatmentBooked('Treatment booked'),
  reminder('Reminder');

  const NoticeKind(this.label);

  final String label;
}

/// One message in the inbox of the person.
///
/// The application delivers every decision here. UC-03 and UC-10 both need it.
class Notice {
  const Notice({
    required this.id,
    required this.claimNumber,
    required this.kind,
    required this.title,
    required this.body,
    required this.sentAt,
    this.readAt,
  });

  final String id;
  final String claimNumber;
  final NoticeKind kind;
  final String title;
  final String body;
  final DateTime sentAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  Notice copyWith({
    String? id,
    String? claimNumber,
    NoticeKind? kind,
    String? title,
    String? body,
    DateTime? sentAt,
    DateTime? readAt,
  }) {
    return Notice(
      id: id ?? this.id,
      claimNumber: claimNumber ?? this.claimNumber,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      body: body ?? this.body,
      sentAt: sentAt ?? this.sentAt,
      readAt: readAt ?? this.readAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Notice &&
          other.id == id &&
          other.claimNumber == claimNumber &&
          other.kind == kind &&
          other.title == title &&
          other.body == body &&
          other.sentAt == sentAt &&
          other.readAt == readAt;

  @override
  int get hashCode =>
      Object.hash(id, claimNumber, kind, title, body, sentAt, readAt);
}
