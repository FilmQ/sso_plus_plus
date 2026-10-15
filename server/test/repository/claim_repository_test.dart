import 'package:sst_server/repository/claim_repository.dart';
import 'package:sst_server/repository/repository.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../support/test_db.dart';

void main() {
  final db = useTestDb();
  final repo = ClaimRepository(db);

  Future<Row> claimRow(int id) async =>
      (await db.performQuery('SELECT * FROM InjuryClaim WHERE claim_id = :id', {'id': id})).rows.single;

  test('Q1.6 insertClaim: status from the register result', () => inRollback(db, () async {
        final covered = await insertTestClaim(repo);
        final unavailable = await insertTestClaim(repo, result: 'Register unavailable');
        expect((await claimRow(covered))['claim_status'], 'Awaiting verification');
        expect((await claimRow(unavailable))['claim_status'], 'Register unavailable');
      }));

  test('Q1.7 assignClaimNo: SST-<year>-<6 digits>, and submitted_at', () => inRollback(db, () async {
        final id = await insertTestClaim(repo);
        final r = await repo.assignClaimNo(id);
        expect(r.claimNo, matches(RegExp(r'^SST-\d{4}-\d{6}$')));
        expect(r.claimNo, endsWith(id.toString().padLeft(6, '0')));
        expect(r.claimNo, contains('SST-${r.submittedAt.year}-'));
      }));

  test('Q2.4 findHomeClaim: claim card, next appointment and treatment of person 101', () async {
    final row = await repo.findHomeClaim(101);
    expect(row, containsPair('claim_no', 'SST-2026-000143'));
    expect(row, containsPair('first_name', 'สมชาย'));
    expect(row, containsPair('officer_checked_time', '5 October 2026 : 09:15'));
    expect(row, containsPair('appointment_status', 'Confirmed'));
    expect(row, containsPair('appointment_time', '16 October 2026 : 10:00'));
    expect(row, containsPair('consultant_name', 'นพ. ธนา ศรีสุข'));
    expect(row, containsPair('treatment_status', 'Accepted'));
    expect(await repo.findHomeClaim(999), isNull);
  });

  test('Q1.8 insertDocument adds one Pending document', () => inRollback(db, () async {
        final id = await insertTestClaim(repo);
        final n = await repo.insertDocument(
          claimId: id,
          docTypeId: 1,
          fileName: 'id.jpg',
          fileUri: '/claims/$id/id.jpg',
          mimeType: 'image/jpeg',
          fileSizeBytes: 1000,
        );
        expect(n, 1);
        expect(await repo.findDocuments(id), hasLength(1));
      }));

  test('Q1.9 insertAutoEligibility adds an automatic check (officer_id NULL)', () => inRollback(db, () async {
        final id = await insertTestClaim(repo);
        expect(await repo.findAutoEligibility(id), containsPair('eligibility_status', 'Covered'));
      }));

  test('Q1.10 insertFirstStatus copies the claim status into the history', () => inRollback(db, () async {
        final id = await insertTestClaim(repo);
        final rs = await db.performQuery('SELECT * FROM ClaimStatusHistory WHERE claim_id = :id', {'id': id});
        expect(rs.rows.single['to_status'], 'Awaiting verification');
        expect(rs.rows.single['change_reason'], 'Submitted by the user');
      }));

  test('QO1.1 findPendingClaims: the seed has none; a new claim is listed', () => inRollback(db, () async {
        expect(await repo.findPendingClaims(), isEmpty);
        final id = await insertTestClaim(repo);
        final rows = await repo.findPendingClaims();
        expect(rows.single['claim_id'], id);
        expect(rows.single['claimant_name'], 'นาย ชัยวัฒน์ สุขเจริญ');
      }));

  test('QO1.2 countByStatus counts the three waiting statuses', () => inRollback(db, () async {
        await insertTestClaim(repo, result: 'Register unavailable');
        final counts = await repo.countByStatus();
        expect(counts, {'awaiting_verification': 0, 'reviews_needed': 0, 'register_unavailable': 1});
      }));

  test('QO1.3 findClaimSummary of SST-2026-000143', () async {
    final row = await repo.findClaimSummary(143);
    expect(row, containsPair('user_name', 'สมชาย ประเสริฐ'));
    expect(row, containsPair('employer_on_claim', 'Siam Precision Parts Co., Ltd.'));
    expect(row, containsPair('date_of_injury', '28 September 2026'));
  });

  test('QO1.4 findDocuments of claim 143: 3 files', () async {
    final rows = await repo.findDocuments(143);
    expect(rows.map((r) => r['file_name']), ['id_card_front.jpg', 'medical_record_rama.pdf', 'injury_form_kt16.pdf']);
    expect(rows.first['file_size'], '1229 kB');
  });

  test('QO1.5 findAutoEligibility of claim 143', () async {
    final row = await repo.findAutoEligibility(143);
    expect(row, containsPair('eligibility_status', 'Covered'));
    expect(row, containsPair('contribution_period', '1 June 2019 - present'));
    expect(row, containsPair('sso_account_no', '1000123456'));
  });

  test('QO1.6 findRejectionReasons: R01 to R05', () async {
    expect((await repo.findRejectionReasons()).map((r) => r['reason_code']), ['R01', 'R02', 'R03', 'R04', 'R05']);
  });

  test('QO2.1 saveResult Covered: officer check, history and status', () => inRollback(db, () async {
        final id = await insertTestClaim(repo);
        await repo.saveResult(claimId: id, result: 'Covered', officerId: 1);
        expect((await claimRow(id))['claim_status'], 'Covered');
        final checks = await db.performQuery(
            'SELECT is_override FROM EligibilityCheck WHERE claim_id = :id AND officer_id = 1', {'id': id});
        expect(checks.rows.single['is_override'], false);
      }));

  test('QO3.1 saveResult Not covered: status Not covered, is_override TRUE', () => inRollback(db, () async {
        final id = await insertTestClaim(repo);
        await repo.saveResult(claimId: id, result: 'Not covered', officerId: 1, overrideReason: 'R02');
        expect((await claimRow(id))['claim_status'], 'Not covered');
        final checks = await db.performQuery(
            'SELECT is_override FROM EligibilityCheck WHERE claim_id = :id AND officer_id = 1', {'id': id});
        expect(checks.rows.single['is_override'], true);
      }));

  test('QO3.2 insertRejection: status Rejected; a Rejected claim cannot be rejected again', () => inRollback(db, () async {
        final id = await insertTestClaim(repo);
        await repo.saveResult(claimId: id, result: 'Not covered', officerId: 1);
        await repo.insertRejection(claimId: id, reasonCode: 'R02', officerId: 1, officerMessage: 'Test');
        expect((await claimRow(id))['claim_status'], 'Rejected');
        await expectLater(
          repo.insertRejection(claimId: id, reasonCode: 'R02', officerId: 1),
          throwsA(isA<NoRowChangedException>()),
        );
      }));

  test('QO5.4 updateNoTreatment: only a Covered claim', () => inRollback(db, () async {
        await repo.updateNoTreatment(claimId: 155, officerId: 1);
        expect((await claimRow(155))['claim_status'], 'No treatment required');
        await expectLater(repo.updateNoTreatment(claimId: 151, officerId: 1), throwsA(isA<NoRowChangedException>()));
      }));
}
