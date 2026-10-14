import '../../models/appointment.dart';
import '../../models/claim.dart';
import '../../models/claim_document.dart';
import '../../models/claim_status.dart';
import '../../models/consultation_report.dart';
import '../../models/consultation_session.dart';
import '../../models/contact_attempt.dart';
import '../../models/eligibility.dart';
import '../../models/injury_details.dart';
import 'seed_people.dart';

/// The hardcoded data that fills the console.
///
/// Each screen of Figma page 02 needs a case at the right stage. The list
/// below says which claim answers which screen:
///
/// * D1, D2 — 0139, 0137, 0131, 0128 wait for a Section 33 decision.
/// * D3 — 0135 is covered and needs a date.
/// * D4 — 0122, 0119 and 0105 passed their reply deadline.
/// * D5 — 0126 is confirmed and needs a session.
/// * D6 — 0114 has a prepared session.
/// * D7 — 0108 has a completed session and an unsigned report.
/// * D8 — 0088 has a signed report and no treatment date.
abstract final class SeedConsole {
  static const String officer = 'P. Chaiyaporn';
  static const String consultant = 'Dr. Anong Wattana';
  static const String specialty = 'Orthopaedics';

  static List<ClaimDocument> _docs({bool complete = true}) => <ClaimDocument>[
    const ClaimDocument(
      type: DocumentType.medicalCertificate,
      fileName: 'cert_bangkok_hosp.pdf',
    ),
    const ClaimDocument(
      type: DocumentType.employerStatement,
      fileName: 'form_16_signed.jpg',
    ),
    if (complete)
      const ClaimDocument(
        type: DocumentType.identification,
        fileName: 'id_card.jpg',
      )
    else
      const ClaimDocument(type: DocumentType.identification),
  ];

  static Claim _claim({
    required String number,
    required String personId,
    required ClaimStatus status,
    required DateTime injuryOn,
    required DateTime submittedOn,
    required String place,
    required String cause,
    required String bodyPart,
    required String employer,
    InjuryCategory category = InjuryCategory.fracture,
    bool completeDocs = true,
    EligibilityVerification? verification,
  }) {
    return Claim(
      claimNumber: number,
      personId: personId,
      status: status,
      createdAt: submittedOn.subtract(const Duration(minutes: 30)),
      submittedAt: submittedOn,
      injury: InjuryDetails(
        date: injuryOn,
        time: '09:30',
        place: place,
        cause: cause,
        bodyPart: bodyPart,
        employer: employer,
        category: category,
      ),
      documents: _docs(complete: completeDocs),
      verification: verification,
    );
  }

  static EligibilityVerification _covered(DateTime at) =>
      EligibilityVerification(
        result: EligibilityResult.covered,
        decidedAt: at,
        officerName: officer,
        evidence: '${SeedPeople.register} · contributions from 06/2019',
      );

