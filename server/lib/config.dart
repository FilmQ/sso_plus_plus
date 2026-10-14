import 'dart:io';

import 'db/db_connector.dart';

/// Settings from environment variables. See `.env.example` at the repository
/// root. The default values agree with `docker-compose.yml`.
class Config {
  Config([Map<String, String>? env]) : _env = env ?? Platform.environment;

  final Map<String, String> _env;

  String _get(String key, String fallback) => _env[key] ?? fallback;

  String get dbHost => _get('DB_HOST', 'localhost');
  int get dbPort => int.parse(_get('DB_PORT', '5432'));
  String get dbName => _get('DB_NAME', 'sst');
  String get testDbName => _get('TEST_DB_NAME', 'sst_test');
  String get dbUser => _get('DB_USER', 'sst');
  String get dbPassword => _get('DB_PASSWORD', 'sst');

  int get serverPort => int.parse(_get('SERVER_PORT', '8080'));

  /// The key that signs the login tokens. Change it outside development.
  String get sessionSecret => _get('SESSION_SECRET', 'dev-only-secret');

  /// The folder for uploaded files (07-open-questions.md, item 4).
  String get storageDir => _get('STORAGE_DIR', 'storage');

  DBConnector connector({bool test = false}) => DBConnector(
        host: dbHost,
        port: dbPort,
        database: test ? testDbName : dbName,
        username: dbUser,
        password: dbPassword,
      );
}
