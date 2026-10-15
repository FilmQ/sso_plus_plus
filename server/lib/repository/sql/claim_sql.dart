// GENERATED from docs/spec/database/queries.sql. Do not edit by hand.
// The test queries_match_report_test.dart makes sure that this text stays the same as the report.
// ignore_for_file: constant_identifier_names

/// SQL of [ClaimRepository]. Each constant has the name of its Query ID.
abstract final class ClaimSql {
  // Q1.6 [U1] ยื่นคำร้องกรณีประสบอันตราย (Submit Injury Application)
  static const q1_6 = r'''
INSERT INTO InjuryClaim
  (insured_id, employer_id, injury_datetime, injury_place,
   injury_cause, body_part, injury_category, claim_status,
   submitted_at, created_at)
VALUES (:insured_id, :employer_id, :injury_datetime,
   :injury_place, :injury_cause, :body_part, :injury_category,
   CASE WHEN :register_result = 'Covered'
        THEN 'Awaiting verification'
        ELSE 'Register unavailable' END,
   NOW(), NOW())
RETURNING claim_id
''';

  // Q1.7 [U1] ยื่นคำร้องกรณีประสบอันตราย (Submit Injury Application)
  static const q1_7 = r'''
UPDATE InjuryClaim
SET claim_no = 'SST-' || TO_CHAR(submitted_at, 'YYYY') || '-'
            || LPAD(claim_id::text, 6, '0')
WHERE claim_id = :claim_id
RETURNING claim_no, submitted_at
''';

  // Q1.8 [U1] ยื่นคำร้องกรณีประสบอันตราย (Submit Injury Application)
  static const q1_8 = r'''
INSERT INTO ClaimDocument
  (claim_id, doc_type_id, file_name, file_uri, mime_type,
   file_size_bytes, uploaded_at, check_status)
VALUES (:claim_id, :doc_type_id, :file_name, :file_uri,
   :mime_type, :file_size_bytes, NOW(), 'Pending')
''';

  // Q1.9 [U1] ยื่นคำร้องกรณีประสบอันตราย (Submit Injury Application)
  static const q1_9 = r'''
INSERT INTO EligibilityCheck
  (claim_id, coverage_id, checked_at, result,
   is_override, evidence_ref)
VALUES (:claim_id, :coverage_id, NOW(), :register_result,
   FALSE, :evidence_ref)
''';

  // Q1.10 [U1] ยื่นคำร้องกรณีประสบอันตราย (Submit Injury Application)
  static const q1_10 = r'''
INSERT INTO ClaimStatusHistory
  (claim_id, to_status, changed_at, change_reason)
SELECT claim_id, claim_status, NOW(), 'Submitted by the user'
FROM InjuryClaim
WHERE claim_id = :claim_id
''';

  // Q2.4 [U2] ดูข้อความแจ้งเตือน (View Notify Message)
  static const q2_4 = r'''
SELECT ic.claim_id, ic.claim_no, ip.first_name,
  CONCAT_WS(', ', ic.injury_category, ic.body_part) AS injury,
  ic.claim_status,
  TO_CHAR(ic.submitted_at, 'FMDD FMMonth YYYY" : "HH24:MI')
    AS submitted_time,
  (SELECT TO_CHAR(MAX(ec.checked_at),
            'FMDD FMMonth YYYY" : "HH24:MI')
   FROM EligibilityCheck ec
   WHERE ec.claim_id = ic.claim_id
     AND ec.officer_id IS NOT NULL) AS officer_checked_time,
  na.appointment_status, na.appointment_time,
  na.consultant_name, na.office_location,
  (SELECT t.treatment_status
   FROM Treatment t
   WHERE t.claim_id = ic.claim_id
   ORDER BY t.created_at DESC
   LIMIT 1) AS treatment_status
FROM InjuryClaim ic
JOIN InsuredPerson ip ON ip.insured_id = ic.insured_id
LEFT JOIN LATERAL (
  SELECT a.appointment_status,
    TO_CHAR(a.schedule_date + a.schedule_time,
      'FMDD FMMonth YYYY" : "HH24:MI') AS appointment_time,
    CONCAT_WS(' ', c.title_name, c.first_name, c.last_name)
      AS consultant_name,
    c.office_location
  FROM Appointment a
  JOIN Consultant c ON c.consultant_id = a.consultant_id
  WHERE a.claim_id = ic.claim_id
    AND a.appointment_status IN ('Pending', 'Confirmed')
  ORDER BY a.created_at DESC
  LIMIT 1
) na ON TRUE
WHERE ic.insured_id = :insured_id
ORDER BY ic.submitted_at DESC
LIMIT 1
''';

