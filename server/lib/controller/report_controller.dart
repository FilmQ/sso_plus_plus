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
  Future<({Uint8List bytes, String mimeType})> openReportFile(int reportId) async =>
      _file((await getReport(reportId))['report_file_uri'] as String?, 'The report file is not available.');

  /// O6-2 and O6-3: the signature image of a filed report (signature_uri of
  /// QO6.2, R-048).
  Future<({Uint8List bytes, String mimeType})> openReportSignature(int reportId) async =>
      _file((await getReport(reportId))['signature_uri'] as String?, 'The report has no signature image.');

  /// The bytes of a stored file, or 404 with [missing].
  Future<({Uint8List bytes, String mimeType})> _file(String? uri, String missing) async {
    final bytes = uri == null ? null : await storage.read(uri);
    if (uri == null || bytes == null) throw ControllerException(404, missing);
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
  /// attached [file] (one of the two) and the [recommendedTreatment]
  /// (R-050). The Model keeps the file (D-057) and saves the draft with
  /// QC2.4 or QC2.5. With no text and no new file, a draft that is a file
  /// keeps its file (to change only the recommendation). Gives the report
  /// page.
  Future<Map<String, Object?>> saveDraft(int appointmentId,
      {String? content, ({String fileName, Uint8List bytes})? file, String? recommendedTreatment}) async {
    final consultantId = _consultantId;
    final text = content?.trim() ?? '';
    final treatment = recommendedTreatment?.trim() ?? '';
    final errors = {
      if (text.isNotEmpty && file != null) 'report': 'Type the report or attach a file, not both.',
      if (file != null && FieldRules.mimeTypeOf(file.fileName) == null) 'file': 'Attach a PDF, JPG or PNG file.',
      if (file != null && file.bytes.length > FieldRules.maxFileBytes) 'file': 'The file must be 10 MB or smaller.',
      if (treatment.isNotEmpty && !ReportModel.treatments.contains(treatment))
        'recommended_treatment': 'Choose Physiotherapy, Occupational therapy or None.',
    };
    if (errors.isNotEmpty) throw ValidationFailedException(errors);
    return db.transaction(() async {
      final page = await openReport(appointmentId);
      final keptFileUri = text.isEmpty && file == null ? page['report_file_uri'] as String? : null;
      if (text.isEmpty && file == null && keptFileUri == null) {
        throw const ValidationFailedException({'report': 'Type the report or attach a file.'});
      }
      await reportModel.saveDraft(appointmentId, page, consultantId,
          content: text.isEmpty ? null : text,
          file: file,
          keptFileUri: keptFileUri,
          recommendedTreatment: treatment.isEmpty ? null : treatment);
      return (await reportModel.reportPage(appointmentId))!;
    });
  }

  /// C2.1 steps 9 to 12.1 (QC2.8, Alternate Case 3 [User did not attend]):
  /// the user did not come. Gives appointment_id and claim_id.
  Future<Map<String, Object?>> markNoShow(int appointmentId) async {
    final row = await reportModel.markNoShow(appointmentId, _consultantId);
    if (row == null) throw const ControllerException(404, 'There is no consultation to report with this ID.');
    return row;
  }

  /// C2.2 steps 5 to 6 (QC2.6): the drawn [signature] (a PNG image) is
  /// confirmed. Gives the page.
  Future<Map<String, Object?>> signReport(int appointmentId, Uint8List? signature) async {
    final consultantId = _consultantId;
    if (signature == null || signature.isEmpty) {
      throw const ValidationFailedException({'signature': 'Draw the signature.'});
    }
    if (!_isPng(signature) || signature.length > maxSignatureBytes) {
      throw const ValidationFailedException({'signature': 'The signature must be a PNG image of 1 MB or smaller.'});
    }
    await reportModel.signReport(await openReport(appointmentId), consultantId, signature);
    return (await reportModel.reportPage(appointmentId))!;
  }

  /// The largest signature image that the server keeps.
  static const maxSignatureBytes = 1048576; // 1 MB

  static bool _isPng(Uint8List b) => b.length > 8 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47;

  /// C2.3 steps 3 to 4 (QC2.7): the report goes to the Evaluation Officer
  /// (it is in QO6.1 from now on, with no message, R-049). Gives the page.
  Future<Map<String, Object?>> fileReport(int appointmentId) async {
    await reportModel.fileReport(await openReport(appointmentId), _consultantId);
    return (await reportModel.reportPage(appointmentId))!;
  }

  /// The attached file of the consultant's draft (C2.1-4), to look at it.
  Future<({Uint8List bytes, String mimeType})> openDraftFile(int appointmentId) async =>
      _file((await openReport(appointmentId))['report_file_uri'] as String?, 'The draft has no file.');

  /// The signature image of the consultant's report (C2.2-2, R-048).
  Future<({Uint8List bytes, String mimeType})> openDraftSignature(int appointmentId) async =>
      _file((await openReport(appointmentId))['signature_uri'] as String?, 'The report has no signature.');
}
