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

  // TEMPORARY until the updated spec pack (R-004).
  // R-004: Q1.4 and Q1.5 need the employer and contribution data of the
  // register, but Q1.1 reads only the name.
  static const findRegisterDetail = r'''
SELECT employer_account_no, employer_name,
  TO_CHAR(registration_date, 'YYYY-MM-DD') AS registration_date,
  TO_CHAR(contribution_start, 'YYYY-MM-DD') AS contribution_start,
  TO_CHAR(contribution_end, 'YYYY-MM-DD') AS contribution_end,
  contribution_months
FROM master_table
WHERE national_id = :national_id
  AND coverage_status = 'ACTIVE'
''';

  // TEMPORARY until the updated spec pack (R-006).
  // R-006: the Home page (U2-1) shows the claim of the user. No report query
  // gives it.
  static const findHomeClaim = r'''
SELECT ic.claim_id, ic.claim_no, ic.claim_status,
  CONCAT_WS(', ', ic.injury_category, ic.body_part) AS injury,
  TO_CHAR(ic.submitted_at, 'FMDD FMMonth YYYY" : "HH24:MI') AS submitted_time,
  TO_CHAR((SELECT MAX(ec.checked_at)
             FROM EligibilityCheck ec
            WHERE ec.claim_id = ic.claim_id
              AND ec.officer_id IS NOT NULL),
          'FMDD FMMonth YYYY" : "HH24:MI') AS checked_time,
  (SELECT COUNT(*) FROM ClaimDocument cd WHERE cd.claim_id = ic.claim_id) AS documents_sent
FROM InjuryClaim ic
WHERE ic.insured_id = :insured_id
ORDER BY ic.submitted_at DESC
LIMIT 1
''';

  // TEMPORARY until the report adds a status condition to QO2.1 and QO3.1
  // (R-012). Locks the claim row for the decision.
  static const findClaimStatusForUpdate = r'''
SELECT claim_status
FROM InjuryClaim
WHERE claim_id = :claim_id
FOR UPDATE
''';
}
