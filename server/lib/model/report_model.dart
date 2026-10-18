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
}
