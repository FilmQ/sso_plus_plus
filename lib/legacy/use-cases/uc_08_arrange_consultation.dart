import '../models/appointment.dart';
import '../models/claim.dart';
import '../models/consultant.dart';
import '../models/consultation_session.dart';
import '../models/notice.dart';
import '../repository/consultation_repository.dart';
import '../repository/notice_repository.dart';
import '../repository/scheduling_repository.dart';
import 'clock.dart';

/// What UC-08 can answer.
sealed class ArrangeResult {
  const ArrangeResult();
}

/// The main flow: the session exists and the case file is released.
class ConsultationArranged extends ArrangeResult {
  const ConsultationArranged(this.session);

  final ConsultationSession session;
}

/// Flow 3a: a document is absent, so the file is flagged (BR-23).
class CaseFileIncomplete extends ArrangeResult {
  const CaseFileIncomplete(this.missing);

  final List<String> missing;
}

/// UC-08 · Arrange Consultation.
///
/// The officer prepares a confirmed appointment for the clinical side. The
/// consultant and the session are assigned, and the case file is released to
/// that consultant only (BR-22).
class ArrangeConsultation {
  const ArrangeConsultation({
    required this.consultation,
    required this.scheduling,
    required this.notices,
    required this.clock,
  });

  final ConsultationRepository consultation;
  final SchedulingRepository scheduling;
  final NoticeRepository notices;
  final Clock clock;

  /// Step 2 and step 3: reserve the session and release the file.
  ///
  /// Set [releaseIncompleteFile] to true to open the session with the file
  /// marked as incomplete, which BR-23 permits.
  Future<ArrangeResult> arrange({
    required Claim claim,
    required Appointment appointment,
    required String consultantId,
    SessionFormat format = SessionFormat.inPerson,
    String room = '',
    bool releaseIncompleteFile = false,
  }) async {
    final List<String> missing = claim.missingDocuments
        .map((doc) => doc.type.label)
        .toList();

    // BR-23: the file must be complete, or flagged as incomplete.
    if (missing.isNotEmpty && !releaseIncompleteFile) {
      return CaseFileIncomplete(missing);
    }

    final DateTime now = clock();

    final ConsultationSession session = await consultation.saveSession(
      ConsultationSession(
        id: 'SES-${claim.claimNumber.split('-').last}-${now.millisecond}',
        claimNumber: claim.claimNumber,
        appointmentId: appointment.id,
        consultantId: consultantId,
        status: SessionStatus.prepared,
        format: format,
        room: format == SessionFormat.tele ? 'Tele-consultation' : room,
      ),
    );

    await notices.save(
      Notice(
        id: 'NTC-${session.id}-A',
        claimNumber: claim.claimNumber,
        kind: NoticeKind.appointmentConfirmed,
        title: 'Your consultation is arranged',
        body:
            'The office prepared your consultation. The final details are in '
            'your appointment.',
        sentAt: now,
      ),
    );

    return ConsultationArranged(session);
  }

  /// The consultants who may take this case (BR-11).
  Future<List<Consultant>> consultantsFor(Claim claim) =>
      scheduling.consultants(specialty: claim.injury.category?.specialty);
}
