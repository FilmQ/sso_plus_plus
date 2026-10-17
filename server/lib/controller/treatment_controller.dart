import '../auth/user_session.dart';
import '../db/db_connector.dart';
import '../model/treatment_model.dart';
import 'controller.dart';

/// U4.1 Accept Case, U4.2 Change Date, U4.3 Reject and U6 View Treatment
/// Schedule (SA report 2.13, sequences U4.1 to U4.3 and U6).
///
/// The page sends the treatment_id. The controller reads the treatment with
/// QU4.4, which checks that it belongs to the signed-in user, and takes the
/// claim_id from that row. QU4.1 and QU4.2 check the owner again (D-041).
class TreatmentController extends Controller {
  TreatmentController(super.session, this.db, this.treatmentModel);

  final DBConnector db;
  final TreatmentModel treatmentModel;

  int get _insuredId => requireRole(Role.user).insuredId!;

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
}
