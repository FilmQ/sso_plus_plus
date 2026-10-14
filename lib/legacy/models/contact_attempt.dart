/// How a telephone call ended.
enum AttemptOutcome {
  noAnswer('No answer'),
  answered('Answered'),
  wrongNumber('Wrong or disconnected number');

  const AttemptOutcome(this.label);

  final String label;
}

/// One telephone call to a claimant (UC-06).
///
/// BR-17 limits the number of attempts. Every attempt is logged, whether or
/// not the claimant answered.
class ContactAttempt {
  const ContactAttempt({
    required this.id,
    required this.appointmentId,
    required this.at,
    required this.outcome,
    required this.officerName,
    this.note = '',
  });

  final String id;
  final String appointmentId;
  final DateTime at;
  final AttemptOutcome outcome;

  /// The officer who made the call (BR-16).
  final String officerName;

  final String note;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactAttempt &&
          other.id == id &&
          other.appointmentId == appointmentId &&
          other.at == at &&
          other.outcome == outcome &&
          other.officerName == officerName &&
          other.note == note;

  @override
  int get hashCode =>
      Object.hash(id, appointmentId, at, outcome, officerName, note);
}
