import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../controller/treatment_controller.dart';
import 'json.dart';

/// U4.1 Accept Case and U4.2 Change Date (the Confirm Treatment page).
void addU4Routes(
  Router router,
  TreatmentController Function(Request) treatments,
) {
  const base = '/u4/treatments/<treatment|[0-9]+>';

  router
    // Q6.1 (one row)
    ..get(base, (Request r, String treatment) async =>
        jsonOk({'treatment': await treatments(r).getTreatment(int.parse(treatment))}))
    // QU4.1
    ..post('$base/accept', (Request r, String treatment) async =>
        jsonOk({'treatment': await treatments(r).acceptTreatment(int.parse(treatment))}))
    // QO5.2 (D-042)
    ..get('$base/available-dates', (Request r, String treatment) async =>
        jsonOk({'dates': await treatments(r).getAvailableDates(int.parse(treatment))}))
    // QU4.2
    ..post('$base/change-date', (Request r, String treatment) async {
      final body = await readJson(r);
      return jsonOk({
        'treatment': await treatments(r).changeDate(int.parse(treatment), (body['new_date'] as String?) ?? ''),
      });
    });
}
