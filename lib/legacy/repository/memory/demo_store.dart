import '../../models/appointment.dart';
import '../../models/appointment_slot.dart';
import '../../models/claim.dart';
import '../../models/consultant.dart';
import '../../models/consultation_report.dart';
import '../../models/consultation_session.dart';
import '../../models/contact_attempt.dart';
import '../../models/insured_person.dart';
import '../../models/notice.dart';
import '../../models/staff_member.dart';
import 'seed_console.dart';
import 'seed_data.dart';
import 'seed_people.dart';

/// Holds all demo data in memory.
///
/// `CLAUDE.md` says to hardcode the data until the table schemas become
/// complete. Every in-memory repository reads and writes this one store, so
/// the screens stay in agreement with each other.
///
/// Both surfaces load the same seed. They are separate programs, so a change
/// on one does not reach the other. Section 13 of IMPLEMENTATION.md explains
/// why the seed must be rich instead.
class DemoStore {
  DemoStore({DateTime? startAt}) : now = startAt ?? SeedPeople.demoStart {
    reset(keepClock: true);
  }

  /// The time that the application believes it is.
  ///
  /// The demo moves this time forward to show a deadline that passes. A real
  /// deployment uses `systemClock` instead.
  DateTime now;

  late List<InsuredPerson> people;
  late List<StaffMember> staff;
  late List<Consultant> consultants;
  late List<AppointmentSlot> slots;
  late List<Claim> claims;
  late List<Appointment> appointments;
  late List<ConsultationSession> sessions;
  late List<ConsultationReport> reports;
  late List<ContactAttempt> attempts;
  late List<Notice> notices;

  /// The member of staff who uses the console now.
  late StaffMember currentStaff;

  int _lastClaimSequence = SeedData.lastClaimSequence;

  /// The person whose claims the patient application shows.
  InsuredPerson get person => people.first;

  /// Supplies the next claim number in the series.
  String nextClaimNumber() {
    _lastClaimSequence++;
    final String sequence = _lastClaimSequence.toString().padLeft(4, '0');
    return 'CLM-2569-$sequence';
  }

  /// Moves the demo clock forward.
  ///
  /// The demo uses this to show what happens when a confirmation window
  /// closes (UC-05, 3a, into UC-06).
  void advanceBy(Duration amount) => now = now.add(amount);

  /// Puts the store back to its first state.
  void reset({bool keepClock = false}) {
    if (!keepClock) {
      now = SeedPeople.demoStart;
    }
    people = List<InsuredPerson>.from(SeedPeople.people);
    staff = List<StaffMember>.from(SeedPeople.staff);
    consultants = List<Consultant>.from(SeedPeople.consultants);
    slots = <AppointmentSlot>[
      ...SeedPeople.slots(),
      ...SeedPeople.treatmentSlots(),
    ];
    claims = <Claim>[...SeedData.claims(), ...SeedConsole.claims()];
    appointments = <Appointment>[
      ...SeedData.appointments(),
      ...SeedConsole.appointments(),
    ];
    sessions = SeedConsole.sessions();
    reports = <ConsultationReport>[
      ...SeedData.reports(),
      ...SeedConsole.reports(),
    ];
    attempts = SeedConsole.attempts();
    notices = SeedData.notices();
    currentStaff = SeedPeople.officer;
    _lastClaimSequence = SeedData.lastClaimSequence;
  }
}
