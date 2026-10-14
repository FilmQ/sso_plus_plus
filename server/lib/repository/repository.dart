import '../db/db_connector.dart';

export '../db/db_connector.dart' show DBConnector, ResultSet;

typedef Row = Map<String, Object?>;

/// Base class of all repositories (SA report 2.18, class Repository).
abstract class Repository {
  Repository(this.db);

  final DBConnector db;

  /// Runs one statement and gives its rows.
  Future<ResultSet> query(String sql, [Map<String, Object?> params = const {}]) =>
      db.performQuery(sql, params);

  /// Runs one statement and gives the number of changed rows.
  Future<int> execute(String sql, [Map<String, Object?> params = const {}]) async =>
      (await db.performQuery(sql, params)).affectedRows;

  /// Runs all statements of one Query ID in one transaction (brief, rule 2).
  ///
  /// If [guard] is set and that statement changes no row, the transaction rolls
  /// back and [NoRowChangedException] is thrown. The report's guarded UPDATE
  /// (for example `AND appointment_status = 'Pending'`) then stops the other
  /// statements of the same Query ID.
  Future<List<ResultSet>> runAll(
    String queryId,
    List<String> statements,
    Map<String, Object?> params, {
    int? guard,
  }) =>
      db.transaction(() async {
        final results = <ResultSet>[];
        for (final sql in statements) {
          final rs = await query(sql, params);
          if (guard == results.length && rs.affectedRows == 0) {
            throw NoRowChangedException(queryId);
          }
          results.add(rs);
        }
        return results;
      });
}

/// A guarded statement changed no row: the row is not in the expected state.
class NoRowChangedException implements Exception {
  const NoRowChangedException(this.queryId);

  final String queryId;

  @override
  String toString() => 'NoRowChangedException: $queryId changed no row';
}
