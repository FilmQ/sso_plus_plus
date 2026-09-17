import '../models/appointment.dart';

/// Reads and writes appointments.
///
/// One repository holds the consultation dates and the treatment dates,
/// because one `Appointment` entity holds both. The `kind` field separates
/// them.
abstract interface class SchedulingRepository {
  /// Every appointment against one claim, with the newest first.
  Future<List<Appointment>> forClaim(String claimNumber);

  /// Every appointment of one person across all of their claims.
  Future<List<Appointment>> forPerson(String personId);

  /// One appointment, or null if the identifier is not known.
  Future<Appointment?> byId(String id);

  /// The appointment that waits for an answer from the person.
  ///
  /// The home screen shows this one in its "next step" card. It is null when
  /// nothing waits.
  Future<Appointment?> awaitingReply(String personId);

  /// Stores a new appointment or replaces an existing one.
  Future<Appointment> save(Appointment appointment);
}
