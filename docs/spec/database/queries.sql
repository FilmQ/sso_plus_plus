-- SST Injury Claim & Treatment Application: every SQL statement of the use case descriptions
-- Source: SA report section 2.16 (Query Table). PostgreSQL. Named parameters are written :name.
-- One block per Query ID; a block can hold several statements that run in one transaction.

-- Q1.1  [U1] ยื่นคำร้องกรณีประสบอันตราย (Submit Injury Application)
SELECT national_id, title_name, first_name, last_name,
  employer_account_no, employer_name, registration_date,
  contribution_start, contribution_end, contribution_months
FROM master_table
WHERE national_id = :national_id
  AND coverage_status = 'ACTIVE';

-- Q1.2  [U1] ยื่นคำร้องกรณีประสบอันตราย (Submit Injury Application)
SELECT COUNT(*) AS cnt
FROM InsuredPerson
WHERE national_id = :national_id;

-- Q1.3  [U1] ยื่นคำร้องกรณีประสบอันตราย (Submit Injury Application)
INSERT INTO InsuredPerson
  (national_id, title_name, first_name, last_name,
   date_of_birth, gender, phone_no, address, created_at)
VALUES (:national_id, :title_name, :first_name, :last_name,
   :date_of_birth, :gender, :phone_no, :address, NOW())
RETURNING insured_id;

-- Q1.4  [U1] ยื่นคำร้องกรณีประสบอันตราย (Submit Injury Application)
INSERT INTO Employer (sso_account_no, employer_name)
VALUES (:employer_account_no, :employer_name)
ON CONFLICT (sso_account_no) DO UPDATE
  SET employer_name = EXCLUDED.employer_name
RETURNING employer_id;

-- Q1.5  [U1] ยื่นคำร้องกรณีประสบอันตราย (Submit Injury Application)
INSERT INTO Section33Coverage
  (insured_id, employer_id, registration_date,
   contribution_start, contribution_end,
   contribution_months, coverage_status)
VALUES (:insured_id, :employer_id, :registration_date,
   :contribution_start, :contribution_end,
   :contribution_months, 'ACTIVE')
RETURNING coverage_id;

-- Q1.6  [U1] ยื่นคำร้องกรณีประสบอันตราย (Submit Injury Application)
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
RETURNING claim_id;

-- Q1.7  [U1] ยื่นคำร้องกรณีประสบอันตราย (Submit Injury Application)
UPDATE InjuryClaim
SET claim_no = 'SST-' || TO_CHAR(submitted_at, 'YYYY') || '-'
            || LPAD(claim_id::text, 6, '0')
WHERE claim_id = :claim_id
RETURNING claim_no, submitted_at;

-- Q1.8  [U1] ยื่นคำร้องกรณีประสบอันตราย (Submit Injury Application)
INSERT INTO ClaimDocument
  (claim_id, doc_type_id, file_name, file_uri, mime_type,
   file_size_bytes, uploaded_at, check_status)
VALUES (:claim_id, :doc_type_id, :file_name, :file_uri,
   :mime_type, :file_size_bytes, NOW(), 'Pending');

-- Q1.9  [U1] ยื่นคำร้องกรณีประสบอันตราย (Submit Injury Application)
INSERT INTO EligibilityCheck
  (claim_id, coverage_id, checked_at, result,
   is_override, evidence_ref)
VALUES (:claim_id, :coverage_id, NOW(), :register_result,
   FALSE, :evidence_ref);

-- Q1.10  [U1] ยื่นคำร้องกรณีประสบอันตราย (Submit Injury Application)
INSERT INTO ClaimStatusHistory
  (claim_id, to_status, changed_at, change_reason)
SELECT claim_id, claim_status, NOW(), 'Submitted by the user'
FROM InjuryClaim
WHERE claim_id = :claim_id;

-- Q2.1  [U2] ดูข้อความแจ้งเตือน (View Notify Message)
SELECT COUNT(*) AS unread
FROM Notification
WHERE insured_id = :insured_id
  AND read_at IS NULL;

-- Q2.2  [U2] ดูข้อความแจ้งเตือน (View Notify Message)
SELECT notification_id, claim_id, subject, body,
  TO_CHAR(sent_at, 'FMDD FMMonth YYYY" : "HH24:MI') AS sent_time,
  read_at IS NOT NULL AS is_read
FROM Notification
WHERE insured_id = :insured_id
ORDER BY sent_at DESC;

