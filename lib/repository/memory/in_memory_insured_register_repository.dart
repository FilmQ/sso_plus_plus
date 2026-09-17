import '../../models/insured_person.dart';
import '../insured_register_repository.dart';
import 'demo_store.dart';

/// Answers Section 33 questions from hardcoded data.
///
/// The deck calls the register an external system. The application asks it
/// through this interface, so the real service can replace this class later.
class InMemoryInsuredRegisterRepository implements InsuredRegisterRepository {
  InMemoryInsuredRegisterRepository(this._store);

  final DemoStore _store;

  /// The date on which the contributions of the seeded person started.
  static final DateTime _coverFrom = DateTime(2021, 3, 1);

  @override
  Future<InsuredPerson?> byId(String personId) async {
    return _store.person.id == personId ? _store.person : null;
  }

  @override
  Future<bool> hasActiveSection33(
    String nationalId,
    DateTime injuryDate,
  ) async {
    if (_store.person.nationalId != nationalId) {
      return false;
    }
    // BR-04: the date of the injury decides, not the date of the submission.
    return injuryDate.isAfter(_coverFrom);
  }
}
