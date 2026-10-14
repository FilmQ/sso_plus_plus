import 'package:sst_server/db/named_parameters.dart';
import 'package:test/test.dart';

void main() {
  test('converts :name to \$n and reuses the number for a repeated name', () {
    final p = NamedParameters.parse(
        'SELECT 1 WHERE a = :claim_id AND b = :officer_id AND c = :claim_id');
    expect(p.sql, r'SELECT 1 WHERE a = $1 AND b = $2 AND c = $1');
    expect(p.names, ['claim_id', 'officer_id']);
  });

  test('does not change ::casts', () {
    final p = NamedParameters.parse('SELECT :slot_date::date + TIME \'09:00\'');
    expect(p.sql, r"SELECT $1::date + TIME '09:00'");
  });

  test('does not change string literals, quoted names and comments', () {
    final p = NamedParameters.parse(
        "SELECT TO_CHAR(x, 'FMDD FMMonth YYYY\" : \"HH24:MI') AS \"a:b\", :id -- :not\n");
    expect(p.sql, "SELECT TO_CHAR(x, 'FMDD FMMonth YYYY\" : \"HH24:MI') AS \"a:b\", \$1 -- :not\n");
    expect(p.names, ['id']);
  });

  test('reads E-strings with backslash escapes', () {
    final p = NamedParameters.parse(r"SELECT CONCAT_WS(E'\n\':x', :a)");
    expect(p.names, ['a']);
  });

  test('bind() gives values in placeholder order and needs every name', () {
    final p = NamedParameters.parse('SELECT :b, :a, :b');
    expect(p.bind({'a': 1, 'b': 2}), [2, 1]);
    expect(() => p.bind({'a': 1}), throwsArgumentError);
  });
}
