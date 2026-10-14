import 'repository.dart';
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

  // QO6.3 [O6] Gives 0 when the report was already read.
  Future<int> updateReadAt(int reportId) => execute(ReportSql.qO6_3, {'report_id': reportId});

  // QC2.1 [C2.1]
  Future<List<Row>> findConsultationsAwaitingReport(int consultantId) async =>
      (await query(ReportSql.qC2_1, {'consultant_id': consultantId})).rows;

  // QC2.2 [C2.1] Gives 0 when the session is already there.
  Future<int> insertSessionIfMissing(int appointmentId) =>
      execute(ReportSql.qC2_2, {'appointment_id': appointmentId});

  // QC2.3 [C2.1]
  Future<Row?> findReportPage(int appointmentId) async =>
      (await query(ReportSql.qC2_3, {'appointment_id': appointmentId})).firstOrNull;

  // QC2.4 [C2.1] Gives the new report_id.
  Future<int> insertDraft(int sessionId, int consultantId, String reportContent) async {
    final rs = await query(ReportSql.qC2_4, {
      'session_id': sessionId,
      'consultant_id': consultantId,
      'report_content': reportContent,
    });
    return rs.rows.single['report_id'] as int;
  }

  // QC2.5 [C2.1] Gives 0 when the report is filed or belongs to another consultant.
  Future<int> updateDraft(int reportId, int consultantId, String reportContent) =>
      execute(ReportSql.qC2_5, {
        'report_id': reportId,
        'consultant_id': consultantId,
        'report_content': reportContent,
      });

  // QC2.6 [C2.2] Gives 0 when there is no content or the report is signed.
  Future<int> updateSignedAt(int reportId, int consultantId) =>
      execute(ReportSql.qC2_6, {'report_id': reportId, 'consultant_id': consultantId});

  // QC2.7 [C2.3] Gives the report_id, or null when the report is not ready (Validation Failed).
  Future<int?> updateDeliveredAt(int reportId, int consultantId) async =>
      (await query(ReportSql.qC2_7, {'report_id': reportId, 'consultant_id': consultantId}))
          .firstOrNull?['report_id'] as int?;
}
