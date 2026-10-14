import 'package:sst_server/model/field_rules.dart';
import 'package:test/test.dart';

void main() {
  group('U1 phone rule (data dictionary, D-016)', () {
    test('accepts 9 or 10 digits that start with 0, with spaces, dots, dashes or brackets', () {
      for (final ok in ['0812345678', '081 234 5678', '081-234-5678', '(02) 315.4400', '023154400']) {
        expect(FieldRules.isPhone(ok), isTrue, reason: ok);
      }
    });

    test('changes a leading +66 into 0', () {
      expect(FieldRules.normalPhone('+66 81 234 5678'), '0812345678');
      expect(FieldRules.isPhone('+66 81 234 5678'), isTrue);
    });

    test('refuses other numbers', () {
      for (final bad in ['08-12', '1812345678', '08123456789', '+1 415 555 0100', '081234567x', '']) {
        expect(FieldRules.isPhone(bad), isFalse, reason: bad);
      }
    });
  });
}
