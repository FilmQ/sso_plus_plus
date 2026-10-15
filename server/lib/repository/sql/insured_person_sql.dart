// GENERATED from docs/spec/database/queries.sql. Do not edit by hand.
// The test queries_match_report_test.dart makes sure that this text stays the same as the report.
// ignore_for_file: constant_identifier_names

/// SQL of [InsuredPersonRepository]. Each constant has the name of its Query ID.
abstract final class InsuredPersonSql {
  // Q1.1 [U1] ยื่นคำร้องกรณีประสบอันตราย (Submit Injury Application)
  static const q1_1 = r'''
SELECT national_id, title_name, first_name, last_name,
  employer_account_no, employer_name, registration_date,
  contribution_start, contribution_end, contribution_months
FROM master_table
WHERE national_id = :national_id
  AND coverage_status = 'ACTIVE'
''';

  // Q1.2 [U1] ยื่นคำร้องกรณีประสบอันตราย (Submit Injury Application)
  static const q1_2 = r'''
SELECT COUNT(*) AS cnt
FROM InsuredPerson
WHERE national_id = :national_id
''';

  // Q1.3 [U1] ยื่นคำร้องกรณีประสบอันตราย (Submit Injury Application)
  static const q1_3 = r'''
INSERT INTO InsuredPerson
  (national_id, title_name, first_name, last_name,
   date_of_birth, gender, phone_no, address, created_at)
VALUES (:national_id, :title_name, :first_name, :last_name,
   :date_of_birth, :gender, :phone_no, :address, NOW())
RETURNING insured_id
''';

  // Q1.4 [U1] ยื่นคำร้องกรณีประสบอันตราย (Submit Injury Application)
  static const q1_4 = r'''
INSERT INTO Employer (sso_account_no, employer_name)
VALUES (:employer_account_no, :employer_name)
ON CONFLICT (sso_account_no) DO UPDATE
  SET employer_name = EXCLUDED.employer_name
RETURNING employer_id
''';

  // Q1.5 [U1] ยื่นคำร้องกรณีประสบอันตราย (Submit Injury Application)
  static const q1_5 = r'''
INSERT INTO Section33Coverage
  (insured_id, employer_id, registration_date,
   contribution_start, contribution_end,
   contribution_months, coverage_status)
VALUES (:insured_id, :employer_id, :registration_date,
   :contribution_start, :contribution_end,
   :contribution_months, 'ACTIVE')
RETURNING coverage_id
''';

  /// Every Query ID of this class, for the test that compares the SQL with the report.
  static const all = <String, List<String>>{
    'Q1.1': [q1_1],
    'Q1.2': [q1_2],
    'Q1.3': [q1_3],
    'Q1.4': [q1_4],
    'Q1.5': [q1_5],
  };
}