  // QO1.1 [O1] ดูคำร้องกรณีประสบอันตราย (View Injury Application)
  static const qO1_1 = r'''
SELECT ic.claim_id,
  ic.claim_no,
  CONCAT_WS(' ', ip.title_name, ip.first_name, ip.last_name)
    AS claimant_name,
  CONCAT_WS(', ', ic.injury_category, ic.body_part) AS injury,
  TO_CHAR(ic.injury_datetime, 'FMDD FMMonth YYYY') AS injury_date,
  TO_CHAR(ic.submitted_at, 'FMDD FMMonth YYYY') AS submitted_date,
  (SELECT COUNT(*)
     FROM ClaimDocument cd
    WHERE cd.claim_id = ic.claim_id) AS documents_sent,
  ic.claim_status AS verification_status
FROM InjuryClaim ic
JOIN InsuredPerson ip ON ip.insured_id = ic.insured_id
WHERE ic.claim_status IN ('Awaiting verification', 'Needs review',
  'Register unavailable')
ORDER BY ic.submitted_at
''';

  // QO1.2 [O1] ดูคำร้องกรณีประสบอันตราย (View Injury Application)
  static const qO1_2 = r'''
SELECT
  COUNT(*) FILTER (WHERE claim_status = 'Awaiting verification')
    AS awaiting_verification,
  COUNT(*) FILTER (WHERE claim_status = 'Needs review')
    AS reviews_needed,
  COUNT(*) FILTER (WHERE claim_status = 'Register unavailable')
    AS register_unavailable
FROM InjuryClaim
''';

  // QO1.3 [O1] ดูคำร้องกรณีประสบอันตราย (View Injury Application)
  static const qO1_3 = r'''
SELECT ic.claim_no,
  CONCAT_WS(' ', ip.first_name, ip.last_name) AS user_name,
  TO_CHAR(ic.submitted_at, 'FMDD FMMonth YYYY') AS submitted_date,
  ip.national_id,
  e.employer_name AS employer_on_claim,
  TO_CHAR(ic.injury_datetime, 'FMDD FMMonth YYYY')
    AS date_of_injury,
  ic.injury_place,
  ic.injury_cause,
  ic.body_part
FROM InjuryClaim ic
JOIN InsuredPerson ip ON ip.insured_id = ic.insured_id
LEFT JOIN Employer e ON e.employer_id = ic.employer_id
WHERE ic.claim_id = :claim_id
''';

  // QO1.4 [O1] ดูคำร้องกรณีประสบอันตราย (View Injury Application)
  static const qO1_4 = r'''
SELECT file_name,
  pg_size_pretty(file_size_bytes::bigint) AS file_size,
  file_uri
FROM ClaimDocument
WHERE claim_id = :claim_id
ORDER BY uploaded_at
''';

  // QO1.5 [O1] ดูคำร้องกรณีประสบอันตราย (View Injury Application)
  static const qO1_5 = r'''
SELECT ec.result AS eligibility_status,
  TO_CHAR(s.contribution_start, 'FMDD FMMonth YYYY') || ' - ' ||
    COALESCE(TO_CHAR(s.contribution_end, 'FMDD FMMonth YYYY'),
             'present') AS contribution_period,
  e.employer_name AS employer_in_register,
  e.sso_account_no,
  TO_CHAR(ec.checked_at, 'FMDD FMMonth YYYY" : "HH24:MI')
    AS register_queried
FROM EligibilityCheck ec
LEFT JOIN Section33Coverage s ON s.coverage_id = ec.coverage_id
LEFT JOIN Employer e ON e.employer_id = s.employer_id
WHERE ec.claim_id = :claim_id
  AND ec.officer_id IS NULL
ORDER BY ec.checked_at DESC
LIMIT 1
''';

  // QO1.6 [O3] ปฏิเสธคำร้อง (Reject Injury Application)
  static const qO1_6 = r'''
SELECT reason_code, name_th, description
FROM RejectionReason
ORDER BY reason_code
''';

  // QO2.1 [O2] อนุมัติคำร้อง (Approve Injury Application)
  static const qO2_1 = r'''
WITH prev AS (
  SELECT claim_id, claim_status
  FROM InjuryClaim
  WHERE claim_id = :claim_id
    AND claim_status IN ('Awaiting verification', 'Needs review',
      'Register unavailable')
), decided AS (
  UPDATE InjuryClaim ic
  SET claim_status = :result::varchar
  FROM prev
  WHERE ic.claim_id = prev.claim_id
  RETURNING ic.claim_id
), history AS (
  INSERT INTO ClaimStatusHistory
    (claim_id, officer_id, from_status, to_status,
     changed_at, change_reason)
  SELECT prev.claim_id, :officer_id, prev.claim_status,
    :result::varchar, NOW(), :override_reason::varchar
  FROM prev
  JOIN decided ON decided.claim_id = prev.claim_id
)
INSERT INTO EligibilityCheck
  (claim_id, coverage_id, officer_id, checked_at, result,
   is_override, override_reason, evidence_ref)
SELECT ec.claim_id, ec.coverage_id, :officer_id, NOW(),
  :result::varchar, :result::varchar <> ec.result,
  :override_reason::varchar, ec.evidence_ref
FROM EligibilityCheck ec
JOIN decided ON decided.claim_id = ec.claim_id
WHERE ec.officer_id IS NULL
ORDER BY ec.checked_at DESC
LIMIT 1
''';