  static List<Claim> claims() => <Claim>[
    // D1 and D2 — waiting for a Section 33 decision.
    _claim(
      number: 'CLM-2569-0139',
      personId: 'USR-002',
      status: ClaimStatus.awaitingVerification,
      injuryOn: DateTime(2026, 9, 2),
      submittedOn: DateTime(2026, 9, 10, 16, 2),
      place: 'Rolling mill, bay 1',
      cause: 'Caught between steel sheets',
      bodyPart: 'Left hand',
      // The employer on the claim differs from the one in the register, so
      // UC-02 (flow 2b) gives "Needs review".
      employer: 'Thai Steel Works, Rayong branch',
    ),
    _claim(
      number: 'CLM-2569-0137',
      personId: 'USR-003',
      status: ClaimStatus.awaitingVerification,
      injuryOn: DateTime(2026, 8, 28),
      submittedOn: DateTime(2026, 9, 10, 11, 45),
      place: 'Cold store, aisle 4',
      cause: 'Fell from a ladder',
      bodyPart: 'Right ankle',
      employer: 'P.N. Foods',
      category: InjuryCategory.sprain,
      completeDocs: false,
    ),
    _claim(
      number: 'CLM-2569-0131',
      personId: 'USR-004',
      status: ClaimStatus.awaitingVerification,
      injuryOn: DateTime(2026, 8, 25),
      submittedOn: DateTime(2026, 9, 9, 8, 20),
      place: 'Depot platform 2',
      cause: 'Struck by a maintenance trolley',
      bodyPart: 'Lower back',
      employer: 'BKK Metro',
      category: InjuryCategory.sprain,
    ),
    _claim(
      number: 'CLM-2569-0128',
      personId: 'USR-005',
      status: ClaimStatus.awaitingVerification,
      injuryOn: DateTime(2026, 8, 21),
      submittedOn: DateTime(2026, 9, 8, 14, 33),
      place: 'Dye house',
      cause: 'Splashed by hot dye',
      bodyPart: 'Hand or arm, burn',
      employer: 'Nova Textile',
      category: InjuryCategory.burn,
    ),

    // D3 — covered, and it needs a date.
    _claim(
      number: 'CLM-2569-0135',
      personId: 'USR-009',
      status: ClaimStatus.verifiedCovered,
      injuryOn: DateTime(2026, 9, 1),
      submittedOn: DateTime(2026, 9, 9, 10, 15),
      place: 'Furnace floor',
      cause: 'Dropped a steel billet on the foot',
      bodyPart: 'Left foot',
      employer: 'Thai Steel Works',
      verification: _covered(DateTime(2026, 9, 10, 9, 5)),
    ),

    // D4 — past the reply deadline.
    _claim(
      number: 'CLM-2569-0122',
      personId: 'USR-006',
      status: ClaimStatus.appointmentProposed,
      injuryOn: DateTime(2026, 8, 27),
      submittedOn: DateTime(2026, 9, 2, 9, 5),
      place: 'Warehouse A',
      cause: 'Trapped a finger in a roller door',
      bodyPart: 'Right hand',
      employer: 'Siam Logistics Co., Ltd.',
      verification: _covered(DateTime(2026, 9, 3, 10, 0)),
    ),
    _claim(
      number: 'CLM-2569-0119',
      personId: 'USR-007',
      status: ClaimStatus.appointmentProposed,
      injuryOn: DateTime(2026, 8, 26),
      submittedOn: DateTime(2026, 9, 1, 15, 40),
      place: 'Signal box 7',
      cause: 'Slipped on an oily step',
      bodyPart: 'Lower back',
      employer: 'BKK Metro',
      category: InjuryCategory.sprain,
      verification: _covered(DateTime(2026, 9, 2, 11, 20)),
    ),
    _claim(
      number: 'CLM-2569-0105',
      personId: 'USR-008',
      status: ClaimStatus.appointmentProposed,
      injuryOn: DateTime(2026, 8, 19),
      submittedOn: DateTime(2026, 8, 28, 13, 10),
      place: 'Cutting room',
      cause: 'Cut by a fabric blade',
      bodyPart: 'Left hand',
      employer: 'Nova Textile',
      category: InjuryCategory.laceration,
      verification: _covered(DateTime(2026, 8, 29, 9, 0)),
    ),

    // D5 — confirmed, and it needs a session.
    _claim(
      number: 'CLM-2569-0126',
      personId: 'USR-010',
      status: ClaimStatus.appointmentConfirmed,
      injuryOn: DateTime(2026, 8, 29),
      submittedOn: DateTime(2026, 9, 3, 8, 45),
      place: 'Packing line 3',
      cause: 'Hand caught in a sealing machine',
      bodyPart: 'Right hand',
      employer: 'P.N. Foods',
      verification: _covered(DateTime(2026, 9, 4, 9, 30)),
    ),

    // D6 — a prepared session.
    _claim(
      number: 'CLM-2569-0114',
      personId: 'USR-011',
      status: ClaimStatus.appointmentConfirmed,
      injuryOn: DateTime(2026, 8, 22),
      submittedOn: DateTime(2026, 8, 30, 10, 5),
      place: 'Loading bay 1',
      cause: 'Struck by a falling crate',
      bodyPart: 'Left forearm',
      employer: 'Siam Logistics Co., Ltd.',
      verification: _covered(DateTime(2026, 8, 31, 14, 10)),
    ),

    // D7 — a completed session and an unsigned report.
    _claim(
      number: 'CLM-2569-0108',
      personId: 'USR-012',
      status: ClaimStatus.consultationCompleted,
      injuryOn: DateTime(2026, 8, 15),
      submittedOn: DateTime(2026, 8, 24, 9, 25),
      place: 'Track section 12',
      cause: 'Twisted the knee on ballast',
      bodyPart: 'Right ankle',
      employer: 'BKK Metro',
      category: InjuryCategory.sprain,
      verification: _covered(DateTime(2026, 8, 25, 11, 0)),
    ),

    // D8 — a signed report and no treatment date.
    _claim(
      number: 'CLM-2569-0088',
      personId: 'USR-006',
      status: ClaimStatus.reportSigned,
      injuryOn: DateTime(2026, 8, 10),
      submittedOn: DateTime(2026, 8, 18, 11, 30),
      place: 'Warehouse A, rack 6',
      cause: 'Fell from a step ladder',
      bodyPart: 'Right forearm',
      employer: 'Siam Logistics Co., Ltd.',
      verification: _covered(DateTime(2026, 8, 19, 9, 45)),
    ),
  ];

