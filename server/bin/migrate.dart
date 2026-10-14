import 'package:sst_server/config.dart';
import 'package:sst_server/db/migrator.dart';

/// Loads the schema and the seed again. All data in the database is lost.
///
///   dart run bin/migrate.dart          the dev database (DB_NAME)
///   dart run bin/migrate.dart --test   the test database (TEST_DB_NAME)
Future<void> main(List<String> args) async {
  final db = Config().connector(test: args.contains('--test'));
  await db.connect();
  try {
    final migrator = Migrator(db);
    await migrator.reset();
    print('Loaded ${migrator.files.length} files into ${db.url}');
  } finally {
    await db.close();
  }
}
