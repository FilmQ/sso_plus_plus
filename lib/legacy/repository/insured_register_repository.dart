import '../models/insured_person.dart';
import '../models/register_record.dart';

/// Reads the Section 33 register of the Social Security Office.
///
/// UC-02 queries this register. In the deck it is an external system. Here it
/// is hardcoded until the table schemas become complete.
abstract interface class InsuredRegisterRepository {
  /// One insured person, or null if the identifier is not known.
  Future<InsuredPerson?> byId(String personId);

  /// Every insured person that the demonstration knows.
  Future<List<InsuredPerson>> all();

  /// True if an active Section 33 record covers [injuryDate].
  ///
  /// BR-04 says to decide coverage on the insured state at the date of the
  /// injury, and not at the date of the submission.
  Future<bool> hasActiveSection33(String nationalId, DateTime injuryDate);

  /// The full record, with the evidence that screen D2 shows.
  ///
  /// The record says whether the register answered at all, so UC-02 can hold
  /// the claim and retry.
  Future<RegisterRecord> lookup(String nationalId, DateTime injuryDate);
}
