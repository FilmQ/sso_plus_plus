import 'dart:typed_data';

import 'package:sst_server/repository/claim_repository.dart';
import 'package:sst_server/storage/file_storage.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../support/http.dart';
import '../support/test_db.dart';

/// O1 to O3 through the HTTP routes. The seed has no claim to verify, so each
/// test adds one for person 105 (insertTestClaim) with one stored document.
void main() {
  final db = useTestDb();
  final claims = ClaimRepository(db);
  const storageDir = 'build/test-storage';
  final storage = LocalFileStorage(storageDir);
  final pdf = Uint8List.fromList('%PDF-1.4 test'.codeUnits);

  Future<int> pendingClaim({String result = 'Covered'}) async {
    final id = await insertTestClaim(claims, result: result);
    await claims.insertDocument(
      claimId: id,
      docTypeId: 2,
      fileName: 'medical_record.pdf',
      fileUri: await storage.save(id, 'medical_record.pdf', pdf),
      mimeType: 'application/pdf',
      fileSizeBytes: pdf.length,
    );
    return id;
  }

  Future<TestClient> officer() async {
    final c = TestClient(db, storageDir: storageDir);
    await c.login('kanya.w@sso.go.th', app: 'console'); // officer 1
    return c;
  }

  Future<String> status(int id) async => (await db.performQuery(
          'SELECT claim_status FROM InjuryClaim WHERE claim_id = :id', {'id': id}))
      .rows
      .single['claim_status']! as String;

  Future<Map<String, Object?>> lastMessage(int id) async => (await db.performQuery(
          'SELECT subject, body FROM Notification WHERE claim_id = :id ORDER BY notification_id DESC LIMIT 1',
          {'id': id}))
      .rows
      .single;

  test('O1 Normal Case: the Verification Page lists the claim, then the Eligibility Decision Page opens it', () =>
      inRollback(db, () async {
        final covered = await pendingClaim();
        final unavailable = await pendingClaim(result: 'Register unavailable');
        final c = await officer();

        final page = (await c.get('/o1/claims')).json; // QO1.1, QO1.2
        final rows = (page['claims']! as List).cast<Map>();
        expect([for (final r in rows) r['claim_id']], containsAll([covered, unavailable]));
        final row = rows.firstWhere((r) => r['claim_id'] == covered);
        expect(row['verification_status'], 'Awaiting verification');
        expect(row['documents_sent'], 1);
        expect(page['counts'], {'awaiting_verification': 1, 'reviews_needed': 0, 'register_unavailable': 1});

        final detail = (await c.get('/o1/claims/$covered')).json; // QO1.3 to QO1.5
        expect((detail['summary']! as Map)['injury_cause'], 'Slipped on ice');
        expect((detail['documents']! as List).single, containsPair('file_name', 'medical_record.pdf'));
        expect((detail['eligibility']! as Map)['eligibility_status'], 'Covered');
        final noCheck = (await c.get('/o1/claims/$unavailable')).json['eligibility'] as Map;
        expect(noCheck['eligibility_status'], 'Register unavailable');
        expect((await c.get('/o1/claims/999999')).status, 404);
      }));

  test('O1 step 6: View opens the stored file of the claim; another name gives 404', () => inRollback(db, () async {
        final id = await pendingClaim();
        final c = await officer();
        final (code, type, bytes) = await c.getBytes('/o1/claims/$id/documents/medical_record.pdf');
        expect(code, 200);
        expect(type, 'application/pdf');
        expect(bytes, pdf);
        expect((await c.getBytes('/o1/claims/$id/documents/other.pdf')).$1, 404);
        expect((await c.getBytes('/o1/claims/143/documents/id_card_front.jpg')).$1, 404,
            reason: 'the seed files are not in the storage');
      }));

  test('O2 Normal Case: Confirm sets Covered and tells the user (QO2.1, QN.1)', () => inRollback(db, () async {
        final id = await pendingClaim(result: 'Register unavailable');
        final c = await officer();
        final r = await c.post('/o2/claims/$id/confirm', {'override_reason': 'Register checked by phone'});
        expect(r.json, {'claim_status': 'Covered'});
        expect(await status(id), 'Covered');
        final no = (await db.performQuery('SELECT claim_no FROM InjuryClaim WHERE claim_id = :id', {'id': id}))
            .rows
            .single['claim_no'];
        expect(await lastMessage(id),
            {'subject': 'Claim confirmed', 'body': 'Your claim $no is covered under Section 33.'});
        final check = (await db.performQuery(
                'SELECT officer_id, is_override, override_reason FROM EligibilityCheck '
                'WHERE claim_id = :id AND officer_id IS NOT NULL', {'id': id}))
            .rows
            .single;
        expect(check, {'officer_id': 1, 'is_override': true, 'override_reason': 'Register checked by phone'});
        expect((await c.get('/o1/claims')).json['claims'], isNot(contains(containsPair('claim_id', id))));
      }));

  test('O2: a decided claim gives 409 and no second message', () => inRollback(db, () async {
        final c = await officer();
        Future<Object?> count() async =>
            (await db.performQuery('SELECT COUNT(*) AS n FROM Notification WHERE claim_id = 143')).rows.single['n'];
        final before = await count();
        expect((await c.post('/o2/claims/143/confirm', {})).status, 409);
        expect(await count(), before);
      }));

  test('O3 Normal Case: Not Covered with a reason sets Rejected and tells the user (QO3.1, QO3.2, QN.2)', () =>
      inRollback(db, () async {
        final id = await pendingClaim();
        final c = await officer();
        final reasons = ((await c.get('/o3/rejection-reasons')).json['reasons']! as List).cast<Map>(); // QO1.6
        expect([for (final r in reasons) r['reason_code']], ['R01', 'R02', 'R03', 'R04', 'R05']);

        final r = await c.post('/o3/claims/$id/reject',
            {'reason_code': 'R05', 'officer_message': 'The injury happened at home, not at work.'});
        expect(r.json, {'claim_status': 'Rejected'});
        expect(await status(id), 'Rejected');
        final msg = await lastMessage(id);
        expect(msg['subject'], 'Application rejected');
        expect(msg['body'], endsWith('\n\nThe injury happened at home, not at work.'));
        final history = await db.performQuery(
            'SELECT to_status, change_reason FROM ClaimStatusHistory WHERE claim_id = :id AND officer_id = 1 '
            'ORDER BY changed_at, to_status', {'id': id});
        expect([for (final h in history.rows) h['to_status']], containsAll(['Not covered', 'Rejected']));
      }));

  test('O3: a wrong reason or a long message gives 422; a decided claim gives 409', () => inRollback(db, () async {
        final id = await pendingClaim();
        final c = await officer();
        final bad = await c.post('/o3/claims/$id/reject', {'reason_code': 'R99'});
        expect(bad.status, 422);
        expect((bad.json['fields']! as Map).keys, ['reason_code']);
        final long = await c.post('/o3/claims/$id/reject', {'reason_code': 'R01', 'officer_message': 'x' * 1001});
        expect((long.json['fields']! as Map).keys, ['officer_message']);
        expect(await status(id), 'Awaiting verification');
        expect((await c.post('/o3/claims/151/reject', {'reason_code': 'R01'})).status, 409);
      }));

  test('O1 to O3 need an Evaluation Officer (401)', () => inRollback(db, () async {
        final user = TestClient(db);
        await user.login('1100800345672');
        expect((await user.get('/o1/claims')).status, 401);
        expect((await user.post('/o2/claims/143/confirm', {})).status, 401);
        final consultant = TestClient(db);
        expect((await consultant.login('thana.s@ssorehab.go.th', app: 'console')).status, 200);
        expect((await consultant.get('/o1/claims')).status, 401);
      }));
}
