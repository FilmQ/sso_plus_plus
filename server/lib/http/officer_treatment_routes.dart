import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../controller/treatment_controller.dart';
import 'json.dart';

/// O5.1 Book Treatment and O5.2 No Treatment Required (the Treatment page).
void addOfficerTreatmentRoutes(
  Router router,
  TreatmentController Function(Request) treatments,
) {
  router
    // QO5.1
    ..get('/o5/claims', (Request r) async => jsonOk({'claims': await treatments(r).getClaimsForTreatment()}))
    // QO5.2
    ..get('/o5/available-times', (Request r) async {
      final q = r.url.queryParameters;
      return jsonOk({
        'slots': await treatments(r).getAvailableTimes(q['facility'] ?? '', q['from'] ?? '', q['to'] ?? ''),
      });
    })
    // QO5.3, QN.1
    ..post('/o5/claims/<claim|[0-9]+>/treatment', (Request r, String claim) async {
      final body = await readJson(r);
      final reportId = body['report_id'];
      if (reportId is! int) throw const FormatException('report_id must be a number');
      return jsonOk(await treatments(r).bookTreatment(int.parse(claim), reportId, body));
    })
    // QO5.4, QN.4
    ..post('/o5/claims/<claim|[0-9]+>/no-treatment', (Request r, String claim) async =>
        jsonOk(await treatments(r).closeWithoutTreatment(int.parse(claim))));
}
