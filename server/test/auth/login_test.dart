import 'package:sst_server/auth/session_token.dart';
import 'package:sst_server/auth/user_session.dart';
import 'package:test/test.dart';

import '../support/http.dart';
import '../support/test_db.dart';

void main() {
  final db = useTestDb();

  group('SessionToken', () {
    const session = UserSession(
        accountId: 1, role: Role.user, displayName: 'นาย สมชาย ประเสริฐ', firstName: 'สมชาย', insuredId: 101);
    final tokens = SessionToken('secret');

    test('a token gives back the same session', () {
      final s = tokens.verify(tokens.issue(session))!;
      expect(s.insuredId, 101);
      expect(s.displayName, 'นาย สมชาย ประเสริฐ');
    });

    test('a changed, foreign or expired token is not accepted', () {
      final token = tokens.issue(session);
      expect(tokens.verify('x$token'), isNull);
      expect(SessionToken('other').verify(token), isNull);
      expect(tokens.verify(token, now: DateTime.now().add(const Duration(days: 1))), isNull);
    });
  });

  group('POST /auth/login', () {
    late TestClient client;
    setUp(() => client = TestClient(db));

    test('the seed user signs in to the user app with the national ID', () async {
      final r = await client.login('1103700123456');
      expect(r.status, 200);
      final session = r.json['session'] as Map;
      expect(session['role'], 'USER');
      expect(session['insured_id'], 101);
      expect(session['display_name'], 'นาย สมชาย ประเสริฐ');
    });

    test('the seed officer and consultant sign in to the console', () async {
      final officer = await client.login('kanya.w@sso.go.th', app: 'console');
      expect((officer.json['session'] as Map)['officer_id'], 1);
      expect((officer.json['session'] as Map)['display_name'], 'กัญญา วงศ์ศิริ');
      final consultant = await client.login('thana.s@ssorehab.go.th', app: 'console');
      expect((consultant.json['session'] as Map)['display_name'], 'นพ. ธนา ศรีสุข');
    });

    test('a wrong password or a role from the other app gives 401', () async {
      expect((await client.login('1103700123456', password: 'Wrong1234')).status, 401);
      expect((await client.login('kanya.w@sso.go.th')).status, 401);
      expect((await client.login('1103700123456', app: 'console')).status, 401);
    });

    test('GET /auth/me needs a valid token', () async {
      expect((await client.get('/auth/me')).status, 401);
      await client.login('1103700123456');
      expect((await client.get('/auth/me')).status, 200);
    });
  });
}
