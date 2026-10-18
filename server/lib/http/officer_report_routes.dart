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
    // O6 step 4.2: the file of a report that is a file (no SQL)
    ..get('$report/file', (Request r, String id) async {
      final file = await reports(r).openReportFile(int.parse(id));
      return Response.ok(file.bytes, headers: {'content-type': file.mimeType});
    })
    // QO6.3, QO6.2
    ..post('$report/view', (Request r, String id) async =>
        jsonOk({'report': await reports(r).viewReport(int.parse(id))}));
}
