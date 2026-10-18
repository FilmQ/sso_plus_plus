import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sst_server/config.dart';
import 'package:sst_server/db/migrator.dart';

/// Loads the schema and the seed again. All data in the database is lost.
///
///   dart run bin/migrate.dart          the dev database (DB_NAME)
///   dart run bin/migrate.dart --test   the test database (TEST_DB_NAME)
///
/// For the dev database it also copies the demo files of the seed documents
/// (`server/db/demo-files/`) into the file storage (D-056).
Future<void> main(List<String> args) async {
  final test = args.contains('--test');
  final config = Config();
  final db = config.connector(test: test);
  await db.connect();
  try {
    final migrator = Migrator(db);
    await migrator.reset();
    print('Loaded ${migrator.files.length} files into ${db.url}');
    if (!test) {
      final copied = await _copyDemoFiles(p.join(migrator.root, 'server/db/demo-files'), config.storageDir);
      print('Copied $copied demo files into ${config.storageDir}');
    }
  } finally {
    await db.close();
  }
}

/// Copies every file under [from] to the same path under [to].
Future<int> _copyDemoFiles(String from, String to) async {
  final dir = Directory(from);
  if (!dir.existsSync()) return 0;
  var n = 0;
  for (final file in dir.listSync(recursive: true).whereType<File>()) {
    final target = File(p.join(to, p.relative(file.path, from: from)));
    await target.parent.create(recursive: true);
    await file.copy(target.path);
    n++;
  }
  return n;
}
