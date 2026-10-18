import 'api_client.dart';

/// The officer side of server ReportController (O6; D-053).
class ReportApi {
  const ReportApi(this.api);

  final ApiClient api;

  /// QO6.1: the filed reports, the reports not viewed first.
  Future<List<Map<String, Object?>>> getReportList() async =>
      ((await api.get('/o6/reports'))['reports']! as List<Object?>).cast<Map<String, Object?>>();

  /// QO6.2: the Consultation Report Page.
  Future<Map<String, Object?>> getReport(int reportId) async =>
      (await api.get('/o6/reports/$reportId'))['report']! as Map<String, Object?>;

  /// QO6.3 and QO6.2: "View". Gives the report again (Viewed).
  Future<Map<String, Object?>> viewReport(int reportId) async =>
      (await api.post('/o6/reports/$reportId/view'))['report']! as Map<String, Object?>;
}
