import '../models/appointment.dart';
import '../models/appointment_slot.dart';
import '../models/consultant.dart';
import '../models/contact_attempt.dart';

/// Reads and writes appointments, slots and consultants.
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

  // --- The console needs these ---

  /// Every appointment whose reply deadline has passed and which nobody has
  /// answered. Screen D4 works from this list (UC-06).
  Future<List<Appointment>> pastDeadline(DateTime now);

  /// Every appointment that still waits for an answer.
  Future<List<Appointment>> awaitingConfirmation();

  /// The consultants, with an optional filter on the specialty (BR-11).
  Future<List<Consultant>> consultants({String? specialty});

  /// One consultant, or null if the identifier is not known.
  Future<Consultant?> consultantById(String id);

  /// The free slots for a specialty (BR-12).
  ///
  /// Pass `treatment: true` for a treatment slot instead of a consultation
  /// slot.
  Future<List<AppointmentSlot>> freeSlots({
    String? specialty,
    bool treatment = false,
  });

  /// One slot, or null if the identifier is not known.
  Future<AppointmentSlot?> slotById(String id);

  /// Stores a slot. Use it to hold, to book and to release (BR-19).
  Future<AppointmentSlot> saveSlot(AppointmentSlot slot);

  /// The telephone calls against one appointment, with the newest last.
  Future<List<ContactAttempt>> attemptsFor(String appointmentId);

  /// Logs one telephone call, answered or not (BR-17).
  Future<ContactAttempt> addAttempt(ContactAttempt attempt);
}
