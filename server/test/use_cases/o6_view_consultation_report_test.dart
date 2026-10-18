import 'package:test/test.dart';

import '../support/http.dart';
import '../support/test_db.dart';

/// O6 through the HTTP routes, with the 3 filed seed reports (85 and 86
/// viewed, 87 not viewed).
void main() {
  final db = useTestDb();

  Future<TestClient> officer() async {
    final c = TestClient(db);
    await c.login('kanya.w@sso.go.th', app: 'console'); // officer 1
    return c;
  }

  test('O6 Normal Case: the list, the report page, then View; the report becomes Viewed', () =>
      inRollback(db, () async {
        final c = await officer();
        final list = ((await c.get('/o6/reports')).json['reports']! as List).cast<Map>(); // QO6.1
        expect([for (final r in list) r['report_id']], [87, 86, 85], reason: 'not viewed first');
        expect(list.first['view_status'], 'Pending');

        final page = (await c.get('/o6/reports/87')).json['report'] as Map; // QO6.2
        expect(page['claim_no'], 'SST-2026-000143');
        expect(page['signature_status'], 'Signature signed');
        expect(page['view_status'], 'Pending');
        expect(page['report_content'], startsWith('Closed fracture of the distal radius'));
        expect(page['user_age'], isA<int>());

        final viewed = (await c.post('/o6/reports/87/view')).json['report'] as Map; // QO6.3
        expect(viewed['view_status'], 'Viewed');
        final again = await c.post('/o6/reports/87/view');
        expect(again.status, 200, reason: 'a second view changes nothing');
        final after = ((await c.get('/o6/reports')).json['reports']! as List).cast<Map>();
        expect(after.every((r) => r['view_status'] == 'Viewed'), isTrue);
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
