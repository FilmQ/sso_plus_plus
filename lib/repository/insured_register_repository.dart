import '../models/insured_person.dart';

/// Reads the Section 33 register of the Social Security Office.
///
/// UC-02 queries this register. In the deck it is an external system. Here it
/// is hardcoded until the table schemas become complete.
abstract interface class InsuredRegisterRepository {
  /// One insured person, or null if the identifier is not known.
  Future<InsuredPerson?> byId(String personId);

  /// True if an active Section 33 record covers [injuryDate].
  ///
  /// BR-04 says to decide coverage on the insured state at the date of the
  /// injury, and not at the date of the submission.
  Future<bool> hasActiveSection33(String nationalId, DateTime injuryDate);
}
