import 'dart:async';

import 'package:postgres/postgres.dart';

import 'named_parameters.dart';
import 'result_set.dart';

export 'result_set.dart';

/// The one gate to PostgreSQL (SA report 2.18, class DBConnector).
///
/// Every Repository sends its SQL through [performQuery]. A [transaction]
/// keeps one pooled connection for all statements in its body. A transaction
/// inside a transaction joins the outer one.
class DBConnector {
  DBConnector({
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    required this.password,
  });

  final String host;
  final int port;
  final String database;
  final String username;
  final String password;

  Pool<void>? _pool;

  static final _txKey = Object();

  /// The connection URL, for logs. It does not show the password.
  String get url => 'postgresql://$username@$host:$port/$database';

  /// Opens the connection pool. The session time zone is Asia/Bangkok.
  Future<void> connect() async {
    _pool ??= Pool.withEndpoints(
      [
        Endpoint(
          host: host,
          port: port,
          database: database,
          username: username,
          password: password,
        ),
      ],
      settings: const PoolSettings(
        maxConnectionCount: 10,
        sslMode: SslMode.disable,
        timeZone: 'Asia/Bangkok',
      ),
    );
  }

  /// Runs one SQL statement. [sql] uses the report's `:name` parameters.
  Future<ResultSet> performQuery(
    String sql, [
    Map<String, Object?> params = const {},
  ]) async {
    final named = NamedParameters.parse(sql);
    final result = await _session.execute(
      named.sql,
      parameters: named.bind(params),
    );
    return ResultSet(
      [for (final row in result) row.toColumnMap()],
      result.affectedRows,
    );
  }

  /// Runs [body] in one transaction. If [body] throws, the transaction rolls
  /// back. If [rollbackOnly] is true, it rolls back also on success (tests).
  Future<T> transaction<T>(
    Future<T> Function() body, {
    bool rollbackOnly = false,
  }) {
    if (Zone.current[_txKey] != null) return body();
    return _requirePool().withConnection(
      (connection) => runZoned(
        () async {
          await beginTransaction();
          try {
            final result = await body();
            rollbackOnly ? await rollback() : await commit();
            return result;
          } catch (_) {
            await rollback();
            rethrow;
          }
        },
        zoneValues: {_txKey: connection},
      ),
    );
  }

  Future<void> beginTransaction() => _txConnection().execute('BEGIN');

  Future<void> commit() => _txConnection().execute('COMMIT');

  Future<void> rollback() => _txConnection().execute('ROLLBACK');

  /// Runs a file with many statements (schema, seed). Not for use case SQL.
  /// A statement ends with `;` at the end of a line.
  Future<void> runScript(String sql) async {
    for (final statement in sql.split(RegExp(r';[ \t]*(\r?\n|$)'))) {
      final text = statement
          .split('\n')
          .where((line) => !line.trimLeft().startsWith('--'))
          .join('\n')
          .trim();
      if (text.isNotEmpty) await _session.execute(text);
    }
  }

  Future<void> close() async {
    await _pool?.close();
    _pool = null;
  }

  Session get _session =>
      (Zone.current[_txKey] as Connection?) ?? _requirePool();

  Connection _txConnection() {
    final connection = Zone.current[_txKey] as Connection?;
    if (connection == null) {
      throw StateError('No transaction. Call DBConnector.transaction().');
    }
    return connection;
  }

  Pool<void> _requirePool() {
    final pool = _pool;
    if (pool == null) {
      throw StateError('DBConnector is not connected. Call connect().');
    }
    return pool;
  }
}
