import '../repository/report_repository.dart';
import 'model.dart';

/// ConsultationReport (SA report 2.18, used in O6, C2.1, C2.2, C2.3).
class ReportModel extends Model {
  ReportModel(this.reports);

  final ReportRepository reports;

  /// QO6.1 (O6 step 2): the filed reports, the reports not viewed first.
  Future<List<Map<String, Object?>>> getReportList() => reports.findFiledReports();

  /// QO6.2 (O6 step 2.1): one filed report, or null.
  Future<Map<String, Object?>?> getReport(int reportId) => reports.findReport(reportId);

  /// QO6.3 (O6 step 4): the first view sets read_at; a later view changes
  /// nothing.
  Future<int> markViewed(int reportId) => reports.updateReadAt(reportId);

  /// QC2.1 (C2.1 step 2): the past Confirmed appointments of the consultant
  /// without a filed report.
  Future<List<Map<String, Object?>>> getPendingConsultations(int consultantId) =>
      reports.findConsultationsAwaitingReport(consultantId);

  /// C2.1 step 2.1 to 2.2: QC2.2 makes the session if it is missing, then
  /// QC2.3 gives the report page. Only an appointment of QC2.1 (the
  /// consultant's own, without a filed report); else null.
  Future<Map<String, Object?>?> openReport(int appointmentId, int consultantId) async {
    if (!(await getPendingConsultations(consultantId)).any((c) => c['appointment_id'] == appointmentId)) {
      return null;
    }
    await reports.insertSessionIfMissing(appointmentId);
    return reportPage(appointmentId);
  }

  /// QC2.3: the report page after a change (also after the report is filed).
  Future<Map<String, Object?>?> reportPage(int appointmentId) => reports.findReportPage(appointmentId);

  /// C2.1 step 6.2 and 8: QC2.4 the first time, QC2.5 after that (Alternate
  /// Case 2 [Draft already saved]). A report is the text or one file.
  Future<void> saveDraft(Map<String, Object?> page, int consultantId, {String? content, String? fileUri}) async {
    final reportId = page['report_id'] as int?;
    if (reportId == null) {
      await reports.insertDraft(page['session_id']! as int, consultantId,
          reportContent: content, reportFileUri: fileUri);
    } else if (await reports.updateDraft(reportId, consultantId, reportContent: content, reportFileUri: fileUri) == 0) {
      throw const StateConflictException('The report is filed and cannot change.');
    }
  }

  /// C2.2 step 6 (QC2.6). A report without text or file gives 422; a signed
  /// report gives 409.
  Future<void> signReport(Map<String, Object?> page, int consultantId) async {
    final reportId = page['report_id'] as int?;
    if (reportId == null || (page['report_content'] == null && page['report_file_uri'] == null)) {
      throw const ValidationFailedException({'report': 'Finish the draft first: type the report or attach a file.'});
    }
    if (await reports.updateSignedAt(reportId, consultantId) == 0) {
      throw const StateConflictException('The report is already signed.');
    }
  }

  /// C2.3 step 4 (QC2.7). When QC2.7 gives no row, the Model tells what is
  /// missing (Alternate Case 1 [Validation Failed], 422), or 409 when the
  /// report is already filed.
  Future<void> fileReport(Map<String, Object?> page, int consultantId) async {
    final reportId = page['report_id'] as int?;
    if (reportId != null && await reports.updateDeliveredAt(reportId, consultantId) != null) return;
    final errors = {
      if (page['report_content'] == null && page['report_file_uri'] == null)
        'report': 'Type the report or attach a file.',
      if (page['signature_status'] != 'Signature signed') 'signature': 'Sign the report.',
    };
    if (errors.isEmpty) throw const StateConflictException('The report is already filed.');
    throw ValidationFailedException(errors);
  }
}
