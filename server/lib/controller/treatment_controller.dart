import '../auth/user_session.dart';
import '../db/db_connector.dart';
import '../model/claim_model.dart';
import '../model/date_text.dart';
import '../model/notification_model.dart';
import '../model/treatment_model.dart';
import 'controller.dart';

/// U4.1 Accept Case, U4.2 Change Date, U4.3 Reject, U6 View Treatment
/// Schedule, O5.1 Book Treatment and O5.2 No Treatment Required (SA report
/// 2.13, sequences U4.1 to U4.3, U6, O5.1 and O5.2).
///
/// The page sends the treatment_id. The controller reads the treatment with
/// QU4.4, which checks that it belongs to the signed-in user, and takes the
/// claim_id from that row. QU4.1 and QU4.2 check the owner again (D-041).
class TreatmentController extends Controller {
  TreatmentController(super.session, this.db, this.treatmentModel, this.claimModel, this.notificationModel);

  final DBConnector db;
  final TreatmentModel treatmentModel;
  final ClaimModel claimModel;
  final NotificationModel notificationModel;

  int get _insuredId => requireRole(Role.user).insuredId!;

  int get _officerId => requireRole(Role.officer).officerId!;

  static final _date = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  /// U6 step 2 (Q6.1): the Treatments tab of the Schedule Page.
  Future<List<Map<String, Object?>>> getTreatmentSchedule() => treatmentModel.getUpcomingTreatments(_insuredId);

  /// U4.1 steps 1 to 2 (QU4.4): the Confirm Treatment page (U4-1).
  Future<Map<String, Object?>> getTreatment(int treatmentId) async {
    final treatment = await treatmentModel.getTreatmentDetail(treatmentId, _insuredId);
    if (treatment == null) throw const ControllerException(404, 'There is no treatment with this ID.');
    return treatment;
  }

  /// U4.1 step 4 (QU4.1). Gives the treatment again (Accepted).
  Future<Map<String, Object?>> acceptTreatment(int treatmentId) => db.transaction(() async {
        final t = await getTreatment(treatmentId);
        await treatmentModel.accept(treatmentId, t['claim_id']! as int, _insuredId);
        return getTreatment(treatmentId);
      });

  /// U4.2 step 2 (QU4.5): the dates of "Choose another date".
  Future<List<Map<String, Object?>>> getAvailableDates(int treatmentId) async {
    await getTreatment(treatmentId);
    return treatmentModel.getAvailableDates(treatmentId, _insuredId);
  }

  /// U4.2 step 4 (QU4.2). Gives the treatment with the new date (Accepted).
  Future<Map<String, Object?>> changeDate(int treatmentId, String newDate) {
    if (!_date.hasMatch(newDate) || DateTime.tryParse(newDate) == null) {
      throw const FormatException('new_date must be yyyy-MM-dd');
    }
    return db.transaction(() async {
      await treatmentModel.changeDate(await getTreatment(treatmentId), newDate, _insuredId);
      return getTreatment(treatmentId);
    });
  }

  /// U4.3 step 3 (QU4.3), called by [AutoCancelJob] without a session.
  Future<int> cancelUnacceptedTreatments() => treatmentModel.cancelExpired();

  /// O5.1 steps 1 to 2 (QO5.1): the claims of the Treatment page.
  Future<List<Map<String, Object?>>> getClaimsForTreatment() {
    _officerId;
    return treatmentModel.getClaimsForTreatment();
  }

  /// O5.1 step 2.1 (QO5.2): the start hours of [facility] from [dateFrom] to
  /// [dateTo] for a treatment of [duration] minutes.
  Future<List<Map<String, Object?>>> getAvailableTimes(String facility, int? duration, String dateFrom, String dateTo) {
    final officerId = _officerId;
    if (!_date.hasMatch(dateFrom) || !_date.hasMatch(dateTo) || facility.trim().isEmpty || duration == null) {
      throw const FormatException('facility, duration and from and to (yyyy-MM-dd) are necessary');
    }
    return treatmentModel.getFacilitySlots(facility, duration, dateFrom, dateTo, officerId);
  }

  /// O5.1 step 6.1: QO5.3, then QN.1 "Treatment booked" to the user, in one
  /// transaction. Gives the treatment_id and the treatment time for O5.1-3.
  Future<Map<String, Object?>> bookTreatment(int claimId, int reportId, Map<String, Object?> details) {
    final officerId = _officerId;
    final date = (details['date'] as String?) ?? '';
    final time = (details['time'] as String?) ?? '';
    final duration = details['duration_minutes'];
    if (!_date.hasMatch(date) || !RegExp(r'^\d{2}:\d{2}$').hasMatch(time) || duration is! int) {
      throw const FormatException('date (yyyy-MM-dd), time (HH:mm) and duration_minutes are necessary');
    }
    return db.transaction(() async {
      final booked = await treatmentModel.bookTreatment(claimId, reportId,
          type: (details['treatment_type'] as String?) ?? '',
          duration: duration,
          facility: (details['facility_name'] as String?) ?? '',
          date: date,
          time: time,
          officerId: officerId);
      final when = DateText.dateTime(booked.slotAt);
      // The QN.1 text of O5.1 is the text of Figma U4-5 (D-052).
      await notificationModel.notifyUser(
          claimId, 'Treatment booked', '${details['treatment_type']} on $when. Please accept or choose another date.');
      return {'treatment_id': booked.treatmentId, 'treatment_date': when};
    });
  }

  /// O5.2 step 6.1: QO5.4, then QN.4 to the user, in one transaction. Only a
  /// claim of QO5.1 (409).
  Future<Map<String, Object?>> closeWithoutTreatment(int claimId) {
    final officerId = _officerId;
    return db.transaction(() async {
      if (!(await treatmentModel.getClaimsForTreatment()).any((c) => c['claim_id'] == claimId)) {
        throw const ControllerException(409, 'The claim cannot be closed. Open the page again.');
      }
      await claimModel.closeWithoutTreatment(claimId, officerId: officerId);
      await notificationModel.notifyNoTreatment(claimId);
      return {'claim_status': 'No treatment required'};
    });
  }
}
