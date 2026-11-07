-- Extra made-up data for the demo (docs/DECISIONS.md, D-066). Only `make db-demo` loads this file.
-- The tests and `make db-reset` do not load it, because they expect the exact rows of seed.sql.
-- All people, national IDs and phone numbers are made up. The password of each account is Password123.
-- To change the quantity of claims, change the numbers in the "stage" list. Dates start from the load day.

CREATE TABLE demo_day AS
SELECT ROW_NUMBER() OVER (ORDER BY d)::int AS n, d
FROM (SELECT CURRENT_DATE + g AS d FROM generate_series(1, 200) g) f
WHERE EXTRACT(ISODOW FROM d) < 6
UNION ALL
SELECT -ROW_NUMBER() OVER (ORDER BY d DESC)::int, d
FROM (SELECT CURRENT_DATE - g AS d FROM generate_series(1, 200) g) p
WHERE EXTRACT(ISODOW FROM d) < 6;

-- One row for each claim. Each later statement reads this plan and takes the rows that its stage needs.
-- Appointment slots are unique in each group. Hour 09:00 stays free, and the slots do not use the seed rows
-- 510, 512 and 513. Treatment hours do not use 10:00, the hour of seed treatment 403.
CREATE TABLE demo_plan AS
WITH stage (ord, stage, claims, slot_group) AS (VALUES
  (1, 'verify', 12, NULL),            -- O1 to O3: Verification list
  (2, 'unavailable', 3, NULL),        -- O1 to O3: Verification list, register check failed
  (3, 'schedule', 10, NULL),          -- O4: Scheduling list
  (4, 'pending', 8, 'future'),        -- U3: the user must confirm
  (5, 'confirmed', 10, 'future'),     -- U5, C1: future appointments
  (6, 'report_due', 6, 'past'),       -- C2: consultation finished, no report
  (7, 'draft', 3, 'past'),            -- C2: draft report, not signed
  (8, 'noshow', 2, 'past'),           -- O4: user did not attend, the claim is on the list again
  (9, 'filed', 8, 'past'),            -- O6, O5: filed report, no treatment
  (10, 'treat_pending', 6, 'past'),   -- U4, U6: the user must accept
  (11, 'treat_accepted', 6, 'past'),  -- U6: accepted treatment
  (12, 'treat_cancelled', 2, 'past'), -- U4.3: not accepted in time, claim withdrawn
  (13, 'no_treatment', 3, 'past'),    -- O5.2: closed claim
  (14, 'rejected', 5, NULL),          -- O3: rejected claim
  (15, 'withdrawn', 2, 'past')        -- U3.3: user cannot attend, claim withdrawn
), numbered AS (
  SELECT s.stage, s.slot_group, g AS k,
    ROW_NUMBER() OVER (ORDER BY s.ord, g)::int AS i,
    (ROW_NUMBER() OVER (PARTITION BY s.slot_group ORDER BY s.ord, g) - 1)::int AS j,
    (ROW_NUMBER() OVER (PARTITION BY s.stage IN ('treat_pending', 'treat_accepted') ORDER BY s.ord, g) - 1)::int AS t
  FROM stage s CROSS JOIN LATERAL generate_series(1, s.claims) g
), scenario (s, place, cause, body_part, category, findings, diagnosis) AS (VALUES
  (0, 'Assembly line 4, Rangsit, Pathum Thani', 'Hand caught between two metal parts', 'left hand', 'Crush injury', 'Swelling and bruises on the left hand', 'Crush injury of the left hand'),
  (1, 'Warehouse 5, Bang Na, Bangkok', 'Fell from a forklift step', 'right knee', 'Sprain', 'Pain and swelling of the right knee', 'Sprain of the right knee'),
  (2, 'Welding bay 2, Bang Pu, Samut Prakan', 'Hot metal hit the arm', 'right forearm', 'Burn', 'Healing burn, no infection', 'Second-degree burn, right forearm'),
  (3, 'Packing line 1, Pak Kret, Nonthaburi', 'Cut by a box cutter', 'left thumb', 'Cut', 'Closed wound with stitches', 'Deep cut of the left thumb'),
  (4, 'Loading dock, Khlong Luang, Pathum Thani', 'Lifted a heavy pallet', 'lower back', 'Back strain', 'Muscle spasm in the lower back', 'Lumbar muscle strain'),
  (5, 'Machine shop, Bang Phli, Samut Prakan', 'Struck by a falling tool', 'right foot', 'Fracture', 'Limited movement of the right foot', 'Metatarsal fracture, right foot'),
  (6, 'Cold storage 3, Lat Krabang, Bangkok', 'Slipped on an icy floor', 'left ankle', 'Sprain', 'Swelling of the left ankle', 'Sprain of the left ankle'),
  (7, 'Paint line, Bang Bo, Samut Prakan', 'Chemical splash on the skin', 'left arm', 'Burn', 'Red skin, healing well', 'Chemical burn, left arm'),
  (8, 'Stamping line 2, Si Racha, Chon Buri', 'Finger pressed in a stamping machine', 'right index finger', 'Fracture', 'Stiff right index finger', 'Fracture of the right index finger'),
  (9, 'Warehouse 2, Lam Luk Ka, Pathum Thani', 'Fell from a ladder', 'left shoulder', 'Other', 'Pain when the left shoulder moves', 'Rotator cuff strain, left shoulder'),
  (10, 'Timber yard, Bang Bua Thong, Nonthaburi', 'Cut by a saw blade', 'right palm', 'Cut', 'Healing wound of the right palm', 'Deep cut of the right palm'),
  (11, 'Delivery bay, Bang Khen, Bangkok', 'Twisted the back while lifting', 'middle back', 'Back strain', 'Pain when the back bends', 'Thoracic muscle strain')
), planned AS (
  SELECT n.*, sc.place, sc.cause, sc.body_part, sc.category, sc.findings, sc.diagnosis,
    164 + n.i AS claim_id, 110 + n.i AS insured_id, 210 + n.i AS coverage_id,
    11 + n.i % 10 AS employer_id, 1 + n.i % 5 AS officer_id,
    CASE WHEN n.j % 2 = 0 THEN 1 ELSE 2 + (n.j / 2) % 4 END AS consultant_id,
    CASE n.slot_group WHEN 'future' THEN 2 + n.j / 5 WHEN 'past' THEN -(2 + n.j / 5) END AS day_n,
    make_time((ARRAY[10, 11, 13, 14, 15])[1 + n.j % 5], 0, 0) AS appt_time,
    CASE n.i % 3 WHEN 0 THEN 'นาย' WHEN 1 THEN 'นาง' ELSE 'นางสาว' END AS title_name,
    CASE n.i % 3 WHEN 0 THEN 'M' ELSE 'F' END AS gender,
    CASE WHEN n.i % 3 = 0
      THEN (ARRAY['อนุชา', 'ณัฐพล', 'สุรชัย', 'วิชัย', 'ธนกร', 'ปรีชา', 'กฤษณะ', 'อดิศร', 'พงศกร', 'เอกชัย'])[1 + (n.i / 3) % 10]
      ELSE (ARRAY['สุภาพร', 'กาญจนา', 'นิภา', 'ปิยะดา', 'รัตนา', 'ศิริลักษณ์', 'จันทร์เพ็ญ', 'ดวงใจ', 'มณีรัตน์', 'ลัดดา', 'พรทิพย์', 'เบญจมาศ'])[1 + n.i % 12]
    END AS first_name,
    (ARRAY['บุญมี', 'ศรีสมบูรณ์', 'แก้วกล้า', 'รักษาดี', 'ทองสุข', 'พูนผล', 'เจริญยิ่ง', 'มีชัย', 'สายบุญ', 'วงศ์ไทย', 'ดีเลิศ', 'ใจเย็น', 'คำแสน', 'สมบัติ'])[1 + (n.i * 5) % 14] AS last_name,
    n.i || '/' || (1 + n.i % 9) || ' ' || (ARRAY['ถ.รังสิต-นครนายก ต.คลองหก อ.คลองหลวง จ.ปทุมธานี 12120', 'ถ.สุขุมวิท ต.บางปูใหม่ อ.เมือง จ.สมุทรปราการ 10280', 'ถ.แจ้งวัฒนะ ต.ปากเกร็ด อ.ปากเกร็ด จ.นนทบุรี 11120', 'ถ.ลาดกระบัง แขวงลาดกระบัง เขตลาดกระบัง กรุงเทพฯ 10520', 'ถ.สุขุมวิท ต.ศรีราชา อ.ศรีราชา จ.ชลบุรี 20110'])[1 + n.i % 5] AS address,
    (CASE n.stage
      WHEN 'verify' THEN LOCALTIMESTAMP - n.k * INTERVAL '9 hours'
      WHEN 'unavailable' THEN LOCALTIMESTAMP - n.k * INTERVAL '9 hours'
      WHEN 'schedule' THEN LOCALTIMESTAMP - INTERVAL '3 days' - n.k * INTERVAL '7 hours'
      WHEN 'rejected' THEN LOCALTIMESTAMP - INTERVAL '3 days' - n.k * INTERVAL '1 day'
      WHEN 'pending' THEN LOCALTIMESTAMP - INTERVAL '3 days' - n.k * INTERVAL '5 hours'
      WHEN 'confirmed' THEN LOCALTIMESTAMP - INTERVAL '3 days' - n.k * INTERVAL '5 hours'
    END) AS recent_submit
  FROM numbered n JOIN scenario sc ON sc.s = n.i % 12
)
SELECT p.*, c.office_location AS location,
  CONCAT_WS(' ', c.title_name, c.first_name, c.last_name) AS consultant_name,
  CONCAT_WS(' ', p.title_name, p.first_name, p.last_name) AS user_name,
  'SST-' || TO_CHAR(COALESCE(p.recent_submit, a.d + p.appt_time - INTERVAL '9 days'), 'YYYY') || '-' || LPAD(p.claim_id::text, 6, '0') AS claim_no,
  a.d AS appt_date,
  a.d + p.appt_time AS appt_at,
  COALESCE(p.recent_submit, a.d + p.appt_time - INTERVAL '9 days') AS submitted_at,
  COALESCE(p.recent_submit, a.d + p.appt_time - INTERVAL '9 days') + INTERVAL '2 days' AS officer_at,
  COALESCE(p.recent_submit, a.d + p.appt_time - INTERVAL '9 days') + INTERVAL '3 days' AS appt_created,
  TO_CHAR(a.d + p.appt_time, 'FMDD FMMonth YYYY" : "HH24:MI') AS appt_text,
  TO_CHAR(a.d + p.appt_time - INTERVAL '1 day', 'FMDD FMMonth YYYY" : "HH24:MI') AS confirm_by,
  CASE
    WHEN p.stage = 'no_treatment' OR (p.stage = 'filed' AND p.k % 4 = 0) THEN 'None'
    WHEN p.i % 2 = 0 THEN 'Physiotherapy'
    ELSE 'Occupational therapy'
  END AS recommended,
  CASE WHEN p.stage = 'treat_cancelled' THEN x.d ELSE f.d END AS treat_date,
  CASE WHEN p.stage = 'treat_cancelled' THEN TIME '10:00'
       ELSE make_time((ARRAY[9, 11, 13, 14, 15, 16])[1 + p.t % 6], 0, 0) END AS treat_time
