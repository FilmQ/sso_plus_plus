-- Moves the fixed dates of seed.sql near the load day for the demo (docs/DECISIONS.md, D-069). Only `make db-demo`
-- loads this file, because the tests expect the exact dates of seed.sql. It loads before 001_demo_data.sql, so the
-- demo rows do not use the slots of the moved seed rows.
-- The dates move by whole weeks, so each row keeps its weekday. The last seed day, Monday 19 October 2026, moves to
-- the last Monday on or before the load day (9 November 2026 for a load from 9 to 15 November 2026).
-- The rows that seed.sql already dates from the load day do not move: appointments 510, 512 and 513, the date of
-- treatment 403, and messages 907, 908 and 909 (but a weekend date of appointment 510 moves to Monday, see below).
-- Birth, register and contribution dates do not move.

CREATE TABLE seed_shift AS
SELECT 7 * ((CURRENT_DATE - DATE '2026-10-19') / 7) AS days, 7 * ((CURRENT_DATE - DATE '2026-10-19') / 7) * INTERVAL '1 day' AS shift,
  CASE EXTRACT(ISODOW FROM CURRENT_DATE + 5) WHEN 6 THEN 2 WHEN 7 THEN 1 ELSE 0 END AS appt_510_days;

UPDATE InsuredPerson SET created_at = created_at + s.shift FROM seed_shift s;

UPDATE InjuryClaim SET injury_datetime = injury_datetime + s.shift, submitted_at = submitted_at + s.shift,
  created_at = created_at + s.shift FROM seed_shift s;

UPDATE ClaimDocument SET uploaded_at = uploaded_at + s.shift, checked_at = checked_at + s.shift FROM seed_shift s;

-- The register reference has the date of the claim, as in the demo rows.
UPDATE EligibilityCheck e SET checked_at = e.checked_at + s.shift,
  evidence_ref = 'REG-' || TO_CHAR(c.submitted_at, 'YYYYMMDD') || '-' || LPAD(c.claim_id::text, 4, '0')
FROM seed_shift s, InjuryClaim c WHERE c.claim_id = e.claim_id;

UPDATE ClaimRejection SET rejection_timestamp = rejection_timestamp + s.shift, appeal_deadline = appeal_deadline + s.days
FROM seed_shift s;

UPDATE ClaimStatusHistory SET changed_at = changed_at + s.shift FROM seed_shift s;

UPDATE Appointment SET schedule_date = schedule_date + s.days, confirm_deadline = confirm_deadline + s.shift,
  created_at = created_at + s.shift
FROM seed_shift s WHERE appointment_id NOT IN (510, 512, 513);

UPDATE AppointmentConfirmation SET recorded_at = recorded_at + s.shift FROM seed_shift s;

UPDATE PhoneCallAttempt SET called_at = called_at + s.shift FROM seed_shift s;

UPDATE ConsultationSession SET started_at = started_at + s.shift, ended_at = ended_at + s.shift FROM seed_shift s;

UPDATE ConsultationReport SET signed_at = signed_at + s.shift, delivered_at = delivered_at + s.shift,
  read_at = read_at + s.shift FROM seed_shift s;

UPDATE Treatment SET created_at = created_at + s.shift,
  scheduled_date = CASE WHEN treatment_id = 403 THEN scheduled_date ELSE scheduled_date + s.days END
FROM seed_shift s;

-- Messages 902, 903 and 905 have the date of appointment 504 or treatment 402 in the text.
UPDATE Notification SET sent_at = sent_at + s.shift, read_at = read_at + s.shift,
  body = REPLACE(REPLACE(body,
    '16 October 2026', TO_CHAR(DATE '2026-10-16' + s.days, 'FMDD FMMonth YYYY')),
    '19 October 2026', TO_CHAR(DATE '2026-10-19' + s.days, 'FMDD FMMonth YYYY'))
FROM seed_shift s WHERE notification_id NOT IN (907, 908, 909);

-- seed.sql puts appointment 510 (U3 demo) 5 days after the load day, also on a Saturday or a Sunday. It moves to
-- the next Monday, with the dates in the text of messages 907 and 908. The appointment date changes first, because
-- the new deadline can have the old appointment date.
UPDATE Appointment SET schedule_date = schedule_date + s.appt_510_days,
  confirm_deadline = confirm_deadline + s.appt_510_days * INTERVAL '1 day'
FROM seed_shift s WHERE appointment_id = 510;

UPDATE Notification SET body = REPLACE(REPLACE(body,
    TO_CHAR(CURRENT_DATE + 5 + TIME '09:00', 'FMDD FMMonth YYYY" : "HH24:MI'),
    TO_CHAR(CURRENT_DATE + 5 + s.appt_510_days + TIME '09:00', 'FMDD FMMonth YYYY" : "HH24:MI')),
    TO_CHAR(CURRENT_DATE + 4 + TIME '09:00', 'FMDD FMMonth YYYY" : "HH24:MI'),
    TO_CHAR(CURRENT_DATE + 4 + s.appt_510_days + TIME '09:00', 'FMDD FMMonth YYYY" : "HH24:MI'))
FROM seed_shift s WHERE notification_id IN (907, 908);

-- On a Monday, the rows of 19 October move to the load day. A time later than now (treatment 403 is booked at
-- 11:00, message 905 is sent at 00:05) becomes now, so no event is in the future.
UPDATE Treatment SET created_at = LOCALTIMESTAMP WHERE created_at > LOCALTIMESTAMP;
UPDATE Notification SET sent_at = LOCALTIMESTAMP WHERE sent_at > LOCALTIMESTAMP;

DROP TABLE seed_shift;
