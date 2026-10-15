// GENERATED from docs/spec/database/queries.sql. Do not edit by hand.
// The test queries_match_report_test.dart makes sure that this text stays the same as the report.
// ignore_for_file: constant_identifier_names

/// SQL of [AppointmentRepository]. Each constant has the name of its Query ID.
abstract final class AppointmentSql {
  // Q3.2 [U3.1] ยืนยันนัดหมาย (Confirm Appointment)
  static const q3_2 = r'''
SELECT a.appointment_id,
  a.consultant_id,
  a.appointment_status,
  TO_CHAR(a.schedule_date + a.schedule_time,
    'FMDD / FMMM / YYYY" : "HH24:MI') AS appointment_date,
  CONCAT_WS(' ', o.first_name, o.last_name) AS scheduled_by,
  a.appointment_type,
  CONCAT_WS(' ', c.first_name, c.last_name) AS consultant_name,
  c.office_location,
  ic.claim_no,
  CONCAT_WS(', ', ic.injury_category, ic.body_part) AS injury,
  TO_CHAR(ic.injury_datetime, 'FMDD FMMonth YYYY') AS injury_date
FROM Appointment a
JOIN InjuryClaim ic ON ic.claim_id = a.claim_id
JOIN EvaluationOfficer o ON o.officer_id = a.officer_id
JOIN Consultant c ON c.consultant_id = a.consultant_id
WHERE a.claim_id = :claim_id
  AND ic.insured_id = :insured_id
  AND a.appointment_status IN ('Pending', 'Confirmed')
ORDER BY a.created_at DESC
LIMIT 1
''';

  // Q3.3 [U3.1] ยืนยันนัดหมาย (Confirm Appointment)
  static const q3_3 = r'''
WITH confirmed AS (
  UPDATE Appointment
  SET appointment_status = 'Confirmed'
  WHERE appointment_id = :appointment_id
    AND appointment_status = 'Pending'
  RETURNING appointment_id
)
INSERT INTO AppointmentConfirmation
  (appointment_id, channel, outcome, recorded_at)
SELECT appointment_id, 'application', 'Confirmed', NOW()
FROM confirmed
''';

  // Q3.4 [U3.2] ยืนยันนัดหมาย (Request Another Date)
  static const q3_4 = r'''
SELECT TO_CHAR(s.slot_at, 'HH24:MI') AS slot_time
FROM generate_series(:slot_date::date + TIME '09:00',
                     :slot_date::date + TIME '16:00',
                     INTERVAL '1 hour') AS s(slot_at)
WHERE s.slot_at > NOW()
  AND NOT EXISTS (
        SELECT 1
        FROM Appointment a
        WHERE a.consultant_id = :consultant_id
          AND a.schedule_date + a.schedule_time = s.slot_at
          AND a.appointment_status IN ('Pending', 'Confirmed'))
ORDER BY s.slot_at
''';

  // Q3.5 [U3.2] ยืนยันนัดหมาย (Request Another Date)
  static const q3_5 = r'''
WITH old AS (
  UPDATE Appointment
  SET appointment_status = 'Rescheduled'
  WHERE appointment_id = :appointment_id
    AND appointment_status IN ('Pending', 'Confirmed')
  RETURNING appointment_id, claim_id, officer_id, consultant_id,
    appointment_type, location
), new_appt AS (
  INSERT INTO Appointment
    (claim_id, officer_id, consultant_id, supersedes_appt_id,
     appointment_type, schedule_date, schedule_time, location,
     appointment_status, created_at)
  SELECT claim_id, officer_id, consultant_id, appointment_id,
    appointment_type, :new_date, :new_time, location,
    'Confirmed', NOW()
  FROM old
  RETURNING appointment_id
), confirmation AS (
  INSERT INTO AppointmentConfirmation
    (appointment_id, channel, outcome, recorded_at)
  SELECT appointment_id, 'application', 'Requested another date',
    NOW()
  FROM old
)
SELECT appointment_id FROM new_appt
''';

  // Q3.6 [U3.3] ยืนยันนัดหมาย (I cannot attend)
  static const q3_6 = r'''
WITH cancelled AS (
  UPDATE Appointment
  SET appointment_status = 'Cancelled'
  WHERE appointment_id = :appointment_id
    AND appointment_status IN ('Pending', 'Confirmed')
  RETURNING appointment_id
)
INSERT INTO AppointmentConfirmation
  (appointment_id, channel, outcome, recorded_at)
SELECT appointment_id, 'application', 'Cannot attend', NOW()
FROM cancelled
''';

