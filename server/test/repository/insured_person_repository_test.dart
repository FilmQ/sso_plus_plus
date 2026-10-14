import 'package:sst_server/repository/insured_person_repository.dart';
import 'package:test/test.dart';

import '../support/test_db.dart';

void main() {
  final db = useTestDb();
  final repo = InsuredPersonRepository(db);

  test('Q1.1 findInSSORegister: ACTIVE person found, INACTIVE person not found', () async {
    final row = await repo.findInSSORegister('1103700123456');
    expect(row, containsPair('first_name', 'สมชาย'));
    expect(await repo.findInSSORegister('1909900111222'), isNull);
  });

  test('Q1.2 countByNationalId: 1 for a registered ID, 0 for a new ID', () async {
    expect(await repo.countByNationalId('1103700123456'), 1);
    expect(await repo.countByNationalId('1909900111222'), 0);
  });

  test('Q1.3 insertInsuredPerson gives a new insured_id', () => inRollback(db, () async {
        final id = await repo.insertInsuredPerson(
          nationalId: '1909900111222',
          titleName: 'นาย',
          firstName: 'ทดสอบ',
          lastName: 'ไม่มีสิทธิ์',
          dateOfBirth: '1990-01-01',
          gender: 'M',
          phoneNo: '0812345000',
          address: '1 ถ.ทดสอบ กรุงเทพฯ 10100',
        );
        expect(id, greaterThan(105));
        expect(await repo.countByNationalId('1909900111222'), 1);
      }));

  test('Q1.4 upsertEmployer: same account number gives the same employer_id', () => inRollback(db, () async {
        expect(await repo.upsertEmployer(accountNo: '1000123456', name: 'Siam Precision Parts Co., Ltd.'), 11);
        expect(await repo.upsertEmployer(accountNo: '1000999999', name: 'New Co., Ltd.'), greaterThan(15));
      }));

  test('Q1.5 insertCoverage gives a new coverage_id', () => inRollback(db, () async {
        final id = await repo.insertCoverage(
          insuredId: 101,
          employerId: 11,
          registrationDate: '2019-05-20',
          contributionStart: '2019-06-01',
          contributionMonths: 88,
        );
        expect(id, greaterThan(205));
      }));
}
