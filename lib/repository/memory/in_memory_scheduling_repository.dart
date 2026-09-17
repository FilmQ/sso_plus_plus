import '../../models/appointment.dart';
import '../../models/claim.dart';
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
}