-- Q2.3  [U2] ดูข้อความแจ้งเตือน (View Notify Message)
UPDATE Notification
SET read_at = NOW()
WHERE notification_id = :notification_id
  AND insured_id = :insured_id
  AND read_at IS NULL;

-- Q2.4  [U2] ดูข้อความแจ้งเตือน (View Notify Message)
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
LIMIT 1;

-- Q3.1  [U3.1] ยืนยันนัดหมาย (Confirm Appointment)
SELECT COUNT(*) AS unread
FROM Notification
WHERE insured_id = :insured_id
  AND read_at IS NULL;

-- Q3.2  [U3.1] ยืนยันนัดหมาย (Confirm Appointment)
SELECT a.appointment_id,
  a.consultant_id,
  a.appointment_status,
  TO_CHAR(a.schedule_date + a.schedule_time,
    'FMDD / FMMM / YYYY" : "HH24:MI') AS appointment_date,
  CONCAT_WS(' ', o.first_name, o.last_name) AS scheduled_by,
  a.appointment_type,
  CONCAT_WS(' ', c.title_name, c.first_name, c.last_name)
    AS consultant_name,
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
LIMIT 1;

-- Q3.3  [U3.1] ยืนยันนัดหมาย (Confirm Appointment)
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
FROM confirmed;

-- Q3.4  [U3.2] ยืนยันนัดหมาย (Request Another Date)
SELECT TO_CHAR(s.slot_at, 'HH24:MI') AS slot_time
FROM generate_series(:slot_date::date + TIME '09:00',
                     :slot_date::date + TIME '15:00',
                     INTERVAL '1 hour') AS s(slot_at)
WHERE s.slot_at > NOW()
  AND s.slot_at::time <> TIME '12:00'
  AND NOT EXISTS (
        SELECT 1
        FROM Appointment a
        WHERE a.consultant_id = :consultant_id
          AND a.schedule_date + a.schedule_time = s.slot_at
          AND a.appointment_status IN ('Pending', 'Confirmed'))
ORDER BY s.slot_at;

