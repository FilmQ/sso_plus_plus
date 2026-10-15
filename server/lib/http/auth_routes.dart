import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../auth/session_token.dart';
import '../controller/auth_controller.dart';
import '../controller/controller.dart';
import '../repository/user_account_repository.dart';
import 'json.dart';
import 'session_middleware.dart';

/// Login routes (infrastructure, D-003).
void addAuthRoutes(Router router, UserAccountRepository accounts, SessionToken tokens) {
  router
    ..post('/auth/login', (Request request) async {
      final body = await readJson(request);
      final controller = AuthController(null, accounts, tokens);
      final result = await controller.login(
        (body['login_name'] as String?) ?? '',
        (body['password'] as String?) ?? '',
        app: (body['app'] as String?) ?? 'user',
      );
      return jsonOk(result.toJson());
    })
    // Figma P-1 Profile Page (infrastructure, D-003).
    ..get('/auth/profile', (Request request) async {
      final session = sessionOf(request);
      if (session == null || session.insuredId == null) throw const NotAuthorizedException();
      return jsonOk({'profile': await accounts.findUserProfile(session.insuredId!)});
    })
    ..get('/auth/me', (Request request) {
      final session = sessionOf(request);
      if (session == null) throw const NotAuthorizedException();
      return jsonOk({'session': session.toJson()});
    });
}
