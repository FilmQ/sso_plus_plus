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
  AND EXISTS (
        SELECT 1
        FROM InjuryClaim ic
        WHERE ic.claim_id = Treatment.claim_id
          AND ic.insured_id = :insured_id)
RETURNING treatment_id
''';

  // QU4.2 [U4.2] ยืนยันการรักษา (Change Date)
  static const qU4_2 = r'''
UPDATE Treatment
SET scheduled_date = :new_date::date,
    treatment_status = 'Accepted'
WHERE treatment_id = :treatment_id
  AND claim_id = :claim_id
  AND treatment_status = 'Pending'
  AND EXISTS (
        SELECT 1
        FROM InjuryClaim ic
        WHERE ic.claim_id = Treatment.claim_id
          AND ic.insured_id = :insured_id)
  AND :new_date::date BETWEEN CURRENT_DATE + 1 AND scheduled_date + 7
  AND :new_date::date <> scheduled_date
  AND EXTRACT(ISODOW FROM :new_date::date) < 6
  AND NOT EXISTS (
        SELECT 1
        FROM Treatment o
        WHERE o.facility_name = Treatment.facility_name
          AND o.treatment_status IN ('Pending', 'Accepted')
          AND o.treatment_id <> Treatment.treatment_id
          AND o.scheduled_date + o.scheduled_time
                < :new_date::date + Treatment.scheduled_time
                  + make_interval(mins => Treatment.duration_minutes)
          AND :new_date::date + Treatment.scheduled_time
                < o.scheduled_date + o.scheduled_time
                  + make_interval(mins => o.duration_minutes))
RETURNING treatment_id, scheduled_date, scheduled_time
''';

  // QU4.3 [U4.3] ยืนยันการรักษา (Reject)
  static const qU4_3 = r'''
WITH cancelled AS (
  UPDATE Treatment
  SET treatment_status = 'Cancelled'
  WHERE treatment_status = 'Pending'
    AND scheduled_date <= CURRENT_DATE
  RETURNING claim_id, facility_name, scheduled_date
), withdrawn AS (
  UPDATE InjuryClaim ic
  SET claim_status = 'Withdrawn'
  FROM (SELECT DISTINCT claim_id FROM cancelled) c
  WHERE ic.claim_id = c.claim_id
    AND ic.claim_status = 'Covered'
  RETURNING ic.claim_id
), history AS (
  INSERT INTO ClaimStatusHistory
    (claim_id, from_status, to_status, changed_at, change_reason)
  SELECT claim_id, 'Covered', 'Withdrawn', NOW(),
    'Treatment not accepted in time'
  FROM withdrawn
)
INSERT INTO Notification
  (claim_id, insured_id, subject, body, sent_at)
SELECT ic.claim_id,
  ic.insured_id,
  'Treatment cancelled',
  'Your treatment at ' || c.facility_name || ' on '
    || TO_CHAR(c.scheduled_date, 'FMDD FMMonth YYYY')
    || ' was cancelled because it was not accepted in time.'
    || ' Your claim ' || ic.claim_no || ' is now closed.',
  NOW()
FROM cancelled c
JOIN InjuryClaim ic ON ic.claim_id = c.claim_id
''';

  // QU4.4 [U4.1, U4.2] ยืนยันการรักษา (Accept Case) / ยืนยันการรักษา (Change Date)
  static const qU4_4 = r'''
SELECT t.treatment_id,
  t.claim_id,
  t.treatment_status,
  TO_CHAR(t.scheduled_date + t.scheduled_time,
    'FMDD / FMMM / YYYY" : "HH24:MI') AS treatment_date,
  t.treatment_type,
  t.duration_minutes,
  t.facility_name,
  CONCAT_WS(' ', o.first_name, o.last_name) AS booked_by,
  ic.claim_no,
  CONCAT_WS(', ', ic.injury_category, ic.body_part) AS injury,
  TO_CHAR(cr.signed_at, 'FMDD FMMonth YYYY') AS report_signed_date,
  CONCAT_WS(' ', c.title_name, c.first_name, c.last_name)
    AS report_author
FROM Treatment t
JOIN InjuryClaim ic ON ic.claim_id = t.claim_id
JOIN EvaluationOfficer o ON o.officer_id = t.officer_id
JOIN ConsultationReport cr ON cr.report_id = t.report_id
JOIN Consultant c ON c.consultant_id = cr.consultant_id
WHERE t.treatment_id = :treatment_id
  AND ic.insured_id = :insured_id
''';

  // QU4.5 [U4.2] ยืนยันการรักษา (Change Date)
  static const qU4_5 = r'''
SELECT s.slot_day::date AS slot_date,
  TO_CHAR(s.slot_day, 'Dy FMDD FMMonth YYYY') AS date_label
FROM Treatment t
JOIN InjuryClaim ic ON ic.claim_id = t.claim_id
CROSS JOIN LATERAL generate_series(
       (CURRENT_DATE + 1)::timestamp,
       (t.scheduled_date + 7)::timestamp,
       INTERVAL '1 day') AS s(slot_day)
WHERE t.treatment_id = :treatment_id
  AND ic.insured_id = :insured_id
  AND t.treatment_status = 'Pending'
  AND s.slot_day::date <> t.scheduled_date
  AND EXTRACT(ISODOW FROM s.slot_day) < 6
  AND NOT EXISTS (
        SELECT 1
        FROM Treatment o
        WHERE o.facility_name = t.facility_name
          AND o.treatment_status IN ('Pending', 'Accepted')
          AND o.treatment_id <> t.treatment_id
          AND o.scheduled_date + o.scheduled_time
                < s.slot_day::date + t.scheduled_time
                  + make_interval(mins => t.duration_minutes)
          AND s.slot_day::date + t.scheduled_time
                < o.scheduled_date + o.scheduled_time
                  + make_interval(mins => o.duration_minutes))
