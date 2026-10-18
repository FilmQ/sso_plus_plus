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

  /// QO5.1 (O5.1 step 2): the Covered claims with a filed report and no
  /// Pending or Accepted treatment.
  Future<List<Map<String, Object?>>> getClaimsForTreatment() => treatments.findClaimsWithFiledReport();

  /// QO5.2 (O5.1 step 2.1): the hours 09:00 to 16:00 of the weekdays from
  /// [dateFrom] to [dateTo], after now, with slot_state free, mine or busy.
  Future<List<Map<String, Object?>>> getFacilitySlots(String facility, String dateFrom, String dateTo, int officerId) =>
      treatments.findFacilitySlots(facilityName: facility, dateFrom: dateFrom, dateTo: dateTo, officerId: officerId);

  /// QO5.3 (O5.1 step 6.1). QO5.3 checks nothing, so the Model first checks
  /// (D-052): the fields (422), the claim and report are in QO5.1 (409) and
  /// the hour is 'free' at the facility in QO5.2 (409). Gives the
  /// treatment_id and the slot.
  Future<({int treatmentId, DateTime slotAt})> bookTreatment(int claimId, int reportId,
      {required String type,
      required int duration,
      required String facility,
      required String date,
      required String time,
      required int officerId}) async {
    final errors = {
      if (type.trim().isEmpty || type.length > 80) 'treatment_type': 'Choose a treatment type.',
      if (duration <= 0) 'duration_minutes': 'Choose a duration.',
      if (facility.trim().isEmpty || facility.length > 160) 'facility_name': 'Choose a facility.',
    };
    if (errors.isNotEmpty) throw ValidationFailedException(errors);
    if (!(await getClaimsForTreatment()).any((c) => c['claim_id'] == claimId && c['report_id'] == reportId)) {
      throw const StateConflictException('The claim cannot be booked. Open the page again.');
    }
    final slot = (await getFacilitySlots(facility, date, date, officerId)).where((s) {
      final at = s['slot_at']! as DateTime;
      return '${_two(at.hour)}:${_two(at.minute)}' == time;
    }).firstOrNull;
    if (slot == null || slot['slot_state'] != 'free') {
      throw const StateConflictException('This time is not free any more. Choose another time.');
    }
    final id = await treatments.insertTreatment(
      claimId: claimId,
      reportId: reportId,
      officerId: officerId,
      treatmentType: type.trim(),
      durationMinutes: duration,
      facilityName: facility.trim(),
      scheduledDate: date,
      scheduledTime: time,
    );
    return (treatmentId: id, slotAt: slot['slot_at']! as DateTime);
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// QU4.3 (U4.3): cancels each Pending treatment on or before today, tells
  /// its user and closes its claim (Withdrawn). Gives the number of
  /// cancelled treatments.
  Future<int> cancelExpired() => treatments.cancelExpiredAndNotifyUser();
}
