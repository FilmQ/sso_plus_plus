import '../../models/appointment.dart';
import '../../models/appointment_slot.dart';
import '../../models/claim.dart';
import '../../models/consultant.dart';
import '../../models/contact_attempt.dart';
import '../scheduling_repository.dart';
import 'demo_store.dart';

/// Keeps appointments in memory for the demonstration.
class InMemorySchedulingRepository implements SchedulingRepository {
  InMemorySchedulingRepository(this._store);

  final DemoStore _store;

  @override
  Future<List<Appointment>> forClaim(String claimNumber) async {
    final List<Appointment> found = _store.appointments
        .where((Appointment a) => a.claimNumber == claimNumber)
        .toList();
    found.sort((Appointment a, Appointment b) => b.start.compareTo(a.start));
    return found;
  }

  @override
  Future<List<Appointment>> forPerson(String personId) async {
    final Set<String> numbers = _store.claims
        .where((Claim c) => c.personId == personId)
        .map((Claim c) => c.claimNumber)
        .toSet();
    final List<Appointment> found = _store.appointments
        .where((Appointment a) => numbers.contains(a.claimNumber))
        .toList();
    found.sort((Appointment a, Appointment b) => b.start.compareTo(a.start));
    return found;
  }

  @override
  Future<Appointment?> byId(String id) async {
    for (final Appointment appointment in _store.appointments) {
      if (appointment.id == id) {
        return appointment;
      }
    }
    return null;
  }

  @override
  Future<Appointment?> awaitingReply(String personId) async {
    final List<Appointment> all = await forPerson(personId);
    final List<Appointment> waiting = all
        .where((Appointment a) => a.needsReply)
        .toList();
    if (waiting.isEmpty) {
      return null;
    }
    // The nearest date needs an answer first.
    waiting.sort((Appointment a, Appointment b) => a.start.compareTo(b.start));
    return waiting.first;
  }

  @override
  Future<Appointment> save(Appointment appointment) async {
    final int index = _store.appointments.indexWhere(
      (Appointment a) => a.id == appointment.id,
    );
    if (index >= 0) {
      _store.appointments[index] = appointment;
    } else {
      _store.appointments.add(appointment);
    }
    return appointment;
  }

  // --- The console needs these ---

  @override
  Future<List<Appointment>> awaitingConfirmation() async {
    final List<Appointment> found = _store.appointments
        .where((Appointment a) => a.needsReply)
        .toList();
    found.sort(
      (Appointment a, Appointment b) => a.replyBy.compareTo(b.replyBy),
    );
    return found;
  }

  @override
  Future<List<Appointment>> pastDeadline(DateTime now) async {
    final List<Appointment> waiting = await awaitingConfirmation();
    return waiting
        .where((Appointment a) => a.hasExpiredAt(now))
        .toList(growable: false);
  }

  @override
  Future<List<Consultant>> consultants({String? specialty}) async {
    if (specialty == null) {
      return List<Consultant>.from(_store.consultants);
    }
    return _store.consultants
        .where((Consultant c) => c.specialty == specialty)
        .toList();
  }

  @override
  Future<Consultant?> consultantById(String id) async {
    for (final Consultant consultant in _store.consultants) {
      if (consultant.id == id) {
        return consultant;
      }
    }
    return null;
  }

  @override
  Future<List<AppointmentSlot>> freeSlots({
    String? specialty,
    bool treatment = false,
  }) async {
    final Set<String> matching = specialty == null
        ? _store.consultants.map((Consultant c) => c.id).toSet()
        : _store.consultants
              .where((Consultant c) => c.specialty == specialty)
              .map((Consultant c) => c.id)
              .toSet();

    final List<AppointmentSlot> found = _store.slots
        .where(
          (AppointmentSlot s) =>
              s.isFree &&
              s.isTreatment == treatment &&
              matching.contains(s.consultantId),
        )
        .toList();
    found.sort(
      (AppointmentSlot a, AppointmentSlot b) => a.start.compareTo(b.start),
    );
    return found;
  }

  @override
  Future<AppointmentSlot?> slotById(String id) async {
    for (final AppointmentSlot slot in _store.slots) {
      if (slot.id == id) {
        return slot;
      }
    }
    return null;
  }

  @override
  Future<AppointmentSlot> saveSlot(AppointmentSlot slot) async {
    final int index = _store.slots.indexWhere(
      (AppointmentSlot s) => s.id == slot.id,
    );
    if (index >= 0) {
      _store.slots[index] = slot;
    } else {
      _store.slots.add(slot);
    }
    return slot;
  }

  @override
  Future<List<ContactAttempt>> attemptsFor(String appointmentId) async {
    final List<ContactAttempt> found = _store.attempts
        .where((ContactAttempt a) => a.appointmentId == appointmentId)
        .toList();
    found.sort((ContactAttempt a, ContactAttempt b) => a.at.compareTo(b.at));
    return found;
  }

  @override
  Future<ContactAttempt> addAttempt(ContactAttempt attempt) async {
    _store.attempts.add(attempt);
    return attempt;
  }
}
