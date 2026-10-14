import 'package:flutter_test/flutter_test.dart';
import 'package:sso_plus_plus/legacy/models/claim_status.dart';
import 'package:sso_plus_plus/legacy/models/consultation_report.dart';
import 'package:sso_plus_plus/legacy/models/consultation_session.dart';
import 'package:sso_plus_plus/legacy/use-cases/uc_09_conduct_consultation.dart';
import 'package:sso_plus_plus/legacy/use-cases/uc_10_generate_consultation_report.dart';

import '../support/test_context.dart';

void main() {
  late TestContext context;
  late GenerateConsultationReport reports;
  late ConductConsultation session;

  setUp(() {
    context = TestContext();
    reports = GenerateConsultationReport(
      consultation: context.consultation,
      claims: context.claims,
      notices: context.notices,
      clock: context.clock,
    );
    session = ConductConsultation(
      consultation: context.consultation,
      claims: context.claims,
      generateReport: reports,
      clock: context.clock,
    );
  });

  /// The seeded session that waits for the consultant.
  Future<ConsultationSession> prepared() async =>
      (await context.consultation.sessionById('SES-0114-1'))!;

  Future<ConsultationResult> completeWith({
    String findings = 'Closed fracture of the left forearm.',
    String diagnosis = 'Work-related fracture.',
    String treatment = 'Cast for five weeks.',
    String fitness = 'Unfit for lifting.',
  }) async {
    return session.complete(
      session: await prepared(),
      findings: findings,
      diagnosis: diagnosis,
      recommendedTreatment: treatment,
      fitnessForWork: fitness,
      consultantName: 'Dr. Anong Wattana',
      specialty: 'Orthopaedics',
    );
  }

  test('BR-22: a consultant sees only their own sessions', () async {
    final mine = await context.consultation.sessionsForConsultant('CON-001');
    expect(mine, isNotEmpty);

    final other = await context.consultation.sessionsForConsultant('CON-002');
    expect(other, isEmpty);
  });

  test('opening the session marks it in progress', () async {
    final ConsultationSession started = await session.start(await prepared());

    expect(started.status, SessionStatus.inProgress);
    expect(started.startedAt, isNotNull);
  });

  test('flow *a: a draft is kept even if the session stops', () async {
    await session.saveDraft(
      session: await prepared(),
      findings: 'Swelling only so far.',
      diagnosis: '',
      recommendedTreatment: '',
      fitnessForWork: '',
    );

    final ConsultationSession after = await prepared();
    expect(after.findings, 'Swelling only so far.');
    expect(after.status, SessionStatus.prepared);
  });

  test('step 3: a mandatory clinical field stops the close', () async {
    final ConsultationResult result = await completeWith(diagnosis: '');

    expect(result, isA<MandatoryFieldsMissing>());
    expect((result as MandatoryFieldsMissing).fields, contains('Diagnosis'));
    // What the consultant typed is still kept.
    expect((await prepared()).findings, isNotEmpty);
  });

  test('BR-26: a completed session always produces a report', () async {
    final ConsultationResult result = await completeWith();

    expect(result, isA<ConsultationCompleted>());
    final ConsultationCompleted done = result as ConsultationCompleted;

    expect(done.session.status, SessionStatus.completed);
    expect(done.report.version, 1);
    expect(done.report.isSigned, isFalse);
    // The report is assembled from the session, not typed again.
    expect(done.report.findings, done.session.findings);
    expect(done.report.fitnessForWork, 'Unfit for lifting.');

    expect(
      (await context.claims.byNumber('CLM-2569-0114'))?.status,
      ClaimStatus.consultationCompleted,
    );
  });

  test('flow 2a: a non-attendance returns the claim to scheduling', () async {
    final ConsultationResult result = await session.recordNonAttendance(
      await prepared(),
    );

    expect(result, isA<PatientDidNotAttend>());
    expect(
      (await context.claims.byNumber('CLM-2569-0114'))?.status,
      ClaimStatus.appointmentProposed,
    );
  });

  test('UC-10: signing locks the version and moves the claim', () async {
    final ConsultationReport draft = (await context.consultation.byId(
      'RPT-0108-1',
    ))!;
    expect(draft.isSigned, isFalse);

    final SignResult result = await reports.sign(draft);

    expect(result, isA<ReportSigned>());
    // BR-29: the report names who signed it and when.
    final ConsultationReport signed = (result as ReportSigned).report;
    expect(signed.signedAt, isNotNull);

    expect(
      (await context.claims.byNumber('CLM-2569-0108'))?.status,
      ClaimStatus.reportSigned,
    );
  });

  test('UC-10 step 2: an incomplete report cannot be signed', () async {
    final ConsultationReport draft = (await context.consultation.byId(
      'RPT-0108-1',
    ))!;
    final ConsultationReport empty = await context.consultation.save(
      draft.copyWith(diagnosis: ''),
    );

    final SignResult result = await reports.sign(empty);
    expect(result, isA<ReportNotReady>());
  });

  test('BR-28: a correction is a new version, and the old one stays', () async {
    final ConsultationReport signed = (await context.consultation.byId(
      'RPT-0088-1',
    ))!;
    expect(signed.isSigned, isTrue);

    final ConsultationReport corrected = await reports.issueCorrection(
      previous: signed,
      findings: 'Corrected findings.',
      diagnosis: signed.diagnosis,
      recommendedTreatment: signed.recommendedTreatment,
      fitnessForWork: signed.fitnessForWork,
    );

    expect(corrected.version, signed.version + 1);
    expect(corrected.isSigned, isFalse);
    // The earlier version is kept and marked superseded.
    final ConsultationReport old = (await context.consultation.byId(
      'RPT-0088-1',
    ))!;
    expect(old.superseded, isTrue);
  });
}
