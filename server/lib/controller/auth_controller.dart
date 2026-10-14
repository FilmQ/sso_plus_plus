import '../auth/session_token.dart';
import '../auth/user_session.dart';
import '../repository/user_account_repository.dart';
import 'controller.dart';

/// Login (infrastructure, D-003). Not a use case of the SA report.
class AuthController extends Controller {
  AuthController(super.session, this.accounts, this.tokens);

  final UserAccountRepository accounts;
  final SessionToken tokens;

  /// The user app accepts only role USER; the console accepts OFFICER and CONSULTANT.
  static const appRoles = {
    'user': {Role.user},
    'console': {Role.officer, Role.consultant},
  };

  Future<LoginResult> login(String loginName, String password, {required String app}) async {
    final row = await accounts.findAccountByLogin(loginName.trim(), password);
    final allowed = appRoles[app] ?? const <String>{};
    if (row == null || !allowed.contains(row['role'])) {
      throw const ControllerException(401, 'The login name or the password is not correct.');
    }
    final s = UserSession.fromRow(row);
    return LoginResult(tokens.issue(s), s);
  }
}

class LoginResult {
  const LoginResult(this.token, this.session);

  final String token;
  final UserSession session;

  Map<String, Object?> toJson() => {'token': token, 'session': session.toJson()};
}