FROM planned p
LEFT JOIN Consultant c ON c.consultant_id = p.consultant_id AND p.slot_group IS NOT NULL
LEFT JOIN demo_day a ON a.n = p.day_n
LEFT JOIN demo_day f ON f.n = 2 + p.t / 3
LEFT JOIN demo_day x ON x.n = p.day_n + 2;

-- The register stub, the employers and the people.
INSERT INTO Employer (employer_id, sso_account_no, employer_name, branch_name, phone_no, address) OVERRIDING SYSTEM VALUE VALUES
  (16, '1000700001', 'Rangsit Food Products Co., Ltd.', 'สำนักงานใหญ่', '025160011', '77 ม.3 ต.คลองหก อ.คลองหลวง จ.ปทุมธานี 12120'),
  (17, '1000700002', 'Samut Prakan Metal Works Co., Ltd.', 'สาขาบางบ่อ', '023380022', '150 ม.8 ต.บางบ่อ อ.บางบ่อ จ.สมุทรปราการ 10560'),
  (18, '1000700003', 'Laem Chabang Auto Parts Co., Ltd.', 'สาขาศรีราชา', '038490033', '210 ม.6 ต.ทุ่งสุขลา อ.ศรีราชา จ.ชลบุรี 20230'),
  (19, '1000700004', 'Nonthaburi Timber Co., Ltd.', 'สำนักงานใหญ่', '029230044', '35 ม.2 ต.บางบัวทอง อ.บางบัวทอง จ.นนทบุรี 11110'),
  (20, '1000700005', 'Lat Krabang Cold Storage Co., Ltd.', 'สำนักงานใหญ่', '023260055', '19 ถ.ฉลองกรุง แขวงลำปลาทิว เขตลาดกระบัง กรุงเทพฯ 10520');

