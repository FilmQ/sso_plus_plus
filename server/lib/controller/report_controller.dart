import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../auth/user_session.dart';
import '../model/field_rules.dart';
import '../model/report_model.dart';
import '../storage/file_storage.dart';
import 'controller.dart';

/// O6 View Consultation Report (SA report 2.13, sequence O6). Only an
/// Evaluation Officer can use it. C2.1 to C2.3 come later.
class ReportController extends Controller {
  ReportController(super.session, this.reportModel, this.storage);

  final ReportModel reportModel;
  final FileStorage storage;

  void _officer() => requireRole(Role.officer);

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
}
