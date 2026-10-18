import '../repository/report_repository.dart';
import 'model.dart';

/// ConsultationReport (SA report 2.18, used in O6, C2.1, C2.2, C2.3).
class ReportModel extends Model {
  ReportModel(this.reports);

  final ReportRepository reports;

  /// QO6.1 (O6 step 2): the filed reports, the reports not viewed first.
  Future<List<Map<String, Object?>>> getReportList() => reports.findFiledReports();

  /// QO6.2 (O6 step 2.1): one report, or null. QO6.2 does not check that the
  /// report is filed, so the Model gives only a report of QO6.1 (D-053).
  Future<Map<String, Object?>?> getReport(int reportId) async {
    if (!(await getReportList()).any((r) => r['report_id'] == reportId)) return null;
    return reports.findReport(reportId);
  }

  /// QO6.3 (O6 step 4): the first view sets read_at; a later view changes
  /// nothing.
  Future<int> markViewed(int reportId) => reports.updateReadAt(reportId);
}