INSERT INTO master_table (national_id, title_name, first_name, last_name, coverage_status, employer_account_no, employer_name, registration_date, contribution_start, contribution_end, contribution_months)
SELECT '17777' || LPAD(p.i::text, 8, '0'), p.title_name, p.first_name, p.last_name, 'ACTIVE', e.sso_account_no, e.employer_name,
  DATE '2015-01-05' + p.i * 31, DATE '2015-02-01' + p.i * 31, NULL, 60 + p.i % 60
FROM demo_plan p JOIN Employer e ON e.employer_id = p.employer_id;

INSERT INTO InsuredPerson (insured_id, national_id, title_name, first_name, last_name, date_of_birth, gender, phone_no, email, address, created_at) OVERRIDING SYSTEM VALUE
SELECT insured_id, '17777' || LPAD(i::text, 8, '0'), title_name, first_name, last_name, DATE '1975-01-15' + (i * 137) % 9000, gender,
  '0' || (850000000 + i * 1013)::text, NULL, address, submitted_at - INTERVAL '5 minutes'
FROM demo_plan;

INSERT INTO Section33Coverage (coverage_id, insured_id, employer_id, registration_date, contribution_start, contribution_end, contribution_months, coverage_status) OVERRIDING SYSTEM VALUE
SELECT coverage_id, insured_id, employer_id, DATE '2015-01-05' + i * 31, DATE '2015-02-01' + i * 31, NULL, 60 + i % 60, 'ACTIVE'
FROM demo_plan;