-- Q3.5  [U3.2] ยืนยันนัดหมาย (Request Another Date)
WITH old AS (
  UPDATE Appointment
  SET appointment_status = 'Rescheduled'
  WHERE appointment_id = :appointment_id
    AND appointment_status IN ('Pending', 'Confirmed')
    AND :new_date::date + :new_time::time > NOW()
    AND NOT EXISTS (
          SELECT 1
          FROM Appointment b
          WHERE b.consultant_id = Appointment.consultant_id
            AND b.schedule_date = :new_date::date
            AND b.schedule_time = :new_time::time
            AND b.appointment_status IN ('Pending', 'Confirmed'))
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
SELECT appointment_id FROM new_appt;

-- Q3.6  [U3.3] ยืนยันนัดหมาย (I cannot attend)
WITH cancelled AS (
  UPDATE Appointment
  SET appointment_status = 'Cancelled'
  WHERE appointment_id = :appointment_id
    AND appointment_status IN ('Pending', 'Confirmed')
  RETURNING appointment_id, claim_id
), withdrawn AS (
  UPDATE InjuryClaim ic
  SET claim_status = 'Withdrawn'
  FROM cancelled
  WHERE ic.claim_id = cancelled.claim_id
    AND ic.claim_status = 'Covered'
  RETURNING ic.claim_id
), history AS (
  INSERT INTO ClaimStatusHistory
    (claim_id, from_status, to_status, changed_at, change_reason)
  SELECT claim_id, 'Covered', 'Withdrawn', NOW(),
    'User cannot attend the appointment'
  FROM withdrawn
)
INSERT INTO AppointmentConfirmation
  (appointment_id, channel, outcome, recorded_at)
SELECT appointment_id, 'application', 'Cannot attend', NOW()
FROM cancelled;

-- Q3.7  [U3.1, U3.2, U3.3] ยืนยันนัดหมาย (Confirm Appointment) / ยืนยันนัดหมาย (Request Another Date) / ยืนยันนัดหมาย (I cannot attend)
UPDATE Notification
SET read_at = NOW()
WHERE notification_id = :notification_id
  AND insured_id = :insured_id
  AND read_at IS NULL;

-- QU4.1  [U4.1] ยืนยันการรักษา (Accept Case)
UPDATE Treatment
SET treatment_status = 'Accepted'
WHERE treatment_id = :treatment_id
  AND claim_id = :claim_id
  AND treatment_status = 'Pending';

-- QU4.2  [U4.2] ยืนยันการรักษา (Change Date)
UPDATE treatment
SET scheduled_date = :new_date
WHERE claim_id = :current_claim_id
  AND treatment_id = :current_treatment_id
  AND treatment_status = 'Pending';

-- QU4.3  [U4.3] ยืนยันการรักษา (Reject)
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
JOIN InjuryClaim ic ON ic.claim_id = c.claim_id;

-- QU5.1  [U5] ดูตารางนัดหมาย (View Appointment Schedule)
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
ORDER BY a.schedule_date, a.schedule_time;

-- Q6.1  [U6] ดูตารางการรักษา (View Treatment Schedule)
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
ORDER BY t.scheduled_date, t.scheduled_time;

-- QO1.1  [O1] ดูคำร้องกรณีประสบอันตราย (View Injury Application)
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
ORDER BY ic.submitted_at;

-- QO1.2  [O1] ดูคำร้องกรณีประสบอันตราย (View Injury Application)
SELECT
  COUNT(*) FILTER (WHERE claim_status = 'Awaiting verification')
    AS awaiting_verification,
  COUNT(*) FILTER (WHERE claim_status = 'Needs review')
    AS reviews_needed,
  COUNT(*) FILTER (WHERE claim_status = 'Register unavailable')
    AS register_unavailable
FROM InjuryClaim;

-- QO1.3  [O1] ดูคำร้องกรณีประสบอันตราย (View Injury Application)
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
WHERE ic.claim_id = :claim_id;

-- QO1.4  [O1] ดูคำร้องกรณีประสบอันตราย (View Injury Application)
SELECT file_name,
  pg_size_pretty(file_size_bytes::bigint) AS file_size,
  file_uri
FROM ClaimDocument
WHERE claim_id = :claim_id
ORDER BY uploaded_at;

-- QO1.5  [O1] ดูคำร้องกรณีประสบอันตราย (View Injury Application)
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
LIMIT 1;

-- QO1.6  [O3] ปฏิเสธคำร้อง (Reject Injury Application)
SELECT reason_code, name_th, description
FROM RejectionReason
ORDER BY reason_code;

-- QO2.1  [O2] อนุมัติคำร้อง (Approve Injury Application)
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
SELECT decided.claim_id, ec.coverage_id, :officer_id, NOW(),
  :result::varchar, COALESCE(:result::varchar <> ec.result, FALSE),
  :override_reason::varchar, ec.evidence_ref
FROM decided
LEFT JOIN LATERAL (
  SELECT e.coverage_id, e.result, e.evidence_ref
  FROM EligibilityCheck e
  WHERE e.claim_id = decided.claim_id
    AND e.officer_id IS NULL
  ORDER BY e.checked_at DESC
  LIMIT 1
) ec ON TRUE;

-- QO3.1  [O3] ปฏิเสธคำร้อง (Reject Injury Application)
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
SELECT decided.claim_id, ec.coverage_id, :officer_id, NOW(),
  :result::varchar, COALESCE(:result::varchar <> ec.result, FALSE),
  :override_reason::varchar, ec.evidence_ref
FROM decided
LEFT JOIN LATERAL (
  SELECT e.coverage_id, e.result, e.evidence_ref
  FROM EligibilityCheck e
  WHERE e.claim_id = decided.claim_id
    AND e.officer_id IS NULL
  ORDER BY e.checked_at DESC
  LIMIT 1
) ec ON TRUE;

-- QO3.2  [O3] ปฏิเสธคำร้อง (Reject Injury Application)
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
FROM rejected;

-- QO4.1  [O4] สร้างนัดหมาย (Schedule Appointment)
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
ORDER BY ic.submitted_at;

-- QO4.2  [O4] สร้างนัดหมาย (Schedule Appointment)
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
                           :slot_date::date + TIME '15:00',
                           INTERVAL '1 hour') AS s(slot_at)
LEFT JOIN Appointment a
       ON a.consultant_id = c.consultant_id
      AND a.schedule_date + a.schedule_time = s.slot_at
      AND a.appointment_status IN ('Pending', 'Confirmed')
WHERE s.slot_at::time <> TIME '12:00'
ORDER BY consultant_name, s.slot_at;

-- QO4.3  [O4] สร้างนัดหมาย (Schedule Appointment)
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
RETURNING appointment_id;

