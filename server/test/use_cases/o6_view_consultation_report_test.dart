import 'dart:typed_data';

import 'package:sst_server/storage/file_storage.dart';
import 'package:test/test.dart';

import '../support/http.dart';
import '../support/test_db.dart';

/// O6 through the HTTP routes, with the 3 filed seed reports (85 and 86
/// viewed, 87 not viewed).
void main() {
  final db = useTestDb();
  const storageDir = 'build/test-storage';

  Future<TestClient> officer() async {
    final c = TestClient(db, storageDir: storageDir);
    await c.login('kanya.w@sso.go.th', app: 'console'); // officer 1
    return c;
  }

  test('O6 Normal Case: the list, the report page, then View; the report becomes Viewed', () =>
      inRollback(db, () async {
        final c = await officer();
        final list = ((await c.get('/o6/reports')).json['reports']! as List).cast<Map>(); // QO6.1
        expect([for (final r in list) r['report_id']], [87, 90, 86, 85], reason: 'not viewed first');
        expect(list.first['view_status'], 'Pending');

        final page = (await c.get('/o6/reports/87')).json['report'] as Map; // QO6.2
        expect(page['claim_no'], 'SST-2026-000143');
        expect(page['signature_status'], 'Signature signed');
        expect(page['view_status'], 'Pending');
        expect(page['report_content'], startsWith('กระดูกเรเดียสส่วนปลาย'));
        expect(page['user_age'], isA<int>());
        expect(page['recommended_treatment'], 'Physiotherapy', reason: 'Table 2-66 (D-063)');

        final viewed = (await c.post('/o6/reports/87/view')).json['report'] as Map; // QO6.3
        expect(viewed['view_status'], 'Viewed');
        expect(viewed['recommended_treatment'], 'Physiotherapy', reason: 'the page keeps the row after View');
        final again = await c.post('/o6/reports/87/view');
        expect(again.status, 200, reason: 'a second view changes nothing');
        expect(viewed['viewed_at'], matches(RegExp(r'^\d{1,2} [A-Z][a-z]+ \d{4} : \d{2}:\d{2}$')));
        final after = ((await c.get('/o6/reports')).json['reports']! as List).cast<Map>();
        expect(after.firstWhere((r) => r['report_id'] == 87)['view_status'], 'Viewed');
      }));

  test('O6 Alternate Case 1 [File]: a report that is a file opens the file', () => inRollback(db, () async {
        final uri = await LocalFileStorage(storageDir)
            .save(162, 'report_90.pdf', Uint8List.fromList('%PDF-1.4 report'.codeUnits));
        await db.performQuery(
            'UPDATE ConsultationReport SET report_content = NULL, report_file_uri = :uri WHERE report_id = 90',
            {'uri': uri});
        final c = await officer();
        final page = (await c.get('/o6/reports/90')).json['report'] as Map;
        expect(page['report_file_uri'], uri);
        expect(page['report_content'], isNull);
        final (code, type, bytes) = await c.getBytes('/o6/reports/90/file');
        expect(code, 200);
        expect(type, 'application/pdf');
        expect(String.fromCharCodes(bytes), '%PDF-1.4 report');
        expect((await c.getBytes('/o6/reports/87/file')).$1, 404, reason: 'report 87 is text');
      }));

  test('O6: a report that is not filed gives 404', () => inRollback(db, () async {
        await db.performQuery('UPDATE ConsultationReport SET delivered_at = NULL WHERE report_id = 87');
        final c = await officer();
        expect((await c.get('/o6/reports/87')).status, 404);
        expect((await c.post('/o6/reports/87/view')).status, 404);
        expect((await c.get('/o6/reports/999')).status, 404);
      }));

  test('O6 needs an Evaluation Officer (401)', () async {
    final user = TestClient(db);
    await user.login('1100800345672');
    expect((await user.get('/o6/reports')).status, 401);
  });
}