  // QU5.1 [U5] ดูตารางนัดหมาย (View Appointment Schedule)
  static const qU5_1 = r'''
SELECT CONCAT_WS(' ', c.title_name, c.first_name, c.last_name)
    AS consultant_name,
  c.office_location,
  TO_CHAR(a.schedule_date + a.schedule_time,
    'FMDD FMMonth YYYY" : "HH24:MI') AS appointment_date,
  ic.claim_no,
  CONCAT_WS(', ', ic.injury_category, ic.body_part) AS injury,
  TO_CHAR(ic.injury_datetime, 'FMDD FMMonth YYYY') AS injury_date
FROM Appointment a
JOIN InjuryClaim ic ON ic.claim_id = a.claim_id
JOIN Consultant c ON c.consultant_id = a.consultant_id
WHERE ic.insured_id = :insured_id
  AND a.schedule_date >= CURRENT_DATE
  AND a.appointment_status IN ('Pending', 'Confirmed')
ORDER BY a.schedule_date, a.schedule_time
''';

  // QO4.1 [O4] สร้างนัดหมาย (Schedule Appointment)
  static const qO4_1 = r'''
SELECT ic.claim_id,
  ic.claim_no,
  CONCAT_WS(' ', ip.first_name, ip.last_name) AS user_name,
  TO_CHAR((SELECT MAX(ec.checked_at)
             FROM EligibilityCheck ec
            WHERE ec.claim_id = ic.claim_id
              AND ec.officer_id IS NOT NULL),
          'FMDD FMMonth YYYY') AS verified_date
FROM InjuryClaim ic
JOIN InsuredPerson ip ON ip.insured_id = ic.insured_id
WHERE ic.claim_status = 'Covered'
  AND NOT EXISTS (
        SELECT 1
        FROM Appointment a
        WHERE a.claim_id = ic.claim_id
          AND a.appointment_status IN ('Pending', 'Confirmed'))
ORDER BY ic.submitted_at
''';

  // QO4.2 [O4] สร้างนัดหมาย (Schedule Appointment)
  static const qO4_2 = r'''
SELECT c.consultant_id,
  CONCAT_WS(' ', c.title_name, c.first_name, c.last_name)
    AS consultant_name,
  c.office_location,
  s.slot_at,
  TO_CHAR(s.slot_at, 'Dy HH24:MI') AS slot_button,
  TO_CHAR(s.slot_at, 'Dy FMDD FMMonth YYYY') AS slot_date_text,
  TO_CHAR(s.slot_at, 'HH24:MI') || ' - ' ||
    TO_CHAR(s.slot_at + INTERVAL '1 hour', 'HH24:MI')
    AS slot_time_range,
  CASE
    WHEN a.appointment_id IS NULL THEN 'free' -- white
    WHEN a.officer_id = :officer_id
     AND a.appointment_status = 'Pending' THEN 'mine' -- purple
    ELSE 'busy' -- grey, not clickable
  END AS slot_state
FROM Consultant c
CROSS JOIN generate_series(:slot_date::date + TIME '09:00',
                           :slot_date::date + TIME '16:00',
                           INTERVAL '1 hour') AS s(slot_at)
LEFT JOIN Appointment a
       ON a.consultant_id = c.consultant_id
      AND a.schedule_date + a.schedule_time = s.slot_at
      AND a.appointment_status IN ('Pending', 'Confirmed')
ORDER BY consultant_name, s.slot_at
''';

  // QO4.3 [O4] สร้างนัดหมาย (Schedule Appointment)
  static const qO4_3 = r'''
INSERT INTO Appointment
  (claim_id, officer_id, consultant_id, appointment_type,
   schedule_date, schedule_time, location, appointment_status,
   confirm_deadline, created_at)
VALUES (:claim_id, :officer_id, :consultant_id,
  :appointment_type, :schedule_date, :schedule_time, :location,
  'Pending',
  :schedule_date::date + :schedule_time::time
    - INTERVAL '24 hours',
  NOW())
RETURNING appointment_id
''';

  // QC1.1 [C1] ดูตารางนัดหมาย (View Appointment Schedule)
  static const qC1_1 = r'''
SELECT a.appointment_id,
  CONCAT_WS(' ', ip.title_name, ip.first_name, ip.last_name)
    AS user_name,
  TO_CHAR(a.schedule_date + a.schedule_time,
    'FMDD FMMonth YYYY" : "HH24:MI') AS appointment_date,
  ic.claim_no,
  CONCAT_WS(', ', ic.injury_category, ic.body_part) AS injury,
  TO_CHAR(ic.injury_datetime, 'FMDD FMMonth YYYY') AS injury_date
FROM Appointment a
JOIN InjuryClaim ic ON ic.claim_id = a.claim_id
JOIN InsuredPerson ip ON ip.insured_id = ic.insured_id
WHERE a.consultant_id = :consultant_id
  AND a.appointment_status = 'Confirmed'
  AND a.schedule_date >= CURRENT_DATE
ORDER BY a.schedule_date, a.schedule_time
''';

  /// Every Query ID of this class, for the test that compares the SQL with the report.
  static const all = <String, List<String>>{
    'Q3.2': [q3_2],
    'Q3.3': [q3_3],
    'Q3.4': [q3_4],
    'Q3.5': [q3_5],
    'Q3.6': [q3_6],
    'QU5.1': [qU5_1],
    'QO4.1': [qO4_1],
    'QO4.2': [qO4_2],
    'QO4.3': [qO4_3],
    'QC1.1': [qC1_1],
  };
}