-- QO5.1  [O5.1] นัดหมายการรักษา (Book Treatment)
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
ORDER BY cr.delivered_at;

-- QO5.2  [O5.1] นัดหมายการรักษา (Book Treatment)
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
ORDER BY s.slot_at;

-- QO5.3  [O5.1] นัดหมายการรักษา (Book Treatment)
INSERT INTO Treatment
  (claim_id, report_id, officer_id, treatment_type,
   facility_name, scheduled_date, scheduled_time,
   treatment_status, created_at)
VALUES (:claim_id, :report_id, :officer_id, :treatment_type,
  :facility_name, :scheduled_date, :scheduled_time, 'Pending',
  NOW())
RETURNING treatment_id;

-- QO5.4  [O5.2] นัดหมายการรักษา (No Treatment Required)
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
JOIN closed ON closed.claim_id = prev.claim_id;

-- QO6.1  [O6] ดูรายงานการให้คำปรึกษา (View Consultation Report)
SELECT cr.report_id,
  ic.claim_no,
  CONCAT_WS(' ', ip.first_name, ip.last_name) AS user_name,
  cr.version_no,
  TO_CHAR(cr.signed_at, 'FMDD FMMonth YYYY') AS signed_date,
  CASE WHEN cr.read_at IS NULL THEN 'Pending' ELSE 'Viewed' END
    AS view_status
FROM ConsultationReport cr
JOIN ConsultationSession cs ON cs.session_id = cr.session_id
JOIN Appointment a ON a.appointment_id = cs.appointment_id
JOIN InjuryClaim ic ON ic.claim_id = a.claim_id
JOIN InsuredPerson ip ON ip.insured_id = ic.insured_id
WHERE cr.delivered_at IS NOT NULL
  AND cr.is_superseded = FALSE
ORDER BY cr.read_at IS NOT NULL, cr.delivered_at DESC;

-- QO6.2  [O6] ดูรายงานการให้คำปรึกษา (View Consultation Report)
SELECT ic.claim_no,
  CONCAT_WS(' ', ip.first_name, ip.last_name) AS user_name,
  TO_CHAR(cr.signed_at, 'FMDD FMMonth YYYY') AS signed_date,
  cr.version_no,
  DATE_PART('year', AGE(ip.date_of_birth))::int AS user_age,
  TO_CHAR(cs.started_at, 'FMDD FMMonth YYYY" : "HH24:MI')
    AS consultation_datetime,
  TO_CHAR(cr.delivered_at, 'FMDD FMMonth YYYY') AS submitted_date,
  CONCAT_WS(' ', c.title_name, c.first_name, c.last_name)
    AS consultant_name,
  cr.report_content,
  CASE WHEN cr.signed_at IS NULL THEN 'Signature pending'
       ELSE 'Signature signed' END AS signature_status,
  CASE WHEN cr.read_at IS NULL THEN 'Pending' ELSE 'Viewed' END
    AS view_status
FROM ConsultationReport cr
JOIN ConsultationSession cs ON cs.session_id = cr.session_id
JOIN Appointment a ON a.appointment_id = cs.appointment_id
JOIN InjuryClaim ic ON ic.claim_id = a.claim_id
JOIN InsuredPerson ip ON ip.insured_id = ic.insured_id
JOIN Consultant c ON c.consultant_id = cr.consultant_id
WHERE cr.report_id = :report_id;

-- QO6.3  [O6] ดูรายงานการให้คำปรึกษา (View Consultation Report)
UPDATE ConsultationReport
SET read_at = NOW()
WHERE report_id = :report_id
  AND read_at IS NULL;

-- QC1.1  [C1] ดูตารางนัดหมาย (View Appointment Schedule)
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
ORDER BY a.schedule_date, a.schedule_time;

-- QC2.1  [C2.1] สร้างรายงานการให้คำปรึกษา (Amend the Draft)
SELECT a.appointment_id,
  ic.claim_no,
  CONCAT_WS(' ', ip.first_name, ip.last_name) AS user_name,
  TO_CHAR(a.schedule_date + a.schedule_time,
    'FMDD FMMonth YYYY" : "HH24:MI') AS consultation_datetime
