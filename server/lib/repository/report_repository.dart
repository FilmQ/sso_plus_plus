import 'repository.dart';
import 'sql/infrastructure_sql.dart';
import 'sql/report_sql.dart';

/// Table ConsultationReport and ConsultationSession (O6, C2).
class ReportRepository extends Repository {
  ReportRepository(super.db);

  final String table = 'ConsultationReport';

  // QO6.1 [O6] Unread reports first.
  Future<List<Row>> findFiledReports() async => (await query(ReportSql.qO6_1)).rows;

  // QO6.2 [O6]
  Future<Row?> findReport(int reportId) async =>
      (await query(ReportSql.qO6_2, {'report_id': reportId})).firstOrNull;

  // Not a report query (D-063, R-062): the recommended treatment of Table 2-66.
  Future<String?> findRecommendedTreatment(int reportId) async =>
      (await query(InfrastructureSql.findRecommendedTreatment, {'report_id': reportId}))
          .firstOrNull?['recommended_treatment'] as String?;

  // QO6.3 [O6] Gives 0 when the report was already read.
  Future<int> updateReadAt(int reportId) => execute(ReportSql.qO6_3, {'report_id': reportId});

  // QC2.1 [C2.1]
  Future<List<Row>> findConsultationsAwaitingReport(int consultantId) async =>
      (await query(ReportSql.qC2_1, {'consultant_id': consultantId})).rows;

  // QC2.2 [C2.1] Gives 0 when the session is already there (ON CONFLICT) or
  // the appointment is not a Confirmed appointment of the consultant.
  Future<int> insertSessionIfMissing(int appointmentId, int consultantId) =>
      execute(ReportSql.qC2_2, {'appointment_id': appointmentId, 'consultant_id': consultantId});

  // QC2.3 [C2.1]
  Future<Row?> findReportPage(int appointmentId) async =>
      (await query(ReportSql.qC2_3, {'appointment_id': appointmentId})).firstOrNull;

  // QC2.4 [C2.1] Gives the new report_id, or null when a draft is already
  // there (ON CONFLICT): then use QC2.5. A report is text or one file.
  Future<int?> insertDraft(int sessionId, int consultantId,
          {String? reportContent, String? reportFileUri, String? recommendedTreatment}) async =>
      (await query(ReportSql.qC2_4, {
        'session_id': sessionId,
        'consultant_id': consultantId,
        'report_content': reportContent,
        'report_file_uri': reportFileUri,
        'recommended_treatment': recommendedTreatment,
      }))
          .firstOrNull?['report_id'] as int?;

  // QC2.5 [C2.1] Also removes the signature. Gives 0 when the report is filed
  // or belongs to another consultant.
  Future<int> updateDraft(int reportId, int consultantId,
          {String? reportContent, String? reportFileUri, String? recommendedTreatment}) =>
      execute(ReportSql.qC2_5, {
        'report_id': reportId,
        'consultant_id': consultantId,
        'report_content': reportContent,
        'report_file_uri': reportFileUri,
        'recommended_treatment': recommendedTreatment,
      });

  // QC2.6 [C2.2] Gives 0 when there is no content or file, no signature file,
  // or the report is signed.
  Future<int> updateSignedAt(int reportId, int consultantId, String signatureUri) => execute(
      ReportSql.qC2_6, {'report_id': reportId, 'consultant_id': consultantId, 'signature_uri': signatureUri});

  // QC2.7 [C2.3] Gives the report_id, or null when the report is not ready (Validation Failed).
  Future<int?> updateDeliveredAt(int reportId, int consultantId) async =>
      (await query(ReportSql.qC2_7, {'report_id': reportId, 'consultant_id': consultantId}))
          .firstOrNull?['report_id'] as int?;

  // QC2.8 [C2.1] Alternate Case 3 [User did not attend]. Gives appointment_id
  // and claim_id, or null when the appointment is not a Confirmed appointment
  // of the consultant, has not started, or has a report.
  Future<Row?> updateNoShow(int appointmentId, int consultantId) async =>
      (await query(ReportSql.qC2_8, {'appointment_id': appointmentId, 'consultant_id': consultantId})).firstOrNull;
}
