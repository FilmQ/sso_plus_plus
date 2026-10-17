import '../auth/user_session.dart';
import '../db/db_connector.dart';
import '../model/treatment_model.dart';
import 'controller.dart';

/// U4.1 Accept Case, U4.2 Change Date, U4.3 Reject and U6 View Treatment
/// Schedule (SA report 2.13, sequences U4.1 to U4.3 and U6).
///
/// The page sends the treatment_id. The controller finds the treatment with
/// Q6.1, which checks that it belongs to the signed-in user, and takes the
/// claim_id from that row (D-041).
class TreatmentController extends Controller {
  TreatmentController(super.session, this.db, this.treatmentModel);

  final DBConnector db;
  final TreatmentModel treatmentModel;

  int get _insuredId => requireRole(Role.user).insuredId!;

  static final _date = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  /// U6 step 2 (Q6.1): the Treatments tab of the Schedule Page.
  Future<List<Map<String, Object?>>> getTreatmentSchedule() => treatmentModel.getUpcomingTreatments(_insuredId);

  /// The Confirm Treatment page (U4-1): one Q6.1 row.
  Future<Map<String, Object?>> getTreatment(int treatmentId) async {
    final treatment = await treatmentModel.getTreatment(treatmentId, _insuredId);
    if (treatment == null) throw const ControllerException(404, 'There is no upcoming treatment with this ID.');
    return treatment;
  }

  /// U4.1 step 2 (QU4.1). Gives the treatment again (Accepted).
  Future<Map<String, Object?>> acceptTreatment(int treatmentId) => db.transaction(() async {
        final t = await getTreatment(treatmentId);
        await treatmentModel.accept(treatmentId, t['claim_id']! as int);
        return getTreatment(treatmentId);
      });

  /// U4.2 step 2 (showAvailableDates, QO5.2).
  Future<List<String>> getAvailableDates(int treatmentId) async =>
      treatmentModel.getAvailableDates(await getTreatment(treatmentId));

  /// U4.2 step 4 (QU4.2). Gives the treatment with the new date (still Pending).
  Future<Map<String, Object?>> changeDate(int treatmentId, String newDate) {
    if (!_date.hasMatch(newDate) || DateTime.tryParse(newDate) == null) {
      throw const FormatException('new_date must be yyyy-MM-dd');
    }
    return db.transaction(() async {
      await treatmentModel.changeDate(await getTreatment(treatmentId), newDate);
      return getTreatment(treatmentId);
    });
  }

  /// U4.3 step 3 (QU4.3), called by [AutoCancelJob] without a session.
  Future<int> cancelUnacceptedTreatments() => treatmentModel.cancelExpired();
}
