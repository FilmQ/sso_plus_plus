// GENERATED from docs/spec/database/queries.sql. Do not edit by hand.
// The test queries_match_report_test.dart makes sure that this text stays the same as the report.
// ignore_for_file: constant_identifier_names

/// SQL of [TreatmentRepository]. Each constant has the name of its Query ID.
abstract final class TreatmentSql {
  // QU4.1 [U4.1] ยืนยันการรักษา (Accept Case)
  static const qU4_1 = r'''
UPDATE Treatment
SET treatment_status = 'Accepted'
WHERE treatment_id = :treatment_id
  AND claim_id = :claim_id
  AND treatment_status = 'Pending'
''';

  // QU4.2 [U4.2] ยืนยันการรักษา (Change Date)
  static const qU4_2 = r'''
UPDATE treatment
SET scheduled_date = :new_date
WHERE claim_id = :current_claim_id
  AND treatment_id = :current_treatment_id
  AND treatment_status = 'Pending'
''';

  // QU4.3 [U4.3] ยืนยันการรักษา (Reject)
  static const qU4_3 = r'''
WITH cancelled AS (
  UPDATE Treatment
  SET treatment_status = 'Cancelled'
  WHERE treatment_status = 'Pending'
    AND scheduled_date <= CURRENT_DATE
  RETURNING claim_id, facility_name, scheduled_date
)
INSERT INTO Notification
  (claim_id, insured_id, subject, body, sent_at)
SELECT ic.claim_id,
  ic.insured_id,
  'Treatment cancelled',
  'Your treatment at ' || c.facility_name || ' on '
    || TO_CHAR(c.scheduled_date, 'FMDD FMMonth YYYY')
    || ' was cancelled because it was not accepted in time.',
  NOW()
FROM cancelled c
JOIN InjuryClaim ic ON ic.claim_id = c.claim_id
''';

  // Q6.1 [U6] ดูตารางการรักษา (View Treatment Schedule)
  static const q6_1 = r'''
SELECT t.treatment_id,
  t.facility_name,
  t.treatment_type,
  TO_CHAR(t.scheduled_date + t.scheduled_time,
    'FMDD FMMonth YYYY" : "HH24:MI') AS treatment_date,
  t.treatment_status,
  ic.claim_id,
  ic.claim_no,
  CONCAT_WS(', ', ic.injury_category, ic.body_part) AS injury,
  TO_CHAR(ic.injury_datetime, 'FMDD FMMonth YYYY') AS injury_date
FROM Treatment t
JOIN InjuryClaim ic ON ic.claim_id = t.claim_id
WHERE ic.insured_id = :insured_id
  AND t.scheduled_date >= CURRENT_DATE
  AND t.treatment_status IN ('Pending', 'Accepted')
ORDER BY t.scheduled_date, t.scheduled_time
''';

  // QO5.1 [O5.1] นัดหมายการรักษา (Book Treatment)
  static const qO5_1 = r'''
SELECT ic.claim_id,
  ic.claim_no,
  CONCAT_WS(' ', ip.first_name, ip.last_name) AS user_name,
  cr.report_id,
  cr.version_no,
  TO_CHAR(cr.signed_at, 'FMDD FMMonth YYYY') AS signed_date,
  CONCAT_WS(' ', c.title_name, c.first_name, c.last_name)
    AS report_author
FROM ConsultationReport cr
JOIN ConsultationSession cs ON cs.session_id = cr.session_id
JOIN Appointment a ON a.appointment_id = cs.appointment_id
JOIN InjuryClaim ic ON ic.claim_id = a.claim_id
JOIN InsuredPerson ip ON ip.insured_id = ic.insured_id
JOIN Consultant c ON c.consultant_id = cr.consultant_id
WHERE cr.delivered_at IS NOT NULL
  AND cr.is_superseded = FALSE
  AND ic.claim_status = 'Covered'
  AND NOT EXISTS (
        SELECT 1
        FROM Treatment t
        WHERE t.claim_id = ic.claim_id
          AND t.treatment_status IN ('Pending', 'Accepted'))
ORDER BY cr.delivered_at
''';

  // QO5.2 [O5.1] นัดหมายการรักษา (Book Treatment)
  static const qO5_2 = r'''
SELECT s.slot_at,
  TO_CHAR(s.slot_at, 'Dy FMDD Mon - HH24:MI') AS slot_button,
  CASE
    WHEN t.treatment_id IS NULL THEN 'free' -- white
    WHEN t.officer_id = :officer_id
     AND t.treatment_status = 'Pending' THEN 'mine' -- purple
    ELSE 'busy' -- grey
  END AS slot_state
FROM generate_series(:date_from::date + TIME '09:00',
                     :date_to::date + TIME '16:00',
                     INTERVAL '1 hour') AS s(slot_at)
LEFT JOIN Treatment t
       ON t.facility_name = :facility_name
      AND t.scheduled_date + t.scheduled_time = s.slot_at
      AND t.treatment_status IN ('Pending', 'Accepted')
WHERE s.slot_at::time BETWEEN TIME '09:00' AND TIME '16:00'
  AND s.slot_at > NOW()
ORDER BY s.slot_at
''';

  // QO5.3 [O5.1] นัดหมายการรักษา (Book Treatment)
  static const qO5_3 = r'''
INSERT INTO Treatment
  (claim_id, report_id, officer_id, treatment_type,
   facility_name, scheduled_date, scheduled_time,
   treatment_status, created_at)
VALUES (:claim_id, :report_id, :officer_id, :treatment_type,
  :facility_name, :scheduled_date, :scheduled_time, 'Pending',
  NOW())
RETURNING treatment_id
''';

  /// Every Query ID of this class, for the test that compares the SQL with the report.
  static const all = <String, List<String>>{
    'QU4.1': [qU4_1],
    'QU4.2': [qU4_2],
    'QU4.3': [qU4_3],
    'Q6.1': [q6_1],
    'QO5.1': [qO5_1],
    'QO5.2': [qO5_2],
    'QO5.3': [qO5_3],
  };
}