-- The claims and their three documents. The documents use the demo files of claim 161, so "View" opens a real file.
INSERT INTO InjuryClaim (claim_id, claim_no, insured_id, employer_id, injury_datetime, injury_place, injury_cause, body_part, injury_category, claim_status, submitted_at, created_at) OVERRIDING SYSTEM VALUE
SELECT claim_id, claim_no, insured_id, employer_id, submitted_at - (1 + i % 4) * INTERVAL '1 day' - INTERVAL '2 hours', place, cause, body_part, category,
  CASE stage
    WHEN 'verify' THEN 'Awaiting verification'
    WHEN 'unavailable' THEN 'Register unavailable'
    WHEN 'rejected' THEN 'Rejected'
    WHEN 'no_treatment' THEN 'No treatment required'
    WHEN 'treat_cancelled' THEN 'Withdrawn'
    WHEN 'withdrawn' THEN 'Withdrawn'
    ELSE 'Covered'
  END, submitted_at, submitted_at
FROM demo_plan;

INSERT INTO ClaimDocument (claim_id, doc_type_id, file_name, file_uri, mime_type, file_size_bytes, uploaded_at, check_status)
SELECT p.claim_id, d.doc_type_id, d.file_name, '/claims/161/' || d.file_name, d.mime_type, d.size + p.i * 1024, p.submitted_at - INTERVAL '2 minutes', 'Pending'
FROM demo_plan p CROSS JOIN (VALUES
  (1, 'id_card.jpg', 'image/jpeg', 982016),
  (2, 'medical_record_bangphli.pdf', 'application/pdf', 704512),
  (3, 'injury_form_kt16.pdf', 'application/pdf', 296960)
) d (doc_type_id, file_name, mime_type, size);

-- The automatic check (Q1.9) and the officer's check (QO2.1, QO3.1).
INSERT INTO EligibilityCheck (claim_id, coverage_id, officer_id, checked_at, result, is_override, override_reason, evidence_ref)
SELECT claim_id, CASE WHEN stage = 'unavailable' THEN NULL ELSE coverage_id END, NULL, submitted_at,
  CASE WHEN stage = 'unavailable' THEN 'Register unavailable' ELSE 'Covered' END, FALSE, NULL,
  'REG-' || TO_CHAR(submitted_at, 'YYYYMMDD') || '-' || LPAD(claim_id::text, 4, '0')