  static List<Appointment> appointments() => <Appointment>[
    // D4 — these three passed their reply deadline before the demo starts.
    _waiting(
      'APT-0122-1',
      'CLM-2569-0122',
      DateTime(2026, 9, 15, 9, 0),
      DateTime(2026, 9, 12, 17, 0),
    ),
    _waiting(
      'APT-0119-1',
      'CLM-2569-0119',
      DateTime(2026, 9, 16, 13, 30),
      DateTime(2026, 9, 12, 17, 0),
    ),
    _waiting(
      'APT-0105-1',
      'CLM-2569-0105',
      DateTime(2026, 9, 17, 15, 0),
      DateTime(2026, 9, 13, 17, 0),
    ),

    // D5, D6 and D7 — confirmed dates.
    _confirmed('APT-0126-1', 'CLM-2569-0126', DateTime(2026, 9, 16, 9, 0)),
    _confirmed('APT-0114-1', 'CLM-2569-0114', DateTime(2026, 9, 14, 11, 0)),
    _confirmed('APT-0108-1', 'CLM-2569-0108', DateTime(2026, 9, 8, 10, 0)),
    _confirmed('APT-0088-1', 'CLM-2569-0088', DateTime(2026, 9, 1, 9, 30)),
  ];

  static Appointment _waiting(
    String id,
    String claim,
    DateTime start,
    DateTime replyBy,
  ) => Appointment(
    id: id,
    claimNumber: claim,
    kind: AppointmentKind.consultation,
    start: start,
    end: start.add(const Duration(minutes: 30)),
    status: AppointmentStatus.awaitingConfirmation,
    replyBy: replyBy,
    consultantName: consultant,
    specialty: specialty,
    facility: SeedPeople.facility,
    room: 'Room 4, 2nd floor',
  );

  static Appointment _confirmed(String id, String claim, DateTime start) =>
      Appointment(
        id: id,
        claimNumber: claim,
        kind: AppointmentKind.consultation,
        start: start,
        end: start.add(const Duration(minutes: 30)),
        status: AppointmentStatus.confirmed,
        replyBy: start.subtract(const Duration(days: 2)),
        consultantName: consultant,
        specialty: specialty,
        facility: SeedPeople.facility,
        room: 'Room 4, 2nd floor',
        channel: ConfirmationChannel.selfService,
        confirmedAt: start.subtract(const Duration(days: 3)),
      );

  /// The calls that an officer already made (UC-06).
  static List<ContactAttempt> attempts() => <ContactAttempt>[
    ContactAttempt(
      id: 'ATT-0119-1',
      appointmentId: 'APT-0119-1',
      at: DateTime(2026, 9, 13, 10, 15),
      outcome: AttemptOutcome.noAnswer,
      officerName: officer,
      note: 'No answer · logged and queued for a second call',
    ),
    ContactAttempt(
      id: 'ATT-0105-1',
      appointmentId: 'APT-0105-1',
      at: DateTime(2026, 9, 11, 9, 30),
      outcome: AttemptOutcome.noAnswer,
      officerName: officer,
      note: 'No answer',
    ),
    ContactAttempt(
      id: 'ATT-0105-2',
      appointmentId: 'APT-0105-1',
      at: DateTime(2026, 9, 12, 14, 40),
      outcome: AttemptOutcome.noAnswer,
      officerName: officer,
      note: 'No answer · called at a different time of day',
    ),
    ContactAttempt(
      id: 'ATT-0105-3',
      appointmentId: 'APT-0105-1',
      at: DateTime(2026, 9, 13, 16, 5),
      outcome: AttemptOutcome.noAnswer,
      officerName: officer,
      note: 'No answer · the permitted attempts are now used',
    ),
  ];