  // QO3.1 [O3] ปฏิเสธคำร้อง (Reject Injury Application)
  static const qO3_1 = r'''
WITH prev AS (
  SELECT claim_id, claim_status
  FROM InjuryClaim
  WHERE claim_id = :claim_id
    AND claim_status IN ('Awaiting verification', 'Needs review',
      'Register unavailable')
), decided AS (
  UPDATE InjuryClaim ic
  SET claim_status = :result::varchar
  FROM prev
  WHERE ic.claim_id = prev.claim_id
  RETURNING ic.claim_id
), history AS (
  INSERT INTO ClaimStatusHistory
    (claim_id, officer_id, from_status, to_status,
     changed_at, change_reason)
  SELECT prev.claim_id, :officer_id, prev.claim_status,
    :result::varchar, NOW(), :override_reason::varchar
  FROM prev
  JOIN decided ON decided.claim_id = prev.claim_id
)
INSERT INTO EligibilityCheck
  (claim_id, coverage_id, officer_id, checked_at, result,
   is_override, override_reason, evidence_ref)
SELECT ec.claim_id, ec.coverage_id, :officer_id, NOW(),
  :result::varchar, :result::varchar <> ec.result,
  :override_reason::varchar, ec.evidence_ref
FROM EligibilityCheck ec
JOIN decided ON decided.claim_id = ec.claim_id
WHERE ec.officer_id IS NULL
ORDER BY ec.checked_at DESC
LIMIT 1
''';

  // QO3.2 [O3] ปฏิเสธคำร้อง (Reject Injury Application)
  static const qO3_2 = r'''
WITH prev AS (
  SELECT claim_id, claim_status
  FROM InjuryClaim
  WHERE claim_id = :claim_id
    AND claim_status IN ('Awaiting verification', 'Needs review',
      'Register unavailable', 'Not covered')
), rejected AS (
  UPDATE InjuryClaim ic
  SET claim_status = 'Rejected'
  FROM prev
  WHERE ic.claim_id = prev.claim_id
  RETURNING ic.claim_id
), history AS (
  INSERT INTO ClaimStatusHistory
    (claim_id, officer_id, from_status, to_status,
     changed_at, change_reason)
  SELECT prev.claim_id, :officer_id, prev.claim_status, 'Rejected',
    NOW(), :reason_code::varchar
  FROM prev
  JOIN rejected ON rejected.claim_id = prev.claim_id
)
INSERT INTO ClaimRejection
  (claim_id, reason_code, officer_id, officer_message,
   rejection_timestamp, is_superseded)
SELECT claim_id, :reason_code::varchar, :officer_id,
  :officer_message, NOW(), FALSE
FROM rejected
''';

  // QO5.4 [O5.2] นัดหมายการรักษา (No Treatment Required)
  static const qO5_4 = r'''
WITH prev AS (
  SELECT claim_id, claim_status
  FROM InjuryClaim
  WHERE claim_id = :claim_id
    AND claim_status = 'Covered'
), closed AS (
  UPDATE InjuryClaim ic
  SET claim_status = 'No treatment required'
  FROM prev
  WHERE ic.claim_id = prev.claim_id
  RETURNING ic.claim_id
)
INSERT INTO ClaimStatusHistory
  (claim_id, officer_id, from_status, to_status,
   changed_at, change_reason)
SELECT prev.claim_id, :officer_id, prev.claim_status,
  'No treatment required', NOW(),
  'Consultation report: no treatment required'
FROM prev
JOIN closed ON closed.claim_id = prev.claim_id
''';

  /// Every Query ID of this class, for the test that compares the SQL with the report.
  static const all = <String, List<String>>{
    'Q1.6': [q1_6],
    'Q1.7': [q1_7],
    'Q1.8': [q1_8],
    'Q1.9': [q1_9],
    'Q1.10': [q1_10],
    'Q2.4': [q2_4],
    'QO1.1': [qO1_1],
    'QO1.2': [qO1_2],
    'QO1.3': [qO1_3],
    'QO1.4': [qO1_4],
    'QO1.5': [qO1_5],
    'QO1.6': [qO1_6],
    'QO2.1': [qO2_1],
    'QO3.1': [qO3_1],
    'QO3.2': [qO3_2],
    'QO5.4': [qO5_4],
  };
}