FROM demo_plan
UNION ALL
SELECT claim_id, coverage_id, officer_id, officer_at, CASE WHEN stage = 'rejected' THEN 'Not covered' ELSE 'Covered' END,
  stage = 'rejected', CASE WHEN stage = 'rejected' THEN 'ตรวจสอบกับนายจ้างแล้ว ข้อมูลไม่ตรงตามเงื่อนไขมาตรา 33' END,
  'REG-' || TO_CHAR(submitted_at, 'YYYYMMDD') || '-' || LPAD(claim_id::text, 4, '0')
FROM demo_plan
WHERE stage NOT IN ('verify', 'unavailable');

INSERT INTO ClaimRejection (claim_id, reason_code, officer_id, officer_message, rejection_timestamp, is_superseded)
SELECT claim_id, (ARRAY['R02', 'R03', 'R04', 'R05'])[1 + k % 4], officer_id, 'กรุณาติดต่อเจ้าหน้าที่หากต้องการข้อมูลเพิ่มเติม', officer_at, FALSE
FROM demo_plan WHERE stage = 'rejected';

-- The status history of each claim (05-states.md).
INSERT INTO ClaimStatusHistory (claim_id, officer_id, from_status, to_status, changed_at, change_reason)
SELECT claim_id, NULL::integer, NULL, CASE WHEN stage = 'unavailable' THEN 'Register unavailable' ELSE 'Awaiting verification' END, submitted_at, 'Submitted by the user'
FROM demo_plan
UNION ALL
SELECT claim_id, officer_id, 'Awaiting verification', CASE WHEN stage = 'rejected' THEN 'Not covered' ELSE 'Covered' END, officer_at, NULL
FROM demo_plan WHERE stage NOT IN ('verify', 'unavailable')
UNION ALL
SELECT p.claim_id, p.officer_id, 'Not covered', 'Rejected', p.officer_at, r.reason_code
FROM demo_plan p JOIN ClaimRejection r ON r.claim_id = p.claim_id WHERE p.stage = 'rejected'
UNION ALL
SELECT claim_id, officer_id, 'Covered', 'No treatment required', appt_at + INTERVAL '1 day', 'Consultation report: no treatment required'
FROM demo_plan WHERE stage = 'no_treatment'
UNION ALL
SELECT claim_id, NULL, 'Covered', 'Withdrawn', appt_created + INTERVAL '2 hours', 'User cannot attend the appointment'
FROM demo_plan WHERE stage = 'withdrawn'
UNION ALL
SELECT claim_id, NULL, 'Covered', 'Withdrawn', treat_date + TIME '00:05', 'Treatment not accepted in time'
FROM demo_plan WHERE stage = 'treat_cancelled';

-- The appointments, the user's answers and the consultation sessions.
INSERT INTO Appointment (claim_id, officer_id, consultant_id, appointment_type, schedule_date, schedule_time, location, appointment_status, confirm_deadline, created_at)
SELECT claim_id, officer_id, consultant_id, 'Onsite', appt_date, appt_time, location,
  CASE stage WHEN 'pending' THEN 'Pending' WHEN 'noshow' THEN 'No show' WHEN 'withdrawn' THEN 'Cancelled' ELSE 'Confirmed' END,
  appt_at - INTERVAL '1 day', appt_created
FROM demo_plan WHERE slot_group IS NOT NULL;

INSERT INTO AppointmentConfirmation (appointment_id, channel, outcome, recorded_at)
SELECT a.appointment_id, 'application', CASE WHEN p.stage = 'withdrawn' THEN 'Cannot attend' ELSE 'Confirmed' END, p.appt_created + INTERVAL '2 hours'
FROM demo_plan p JOIN Appointment a ON a.claim_id = p.claim_id
WHERE p.slot_group IS NOT NULL AND p.stage <> 'pending';

INSERT INTO ConsultationSession (appointment_id, consultant_id, officer_id, started_at, ended_at, attendance, findings, diagnosis, recommended_treatment, session_status)
SELECT a.appointment_id, p.consultant_id, p.officer_id, p.appt_at,
  CASE WHEN p.stage = 'noshow' THEN p.appt_at + INTERVAL '1 hour' ELSE p.appt_at + INTERVAL '40 minutes' END,
  CASE WHEN p.stage = 'noshow' THEN 'No show' ELSE 'Attended' END,
  CASE WHEN p.stage <> 'noshow' THEN p.findings END,
  CASE WHEN p.stage <> 'noshow' THEN p.diagnosis END,
  CASE WHEN p.stage <> 'noshow' THEN p.recommended END,
  CASE WHEN p.stage = 'noshow' THEN 'Cancelled' ELSE 'Completed' END
