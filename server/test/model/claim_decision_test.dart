import 'package:sst_server/model/claim_model.dart';
import 'package:sst_server/model/model.dart';
import 'package:sst_server/repository/claim_repository.dart';
import 'package:sst_server/storage/file_storage.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../support/test_db.dart';

/// R-012: since the 2026-10-15 pack, QO2.1, QO3.1 and QO3.2 decide only a claim
/// that is not yet decided. ClaimModel turns a 0-row result into a 409.
void main() {
  final db = useTestDb();
  final claims = ClaimRepository(db);
  final model = ClaimModel(claims, LocalFileStorage('build/unused'));

  Future<String> status(int id) async => (await db.performQuery(
          'SELECT claim_status FROM InjuryClaim WHERE claim_id = :id', {'id': id}))
      .rows
      .single['claim_status']! as String;

  test('QO2.1/QO3.1 guard: an Awaiting verification claim can be approved one time only', () => inRollback(db, () async {
        final id = await insertTestClaim(claims);
        await model.confirmResult(id, officerId: 1);
        expect(await status(id), 'Covered');
        await expectLater(model.confirmResult(id, officerId: 1), throwsA(isA<StateConflictException>()));
      }));

  test('QO2.1/QO3.1 guard: a Register unavailable claim can be rejected (Not covered, then Rejected)', () => inRollback(db, () async {
        final id = await insertTestClaim(claims, result: 'Register unavailable');
        await model.rejectApplication(id, officerId: 1, reasonCode: 'R01', officerMessage: 'Not in the register');
        expect(await status(id), 'Rejected');
      }));

  test('QO2.1/QO3.1 guard: decided claims are refused and do not change', () => inRollback(db, () async {
        for (final (id, was) in [(143, 'Covered'), (151, 'Rejected'), (147, 'No treatment required')]) {
          await expectLater(model.confirmResult(id, officerId: 1), throwsA(isA<StateConflictException>()));
          await expectLater(model.rejectApplication(id, officerId: 1, reasonCode: 'R02'),
              throwsA(isA<StateConflictException>()));
          expect(await status(id), was);
        }
        final checks = await db.performQuery(
            'SELECT COUNT(*) AS n FROM EligibilityCheck WHERE claim_id IN (143, 151, 147)');
        expect(checks.rows.single['n'], 4, reason: 'no new EligibilityCheck rows');
      }));

  test('R-013 (settled): a claim without the automatic check can be decided', () => inRollback(db, () async {
        final id = await insertTestClaim(claims);
        await db.performQuery('DELETE FROM EligibilityCheck WHERE claim_id = :id', {'id': id});
        await model.confirmResult(id, officerId: 1);
        expect(await status(id), 'Covered');
        final check = await db.performQuery(
            'SELECT coverage_id, is_override FROM EligibilityCheck WHERE claim_id = :id AND officer_id = 1', {'id': id});
        expect(check.rows.single, {'coverage_id': null, 'is_override': false});
      }));
}
