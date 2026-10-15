/// SQL that is NOT in the SA report. Each statement has a reason in
/// docs/DECISIONS.md. Do not put report queries here; they are generated
/// from queries.sql into the other files of this folder.
abstract final class InfrastructureSql {
  // D-003: login. The bcrypt check is in the database (pgcrypto).
  static const findAccountByLogin = r'''
SELECT ua.account_id, ua.role, ua.insured_id, ua.officer_id, ua.consultant_id,
  CASE ua.role
    WHEN 'USER' THEN CONCAT_WS(' ', ip.title_name, ip.first_name, ip.last_name)
    WHEN 'OFFICER' THEN CONCAT_WS(' ', o.first_name, o.last_name)
    ELSE CONCAT_WS(' ', c.title_name, c.first_name, c.last_name)
  END AS display_name,
  COALESCE(ip.first_name, o.first_name, c.first_name) AS first_name
FROM UserAccount ua
LEFT JOIN InsuredPerson ip ON ip.insured_id = ua.insured_id
LEFT JOIN EvaluationOfficer o ON o.officer_id = ua.officer_id
LEFT JOIN Consultant c ON c.consultant_id = ua.consultant_id
WHERE ua.login_name = :login_name
  AND ua.password_hash = crypt(:password, ua.password_hash)
''';

  // D-003: U1 makes the login account of the new user in the same transaction.
  static const insertUserAccount = r'''
INSERT INTO UserAccount (role, login_name, password_hash, insured_id, created_at)
VALUES ('USER', :login_name, crypt(:password, gen_salt('bf', 8)), :insured_id, NOW())
RETURNING account_id
''';

  // D-003: the Profile page (Figma P-1) of a signed-in user. Login and
  // profile are infrastructure, so this SQL is not in the report.
  static const findUserProfile = r'''
SELECT national_id,
  CONCAT_WS(' ', title_name, first_name, last_name) AS full_name,
  phone_no, address
FROM InsuredPerson
WHERE insured_id = :insured_id
''';
}
