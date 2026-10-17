import '../repository/treatment_repository.dart';
import 'date_text.dart';
import 'model.dart';

/// Treatment (SA report 2.18, used in U4.1, U4.2, U4.3, U6, O5.1).
class TreatmentModel extends Model {
  TreatmentModel(this.treatments);

  final TreatmentRepository treatments;

  /// U4.2: the user can choose a date up to this many days after the booked
  /// date (D-042).
  static const changeWindowDays = 14;

  /// Q6.1 (U6): the Pending and Accepted treatments from today on.
  Future<List<Map<String, Object?>>> getUpcomingTreatments(int insuredId) =>
      treatments.findUpcomingTreatments(insuredId);

  /// One Q6.1 row of the user, or null. Q6.1 has the user's insured_id, so a
  /// user cannot read the treatment of another claim (D-041).
  Future<Map<String, Object?>?> getTreatment(int treatmentId, int insuredId) async =>
      (await getUpcomingTreatments(insuredId)).where((t) => t['treatment_id'] == treatmentId).firstOrNull;

  /// QU4.1 (U4.1). Only a Pending treatment; else NoRowChangedException (409).
  Future<void> accept(int treatmentId, int claimId) => treatments.updateStatusAccepted(treatmentId, claimId);

  /// U4.2 step 2 (showAvailableDates), from a Q6.1 row: the dates ('yyyy-MM-dd')
  /// from tomorrow to [changeWindowDays] days after the booked date on which
  /// the facility is free at the same hour. It uses QO5.2 of O5.1, because U4.2
  /// has no query of its own (D-042). Officer 0 does not exist, so every booked
  /// hour is 'busy'.
  Future<List<String>> getAvailableDates(Map<String, Object?> treatment, {DateTime? today}) async {
    final booked = DateText.parseDateTime(treatment['treatment_date']! as String)!;
    final now = today ?? DateTime.now();
    final rows = await treatments.findFacilitySlots(
      facilityName: treatment['facility_name']! as String,
      dateFrom: DateText.iso(DateTime(now.year, now.month, now.day + 1)),
      dateTo: DateText.iso(DateTime(booked.year, booked.month, booked.day + changeWindowDays)),
      officerId: 0,
    );
    return [
      for (final row in rows)
        if (row['slot_state'] == 'free')
          if (row['slot_at']! as DateTime case final DateTime slot
              when slot.hour == booked.hour && slot.minute == booked.minute)
            if (DateText.iso(slot) != DateText.iso(booked)) DateText.iso(slot),
    ];
  }

  /// QU4.2 (U4.2 step 4). The time stays. QU4.2 does not check that the
  /// facility is free, so the Model accepts only a date of
  /// [getAvailableDates] (422, D-042).
  Future<void> changeDate(Map<String, Object?> treatment, String newDate) async {
    if (!(await getAvailableDates(treatment)).contains(newDate)) {
      throw const ValidationFailedException({'new_date': 'Choose one of the available dates.'});
    }
    await treatments.updateScheduledDate(
        treatment['treatment_id']! as int, treatment['claim_id']! as int, newDate);
  }

  /// QU4.3 (U4.3): cancels each Pending treatment on or before today and
  /// tells its user. Gives the number of cancelled treatments.
  Future<int> cancelExpired() => treatments.cancelExpiredAndNotifyUser();
}
