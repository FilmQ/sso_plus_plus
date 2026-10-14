import 'repository.dart';
import 'sql/treatment_sql.dart';

/// Table Treatment (U4, U6, O5.1).
class TreatmentRepository extends Repository {
  TreatmentRepository(super.db);

  final String table = 'Treatment';

  // QU4.1 [U4.1] Gives 0 when the treatment is not Pending.
  Future<int> updateStatusAccepted(int treatmentId, int claimId) =>
      execute(TreatmentSql.qU4_1, {'treatment_id': treatmentId, 'claim_id': claimId});

  // QU4.2 [U4.2] Gives 0 when the treatment is not Pending.
  Future<int> updateScheduledDate(int treatmentId, int claimId, String newDate) =>
      execute(TreatmentSql.qU4_2, {
        'current_treatment_id': treatmentId,
        'current_claim_id': claimId,
        'new_date': newDate,
      });

  // QU4.3 [U4.3] Gives the number of cancelled treatments (one message for each).
  Future<int> cancelExpiredAndNotifyUser() => execute(TreatmentSql.qU4_3);

  // Q6.1 [U6]
  Future<List<Row>> findUpcomingTreatments(int insuredId) async =>
      (await query(TreatmentSql.q6_1, {'insured_id': insuredId})).rows;

  // QO5.1 [O5.1]
  Future<List<Row>> findClaimsWithFiledReport() async => (await query(TreatmentSql.qO5_1)).rows;

  // QO5.2 [O5.1] Hours 09:00 to 16:00 from [dateFrom] to [dateTo], with slot_state.
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
    required String facilityName,
    required String scheduledDate,
    required String scheduledTime,
  }) async {
    final rs = await query(TreatmentSql.qO5_3, {
      'claim_id': claimId,
      'report_id': reportId,
      'officer_id': officerId,
      'treatment_type': treatmentType,
      'facility_name': facilityName,
      'scheduled_date': scheduledDate,
      'scheduled_time': scheduledTime,
    });
    return rs.rows.single['treatment_id'] as int;
  }
}
