import 'package:sst_server/config.dart';
import 'package:sst_server/db/db_connector.dart';
import 'package:sst_server/db/migrator.dart';
import 'package:test/test.dart';

/// Gives each test file one connector to the test database.
///
/// The test database is loaded again from schema.sql and seed.sql before the
/// file runs. Use [inRollback] so that a test does not change the seed rows.
/// `dart_test.yaml` runs the files one at a time, because they share the database.
DBConnector useTestDb() {
  final db = Config().connector(test: true);
  setUpAll(() async {
    await db.connect();
    await Migrator(db).reset();
  });
  tearDownAll(db.close);
  return db;
}

/// Runs [body] in a transaction that always rolls back.
Future<T> inRollback<T>(DBConnector db, Future<T> Function() body) =>
    db.transaction(body, rollbackOnly: true);
