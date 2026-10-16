import '../repository/appointment_repository.dart';
import 'model.dart';

/// Appointment (SA report 2.18, used in U3.1, U3.2, U3.3, U5, O4, C1).
class AppointmentModel extends Model {
  AppointmentModel(this.appointments);

  final AppointmentRepository appointments;

  /// Data dictionary, Appointment.schedule_time: 09:00 to 15:00 every hour
  /// except 12:00 (the hours of Q3.4 and QO4.2).
  static const bookableHours = ['09:00', '10:00', '11:00', '13:00', '14:00', '15:00'];

  /// Q3.2: the newest Pending or Confirmed appointment of the claim, or null.
  Future<Map<String, Object?>?> getAppointmentDetail(int claimId, int insuredId) =>
      appointments.findLatestAppointment(claimId, insuredId);

  /// Q3.3 (U3.1). Only a Pending appointment; else NoRowChangedException (409).
  Future<void> confirm(int appointmentId) => appointments.confirmAppointment(appointmentId);

  /// Q3.4 (U3.2): the free hours, for example ['10:00', '13:00'].
  Future<List<String>> getFreeSlots(int consultantId, String slotDate) async => [
        for (final row in await appointments.findFreeSlots(consultantId, slotDate)) row['slot_time']! as String,
      ];

  /// Q3.5 (U3.2). Gives the new appointment_id. Q3.5 refuses (409) an
  /// appointment that is not Pending or Confirmed, an hour in the past, and an
  /// hour that the consultant already has.
  /// Q3.5 does not check the bookable hours, so the Model does (422, D-033).
  Future<int> reschedule(int appointmentId, String newDate, String newTime) {
    if (!bookableHours.contains(newTime)) {
      throw const ValidationFailedException({'new_time': 'Choose one of the free times.'});
    }
    return appointments.rescheduleAppointment(appointmentId, newDate, newTime);
  }

  /// Q3.6 (U3.3). Only a Pending or Confirmed appointment. The claim changes
  /// from Covered to Withdrawn (final).
  Future<void> cancel(int appointmentId) => appointments.cancelAppointment(appointmentId);
}
