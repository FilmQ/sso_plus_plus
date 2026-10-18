import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../controller/appointment_controller.dart';
import 'json.dart';

/// O4 Schedule Appointment (the Scheduling page).
void addSchedulingRoutes(
  Router router,
  AppointmentController Function(Request) appointments,
) {
  router
    // QO4.1
    ..get('/o4/claims', (Request r) async => jsonOk({'claims': await appointments(r).getClaimsToSchedule()}))
    // QO4.2
    ..get('/o4/availability', (Request r) async =>
        jsonOk({'slots': await appointments(r).getAvailability(r.url.queryParameters['date'] ?? '')}))
    // QO4.3, QN.3
    ..post('/o4/claims/<claim|[0-9]+>/appointment', (Request r, String claim) async {
      final body = await readJson(r);
      final consultantId = body['consultant_id'];
      if (consultantId is! int) throw const FormatException('consultant_id must be a number');
      return jsonOk(await appointments(r).offerAppointment(
          int.parse(claim), consultantId, (body['date'] as String?) ?? '', (body['time'] as String?) ?? ''));
    });
}
