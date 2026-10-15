import 'repository.dart';
import 'sql/claim_sql.dart';

/// Table InjuryClaim and its child tables (U1, O1, O2, O3, O5.2).
class ClaimRepository extends Repository {
  ClaimRepository(super.db);

  final String table = 'InjuryClaim';

  // Q1.6 [U1] Gives the new claim_id. [registerResult] is 'Covered' or 'Register unavailable'.
  Future<int> insertClaim({
    required int insuredId,
    int? employerId,
    required String injuryDatetime,
    required String injuryPlace,
    required String injuryCause,
    required String bodyPart,
    required String injuryCategory,
    required String registerResult,
  }) async {
    final rs = await query(ClaimSql.q1_6, {
      'insured_id': insuredId,
      'employer_id': employerId,
      'injury_datetime': injuryDatetime,
      'injury_place': injuryPlace,
      'injury_cause': injuryCause,
      'body_part': bodyPart,
      'injury_category': injuryCategory,
      'register_result': registerResult,
    });
    return rs.rows.single['claim_id'] as int;
  }

  // Q1.7 [U1] Gives the claim_no (for example SST-2026-000156) and submitted_at.
  Future<({String claimNo, DateTime submittedAt})> assignClaimNo(int claimId) async {
    final row = (await query(ClaimSql.q1_7, {'claim_id': claimId})).rows.single;
    return (claimNo: row['claim_no']! as String, submittedAt: row['submitted_at']! as DateTime);
  }

  // Q1.8 [U1]
  Future<int> insertDocument({
    required int claimId,
    required int docTypeId,
    required String fileName,
    required String fileUri,
    required String mimeType,
    required int fileSizeBytes,
  }) =>
      execute(ClaimSql.q1_8, {
        'claim_id': claimId,
        'doc_type_id': docTypeId,
        'file_name': fileName,
        'file_uri': fileUri,
        'mime_type': mimeType,
        'file_size_bytes': fileSizeBytes,
      });

  // Q1.9 [U1]
  Future<int> insertAutoEligibility({
    required int claimId,
    int? coverageId,
    required String registerResult,
    String? evidenceRef,
  }) =>
      execute(ClaimSql.q1_9, {
        'claim_id': claimId,
        'coverage_id': coverageId,
        'register_result': registerResult,
        'evidence_ref': evidenceRef,
      });

  // Q1.10 [U1]
  Future<int> insertFirstStatus(int claimId) => execute(ClaimSql.q1_10, {'claim_id': claimId});

  // Q2.4 [U2] The claim card of the Home page: the newest claim of the user,
  // with its next appointment and treatment status. Null when there is no claim.
  Future<Row?> findHomeClaim(int insuredId) async =>
      (await query(ClaimSql.q2_4, {'insured_id': insuredId})).firstOrNull;

  // QO1.1 [O1]
  Future<List<Row>> findPendingClaims() async => (await query(ClaimSql.qO1_1)).rows;

  // QO1.2 [O1]
  Future<Row> countByStatus() async => (await query(ClaimSql.qO1_2)).rows.single;

  // QO1.3 [O1]
  Future<Row?> findClaimSummary(int claimId) async =>
      (await query(ClaimSql.qO1_3, {'claim_id': claimId})).firstOrNull;

  // QO1.4 [O1]
  Future<List<Row>> findDocuments(int claimId) async =>
      (await query(ClaimSql.qO1_4, {'claim_id': claimId})).rows;

  // QO1.5 [O1]
  Future<Row?> findAutoEligibility(int claimId) async =>
      (await query(ClaimSql.qO1_5, {'claim_id': claimId})).firstOrNull;

  // QO1.6 [O3]
  Future<List<Row>> findRejectionReasons() async => (await query(ClaimSql.qO1_6)).rows;

  // QO2.1 [O2] when result is 'Covered', QO3.1 [O3] when result is 'Not covered'.
  // Only a claim in 'Awaiting verification', 'Needs review' or 'Register
  // unavailable' changes; else NoRowChangedException (R-013).
  Future<void> saveResult({
    required int claimId,
    required String result,
    required int officerId,
    String? overrideReason,
  }) async {
    final covered = result == 'Covered';
    await guarded(covered ? 'QO2.1' : 'QO3.1', covered ? ClaimSql.qO2_1 : ClaimSql.qO3_1, {
      'claim_id': claimId,
      'result': result,
      'officer_id': officerId,
      'override_reason': overrideReason,
    });
  }

  // QO3.2 [O3] Only a claim that is not yet decided or is 'Not covered'.
  Future<void> insertRejection({
    required int claimId,
    required String reasonCode,
    required int officerId,
    String? officerMessage,
  }) =>
      guarded('QO3.2', ClaimSql.qO3_2, {
        'claim_id': claimId,
        'reason_code': reasonCode,
        'officer_id': officerId,
        'officer_message': officerMessage,
      });

  // QO5.4 [O5.2] Only a 'Covered' claim.
  Future<void> updateNoTreatment({required int claimId, required int officerId}) =>
      guarded('QO5.4', ClaimSql.qO5_4, {'claim_id': claimId, 'officer_id': officerId});
}
