import '../auth/user_session.dart';
import '../model/report_model.dart';
import 'controller.dart';

/// O6 View Consultation Report (SA report 2.13, sequence O6). Only an
/// Evaluation Officer can use it. C2.1 to C2.3 come later.
class ReportController extends Controller {
  ReportController(super.session, this.reportModel);

  final ReportModel reportModel;

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

  /// O6 steps 3 to 4 (QO6.3): "View". Gives the report again (Viewed).
  Future<Map<String, Object?>> viewReport(int reportId) async {
    await getReport(reportId);
    await reportModel.markViewed(reportId);
    return getReport(reportId);
  }
}
