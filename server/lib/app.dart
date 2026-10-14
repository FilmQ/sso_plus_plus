import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'config.dart';
import 'db/db_connector.dart';
import 'http/cors.dart';
import 'http/json.dart';

/// Connects the HTTP routes to the Controllers.
class App {
  App(this.config, this.db);

  final Config config;
  final DBConnector db;

  Handler get handler {
    final router = Router()
      ..get('/health', (Request _) async {
        await db.performQuery('SELECT 1');
        return jsonOk({'status': 'ok'});
      });
    return const Pipeline().addMiddleware(cors()).addHandler(router.call);
  }
}
