import '../repository/appointment_repository.dart';
import 'model.dart';

/// Appointment (SA report 2.18, used in U3.1, U3.2, U3.3, U5, O4, C1).
class AppointmentModel extends Model {
  AppointmentModel(this.appointments);

  final AppointmentRepository appointments;

  /// Q3.2: the newest Pending or Confirmed appointment of the claim, or null.
  Future<Map<String, Object?>?> getAppointmentDetail(int claimId, int insuredId) =>
      appointments.findLatestAppointment(claimId, insuredId);

  /// Q3.3 (U3.1). Only a Pending appointment; else NoRowChangedException (409).
  Future<void> confirm(int appointmentId) => appointments.confirmAppointment(appointmentId);

  /// Q3.4 (U3.2): the free hours, for example ['10:00', '13:00'].
  Future<List<String>> getFreeSlots(int consultantId, String slotDate) async => [
        for (final row in await appointments.findFreeSlots(consultantId, slotDate)) row['slot_time']! as String,
      ];

  /// Q3.5 (U3.2). Gives the new appointment_id. Refuses a time that is not free
  /// (D-033): Q3.5 itself does not check it.
  Future<int> reschedule(int appointmentId, int consultantId, String newDate, String newTime) async {
    if (!(await getFreeSlots(consultantId, newDate)).contains(newTime)) {
      throw const StateConflictException('This time is not free any more. Choose another time.');
    }
    return appointments.rescheduleAppointment(appointmentId, newDate, newTime);
  }

  /// Q3.6 (U3.3). Only a Pending or Confirmed appointment.
  Future<void> cancel(int appointmentId) => appointments.cancelAppointment(appointmentId);
}
