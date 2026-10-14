import 'package:sst_server/db/db_connector.dart';
import 'package:test/test.dart';

import '../support/test_db.dart';

void main() {
  final db = useTestDb();

  test('the seed is loaded and the time zone is Asia/Bangkok', () async {
    final claims = await db.performQuery('SELECT COUNT(*) AS n FROM InjuryClaim');
    expect(claims.rows.single['n'], 5);
    final tz = await db.performQuery('SHOW timezone');
    expect(tz.rows.single.values.single, 'Asia/Bangkok');
  });

  test('a transaction with rollbackOnly does not keep its changes', () async {
    await db.transaction(() async {
      await db.performQuery('DELETE FROM ClaimStatusHistory');
      final rs = await db.performQuery('SELECT COUNT(*) AS n FROM ClaimStatusHistory');
      expect(rs.rows.single['n'], 0);
    }, rollbackOnly: true);
    final rs = await db.performQuery('SELECT COUNT(*) AS n FROM ClaimStatusHistory');
    expect(rs.rows.single['n'], 5);
  });

  test('an error in the body rolls the transaction back', () async {
    await expectLater(
      db.transaction(() async {
        await db.performQuery('DELETE FROM ClaimStatusHistory');
        throw StateError('stop');
      }),
      throwsStateError,
    );
    final rs = await db.performQuery('SELECT COUNT(*) AS n FROM ClaimStatusHistory');
    expect(rs.rows.single['n'], 5);
  });

  test('a transaction inside a transaction joins the outer one', () async {
    await db.transaction(() async {
      await db.transaction(() => db.performQuery('DELETE FROM ClaimStatusHistory'));
    }, rollbackOnly: true);
    final rs = await db.performQuery('SELECT COUNT(*) AS n FROM ClaimStatusHistory');
    expect(rs.rows.single['n'], 5);
  });

  test('performQuery gives affectedRows', () async {
    final rs = await inRollback(db, () => db.performQuery(
        'UPDATE Notification SET read_at = NOW() WHERE insured_id = :id', {'id': 101}));
    expect(rs, isA<ResultSet>());
    expect(rs.affectedRows, 2);
  });
}
