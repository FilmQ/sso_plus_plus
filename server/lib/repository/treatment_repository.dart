import 'repository.dart';
import 'sql/treatment_sql.dart';

/// Table Treatment (U4, U6, O5.1).
class TreatmentRepository extends Repository {
  TreatmentRepository(super.db);

  final String table = 'Treatment';

  // QU4.4 [U4.1, U4.2] One treatment of the user with the page data, or null.
  Future<Row?> findTreatmentDetail(int treatmentId, int insuredId) async =>
      (await query(TreatmentSql.qU4_4, {'treatment_id': treatmentId, 'insured_id': insuredId})).rows.firstOrNull;

  // QU4.1 [U4.1] Only a Pending treatment of the user. Else NoRowChangedException.
  Future<void> updateStatusAccepted(int treatmentId, int claimId, int insuredId) => guarded('QU4.1',
      TreatmentSql.qU4_1, {'treatment_id': treatmentId, 'claim_id': claimId, 'insured_id': insuredId});

  // QU4.5 [U4.2] The free weekdays (slot_date, date_label) of a Pending treatment of the user.
  Future<List<Row>> findAvailableDates(int treatmentId, int insuredId) async =>
      (await query(TreatmentSql.qU4_5, {'treatment_id': treatmentId, 'insured_id': insuredId})).rows;

  // QU4.2 [U4.2] Saves the new date and sets Accepted. Only a Pending treatment
  // of the user and a date of QU4.5. Else NoRowChangedException.
  Future<void> updateScheduledDate(int treatmentId, int claimId, String newDate, int insuredId) =>
      guarded('QU4.2', TreatmentSql.qU4_2, {
        'treatment_id': treatmentId,
        'claim_id': claimId,
        'new_date': newDate,
        'insured_id': insuredId,
      });

  // QU4.3 [U4.3] Gives the number of cancelled treatments (one message for each).
  // Their Covered claims become Withdrawn.
  Future<int> cancelExpiredAndNotifyUser() => execute(TreatmentSql.qU4_3);

  // Q6.1 [U6]
  Future<List<Row>> findUpcomingTreatments(int insuredId) async =>
      (await query(TreatmentSql.q6_1, {'insured_id': insuredId})).rows;

  // QO5.1 [O5.1]
  Future<List<Row>> findClaimsWithFiledReport() async => (await query(TreatmentSql.qO5_1)).rows;

  // QO5.2 [O5.1] Hours 09:00 to 16:00 of the weekdays from [dateFrom] to [dateTo], with slot_state.
  Future<List<Row>> findFacilitySlots({
    required String facilityName,
    required String dateFrom,
    required String dateTo,
    required int officerId,
  }) async =>
      (await query(TreatmentSql.qO5_2, {
        'facility_name': facilityName,
        'date_from': dateFrom,
        'date_to': dateTo,
        'officer_id': officerId,
      }))
          .rows;

  // QO5.3 [O5.1] Gives the new treatment_id.
  Future<int> insertTreatment({
    required int claimId,
    required int reportId,
    required int officerId,
    required String treatmentType,
    required int durationMinutes,
    required String facilityName,
    required String scheduledDate,
    required String scheduledTime,
  }) async {
    final rs = await query(TreatmentSql.qO5_3, {
      'claim_id': claimId,
      'report_id': reportId,
      'officer_id': officerId,
      'treatment_type': treatmentType,
      'duration_minutes': durationMinutes,
      'facility_name': facilityName,
      'scheduled_date': scheduledDate,
      'scheduled_time': scheduledTime,
    });
    return rs.rows.single['treatment_id'] as int;
  }
}
