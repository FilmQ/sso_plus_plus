import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'auth/session_token.dart';
import 'config.dart';
import 'db/db_connector.dart';
import 'http/auth_routes.dart';
import 'http/cors.dart';
import 'http/json.dart';
import 'http/session_middleware.dart';
import 'repository/user_account_repository.dart';

/// Connects the HTTP routes to the Controllers.
class App {
  App(this.config, this.db) : tokens = SessionToken(config.sessionSecret);

  final Config config;
  final DBConnector db;
  final SessionToken tokens;

  Handler get handler {
    final router = Router()
      ..get('/health', (Request _) async {
        await db.performQuery('SELECT 1');
        return jsonOk({'status': 'ok'});
      });
    addAuthRoutes(router, UserAccountRepository(db), tokens);
    return const Pipeline()
        .addMiddleware(cors())
        .addMiddleware(errorMiddleware())
        .addMiddleware(sessionMiddleware(tokens))
        .addHandler(router.call);
  }
}
