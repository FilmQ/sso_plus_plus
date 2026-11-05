import 'dart:typed_data';

import '../repository/report_repository.dart';
import '../storage/file_storage.dart';
import 'model.dart';

/// ConsultationReport (SA report 2.18, used in O6, C2.1, C2.2, C2.3).
class ReportModel extends Model {
  ReportModel(this.reports, this.storage);

  final ReportRepository reports;
  final FileStorage storage;

  /// The choices of the "Recommended treatment" field (C2.1, R-050).
  static const treatments = ['Physiotherapy', 'Occupational therapy', 'None'];

  /// QO6.1 (O6 step 2): the filed reports, the reports not viewed first.
  Future<List<Map<String, Object?>>> getReportList() => reports.findFiledReports();

  /// QO6.2 (O6 step 2.1): one filed report, or null. It also has the
  /// recommended treatment of Table 2-66, which QO6.2 does not give (D-063).
  Future<Map<String, Object?>?> getReport(int reportId) async {
    final report = await reports.findReport(reportId);
    if (report == null) return null;
    return {...report, 'recommended_treatment': await reports.findRecommendedTreatment(reportId)};
  }

  /// QO6.3 (O6 step 4): the first view sets read_at; a later view changes
  /// nothing.
  Future<int> markViewed(int reportId) => reports.updateReadAt(reportId);

  /// QC2.1 (C2.1 step 2): the past Confirmed appointments of the consultant
  /// without a filed report.
  Future<List<Map<String, Object?>>> getPendingConsultations(int consultantId) =>
      reports.findConsultationsAwaitingReport(consultantId);

  /// True when [appointmentId] is in QC2.1 for the consultant.
  Future<bool> _isPending(int appointmentId, int consultantId) async =>
      (await getPendingConsultations(consultantId)).any((c) => c['appointment_id'] == appointmentId);

  /// C2.1 step 2.1 to 2.2: QC2.2 makes the session if it is missing, then
  /// QC2.3 gives the report page. Only an appointment of QC2.1 (the
  /// consultant's own, without a filed report); else null.
  Future<Map<String, Object?>?> openReport(int appointmentId, int consultantId) async {
    if (!await _isPending(appointmentId, consultantId)) return null;
    await reports.insertSessionIfMissing(appointmentId, consultantId);
    return reportPage(appointmentId);
  }

  /// QC2.3: the report page after a change (also after the report is filed).
  Future<Map<String, Object?>?> reportPage(int appointmentId) => reports.findReportPage(appointmentId);

  /// C2.1 step 8: keeps the attached file as `/reports/<session_id>/<file name>`
  /// (D-057) and gives its report_file_uri.
  Future<String> storeFile(int sessionId, ({String fileName, Uint8List bytes}) file) =>
      storage.saveReportFile(sessionId, file.fileName, file.bytes);

  /// C2.1 step 6.2 and 8: QC2.4 the first time, QC2.5 after that (Alternate
  /// Case 2 [Draft already saved]); QC2.4 gives no row when a draft is
  /// already there, then QC2.5 runs (R-053). A report is the text or one
  /// file ([keptFileUri] is the saved file when no new file comes);
  /// [recommendedTreatment] goes to the session (R-050).
  Future<void> saveDraft(int appointmentId, Map<String, Object?> page, int consultantId,
      {String? content,
      ({String fileName, Uint8List bytes})? file,
      String? keptFileUri,
      String? recommendedTreatment}) async {
    final sessionId = page['session_id']! as int;
    final fileUri = file == null ? keptFileUri : await storeFile(sessionId, file);
    var reportId = page['report_id'] as int?;
    if (reportId == null) {
      reportId = await reports.insertDraft(sessionId, consultantId,
          reportContent: content, reportFileUri: fileUri, recommendedTreatment: recommendedTreatment);
      if (reportId != null) return;
      reportId = (await reportPage(appointmentId))?['report_id'] as int?;
    }
    final changed = reportId == null
        ? 0
        : await reports.updateDraft(reportId, consultantId,
            reportContent: content, reportFileUri: fileUri, recommendedTreatment: recommendedTreatment);
    if (changed == 0) throw const StateConflictException('The report is filed and cannot change.');
  }

  /// C2.2 step 6: keeps the drawn signature as
  /// `/reports/<session_id>/signature.png` (R-048) and gives its signature_uri.
  Future<String> storeSignature(int sessionId, Uint8List signature) => storage.saveSignature(sessionId, signature);

  /// C2.2 step 6 (QC2.6). A report without text or file gives 422; a signed
  /// report gives 409.
  Future<void> signReport(Map<String, Object?> page, int consultantId, Uint8List signature) async {
    final reportId = page['report_id'] as int?;
    if (reportId == null || (page['report_content'] == null && page['report_file_uri'] == null)) {
      throw const ValidationFailedException({'report': 'Finish the draft first: type the report or attach a file.'});
    }
    // Check before the file store writes, so that the image of a signed report stays the same.
    if (page['signature_status'] == 'Signature signed') {
      throw const StateConflictException('The report is already signed.');
    }
    final uri = await storeSignature(page['session_id']! as int, signature);
    if (await reports.updateSignedAt(reportId, consultantId, uri) == 0) {
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
      if (page['recommended_treatment'] == null) 'recommended_treatment': 'Choose the recommended treatment.',
      if (page['signature_status'] != 'Signature signed') 'signature': 'Sign the report.',
    };
    if (errors.isEmpty) throw const StateConflictException('The report is already filed.');
    throw ValidationFailedException(errors);
  }

  /// C2.1 step 12.1 (QC2.8, Alternate Case 3 [User did not attend]): the
  /// session is `No show` / `Cancelled` and the appointment `No show`; the
  /// claim stays `Covered` and is in QO4.1 again (R-051). Gives
  /// appointment_id and claim_id. Not an appointment of QC2.1 gives null; a
  /// consultation with a report gives 409.
  Future<Map<String, Object?>?> markNoShow(int appointmentId, int consultantId) async {
    if (!await _isPending(appointmentId, consultantId)) return null;
    final row = await reports.updateNoShow(appointmentId, consultantId);
    if (row == null) throw const StateConflictException('The consultation has a report. Use the report instead.');
    return row;
  }
}
