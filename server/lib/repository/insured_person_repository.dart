import 'repository.dart';
import 'sql/insured_person_sql.dart';

/// Table InsuredPerson, and the SSO register stub `master_table` (U1).
class InsuredPersonRepository extends Repository {
  InsuredPersonRepository(super.db);

  final String table = 'InsuredPerson';

  // Q1.1 [U1] The person in the SSO register with coverage ACTIVE, or null.
  Future<Row?> findInSSORegister(String nationalId) async =>
      (await query(InsuredPersonSql.q1_1, {'national_id': nationalId})).firstOrNull;

  // Q1.2 [U1]
  Future<int> countByNationalId(String nationalId) async =>
      (await query(InsuredPersonSql.q1_2, {'national_id': nationalId})).rows.single['cnt'] as int;

  // Q1.3 [U1] Gives the new insured_id.
  Future<int> insertInsuredPerson({
    required String nationalId,
    required String titleName,
    required String firstName,
    required String lastName,
    required String dateOfBirth,
    required String gender,
    required String phoneNo,
    required String address,
  }) async {
    final rs = await query(InsuredPersonSql.q1_3, {
      'national_id': nationalId,
      'title_name': titleName,
      'first_name': firstName,
      'last_name': lastName,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'phone_no': phoneNo,
      'address': address,
    });
    return rs.rows.single['insured_id'] as int;
  }

  // Q1.4 [U1] Gives the employer_id (new or updated).
  Future<int> upsertEmployer({required String accountNo, required String name}) async {
    final rs = await query(InsuredPersonSql.q1_4, {
      'employer_account_no': accountNo,
      'employer_name': name,
    });
    return rs.rows.single['employer_id'] as int;
  }

  // Q1.5 [U1] Gives the new coverage_id.
  Future<int> insertCoverage({
    required int insuredId,
    required int employerId,
    required String registrationDate,
    required String contributionStart,
    String? contributionEnd,
    required int contributionMonths,
  }) async {
    final rs = await query(InsuredPersonSql.q1_5, {
      'insured_id': insuredId,
      'employer_id': employerId,
      'registration_date': registrationDate,
      'contribution_start': contributionStart,
      'contribution_end': contributionEnd,
      'contribution_months': contributionMonths,
    });
    return rs.rows.single['coverage_id'] as int;
  }
}