FROM demo_plan p JOIN Appointment a ON a.claim_id = p.claim_id
WHERE p.stage IN ('draft', 'noshow', 'filed', 'treat_pending', 'treat_accepted', 'treat_cancelled', 'no_treatment');

-- The reports. A draft has no signature. Half of the filed reports with no treatment are not viewed yet.
INSERT INTO ConsultationReport (session_id, consultant_id, version_no, report_content, signature_uri, signed_at, delivered_at, read_at, is_superseded)
SELECT s.session_id, p.consultant_id, 1,
  p.diagnosis || '. ' || CASE p.recommended
    WHEN 'None' THEN 'Healing well. No further treatment required.'
    WHEN 'Physiotherapy' THEN 'Physiotherapy twice a week for 4 weeks.'
    ELSE 'Occupational therapy twice a week for 6 weeks.'
  END,
  CASE WHEN p.stage <> 'draft' THEN '/reports/' || (ARRAY[301, 302, 303, 306])[1 + p.i % 4] || '/signature.png' END,
  CASE WHEN p.stage <> 'draft' THEN p.appt_at + INTERVAL '3 hours' END,
  CASE WHEN p.stage <> 'draft' THEN p.appt_at + INTERVAL '3 hours 5 minutes' END,
  CASE WHEN p.stage <> 'draft' AND NOT (p.stage = 'filed' AND p.k % 2 = 1) THEN p.appt_at + INTERVAL '1 day' END,
  FALSE
FROM demo_plan p
JOIN Appointment a ON a.claim_id = p.claim_id
JOIN ConsultationSession s ON s.appointment_id = a.appointment_id
WHERE p.stage IN ('draft', 'filed', 'treat_pending', 'treat_accepted', 'treat_cancelled', 'no_treatment');

-- The treatments. A Pending treatment is in the future, so AutoCancelJob (QU4.3) does not cancel it at server start.
INSERT INTO Treatment (claim_id, report_id, officer_id, treatment_type, duration_minutes, facility_name, scheduled_date, scheduled_time, treatment_status, created_at)
SELECT p.claim_id, r.report_id, p.officer_id, p.recommended, (ARRAY[30, 45, 60])[1 + p.i % 3], 'SSO Rehabilitation Center', p.treat_date, p.treat_time,
  CASE p.stage WHEN 'treat_pending' THEN 'Pending' WHEN 'treat_accepted' THEN 'Accepted' ELSE 'Cancelled' END,
  p.appt_at + INTERVAL '1 day'
FROM demo_plan p
JOIN Appointment a ON a.claim_id = p.claim_id
JOIN ConsultationSession s ON s.appointment_id = a.appointment_id
JOIN ConsultationReport r ON r.session_id = s.session_id
WHERE p.stage IN ('treat_pending', 'treat_accepted', 'treat_cancelled');

-- The messages, with the words of QN.1 to QN.5 and QU4.3. Newer messages for users stay unread, so the red dot shows.
-- Consultants get messages only for future appointments, so "Recent changes" does not push the schedule off the screen.
INSERT INTO Notification (claim_id, insured_id, consultant_id, subject, body, sent_at, read_at)
SELECT claim_id, insured_id, NULL::integer, 'Claim confirmed', 'Your claim ' || claim_no || ' is covered under Section 33.', officer_at,
  CASE WHEN stage <> 'schedule' THEN officer_at + INTERVAL '1 hour' END
FROM demo_plan WHERE stage NOT IN ('verify', 'unavailable', 'rejected')
UNION ALL
SELECT p.claim_id, p.insured_id, NULL, 'Application rejected', CONCAT_WS(E'\n\n', rr.description, r.officer_message), p.officer_at,
  CASE WHEN p.k % 2 = 0 THEN p.officer_at + INTERVAL '1 hour' END
FROM demo_plan p JOIN ClaimRejection r ON r.claim_id = p.claim_id JOIN RejectionReason rr ON rr.reason_code = r.reason_code
UNION ALL
SELECT claim_id, insured_id, NULL, 'Appointment scheduled',
  'Your appointment with ' || consultant_name || ' is on ' || appt_text || ' at ' || location || '. Please confirm it in the application by ' || confirm_by || '.',
  appt_created, CASE WHEN stage <> 'pending' THEN appt_created + INTERVAL '1 hour' END
