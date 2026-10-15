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

  /// Runs a guarded statement of the report: its WHERE (or WITH) clause has
  /// the status condition, so 0 changed rows means that the state did not allow
  /// the change. Then [NoRowChangedException] is thrown (HTTP 409, D-008).
  Future<ResultSet> guarded(String queryId, String sql, Map<String, Object?> params) async {
    final rs = await query(sql, params);
    if (rs.affectedRows == 0) throw NoRowChangedException(queryId);
    return rs;
  }
}

/// A guarded statement changed no row: the row is not in a state that allows the change.
class NoRowChangedException implements Exception {
  const NoRowChangedException(this.queryId);

  final String queryId;

  @override
  String toString() => 'NoRowChangedException: $queryId changed no row';
}
