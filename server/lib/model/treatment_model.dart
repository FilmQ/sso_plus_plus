import '../repository/treatment_repository.dart';
import 'date_text.dart';
import 'model.dart';

/// Treatment (SA report 2.18, used in U4.1, U4.2, U4.3, U6, O5.1).
class TreatmentModel extends Model {
  TreatmentModel(this.treatments);

  final TreatmentRepository treatments;

  /// Q6.1 (U6): the Pending and Accepted treatments from today on.
  Future<List<Map<String, Object?>>> getUpcomingTreatments(int insuredId) =>
      treatments.findUpcomingTreatments(insuredId);

  /// QU4.4 (U4.1 steps 1 to 2): one treatment of the user, or null.
  Future<Map<String, Object?>?> getTreatmentDetail(int treatmentId, int insuredId) =>
      treatments.findTreatmentDetail(treatmentId, insuredId);

  /// QU4.1 (U4.1). Only a Pending treatment of the user; else
  /// NoRowChangedException (409).
  Future<void> accept(int treatmentId, int claimId, int insuredId) =>
      treatments.updateStatusAccepted(treatmentId, claimId, insuredId);

  /// QU4.5 (U4.2 step 2): the free weekdays, each as slot_date ('yyyy-MM-dd')
  /// and date_label (for example 'Tue 27 October 2026').
  Future<List<Map<String, Object?>>> getAvailableDates(int treatmentId, int insuredId) async => [
        for (final row in await treatments.findAvailableDates(treatmentId, insuredId))
          {'slot_date': DateText.iso(row['slot_date']! as DateTime), 'date_label': row['date_label']},
      ];

  /// QU4.2 (U4.2 step 4): saves the new date and sets Accepted. For a Pending
  /// treatment, a date that QU4.5 does not give is a validation error (422);
  /// other refusals of QU4.2 are NoRowChangedException (409) (D-046).
  Future<void> changeDate(Map<String, Object?> treatment, String newDate, int insuredId) async {
    final treatmentId = treatment['treatment_id']! as int;
    if (treatment['treatment_status'] == 'Pending' &&
        !(await getAvailableDates(treatmentId, insuredId)).any((d) => d['slot_date'] == newDate)) {
      throw const ValidationFailedException({'new_date': 'Choose one of the available dates.'});
    }
    await treatments.updateScheduledDate(treatmentId, treatment['claim_id']! as int, newDate, insuredId);
  }

  /// QU4.3 (U4.3): cancels each Pending treatment on or before today, tells
  /// its user and closes its claim (Withdrawn). Gives the number of
  /// cancelled treatments.
  Future<int> cancelExpired() => treatments.cancelExpiredAndNotifyUser();
}