FROM demo_plan WHERE slot_group IS NOT NULL
UNION ALL
SELECT claim_id, NULL, consultant_id, 'New appointment',
  user_name || ' (claim ' || claim_no || ') is booked with you on ' || appt_text || ' at ' || location || '. Waiting for the patient to confirm.',
  appt_created, NULL
FROM demo_plan WHERE stage = 'pending'
UNION ALL
SELECT claim_id, NULL, consultant_id, 'Appointment confirmed',
  user_name || ' (claim ' || claim_no || ') confirmed the appointment on ' || appt_text || ' at ' || location || '.',
  appt_created + INTERVAL '2 hours', NULL
FROM demo_plan WHERE stage = 'confirmed'
UNION ALL
SELECT claim_id, NULL, consultant_id, 'Appointment cancelled',
  user_name || ' (claim ' || claim_no || ') cannot attend the appointment on ' || appt_text || '. The appointment is cancelled and the claim is withdrawn.',
  appt_created + INTERVAL '2 hours', NULL
FROM demo_plan WHERE stage = 'withdrawn'
UNION ALL
SELECT claim_id, insured_id, NULL, 'Treatment booked',
  recommended || ' on ' || TO_CHAR(treat_date + treat_time, 'FMDD FMMonth YYYY" : "HH24:MI') || '. Please accept or choose another date.',
  appt_at + INTERVAL '1 day', CASE WHEN stage <> 'treat_pending' THEN appt_at + INTERVAL '26 hours' END
FROM demo_plan WHERE stage IN ('treat_pending', 'treat_accepted', 'treat_cancelled')
UNION ALL
SELECT claim_id, insured_id, NULL, 'Treatment cancelled',
  'Your treatment at SSO Rehabilitation Center on ' || TO_CHAR(treat_date, 'FMDD FMMonth YYYY') || ' was cancelled because it was not accepted in time. Your claim ' || claim_no || ' is now closed.',
  treat_date + TIME '00:05', NULL
FROM demo_plan WHERE stage = 'treat_cancelled'
UNION ALL
SELECT claim_id, insured_id, NULL, 'No treatment required',
  'The consultation report for your claim ' || claim_no || ' says no treatment is required, so your claim is now closed.',
  appt_at + INTERVAL '1 day', NULL
FROM demo_plan WHERE stage = 'no_treatment';

-- An account for each person and staff member that has none, also for the seed people 107 to 110.
INSERT INTO UserAccount (role, login_name, password_hash, insured_id, created_at)
SELECT 'USER', p.national_id, crypt('Password123', gen_salt('bf', 8)), p.insured_id, NOW()
FROM InsuredPerson p WHERE NOT EXISTS (SELECT 1 FROM UserAccount u WHERE u.insured_id = p.insured_id);

INSERT INTO UserAccount (role, login_name, password_hash, officer_id, created_at)
SELECT 'OFFICER', o.email, crypt('Password123', gen_salt('bf', 8)), o.officer_id, NOW()
FROM EvaluationOfficer o WHERE NOT EXISTS (SELECT 1 FROM UserAccount u WHERE u.officer_id = o.officer_id);

INSERT INTO UserAccount (role, login_name, password_hash, consultant_id, created_at)
SELECT 'CONSULTANT', c.email, crypt('Password123', gen_salt('bf', 8)), c.consultant_id, NOW()
FROM Consultant c WHERE c.email IS NOT NULL AND NOT EXISTS (SELECT 1 FROM UserAccount u WHERE u.consultant_id = c.consultant_id);

-- The next new row must not use an ID from this file.
SELECT setval(pg_get_serial_sequence('insuredperson', 'insured_id'), (SELECT MAX(insured_id) FROM InsuredPerson));
SELECT setval(pg_get_serial_sequence('employer', 'employer_id'), (SELECT MAX(employer_id) FROM Employer));
SELECT setval(pg_get_serial_sequence('section33coverage', 'coverage_id'), (SELECT MAX(coverage_id) FROM Section33Coverage));
SELECT setval(pg_get_serial_sequence('injuryclaim', 'claim_id'), (SELECT MAX(claim_id) FROM InjuryClaim));

DROP TABLE demo_plan;
DROP TABLE demo_day;
