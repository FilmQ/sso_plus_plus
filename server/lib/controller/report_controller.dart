import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../auth/user_session.dart';
import '../db/db_connector.dart';
import '../model/field_rules.dart';
import '../model/model.dart';
import '../model/report_model.dart';
import '../storage/file_storage.dart';
import 'controller.dart';

/// O6 View Consultation Report (Evaluation Officer) and C2.1 to C2.3 Create
/// Consultation Report (Consultant) (SA report 2.13, sequences O6, C2.1 to
/// C2.3).
class ReportController extends Controller {
  ReportController(super.session, this.db, this.reportModel, this.storage);

  final DBConnector db;
  final ReportModel reportModel;
  final FileStorage storage;

  void _officer() => requireRole(Role.officer);

  int get _consultantId => requireRole(Role.consultant).consultantId!;

  /// O6 steps 1 to 2 (QO6.1): the report list.
  Future<List<Map<String, Object?>>> getReportList() {
    _officer();
    return reportModel.getReportList();
  }

  /// O6 step 2.1 (QO6.2): the Consultation Report Page.
  Future<Map<String, Object?>> getReport(int reportId) async {
    _officer();
    final report = await reportModel.getReport(reportId);
    if (report == null) throw const ControllerException(404, 'There is no filed report with this ID.');
    return report;
  }

  /// O6 step 4.2 (Alternate Case 1 [File]): the file of a report that is a
  /// file (report_file_uri of QO6.2). Gives the bytes and the MIME type.
  Future<({Uint8List bytes, String mimeType})> openReportFile(int reportId) async {
    final uri = (await getReport(reportId))['report_file_uri'] as String?;
    final bytes = uri == null ? null : await storage.read(uri);
    if (uri == null || bytes == null) throw const ControllerException(404, 'The report file is not available.');
    return (bytes: bytes, mimeType: FieldRules.mimeTypeOf(p.basename(uri)) ?? 'application/octet-stream');
  }

  /// O6 steps 3 to 4 (QO6.3): "View". Gives the report again (Viewed).
  Future<Map<String, Object?>> viewReport(int reportId) async {
    await getReport(reportId);
    await reportModel.markViewed(reportId);
    return getReport(reportId);
  }

  /// C2.1 steps 1 to 2 (QC2.1): the consultations that wait for a report.
  Future<List<Map<String, Object?>>> getPendingConsultations() => reportModel.getPendingConsultations(_consultantId);

  /// C2.1 steps 2.1 to 2.2 (QC2.2, QC2.3): the report page of a consultation.
  Future<Map<String, Object?>> openReport(int appointmentId) async {
    final page = await reportModel.openReport(appointmentId, _consultantId);
    if (page == null) throw const ControllerException(404, 'There is no consultation to report with this ID.');
    return page;
  }

  /// C2.1 steps 5 to 8: "Finish the draft" with the typed [content] or an
  /// attached [file] (one of the two). The file store keeps the file
  /// (D-057); QC2.4 or QC2.5 saves the draft. Gives the report page.
  Future<Map<String, Object?>> saveDraft(int appointmentId,
      {String? content, ({String fileName, Uint8List bytes})? file}) async {
    final consultantId = _consultantId;
    final text = content?.trim() ?? '';
    final errors = {
      if (text.isEmpty && file == null) 'report': 'Type the report or attach a file.',
      if (text.isNotEmpty && file != null) 'report': 'Type the report or attach a file, not both.',
      if (file != null && FieldRules.mimeTypeOf(file.fileName) == null) 'file': 'Attach a PDF, JPG or PNG file.',
      if (file != null && file.bytes.length > FieldRules.maxFileBytes) 'file': 'The file must be 10 MB or smaller.',
    };
    if (errors.isNotEmpty) throw ValidationFailedException(errors);
    return db.transaction(() async {
      final page = await openReport(appointmentId);
      final uri =
          file == null ? null : await storage.saveReportFile(page['session_id']! as int, file.fileName, file.bytes);
      await reportModel.saveDraft(page, consultantId, content: text.isEmpty ? null : text, fileUri: uri);
      return (await reportModel.reportPage(appointmentId))!;
    });
  }

  /// C2.2 steps 5 to 6 (QC2.6): the signature is confirmed. Gives the page.
  Future<Map<String, Object?>> signReport(int appointmentId) async {
    await reportModel.signReport(await openReport(appointmentId), _consultantId);
    return (await reportModel.reportPage(appointmentId))!;
  }

  /// C2.3 steps 3 to 4 (QC2.7): the report goes to the Evaluation Officer
  /// (it is in QO6.1 from now on). Gives the page.
  Future<Map<String, Object?>> fileReport(int appointmentId) async {
    await reportModel.fileReport(await openReport(appointmentId), _consultantId);
    return (await reportModel.reportPage(appointmentId))!;
  }

  /// The attached file of the consultant's draft (C2.1-4), to look at it.
  Future<({Uint8List bytes, String mimeType})> openDraftFile(int appointmentId) async {
    final uri = (await openReport(appointmentId))['report_file_uri'] as String?;
    final bytes = uri == null ? null : await storage.read(uri);
    if (uri == null || bytes == null) throw const ControllerException(404, 'The draft has no file.');
    return (bytes: bytes, mimeType: FieldRules.mimeTypeOf(p.basename(uri)) ?? 'application/octet-stream');
  }
}
