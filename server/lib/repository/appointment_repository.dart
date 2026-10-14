import 'repository.dart';
import 'sql/appointment_sql.dart';

/// Table Appointment and AppointmentConfirmation (U3, U5, O4, C1).
class AppointmentRepository extends Repository {
  AppointmentRepository(super.db);

  final String table = 'Appointment';

  // Q3.2 [U3.1] The newest Pending or Confirmed appointment of the claim.
  Future<Row?> findLatestAppointment(int claimId, int insuredId) async =>
      (await query(AppointmentSql.q3_2, {'claim_id': claimId, 'insured_id': insuredId}))
          .firstOrNull;

  // Q3.3 [U3.1] Only a Pending appointment. Else NoRowChangedException.
  Future<void> confirmAppointment(int appointmentId) =>
      runAll('Q3.3', AppointmentSql.q3_3, {'appointment_id': appointmentId}, guard: 0);

  // Q3.4 [U3.2] Free hours (09:00 to 16:00) of the consultant on [slotDate].
  Future<List<Row>> findFreeSlots(int consultantId, String slotDate) async =>
      (await query(AppointmentSql.q3_4, {'consultant_id': consultantId, 'slot_date': slotDate}))
          .rows;

  // Q3.5 [U3.2] Gives the new appointment_id. Only a Pending or Confirmed appointment.
  Future<int> rescheduleAppointment(int appointmentId, String newDate, String newTime) async {
    final results = await runAll('Q3.5', AppointmentSql.q3_5, {
      'appointment_id': appointmentId,
      'new_date': newDate,
      'new_time': newTime,
    }, guard: 0);
    return results.first.rows.single['appointment_id'] as int;
  }

  // Q3.6 [U3.3] Only a Pending or Confirmed appointment.
  Future<void> cancelAppointment(int appointmentId) =>
      runAll('Q3.6', AppointmentSql.q3_6, {'appointment_id': appointmentId}, guard: 0);

  // QU5.1 [U5]
  Future<List<Row>> findUpcomingAppointments(int insuredId) async =>
      (await query(AppointmentSql.qU5_1, {'insured_id': insuredId})).rows;

  // QO4.1 [O4]
  Future<List<Row>> findClaimsToSchedule() async => (await query(AppointmentSql.qO4_1)).rows;

  // QO4.2 [O4] One row per consultant and hour, with slot_state free, mine or busy.
  Future<List<Row>> findConsultantSlots(String slotDate, int officerId) async =>
      (await query(AppointmentSql.qO4_2, {'slot_date': slotDate, 'officer_id': officerId})).rows;

  // QO4.3 [O4] Gives the new appointment_id.
  Future<int> insertAppointment({
    required int claimId,
    required int officerId,
    required int consultantId,
    required String appointmentType,
    required String scheduleDate,
    required String scheduleTime,
    required String location,
  }) async {
    final rs = await query(AppointmentSql.qO4_3, {
      'claim_id': claimId,
      'officer_id': officerId,
      'consultant_id': consultantId,
      'appointment_type': appointmentType,
      'schedule_date': scheduleDate,
      'schedule_time': scheduleTime,
      'location': location,
    });
    return rs.rows.single['appointment_id'] as int;
  }

  // QC1.1 [C1]
  Future<List<Row>> findConfirmedAppointments(int consultantId) async =>
      (await query(AppointmentSql.qC1_1, {'consultant_id': consultantId})).rows;
}
