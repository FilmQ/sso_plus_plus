import '../../models/insured_person.dart';
import '../../models/register_record.dart';
import '../insured_register_repository.dart';
import 'demo_store.dart';

/// Answers Section 33 questions from hardcoded data.
///
/// The deck calls the register an external system. The application asks it
/// through this interface, so the real service can replace this class later.
class InMemoryInsuredRegisterRepository implements InsuredRegisterRepository {
  InMemoryInsuredRegisterRepository(this._store);

  final DemoStore _store;

  /// The date on which the contributions of the seeded people started.
  static final DateTime _coverFrom = DateTime(2019, 6, 1);

  /// The people whom the register cannot answer for.
  ///
  /// This makes the `Register unavailable` tile of screen D1 true.
  static const Set<String> _registerDown = <String>{'USR-005'};

  /// The people whose contributions lapsed (UC-02, flow 2b).
  static const Set<String> _lapsed = <String>{'USR-003'};

  @override
  Future<InsuredPerson?> byId(String personId) async {
    for (final InsuredPerson person in _store.people) {
      if (person.id == personId) {
        return person;
      }
    }
    return null;
  }

  @override
  Future<List<InsuredPerson>> all() async =>
      List<InsuredPerson>.from(_store.people);

  @override
  Future<bool> hasActiveSection33(
    String nationalId,
    DateTime injuryDate,
  ) async {
    final RegisterRecord record = await lookup(nationalId, injuryDate);
    return record.found;
  }

  @override
  Future<RegisterRecord> lookup(String nationalId, DateTime injuryDate) async {
    InsuredPerson? person;
    for (final InsuredPerson candidate in _store.people) {
      if (candidate.nationalId == nationalId) {
        person = candidate;
      }
    }

    if (person == null) {
      return RegisterRecord(available: true, queriedAt: _store.now);
    }

    if (_registerDown.contains(person.id)) {
      return const RegisterRecord.unavailable();
    }

    final bool unbroken = !_lapsed.contains(person.id);

    return RegisterRecord(
      available: true,
      // BR-04: the date of the injury decides, not the date of the
      // submission.
      found: unbroken && injuryDate.isAfter(_coverFrom),
      coverFrom: _coverFrom,
      employerInRegister: person.employer,
      unbroken: unbroken,
      responseTime: const Duration(milliseconds: 1200),
      queriedAt: _store.now,
    );
  }
}