  static List<ConsultationSession> sessions() => <ConsultationSession>[
    // D6 — prepared, and it waits for the consultant.
    const ConsultationSession(
      id: 'SES-0114-1',
      claimNumber: 'CLM-2569-0114',
      appointmentId: 'APT-0114-1',
      consultantId: 'CON-001',
      status: SessionStatus.prepared,
      room: 'Room 4, 2nd floor',
    ),
    // D7 — completed, and its report waits for a signature.
    ConsultationSession(
      id: 'SES-0108-1',
      claimNumber: 'CLM-2569-0108',
      appointmentId: 'APT-0108-1',
      consultantId: 'CON-001',
      status: SessionStatus.completed,
      room: 'Room 4, 2nd floor',
      findings:
          'Swelling of the right ankle with a limited range of movement. No '
          'fracture is seen on the radiograph.',
      diagnosis:
          'Work-related ligament sprain, grade 2. The cause agrees with the '
          'ballast incident of 15 August 2026.',
      recommendedTreatment:
          'Physiotherapy twice each week for four weeks, with a support '
          'bandage.',
      fitnessForWork:
          'Unfit for track duty for four weeks. Seated duty is permitted.',
      startedAt: DateTime(2026, 9, 8, 10, 0),
      completedAt: DateTime(2026, 9, 8, 10, 35),
      draftSavedAt: DateTime(2026, 9, 8, 10, 41),
    ),
    // D8 — completed, signed, and it waits for a treatment date.
    ConsultationSession(
      id: 'SES-0088-1',
      claimNumber: 'CLM-2569-0088',
      appointmentId: 'APT-0088-1',
      consultantId: 'CON-001',
      status: SessionStatus.completed,
      room: 'Room 4, 2nd floor',
      findings: 'Closed fracture of the right radius, without displacement.',
      diagnosis: 'Work-related fracture from a fall of about two metres.',
      recommendedTreatment: 'Cast immobilisation for five weeks.',
      fitnessForWork: 'Unfit for lifting for five weeks.',
      startedAt: DateTime(2026, 9, 1, 9, 30),
      completedAt: DateTime(2026, 9, 1, 10, 5),
    ),
  ];

  static List<ConsultationReport> reports() => <ConsultationReport>[
    // D7 — a draft that waits for the signature of the consultant.
    ConsultationReport(
      id: 'RPT-0108-1',
      claimNumber: 'CLM-2569-0108',
      version: 1,
      findings:
          'Swelling of the right ankle with a limited range of movement. No '
          'fracture is seen on the radiograph.',
      diagnosis:
          'Work-related ligament sprain, grade 2. The cause agrees with the '
          'ballast incident of 15 August 2026.',
      recommendedTreatment:
          'Physiotherapy twice each week for four weeks, with a support '
          'bandage.',
      fitnessForWork:
          'Unfit for track duty for four weeks. Seated duty is permitted.',
      consultantName: consultant,
      specialty: specialty,
      consultedOn: DateTime(2026, 9, 8, 10, 0),
    ),
    // D8 — signed, so a treatment date may be booked from it (BR-31).
    ConsultationReport(
      id: 'RPT-0088-1',
      claimNumber: 'CLM-2569-0088',
      version: 1,
      findings: 'Closed fracture of the right radius, without displacement.',
      diagnosis: 'Work-related fracture from a fall of about two metres.',
      recommendedTreatment: 'Cast immobilisation for five weeks.',
      fitnessForWork: 'Unfit for lifting for five weeks.',
      consultantName: consultant,
      specialty: specialty,
      consultedOn: DateTime(2026, 9, 1, 9, 30),
      signedAt: DateTime(2026, 9, 1, 10, 20),
    ),
  ];
}
