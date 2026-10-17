import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/treatment_api.dart';
import '../../../session/session_providers.dart';
import '../notifications/notification_providers.dart';

final Provider<TreatmentApi> treatmentApiProvider =
    Provider<TreatmentApi>((Ref ref) => TreatmentApi(ref.watch(apiClientProvider)));

/// U5 step 2 (QU5.1): the Appointments tab of the Schedule Page.
final FutureProvider<List<Map<String, Object?>>> appointmentScheduleProvider =
    FutureProvider<List<Map<String, Object?>>>((Ref ref) {
  ref.watch(sessionProvider);
  return ref.read(appointmentApiProvider).getAppointmentSchedule();
});

/// U6 step 2 (Q6.1): the Treatments tab of the Schedule Page.
final FutureProvider<List<Map<String, Object?>>> treatmentScheduleProvider =
    FutureProvider<List<Map<String, Object?>>>((Ref ref) {
  ref.watch(sessionProvider);
  return ref.read(treatmentApiProvider).getTreatmentSchedule();
});
