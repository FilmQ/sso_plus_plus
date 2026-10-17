import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../controller/appointment_controller.dart';
import '../controller/treatment_controller.dart';
import 'json.dart';

/// U5 View Appointment Schedule and U6 View Treatment Schedule (the two tabs
/// of the Schedule Page).
void addScheduleRoutes(
  Router router,
  AppointmentController Function(Request) appointments,
  TreatmentController Function(Request) treatments,
) {
  router
    // QU5.1
    ..get('/u5/appointments', (Request r) async =>
        jsonOk({'appointments': await appointments(r).getAppointmentSchedule()}))
    // Q6.1
    ..get('/u6/treatments', (Request r) async =>
        jsonOk({'treatments': await treatments(r).getTreatmentSchedule()}));
}
