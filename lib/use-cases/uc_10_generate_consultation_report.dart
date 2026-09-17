import '../models/claim_status.dart';
import '../models/consultation_report.dart';
import '../models/consultation_session.dart';
import '../models/notice.dart';
import '../repository/claim_repository.dart';
import '../repository/consultation_repository.dart';
import '../repository/notice_repository.dart';
import 'clock.dart';

/// What the signing step can answer.
sealed class SignResult {
  const SignResult();
}

/// The main flow: the version is locked and filed on the claim.
class ReportSigned extends SignResult {
  const ReportSigned(this.report);

  final ConsultationReport report;
}

/// Step 2: something mandatory is still absent.
class ReportNotReady extends SignResult {
  const ReportNotReady(this.missing);

  final List<String> missing;
}

/// UC-10 · Generate Consultation Report.
///
/// The system assembles the recorded consultation into the standard report.
/// The consultant signs it, and it is filed where the claimant and the
/// officer can read it.
///
/// BR-28 says that a signed report is immutable. A correction is a new
/// version, and the earlier version stays as superseded.
class GenerateConsultationReport {
  const GenerateConsultationReport({
    required this.consultation,
    required this.claims,
    required this.notices,
    required this.clock,
  });

  final ConsultationRepository consultation;
  final ClaimRepository claims;
  final NoticeRepository notices;
  final Clock clock;

  /// Step 1: build the draft from what the session already holds.
  ///
  /// The consultant types nothing again.
  Future<ConsultationReport> assemble({
    required ConsultationSession session,
    required String consultantName,
    required String specialty,
  }) async {
    final List<ConsultationReport> existing = await consultation.forClaim(
      session.claimNumber,
    );
    final int nextVersion = existing.isEmpty ? 1 : existing.first.version + 1;

    return consultation.save(
      ConsultationReport(
        id: 'RPT-${session.claimNumber.split('-').last}-$nextVersion',
        claimNumber: session.claimNumber,
        version: nextVersion,
        findings: session.findings,
        diagnosis: session.diagnosis,
        recommendedTreatment: session.recommendedTreatment,
        fitnessForWork: session.fitnessForWork,
        consultantName: consultantName,
        specialty: specialty,
        consultedOn: session.startedAt,
      ),
    );
  }

  /// The checks that screen D7 lists under "Before signing".
  List<String> outstandingChecks(ConsultationReport report) => <String>[
    if (report.findings.trim().isEmpty) 'Findings recorded',
    if (report.diagnosis.trim().isEmpty) 'Diagnosis recorded',
    if (report.recommendedTreatment.trim().isEmpty)
      'Recommended treatment recorded',
  ];

  /// Step 3: the consultant signs the report.
  Future<SignResult> sign(ConsultationReport report) async {
    final List<String> missing = outstandingChecks(report);
    if (missing.isNotEmpty) {
      return ReportNotReady(missing);
    }
    if (report.isSigned) {
      return ReportSigned(report);
    }

    final DateTime now = clock();

    // BR-29: the report names the consultant who signed it and when.
    final ConsultationReport signed = await consultation.save(
      report.copyWith(signedAt: now),
    );

    final claim = await claims.byNumber(signed.claimNumber);
    if (claim != null && claim.status == ClaimStatus.consultationCompleted) {
      await claims.save(claim.moveTo(ClaimStatus.reportSigned));
    }

    // Step 4: the claimant and the officer are told.
    await notices.save(
      Notice(
        id: 'NTC-${signed.id}-S',
        claimNumber: signed.claimNumber,
        kind: NoticeKind.reportAvailable,
        title: 'Your consultation report is ready',
        body:
            'The consultant signed the report of your consultation. You can '
            'read it in the application.',
        sentAt: now,
      ),
    );

    return ReportSigned(signed);
  }

  /// Flow 3a: a signed report needs a correction.
  ///
  /// The earlier version is kept and marked superseded. The new version is
  /// unsigned until the consultant signs it.
  Future<ConsultationReport> issueCorrection({
    required ConsultationReport previous,
    required String findings,
    required String diagnosis,
    required String recommendedTreatment,
    required String fitnessForWork,
  }) async {
    await consultation.save(previous.copyWith(superseded: true));

    return consultation.save(
      ConsultationReport(
        id:
            'RPT-${previous.claimNumber.split('-').last}-'
            '${previous.version + 1}',
        claimNumber: previous.claimNumber,
        version: previous.version + 1,
        findings: findings,
        diagnosis: diagnosis,
        recommendedTreatment: recommendedTreatment,
        fitnessForWork: fitnessForWork,
        consultantName: previous.consultantName,
        specialty: previous.specialty,
        consultedOn: previous.consultedOn,
      ),
    );
  }
}