ORDER BY s.slot_day
''';

  // Q6.1 [U6] ดูตารางการรักษา (View Treatment Schedule)
  static const q6_1 = r'''
SELECT t.treatment_id,
  t.facility_name,
  t.treatment_type,
  t.duration_minutes,
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
  ip.title_name,
  CONCAT_WS(' ', ip.first_name, ip.last_name) AS user_name,
  cr.report_id,
  cr.version_no,
  TO_CHAR(cr.signed_at, 'FMDD FMMonth YYYY') AS signed_date,
  CONCAT_WS(' ', c.title_name, c.first_name, c.last_name)
    AS report_author,
  cs.recommended_treatment
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
    WHEN EXISTS (
           SELECT 1
           FROM Treatment m
           WHERE m.facility_name = :facility_name
             AND m.scheduled_date + m.scheduled_time = s.slot_at
             AND m.officer_id = :officer_id
             AND m.treatment_status = 'Pending') THEN 'mine' -- purple
    WHEN e.end_at > s.slot_at::date
           + CASE WHEN s.slot_at::time < TIME '12:00'
                  THEN TIME '12:00' ELSE TIME '17:00' END
      OR EXISTS (
           SELECT 1
           FROM Treatment t
           WHERE t.facility_name = :facility_name
             AND t.treatment_status IN ('Pending', 'Accepted')
             AND t.scheduled_date + t.scheduled_time < e.end_at
             AND s.slot_at < t.scheduled_date + t.scheduled_time
                   + make_interval(mins => t.duration_minutes))
      THEN 'busy' -- grey
    ELSE 'free' -- white
  END AS slot_state
FROM generate_series(:date_from::date + TIME '09:00',
                     :date_to::date + TIME '16:00',
                     INTERVAL '1 hour') AS s(slot_at)
CROSS JOIN LATERAL (
  SELECT s.slot_at + make_interval(mins => :duration_minutes::int)
    AS end_at) e
WHERE s.slot_at::time IN (TIME '09:00', TIME '10:00', TIME '11:00',
        TIME '13:00', TIME '14:00', TIME '15:00', TIME '16:00')
  AND s.slot_at > NOW()
  AND EXTRACT(ISODOW FROM s.slot_at) < 6
ORDER BY s.slot_at
''';

  // QO5.3 [O5.1] นัดหมายการรักษา (Book Treatment)
  static const qO5_3 = r'''
INSERT INTO Treatment
  (claim_id, report_id, officer_id, treatment_type,
   duration_minutes, facility_name, scheduled_date, scheduled_time,
   treatment_status, created_at)
SELECT ic.claim_id, cr.report_id, :officer_id, :treatment_type,
  :duration_minutes::int, :facility_name, :scheduled_date::date,
  :scheduled_time::time, 'Pending', NOW()
FROM ConsultationReport cr
JOIN ConsultationSession cs ON cs.session_id = cr.session_id
JOIN Appointment a ON a.appointment_id = cs.appointment_id
JOIN InjuryClaim ic ON ic.claim_id = a.claim_id
CROSS JOIN LATERAL (
  SELECT :scheduled_date::date + :scheduled_time::time AS start_at,
    :scheduled_date::date + :scheduled_time::time
      + make_interval(mins => :duration_minutes::int) AS end_at) v
WHERE cr.report_id = :report_id
  AND ic.claim_id = :claim_id
  AND cr.delivered_at IS NOT NULL
  AND cr.is_superseded = FALSE
  AND ic.claim_status = 'Covered'
  AND NOT EXISTS (
        SELECT 1
        FROM Treatment o
        WHERE o.claim_id = ic.claim_id
          AND o.treatment_status IN ('Pending', 'Accepted'))
  AND :treatment_type::varchar IN ('Physiotherapy',
        'Occupational therapy')
  AND :duration_minutes::int IN (30, 45, 60, 90, 120)
  AND :facility_name::varchar = 'SSO Rehabilitation Center'
  AND v.start_at > NOW()
  AND EXTRACT(ISODOW FROM v.start_at) < 6
  AND :scheduled_time::time IN (TIME '09:00', TIME '10:00',
        TIME '11:00', TIME '13:00', TIME '14:00', TIME '15:00',
        TIME '16:00')
  AND v.end_at <= :scheduled_date::date
        + CASE WHEN :scheduled_time::time < TIME '12:00'
               THEN TIME '12:00' ELSE TIME '17:00' END
  AND NOT EXISTS (
        SELECT 1
        FROM Treatment t
        WHERE t.facility_name = :facility_name
          AND t.treatment_status IN ('Pending', 'Accepted')
          AND t.scheduled_date + t.scheduled_time < v.end_at
          AND v.start_at < t.scheduled_date + t.scheduled_time
                + make_interval(mins => t.duration_minutes))
RETURNING treatment_id
''';

  /// Every Query ID of this class, for the test that compares the SQL with the report.
  static const all = <String, List<String>>{
    'QU4.1': [qU4_1],
    'QU4.2': [qU4_2],
    'QU4.3': [qU4_3],
    'QU4.4': [qU4_4],
    'QU4.5': [qU4_5],
    'Q6.1': [q6_1],
    'QO5.1': [qO5_1],
    'QO5.2': [qO5_2],
    'QO5.3': [qO5_3],
  };
}
