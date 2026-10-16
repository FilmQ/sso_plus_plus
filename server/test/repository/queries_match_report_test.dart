import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sst_server/db/migrator.dart';
import 'package:sst_server/repository/sql/appointment_sql.dart';
import 'package:sst_server/repository/sql/claim_sql.dart';
import 'package:sst_server/repository/sql/insured_person_sql.dart';
import 'package:sst_server/repository/sql/notification_sql.dart';
import 'package:sst_server/repository/sql/report_sql.dart';
import 'package:sst_server/repository/sql/treatment_sql.dart';
import 'package:test/test.dart';

/// Rule 2 of the brief: every repository runs the report's SQL without changes.
void main() {
  final code = <String, List<String>>{
    ...InsuredPersonSql.all,
    ...ClaimSql.all,
    ...NotificationSql.all,
    ...AppointmentSql.all,
    ...TreatmentSql.all,
    ...ReportSql.all,
  };
  final report = _readQueriesSql();

  test('the code has all 58 Query IDs of queries.sql', () {
    expect(report.length, 58);
    expect(code.keys.toSet(), report.keys.toSet());
  });

  for (final id in report.keys) {
    test('$id is the same SQL as in queries.sql', () {
      expect(code[id]?.map(_normal).toList(), report[id]!.map(_normal).toList());
    });
  }
}

/// Splits queries.sql into blocks (one per Query ID) and statements.
Map<String, List<String>> _readQueriesSql() {
  final file = File(p.join(Migrator.findRepoRoot(), 'docs/spec/database/queries.sql'));
  final header = RegExp(r'^-- (Q[A-Z]*\d*\.\d+)\s+\[');
  final sqlStart = RegExp(r'^\s*(SELECT|INSERT|UPDATE|WITH|DELETE)\b');
  final blocks = <String, List<String>>{};
  String? current;
  for (final line in file.readAsLinesSync()) {
    final m = header.firstMatch(line);
    if (m != null) {
      current = m.group(1);
      blocks[current!] = [];
    } else if (current != null) {
      blocks[current]!.add(line);
    }
  }
  return blocks.map((id, lines) {
    final start = lines.indexWhere(sqlStart.hasMatch);
    final body = lines.sublist(start).join('\n');
    final statements = body.split(RegExp(r';[ \t]*(\n|$)')).map((s) => s.trim()).where((s) => s.isNotEmpty);
    return MapEntry(id, statements.toList());
  });
}

String _normal(String sql) => sql.replaceAll(RegExp(r'\s+'), ' ').trim();
