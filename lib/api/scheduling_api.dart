import 'api_client.dart';

/// The officer side of server AppointmentController (O4; D-051).
class SchedulingApi {
  const SchedulingApi(this.api);

  final ApiClient api;

  /// QO4.1: the claims ready to schedule.
  Future<List<Map<String, Object?>>> getClaimsToSchedule() async =>
      ((await api.get('/o4/claims'))['claims']! as List<Object?>).cast<Map<String, Object?>>();

  /// QO4.2: one row per consultant and hour of [date] ('yyyy-MM-dd').
  Future<List<Map<String, Object?>>> getAvailability(String date) async =>
      ((await api.get('/o4/availability?date=$date'))['slots']! as List<Object?>).cast<Map<String, Object?>>();

  /// QO4.3 and QN.3. Gives appointment_id, appointment_date and confirm_by.
  Future<Map<String, Object?>> offerAppointment(int claimId, int consultantId, String date, String time) =>
      api.post('/o4/claims/$claimId/appointment',
          <String, Object?>{'consultant_id': consultantId, 'date': date, 'time': time});
}