FROM Appointment a
JOIN InjuryClaim ic ON ic.claim_id = a.claim_id
JOIN InsuredPerson ip ON ip.insured_id = ic.insured_id
WHERE a.consultant_id = :consultant_id
  AND a.appointment_status = 'Confirmed'
  AND a.schedule_date + a.schedule_time <= NOW()
  AND NOT EXISTS (
        SELECT 1
        FROM ConsultationSession cs
        JOIN ConsultationReport cr ON cr.session_id = cs.session_id
        WHERE cs.appointment_id = a.appointment_id
          AND cr.delivered_at IS NOT NULL)
ORDER BY a.schedule_date, a.schedule_time;

-- QC2.2  [C2.1] สร้างรายงานการให้คำปรึกษา (Amend the Draft)
INSERT INTO ConsultationSession
  (appointment_id, consultant_id, officer_id, started_at,
   attendance, session_status)
SELECT a.appointment_id, a.consultant_id, a.officer_id,
  a.schedule_date + a.schedule_time, 'Attended', 'Completed'
FROM Appointment a
WHERE a.appointment_id = :appointment_id
  AND NOT EXISTS (
        SELECT 1
        FROM ConsultationSession cs
        WHERE cs.appointment_id = a.appointment_id);

-- QC2.3  [C2.1] สร้างรายงานการให้คำปรึกษา (Amend the Draft)
SELECT cs.session_id,
  ic.claim_no,
  CONCAT_WS(' ', ip.first_name, ip.last_name) AS user_name,
  DATE_PART('year', AGE(ip.date_of_birth))::int AS user_age,
  TO_CHAR(cs.started_at, 'FMDD FMMonth YYYY" : "HH24:MI')
    AS consultation_datetime,
  CONCAT_WS(' ', c.title_name, c.first_name, c.last_name)
    AS consultant_name,
  cr.report_id,
  COALESCE(cr.version_no, 1) AS version_no,
  cr.report_content,
  TO_CHAR(cr.signed_at, 'FMDD FMMonth YYYY') AS signed_date,
  CASE WHEN cr.signed_at IS NULL THEN 'Signature pending'
       ELSE 'Signature signed' END AS signature_status
FROM ConsultationSession cs
JOIN Appointment a ON a.appointment_id = cs.appointment_id
JOIN InjuryClaim ic ON ic.claim_id = a.claim_id
JOIN InsuredPerson ip ON ip.insured_id = ic.insured_id
JOIN Consultant c ON c.consultant_id = cs.consultant_id
LEFT JOIN ConsultationReport cr
       ON cr.session_id = cs.session_id
      AND cr.is_superseded = FALSE
WHERE cs.appointment_id = :appointment_id;

-- QC2.4  [C2.1] สร้างรายงานการให้คำปรึกษา (Amend the Draft)
INSERT INTO ConsultationReport
  (session_id, consultant_id, version_no, report_content,
   is_superseded)
VALUES (:session_id, :consultant_id, 1, :report_content, FALSE)
RETURNING report_id;

-- QC2.5  [C2.1] สร้างรายงานการให้คำปรึกษา (Amend the Draft)
UPDATE ConsultationReport
SET report_content = :report_content,
    signed_at = NULL
WHERE report_id = :report_id
  AND consultant_id = :consultant_id
  AND delivered_at IS NULL;

-- QC2.6  [C2.2] สร้างรายงานการให้คำปรึกษา (Sign the Signature)
UPDATE ConsultationReport
SET signed_at = NOW()
WHERE report_id = :report_id
  AND consultant_id = :consultant_id
  AND report_content IS NOT NULL
  AND signed_at IS NULL;

-- QC2.7  [C2.3] สร้างรายงานการให้คำปรึกษา (File the Report)
UPDATE ConsultationReport
SET delivered_at = NOW()
WHERE report_id = :report_id
  AND consultant_id = :consultant_id
  AND report_content IS NOT NULL
  AND signed_at IS NOT NULL
  AND delivered_at IS NULL
RETURNING report_id;

-- QN.1  [O2, O5.1] อนุมัติคำร้อง (Approve Injury Application) / นัดหมายการรักษา (Book Treatment)
INSERT INTO Notification
  (claim_id, insured_id, subject, body, sent_at)
SELECT claim_id, insured_id, :subject, :body, NOW()
FROM InjuryClaim
WHERE claim_id = :claim_id;

-- QN.2  [O3] ปฏิเสธคำร้อง (Reject Injury Application)
INSERT INTO Notification
  (claim_id, insured_id, subject, body, sent_at)
SELECT ic.claim_id,
  ic.insured_id,
  'Application rejected',
  CONCAT_WS(E'\n\n', rr.description, cr.officer_message),
  NOW()
