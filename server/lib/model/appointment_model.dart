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

  /// QU5.1 (U5): the Pending and Confirmed appointments from today on.
  Future<List<Map<String, Object?>>> getUpcomingAppointments(int insuredId) =>
      appointments.findUpcomingAppointments(insuredId);

  /// C1 step 2: QC1.1 gives the Confirmed appointments of the consultant from
  /// today on; QC1.2 gives the "Recent changes" card (step 2.1, R-052).
  Future<({List<Map<String, Object?>> appointments, List<Map<String, Object?>> recentChanges})> getConsultantSchedule(
          int consultantId) async =>
      (
        appointments: await appointments.findConfirmedAppointments(consultantId),
        recentChanges: await appointments.findRecentChanges(consultantId),
      );

  /// QO4.1 (O4 step 2): the Covered claims without a Pending or Confirmed
  /// appointment.
  Future<List<Map<String, Object?>>> getClaimsToSchedule() => appointments.findClaimsToSchedule();

  /// QO4.2 (O4 step 2.1): one row per consultant and bookable hour of
  /// [slotDate], with slot_state free, mine or busy.
  Future<List<Map<String, Object?>>> getConsultantSlots(String slotDate, int officerId) =>
      appointments.findConsultantSlots(slotDate, officerId);

  /// QO4.3 (O4 step 6.1): an Onsite appointment at the consultant's office.
  /// QO4.3 refuses (409) what does not agree with its conditions. So that the
  /// page can show a clear message, the Model first checks (D-051): the date
  /// is a weekday after [today] (422), the claim is in QO4.1 (409), and the
  /// hour is 'free' for the consultant in QO4.2 (409). Gives the
  /// appointment_id and the slot.
  Future<({int appointmentId, DateTime slotAt})> createAppointment(int claimId, int consultantId, String date,
      String time, {required int officerId, required String today}) async {
    if (date.compareTo(today) <= 0) {
      throw const ValidationFailedException({'date': 'Choose a date after today.'});
    }
    if (DateTime.parse(date).weekday > DateTime.friday) {
      throw const ValidationFailedException({'date': 'Choose a weekday (Monday to Friday).'});
    }
    if (!(await getClaimsToSchedule()).any((c) => c['claim_id'] == claimId)) {
      throw const StateConflictException('The claim cannot be scheduled. Open the page again.');
    }
    final slot = (await getConsultantSlots(date, officerId)).where((s) {
      final at = s['slot_at']! as DateTime;
      return s['consultant_id'] == consultantId && '${_two(at.hour)}:${_two(at.minute)}' == time;
    }).firstOrNull;
    if (slot == null || slot['slot_state'] != 'free') {
      throw const StateConflictException('This time is not free any more. Choose another time.');
    }
    final id = await appointments.insertAppointment(
      claimId: claimId,
      officerId: officerId,
      consultantId: consultantId,
      scheduleDate: date,
      scheduleTime: time,
    );
    return (appointmentId: id, slotAt: slot['slot_at']! as DateTime);
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
