import 'dart:io';

import 'package:path/path.dart' as p;

import 'db_connector.dart';

/// Loads the database from the files in this order:
/// 1. `docs/spec/database/schema.sql` (migration 001, the report's schema),
/// 2. `server/db/migrations/*.sql` (infrastructure tables),
/// 3. `docs/spec/database/seed.sql` (the report's sample rows),
/// 4. `server/db/seeds/*.sql` (seed rows for infrastructure tables).
class Migrator {
  Migrator(this.db, {String? repoRoot}) : root = repoRoot ?? findRepoRoot();

  final DBConnector db;
  final String root;

  List<File> get files => [
        File(p.join(root, 'docs/spec/database/schema.sql')),
        ..._sqlIn(p.join(root, 'server/db/migrations')),
        File(p.join(root, 'docs/spec/database/seed.sql')),
        ..._sqlIn(p.join(root, 'server/db/seeds')),
      ];

  /// Removes all tables, then loads every file again.
  Future<void> reset() async {
    await db.runScript('DROP SCHEMA public CASCADE;\nCREATE SCHEMA public;');
    for (final file in files) {
      await db.runScript(await file.readAsString());
    }
  }

  static List<File> _sqlIn(String dir) {
    final d = Directory(dir);
    if (!d.existsSync()) return const [];
    return d.listSync().whereType<File>().where((f) => f.path.endsWith('.sql')).toList()
      ..sort((a, b) => a.path.compareTo(b.path));
  }

  /// Finds the repository root: the first parent folder that has `docs/spec`.
  static String findRepoRoot([String? start]) {
    var dir = Directory(start ?? Directory.current.path).absolute;
    while (true) {
      if (Directory(p.join(dir.path, 'docs/spec')).existsSync()) return dir.path;
      final parent = dir.parent;
      if (parent.path == dir.path) {
        throw StateError('Cannot find docs/spec above ${Directory.current.path}');
      }
      dir = parent;
    }
  }
}