FROM ClaimRejection cr
JOIN InjuryClaim ic ON ic.claim_id = cr.claim_id
JOIN RejectionReason rr ON rr.reason_code = cr.reason_code
WHERE cr.claim_id = :claim_id
  AND cr.is_superseded = FALSE;

-- QN.3  [O4] สร้างนัดหมาย (Schedule Appointment)
WITH appt AS (
  SELECT a.claim_id, ic.insured_id, a.consultant_id, ic.claim_no,
    a.location,
    CONCAT_WS(' ', c.title_name, c.first_name, c.last_name)
      AS consultant_name,
    CONCAT_WS(' ', ip.title_name, ip.first_name, ip.last_name)
      AS user_name,
    TO_CHAR(a.schedule_date + a.schedule_time,
      'FMDD FMMonth YYYY" : "HH24:MI') AS appt_time,
    TO_CHAR(a.confirm_deadline, 'FMDD FMMonth YYYY" : "HH24:MI')
      AS confirm_by
  FROM Appointment a
  JOIN InjuryClaim ic ON ic.claim_id = a.claim_id
  JOIN InsuredPerson ip ON ip.insured_id = ic.insured_id
  JOIN Consultant c ON c.consultant_id = a.consultant_id
  WHERE a.appointment_id = :appointment_id
)
INSERT INTO Notification
  (claim_id, insured_id, consultant_id, subject, body, sent_at)
SELECT claim_id, insured_id, NULL, 'Appointment scheduled',
  CONCAT('Your appointment with ', consultant_name, ' is on ',
    appt_time, ' at ', location,
    '. Please confirm it in the application by ', confirm_by,
    '.'),
  NOW()
FROM appt
UNION ALL
SELECT claim_id, NULL, consultant_id, 'New appointment',
  CONCAT(user_name, ' (claim ', claim_no,
    ') is booked with you on ', appt_time, ' at ', location,
    '. Waiting for the patient to confirm.'),
  NOW()
FROM appt;

-- QN.4  [O5.2] นัดหมายการรักษา (No Treatment Required)
INSERT INTO Notification
  (claim_id, insured_id, subject, body, sent_at)
SELECT claim_id, insured_id, 'No treatment required',
  CONCAT('The consultation report for your claim ', claim_no,
  ' says no treatment is required, so your claim is now closed.'),
  NOW()
FROM InjuryClaim
WHERE claim_id = :claim_id
  AND claim_status = 'No treatment required';

-- QN.5  [U3.1, U3.2, U3.3] ยืนยันนัดหมาย (Confirm Appointment) / ยืนยันนัดหมาย (Request Another Date) / ยืนยันนัดหมาย (I cannot attend)
WITH appt AS (
  SELECT a.claim_id, a.consultant_id, a.appointment_status,
    a.supersedes_appt_id, a.location, ic.claim_no,
    CONCAT_WS(' ', ip.title_name, ip.first_name, ip.last_name)
      AS user_name,
    TO_CHAR(a.schedule_date + a.schedule_time,
      'FMDD FMMonth YYYY" : "HH24:MI') AS appt_time
  FROM Appointment a
  JOIN InjuryClaim ic ON ic.claim_id = a.claim_id
  JOIN InsuredPerson ip ON ip.insured_id = ic.insured_id
  WHERE a.appointment_id = :appointment_id
)
INSERT INTO Notification
  (claim_id, insured_id, consultant_id, subject, body, sent_at)
SELECT claim_id, NULL, consultant_id,
  CASE
    WHEN appointment_status = 'Cancelled' THEN 'Appointment cancelled'
    WHEN supersedes_appt_id IS NOT NULL THEN 'Appointment rescheduled'
    ELSE 'Appointment confirmed'
  END,
  CASE
    WHEN appointment_status = 'Cancelled' THEN
      CONCAT(user_name, ' (claim ', claim_no,
        ') cannot attend the appointment on ', appt_time,
        '. The appointment is cancelled and the claim is withdrawn.')
    WHEN supersedes_appt_id IS NOT NULL THEN
      CONCAT(user_name, ' (claim ', claim_no,
        ') moved the appointment to ', appt_time, ' at ', location, '.')
    ELSE
      CONCAT(user_name, ' (claim ', claim_no,
        ') confirmed the appointment on ', appt_time, ' at ',
        location, '.')
  END,
  NOW()
FROM appt;
