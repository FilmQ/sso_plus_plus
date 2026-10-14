import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'auth/session_token.dart';
import 'config.dart';
import 'controller/insured_form_controller.dart';
import 'db/db_connector.dart';
import 'http/auth_routes.dart';
import 'http/cors.dart';
import 'http/json.dart';
import 'http/session_middleware.dart';
import 'http/u1_routes.dart';
import 'model/claim_model.dart';
import 'model/insured_person_model.dart';
import 'repository/claim_repository.dart';
import 'repository/insured_person_repository.dart';
import 'repository/user_account_repository.dart';
import 'storage/file_storage.dart';

/// Connects the HTTP routes to the Controllers. Repositories have no state,
/// so one of each is enough; Models and Controllers are made per request.
class App {
  App(this.config, this.db)
      : tokens = SessionToken(config.sessionSecret),
        storage = LocalFileStorage(config.storageDir);

  final Config config;
  final DBConnector db;
  final SessionToken tokens;
  final FileStorage storage;

  late final accounts = UserAccountRepository(db);
  late final people = InsuredPersonRepository(db);
  late final claims = ClaimRepository(db);

  InsuredFormController insuredFormController() => InsuredFormController(
        db: db,
        personModel: InsuredPersonModel(people),
        claimModel: ClaimModel(claims, storage),
        accounts: accounts,
        tokens: tokens,
      );

  Handler get handler {
    final router = Router()
      ..get('/health', (Request _) async {
        await db.performQuery('SELECT 1');
        return jsonOk({'status': 'ok'});
      });
    addAuthRoutes(router, accounts, tokens);
    addU1Routes(router, insuredFormController);
    return const Pipeline()
        .addMiddleware(cors())
        .addMiddleware(errorMiddleware())
        .addMiddleware(sessionMiddleware(tokens))
        .addHandler(router.call);
  }
}
