import '../../models/appointment.dart';
import '../../models/claim.dart';
import '../../models/consultation_report.dart';
import '../../models/insured_person.dart';
import '../../models/notice.dart';
import 'seed_data.dart';

/// Holds all demo data in memory.
///
/// `CLAUDE.md` says to hardcode the data until the table schemas become
/// complete. Every in-memory repository reads and writes this one store, so
/// the screens stay in agreement with each other.
///
/// The data does not survive a restart. Section 13 of IMPLEMENTATION.md
/// explains why the seed must be rich instead.
class DemoStore {
  DemoStore({DateTime? startAt})
    : now = startAt ?? SeedData.demoStart,
      person = SeedData.person,
      claims = SeedData.claims(),
      appointments = SeedData.appointments(),
      reports = SeedData.reports(),
      notices = SeedData.notices();

  /// The time that the application believes it is.
  ///
  /// The demo moves this time forward to show a deadline that passes. A real
  /// deployment uses `systemClock` instead.
  DateTime now;

  InsuredPerson person;
  List<Claim> claims;
  List<Appointment> appointments;
  List<ConsultationReport> reports;
  List<Notice> notices;

  int _lastClaimSequence = SeedData.lastClaimSequence;

  /// Supplies the next claim number in the series.
  String nextClaimNumber() {
    _lastClaimSequence++;
    final String sequence = _lastClaimSequence.toString().padLeft(4, '0');
    return 'CLM-2569-$sequence';
  }

  /// Moves the demo clock forward.
  ///
  /// The demo uses this to show what happens when a confirmation window
  /// closes (UC-05, 3a).
  void advanceBy(Duration amount) => now = now.add(amount);

  /// Puts the store back to its first state.
  void reset() {
    now = SeedData.demoStart;
    person = SeedData.person;
    claims = SeedData.claims();
    appointments = SeedData.appointments();
    reports = SeedData.reports();
    notices = SeedData.notices();
    _lastClaimSequence = SeedData.lastClaimSequence;
  }
}
