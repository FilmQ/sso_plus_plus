import '../models/claim_status.dart';
import '../models/consultation_report.dart';
import '../models/consultation_session.dart';
import '../repository/claim_repository.dart';
import '../repository/consultation_repository.dart';
import 'clock.dart';
import 'uc_10_generate_consultation_report.dart';

/// What UC-09 can answer.
sealed class ConsultationResult {
  const ConsultationResult();
}

/// The main flow: the session closed and a report was generated (UC-10).
class ConsultationCompleted extends ConsultationResult {
  const ConsultationCompleted(this.session, this.report);

  final ConsultationSession session;
  final ConsultationReport report;
}

/// Step 3: a mandatory clinical field is empty.
class MandatoryFieldsMissing extends ConsultationResult {
  const MandatoryFieldsMissing(this.fields);

  final List<String> fields;
}

/// Flow 2a: the patient did not attend, so the claim returns to UC-04.
class PatientDidNotAttend extends ConsultationResult {
  const PatientDidNotAttend(this.session);

  final ConsultationSession session;
}

/// UC-09 · Conduct Consultation.
///
/// The consultant examines the patient and records the findings, the
/// diagnosis and the recommended treatment. BR-25 says that the attending
/// consultant records them and that nobody else does. A completed session
/// always produces a report (BR-26).
class ConductConsultation {
  const ConductConsultation({
    required this.consultation,
    required this.claims,
    required this.generateReport,
    required this.clock,
  });

  final ConsultationRepository consultation;
  final ClaimRepository claims;
  final GenerateConsultationReport generateReport;
  final Clock clock;

  /// Step 1: the consultant opens the session.
  Future<ConsultationSession> start(ConsultationSession session) {
    if (session.status != SessionStatus.prepared) {
      return Future<ConsultationSession>.value(session);
    }
    return consultation.saveSession(
      session.copyWith(status: SessionStatus.inProgress, startedAt: clock()),
    );
  }

  /// Flow \*a: keep what the consultant recorded, even if the session stops.
  Future<ConsultationSession> saveDraft({
    required ConsultationSession session,
    required String findings,
    required String diagnosis,
    required String recommendedTreatment,
    required String fitnessForWork,
  }) {
    return consultation.saveSession(
      session.copyWith(
        findings: findings,
        diagnosis: diagnosis,
        recommendedTreatment: recommendedTreatment,
        fitnessForWork: fitnessForWork,
        draftSavedAt: clock(),
      ),
    );
  }

  /// Step 4: the consultant closes the session.
  ///
  /// The session then invokes UC-10, because a completed consultation always
  /// produces a report.
  Future<ConsultationResult> complete({
    required ConsultationSession session,
    required String findings,
    required String diagnosis,
    required String recommendedTreatment,
    required String fitnessForWork,
    required String consultantName,
    required String specialty,
  }) async {
    final ConsultationSession filled = session.copyWith(
      findings: findings,
      diagnosis: diagnosis,
      recommendedTreatment: recommendedTreatment,
      fitnessForWork: fitnessForWork,
    );

    if (!filled.isComplete) {
      // Keep the entries. Only the closing step is refused.
      await consultation.saveSession(filled.copyWith(draftSavedAt: clock()));
      return MandatoryFieldsMissing(filled.missingMandatoryFields);
    }

    final DateTime now = clock();

    final ConsultationSession completed = await consultation.saveSession(
      filled.copyWith(status: SessionStatus.completed, completedAt: now),
    );

    final claim = await claims.byNumber(completed.claimNumber);
    if (claim != null && claim.status == ClaimStatus.appointmentConfirmed) {
      await claims.save(claim.moveTo(ClaimStatus.consultationCompleted));
    }

    // «include» UC-10.
    final ConsultationReport report = await generateReport.assemble(
      session: completed,
      consultantName: consultantName,
      specialty: specialty,
    );

    return ConsultationCompleted(completed, report);
  }

  /// Flow 2a: the patient did not attend.
  Future<ConsultationResult> recordNonAttendance(
    ConsultationSession session,
  ) async {
    final ConsultationSession closed = await consultation.saveSession(
      session.copyWith(
        status: SessionStatus.notAttended,
        completedAt: clock(),
        outcomeNote: 'The patient did not attend.',
      ),
    );

    // The claim returns to scheduling, and the officer is told.
    final claim = await claims.byNumber(closed.claimNumber);
    if (claim != null && claim.status == ClaimStatus.appointmentConfirmed) {
      await claims.save(claim.moveTo(ClaimStatus.appointmentProposed));
    }

    return PatientDidNotAttend(closed);
  }
}
