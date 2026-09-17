import '../../models/appointment.dart';
import '../../models/claim.dart';
import '../../models/claim_document.dart';
import '../../models/claim_status.dart';
import '../../models/consultation_report.dart';
import '../../models/eligibility.dart';
import '../../models/injury_details.dart';
import '../../models/insured_person.dart';
import '../../models/notice.dart';
import '../../models/rejection_notice.dart';

/// The hardcoded data of the demonstration.
///
/// The seed holds one claim at each interesting stage. A demonstration must
/// not have to build a state by many taps, because the data does not survive
/// a restart.
///
/// * `CLM-2569-0143` waits for the person to confirm an appointment.
/// * `CLM-2569-0118` was refused, so the appeal route is open.
/// * `CLM-2569-0091` has a signed report and a treatment date.
abstract final class SeedData {
  /// The moment at which the demonstration starts.
  ///
  /// A fixed time keeps the demonstration the same at every run.
  static final DateTime demoStart = DateTime(2026, 9, 14, 9, 0);

  /// The sequence number of the newest seeded claim.
  static const int lastClaimSequence = 143;

  static const String consultant = 'Dr. Anong Wattana';
  static const String specialty = 'Orthopaedics';
  static const String facility = 'Bangkok Rehabilitation Centre';
  static const String officer = 'K. Siriwan';
  static const String register = 'SSO insured register';

  static const InsuredPerson person = InsuredPerson(
    id: 'USR-001',
    fullName: 'Somchai Prasert',
    nationalId: '1100967890451',
    employer: 'Siam Logistics Co., Ltd.',
    telephone: '081-234-5678',
  );

  static List<ClaimDocument> _allAttached() => <ClaimDocument>[
    const ClaimDocument(
      type: DocumentType.medicalCertificate,
      fileName: 'cert_bangkok_hosp.pdf',
    ),
    const ClaimDocument(
      type: DocumentType.employerStatement,
      fileName: 'form_16_signed.jpg',
    ),
    const ClaimDocument(
      type: DocumentType.identification,
      fileName: 'id_card_front.jpg',
    ),
  ];

  static List<Claim> claims() => <Claim>[
    Claim(
      claimNumber: 'CLM-2569-0143',
      personId: person.id,
      status: ClaimStatus.appointmentProposed,
      createdAt: DateTime(2026, 9, 11, 8, 50),
      submittedAt: DateTime(2026, 9, 11, 9, 14),
      injury: InjuryDetails(
        date: DateTime(2026, 9, 8),
        time: '14:20',
        place: 'Warehouse B, loading bay 3',
        cause: 'Struck by a falling pallet',
        bodyPart: 'Left forearm',
        employer: person.employer,
        category: InjuryCategory.fracture,
      ),
      documents: _allAttached(),
      verification: EligibilityVerification(
        result: EligibilityResult.covered,
        decidedAt: DateTime(2026, 9, 11, 11, 2),
        officerName: officer,
        evidence: '$register · contributions from 03/2021',
      ),
    ),
    Claim(
      claimNumber: 'CLM-2569-0118',
      personId: person.id,
      status: ClaimStatus.rejected,
      createdAt: DateTime(2026, 8, 20, 9, 40),
      submittedAt: DateTime(2026, 8, 20, 10, 5),
      injury: InjuryDetails(
        date: DateTime(2026, 8, 18),
        time: '07:40',
        place: 'Depot yard, gate 2',
        cause: 'Slipped on a wet ramp',
        bodyPart: 'Right ankle',
        employer: 'Thai Freight Partners',
        category: InjuryCategory.sprain,
      ),
      documents: _allAttached(),
      verification: EligibilityVerification(
        result: EligibilityResult.notCovered,
        decidedAt: DateTime(2026, 8, 21, 9, 30),
        officerName: officer,
        evidence: register,
      ),
      rejection: RejectionNotice(
        reasonCode: 'E-33-02',
        reasonText:
            'No active Section 33 contribution covered the date of the '
            'injury. The employer on the claim is not the employer in the '
            'register.',
        decidedAt: DateTime(2026, 8, 21, 9, 30),
        checkedAgainst: register,
      ),
    ),
    Claim(
      claimNumber: 'CLM-2569-0091',
      personId: person.id,
      status: ClaimStatus.treatmentScheduled,
      createdAt: DateTime(2026, 8, 25, 8, 10),
      submittedAt: DateTime(2026, 8, 25, 8, 30),
      injury: InjuryDetails(
        date: DateTime(2026, 8, 24),
        time: '11:15',
        place: 'Assembly line 2',
        cause: 'Hand caught in a press guard',
        bodyPart: 'Right hand',
        employer: person.employer,
        category: InjuryCategory.fracture,
      ),
      documents: _allAttached(),
      verification: EligibilityVerification(
        result: EligibilityResult.covered,
        decidedAt: DateTime(2026, 8, 25, 10, 10),
        officerName: officer,
        evidence: '$register · contributions from 03/2021',
      ),
    ),
  ];

