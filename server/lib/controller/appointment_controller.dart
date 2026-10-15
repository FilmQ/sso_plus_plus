import '../auth/user_session.dart';
import '../db/db_connector.dart';
import '../model/appointment_model.dart';
import '../model/notification_model.dart';
import 'controller.dart';

/// U3.1 Confirm Appointment, U3.2 Request Another Date, U3.3 I cannot attend
/// (SA report 2.13, sequences U3.1 to U3.3).
///
/// The page sends the claim_id. The controller finds the appointment with Q3.2,
/// which checks that the claim belongs to the signed-in user (D-032).
class AppointmentController extends Controller {
  AppointmentController(super.session, this.db, this.appointmentModel, this.notificationModel);

  final DBConnector db;
  final AppointmentModel appointmentModel;
  final NotificationModel notificationModel;

  int get _insuredId => requireRole(Role.user).insuredId!;

  static final _date = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static final _time = RegExp(r'^\d{2}:\d{2}$');

  /// U3.1 step 1 (Q3.1): the number for the red dot of the Notification Page.
  Future<int> checkUnreadNotifications() => notificationModel.countUnread(_insuredId);

  /// U3.1 step 3 (Q3.2): the Appointment Page data.
  Future<Map<String, Object?>> getAppointment(int claimId) async {
    final appointment = await appointmentModel.getAppointmentDetail(claimId, _insuredId);
    if (appointment == null) throw const ControllerException(404, 'There is no open appointment for this claim.');
    return appointment;
  }

  /// U3.1 steps 5 and 6: Q3.3, then Q3.7. Gives the appointment again (Confirmed).
  Future<Map<String, Object?>> confirmAppointment(int claimId, {int? notificationId}) =>
      db.transaction(() async {
        final a = await getAppointment(claimId);
        await appointmentModel.confirm(a['appointment_id']! as int);
        await _markRead(notificationId);
        return getAppointment(claimId);
      });

  /// U3.2 step 5 (Q3.4): the free hours of the consultant on [slotDate].
  Future<List<String>> getFreeSlots(int claimId, String slotDate) async {
    if (!_date.hasMatch(slotDate) || DateTime.tryParse(slotDate) == null) {
      throw const FormatException('date must be yyyy-MM-dd');
    }
    final a = await getAppointment(claimId);
    return appointmentModel.getFreeSlots(a['consultant_id']! as int, slotDate);
  }

  /// U3.2 steps 7.1 and 8: Q3.5, then Q3.7. Gives the new appointment.
  Future<Map<String, Object?>> reschedule(int claimId, String newDate, String newTime, {int? notificationId}) {
    if (!_date.hasMatch(newDate) || !_time.hasMatch(newTime)) {
      throw const FormatException('new_date must be yyyy-MM-dd and new_time HH:mm');
    }
    return db.transaction(() async {
      final a = await getAppointment(claimId);
      await appointmentModel.reschedule(
          a['appointment_id']! as int, a['consultant_id']! as int, newDate, newTime);
      await _markRead(notificationId);
      return getAppointment(claimId);
    });
  }

  /// U3.3 steps 7.1 and 8: Q3.6, then Q3.7. Q3.2 does not read a Cancelled
  /// appointment, so this gives the data from before, with the new status (U3-7).
  Future<Map<String, Object?>> cancelAppointment(int claimId, {int? notificationId}) =>
      db.transaction(() async {
        final a = await getAppointment(claimId);
        await appointmentModel.cancel(a['appointment_id']! as int);
        await _markRead(notificationId);
        return {...a, 'appointment_status': 'Cancelled'};
      });

  /// Q3.7 runs only when the page was opened from a message (D-034).
  Future<void> _markRead(int? notificationId) async {
    if (notificationId != null) await notificationModel.markRead(notificationId, _insuredId);
  }
}
