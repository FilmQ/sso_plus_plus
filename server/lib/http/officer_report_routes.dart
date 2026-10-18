import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../controller/report_controller.dart';
import 'json.dart';

/// O6 View Consultation Report.
void addOfficerReportRoutes(
  Router router,
  ReportController Function(Request) reports,
) {
  const report = '/o6/reports/<report|[0-9]+>';

  router
    // QO6.1
    ..get('/o6/reports', (Request r) async => jsonOk({'reports': await reports(r).getReportList()}))
    // QO6.2
    ..get(report, (Request r, String id) async => jsonOk({'report': await reports(r).getReport(int.parse(id))}))
    // QO6.3, QO6.2
    ..post('$report/view', (Request r, String id) async =>
        jsonOk({'report': await reports(r).viewReport(int.parse(id))}));
}