  static List<Appointment> appointments() => <Appointment>[
    Appointment(
      id: 'APT-0143-1',
      claimNumber: 'CLM-2569-0143',
      kind: AppointmentKind.consultation,
      start: DateTime(2026, 9, 18, 10, 30),
      end: DateTime(2026, 9, 18, 11, 0),
      status: AppointmentStatus.awaitingConfirmation,
      replyBy: DateTime(2026, 9, 16, 17, 0),
      consultantName: consultant,
      specialty: specialty,
      facility: facility,
      room: 'Room 4, 2nd floor',
    ),
    Appointment(
      id: 'APT-0091-1',
      claimNumber: 'CLM-2569-0091',
      kind: AppointmentKind.consultation,
      start: DateTime(2026, 9, 4, 10, 30),
      end: DateTime(2026, 9, 4, 11, 0),
      status: AppointmentStatus.confirmed,
      replyBy: DateTime(2026, 9, 2, 17, 0),
      consultantName: consultant,
      specialty: specialty,
      facility: facility,
      room: 'Room 4, 2nd floor',
      channel: ConfirmationChannel.selfService,
      confirmedAt: DateTime(2026, 9, 1, 14, 5),
    ),
    Appointment(
      id: 'APT-0091-2',
      claimNumber: 'CLM-2569-0091',
      kind: AppointmentKind.treatment,
      start: DateTime(2026, 9, 21, 9, 0),
      end: DateTime(2026, 9, 21, 10, 0),
      status: AppointmentStatus.awaitingConfirmation,
      replyBy: DateTime(2026, 9, 18, 17, 0),
      consultantName: consultant,
      specialty: specialty,
      facility: facility,
      room: 'Physiotherapy unit, 3rd floor',
      treatmentType: 'Cast immobilisation and review',
      reportId: 'RPT-0091-1',
    ),
  ];

  static List<ConsultationReport> reports() => <ConsultationReport>[
    ConsultationReport(
      id: 'RPT-0091-1',
      claimNumber: 'CLM-2569-0091',
      version: 1,
      findings:
          'Closed fracture of the third metacarpal of the right hand. No '
          'nerve damage and no open wound was found.',
      diagnosis:
          'Work-related fracture. The cause agrees with the press guard '
          'incident of 24 August 2026.',
      recommendedTreatment:
          'Cast immobilisation for six weeks. A review follows at three '
          'weeks.',
      consultantName: consultant,
      specialty: specialty,
      signedAt: DateTime(2026, 9, 4, 11, 45),
    ),
  ];

  static List<Notice> notices() => <Notice>[
    Notice(
      id: 'NTC-005',
      claimNumber: 'CLM-2569-0143',
      kind: NoticeKind.appointmentProposed,
      title: 'Confirm your appointment',
      body:
          'An officer proposed a consultation on Friday 18 September 2026 at '
          '10:30. Reply by Wednesday 16 September.',
      sentAt: DateTime(2026, 9, 11, 15, 20),
    ),
    Notice(
      id: 'NTC-004',
      claimNumber: 'CLM-2569-0143',
      kind: NoticeKind.eligibilityResult,
      title: 'Your claim is covered',
      body:
          'An officer verified your Section 33 cover for the date of the '
          'injury. The claim moves to appointment scheduling.',
      sentAt: DateTime(2026, 9, 11, 11, 2),
      readAt: DateTime(2026, 9, 11, 12, 0),
    ),
    Notice(
      id: 'NTC-003',
      claimNumber: 'CLM-2569-0091',
      kind: NoticeKind.treatmentBooked,
      title: 'Treatment booked',
      body:
          'Your consultant booked cast immobilisation for Monday 21 '
          'September 2026 at 09:00.',
      sentAt: DateTime(2026, 9, 4, 11, 50),
    ),
    Notice(
      id: 'NTC-002',
      claimNumber: 'CLM-2569-0091',
      kind: NoticeKind.reportAvailable,
      title: 'Your consultation report is ready',
      body:
          'The consultant signed the report of your consultation of 4 '
          'September 2026.',
      sentAt: DateTime(2026, 9, 4, 11, 45),
      readAt: DateTime(2026, 9, 4, 18, 30),
    ),
    Notice(
      id: 'NTC-001',
      claimNumber: 'CLM-2569-0118',
      kind: NoticeKind.rejection,
      title: 'Your claim is not covered',
      body:
          'Claim CLM-2569-0118 was refused under reason code E-33-02. You '
          'can appeal within 30 days, or resubmit with new evidence.',
      sentAt: DateTime(2026, 8, 21, 9, 30),
      readAt: DateTime(2026, 8, 21, 19, 15),
    ),
  ];
}
