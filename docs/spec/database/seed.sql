-- SST sample data: the five sample rows per table from SA report section 2.17.
-- Load after schema.sql. Rows reference each other through the foreign keys.

-- SSO register stub rows: every sample insured person is ACTIVE, plus one INACTIVE person for the failed check.
INSERT INTO master_table (national_id, title_name, first_name, last_name, coverage_status, employer_account_no,  employer_name, registration_date, contribution_start, contribution_end, contribution_months) VALUES
  ('1103700123456', 'นาย', 'สมชาย', 'ประเสริฐ', 'ACTIVE', '1000123456', 'Siam Precision Parts Co., Ltd.', '2019-05-20', '2019-06-01', NULL, 88),
  ('3120100234561', 'นาง', 'สุดา', 'แก้วมณี', 'ACTIVE', '1000234567', 'Thai Pack Industry Co., Ltd.', '2015-02-10', '2015-03-01', NULL, 139),
  ('1100800345672', 'นาย', 'มานพ', 'ศรีทอง', 'ACTIVE', '1000345678', 'Eastern Coil Steel Co., Ltd.', '2020-07-15', '2020-08-01', NULL, 74),
  ('1209800456789', 'นางสาว', 'วิภา', 'ใจงาม', 'ACTIVE', '1000456789', 'Bangna Logistics Co., Ltd.', '2021-02-15', '2021-03-01', '2026-05-31', 63),
  ('1101500567893', 'นาย', 'ชัยวัฒน์', 'สุขเจริญ', 'ACTIVE', '1000567890', 'Pathum Cold Chain Co., Ltd.', '2017-09-01', '2017-10-01', NULL, 108),
  ('1909900111222', 'นาย', 'ทดสอบ', 'ไม่มีสิทธิ์', 'INACTIVE', NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO InsuredPerson (insured_id, national_id, title_name, first_name, last_name, date_of_birth, gender, phone_no, email, address, created_at) OVERRIDING SYSTEM VALUE VALUES
  (101, '1103700123456', 'นาย', 'สมชาย', 'ประเสริฐ', '1985-04-12', 'M', '0812345678', 'somchai.p@gmail.com', '88/5 ถ.เทพารักษ์ ต.บางพลีใหญ่ อ.บางพลี จ.สมุทรปราการ 10540', '2026-10-02 14:31'),
  (102, '3120100234561', 'นาง', 'สุดา', 'แก้วมณี', '1978-08-19', 'F', '0898765432', 'suda.k@gmail.com', '45/2 ถ.ติวานนท์ ต.ท่าทราย อ.เมือง จ.นนทบุรี 11000', '2026-10-03 10:11'),
  (103, '1100800345672', 'นาย', 'มานพ', 'ศรีทอง', '1991-01-25', 'M', '0865551234', NULL, '12 ซ.บางนา-ตราด 25 แขวงบางนา เขตบางนา กรุงเทพฯ 10260', '2026-09-30 11:46'),
  (104, '1209800456789', 'นางสาว', 'วิภา', 'ใจงาม', '1997-06-02', 'F', '0841239876', 'wipa.j@gmail.com', '7/1 ถ.ศรีนครินทร์ แขวงบางนา เขตบางนา กรุงเทพฯ 10260', '2026-10-03 11:04'),
  (105, '1101500567893', 'นาย', 'ชัยวัฒน์', 'สุขเจริญ', '1983-11-14', 'M', '0829876543', NULL, '199 ม.4 ต.คลองหนึ่ง อ.คลองหลวง จ.ปทุมธานี 12120', '2026-10-06 16:31');

INSERT INTO Employer (employer_id, sso_account_no, employer_name, branch_name, phone_no, address) OVERRIDING SYSTEM VALUE VALUES
  (11, '1000123456', 'Siam Precision Parts Co., Ltd.', 'สำนักงานใหญ่', '023154400', '88 ม.5 ถ.บางนา-ตราด ต.บางพลีใหญ่ อ.บางพลี จ.สมุทรปราการ 10540'),
  (12, '1000234567', 'Thai Pack Industry Co., Ltd.', 'สาขาปากเกร็ด', '029601122', '59 ม.2 ต.บางพูด อ.ปากเกร็ด จ.นนทบุรี 11120'),
  (13, '1000345678', 'Eastern Coil Steel Co., Ltd.', 'สาขาบางปู', '027094455', '300 ม.3 ต.แพรกษา อ.เมือง จ.สมุทรปราการ 10280'),
  (14, '1000456789', 'Bangna Logistics Co., Ltd.', 'สำนักงานใหญ่', '023983300', '41 ถ.บางนา-ตราด แขวงบางนา เขตบางนา กรุงเทพฯ 10260'),
  (15, '1000567890', 'Pathum Cold Chain Co., Ltd.', 'สาขาคลองหลวง', '025291800', '112 ม.7 ต.คลองหนึ่ง อ.คลองหลวง จ.ปทุมธานี 12120');

INSERT INTO Section33Coverage (coverage_id, insured_id, employer_id, registration_date, contribution_start, contribution_end, contribution_months, coverage_status) OVERRIDING SYSTEM VALUE VALUES
  (201, 101, 11, '2019-05-20', '2019-06-01', NULL, 88, 'ACTIVE'),
  (202, 102, 12, '2015-02-10', '2015-03-01', NULL, 139, 'ACTIVE'),
  (203, 103, 13, '2020-07-15', '2020-08-01', NULL, 74, 'ACTIVE'),
  (204, 104, 14, '2021-02-15', '2021-03-01', '2026-05-31', 63, 'ACTIVE'),
  (205, 105, 15, '2017-09-01', '2017-10-01', NULL, 108, 'ACTIVE');

INSERT INTO EvaluationOfficer (officer_id, employee_no, first_name, last_name, phone_no, email) OVERRIDING SYSTEM VALUE VALUES
  (1, 'EO-24017', 'กัญญา', 'วงศ์ศิริ', '0891234501', 'kanya.w@sso.go.th'),
  (2, 'EO-23008', 'ปิยะพงษ์', 'รัตนชัย', '0891234502', 'piyapong.r@sso.go.th'),
  (3, 'EO-22031', 'สมศักดิ์', 'ทองคำ', '0891234503', 'somsak.t@sso.go.th'),
  (4, 'EO-25002', 'นภาพร', 'ศรีสวัสดิ์', '0891234504', 'napaporn.s@sso.go.th'),
  (5, 'EO-21019', 'วรวุฒิ', 'แสงทอง', '0891234505', 'worawut.s@sso.go.th');

INSERT INTO Consultant (consultant_id, license_no, title_name, first_name, last_name, office_location, phone_no, email) OVERRIDING SYSTEM VALUE VALUES
  (1, 'ว.31245', 'นพ.', 'ธนา', 'ศรีสุข', 'Building A, Floor 3, Room 305', '0812223301', 'thana.s@ssorehab.go.th'),
  (2, 'ว.28761', 'พญ.', 'มาลี', 'ใจดี', 'Building A, Floor 2, Room 210', '0812223302', 'malee.j@ssorehab.go.th'),
  (3, 'ว.35512', 'นพ.', 'วีระ', 'ทองดี', 'Building C, Floor 1, Room 104', '0812223303', 'weera.t@ssorehab.go.th'),
  (4, 'ว.40218', 'พญ.', 'อรพิน', 'แสงจันทร์', 'Building B, Floor 2, Room 201', NULL, 'orapin.s@ssorehab.go.th'),
  (5, 'ว.37790', 'นพ.', 'กิตติ', 'พงษ์ไพบูลย์', 'Building B, Floor 1, Room 112', '0812223305', NULL);

INSERT INTO InjuryClaim (claim_id, claim_no, insured_id, employer_id, injury_datetime, injury_place, injury_cause, body_part, injury_category, claim_status, submitted_at, created_at) OVERRIDING SYSTEM VALUE VALUES
  (143, 'SST-2026-000143', 101, 11, '2026-09-28 08:40', 'Factory line 3, Bang Phli, Samut Prakan', 'Hand caught in a conveyor roller', 'right wrist', 'Fracture', 'Covered', '2026-10-02 14:32', '2026-10-02 14:32'),
  (147, 'SST-2026-000147', 102, 12, '2026-09-30 15:10', 'Packing line 2, Pak Kret, Nonthaburi', 'Touched a hot sealing plate', 'left hand', 'Burn', 'No treatment required', '2026-10-03 10:12', '2026-10-03 10:12'),
  (149, 'SST-2026-000149', 103, 13, '2026-09-29 13:25', 'Press shop, Bang Pu, Samut Prakan', 'Foot trapped under a steel coil', 'left foot', 'Crush injury', 'Covered', '2026-09-30 11:47', '2026-09-30 11:47'),
  (151, 'SST-2026-000151', 104, 14, '2026-10-01 07:50', 'Warehouse 2, Bang Na, Bangkok', 'Slipped on a wet loading ramp', 'left ankle', 'Sprain', 'Rejected', '2026-10-03 11:05', '2026-10-03 11:05'),
  (155, 'SST-2026-000155', 105, 15, '2026-10-03 09:30', 'Cold storage, Khlong Luang, Pathum Thani', 'Lifted a heavy crate', 'lower back', 'Back strain', 'Covered', '2026-10-06 16:32', '2026-10-06 16:32');

INSERT INTO DocumentType (doc_type_id, form_code, name_th, name_en, is_required) OVERRIDING SYSTEM VALUE VALUES
  (1, 'DOC-ID', 'สำเนาบัตรประจำตัวประชาชน', 'Image of National ID Card', TRUE),
  (2, 'DOC-MED', 'เวชระเบียนหรือใบรับรองแพทย์', 'Medical Record File', TRUE),
  (3, 'KT-16', 'แบบแจ้งการประสบอันตราย (กท.16)', 'Injury Form File', TRUE),
  (4, 'DOC-BANK', 'สำเนาหน้าสมุดบัญชีธนาคาร', 'Bank Book Copy', FALSE),
  (5, 'DOC-PHOTO', 'ภาพถ่ายบาดแผลหรือสถานที่เกิดเหตุ', 'Injury Photo', FALSE);

INSERT INTO ClaimDocument (document_id, claim_id, doc_type_id, file_name, file_uri, mime_type, file_size_bytes, uploaded_at, check_status, checked_at, remark) OVERRIDING SYSTEM VALUE VALUES
  (2001, 143, 1, 'id_card_front.jpg', '/claims/143/id_card_front.jpg', 'image/jpeg', 1258291, '2026-10-02 14:30', 'Pending', NULL, NULL),
  (2002, 143, 2, 'medical_record_rama.pdf', '/claims/143/medical_record_rama.pdf', 'application/pdf', 865280, '2026-10-02 14:30', 'Pending', NULL, NULL),
  (2003, 143, 3, 'injury_form_kt16.pdf', '/claims/143/injury_form_kt16.pdf', 'application/pdf', 317440, '2026-10-02 14:31', 'Pending', NULL, NULL),
  (2004, 151, 1, 'id_card.jpg', '/claims/151/id_card.jpg', 'image/jpeg', 1003520, '2026-10-03 11:03', 'Pending', NULL, NULL),
  (2005, 151, 2, 'medical_record_bangna.pdf', '/claims/151/medical_record_bangna.pdf', 'application/pdf', 1153434, '2026-10-03 11:04', 'Pending', NULL, NULL);

INSERT INTO EligibilityCheck (check_id, claim_id, coverage_id, officer_id, checked_at, result, is_override, override_reason, evidence_ref) OVERRIDING SYSTEM VALUE VALUES
  (801, 143, 201, NULL, '2026-10-02 14:32', 'Covered', FALSE, NULL, 'REG-20261002-0143'),
  (802, 143, 201, 1, '2026-10-05 09:15', 'Covered', FALSE, NULL, 'REG-20261002-0143'),
  (803, 151, 204, NULL, '2026-10-03 11:05', 'Not covered', FALSE, NULL, 'REG-20261003-0151'),
  (804, 151, 204, 1, '2026-10-06 10:40', 'Not covered', FALSE, NULL, 'REG-20261003-0151'),
  (805, 149, 203, NULL, '2026-09-30 11:47', 'Covered', FALSE, NULL, 'REG-20260930-0149');

INSERT INTO RejectionReason (reason_code, name_th, description, is_automatic) OVERRIDING SYSTEM VALUE VALUES
  ('R01', 'ไม่พบข้อมูลในทะเบียนผู้ประกันตนมาตรา 33', 'ไม่พบเลขประจำตัวประชาชนในทะเบียนผู้ประกันตนมาตรา 33 ณ วันที่ประสบอันตราย', TRUE),
  ('R02', 'ส่งเงินสมทบไม่ครบตามเงื่อนไข', 'การส่งเงินสมทบไม่ครอบคลุมวันที่ประสบอันตรายตามเงื่อนไขมาตรา 33', FALSE),
  ('R03', 'นายจ้างไม่ตรงกับข้อมูลในทะเบียน', 'นายจ้างที่ระบุในคำร้องไม่ตรงกับนายจ้างในทะเบียนผู้ประกันตน', FALSE),
  ('R04', 'เอกสารประกอบไม่ครบถ้วน', 'ไม่มีเอกสารที่ต้องแนบ หรือเอกสารที่แนบอ่านไม่ได้', FALSE),
  ('R05', 'การบาดเจ็บไม่ได้เกิดจากการทำงาน', 'เหตุที่ประสบอันตรายไม่เกี่ยวข้องกับการทำงานให้นายจ้าง', FALSE);

INSERT INTO ClaimRejection (rejection_id, claim_id, reason_code, officer_id, officer_message, rejection_timestamp, appeal_deadline, is_superseded) OVERRIDING SYSTEM VALUE VALUES
  (3001, 151, 'R02', 1, 'The register shows your contributions ended in May 2026. ...', '2026-10-06 10:40', NULL, FALSE);

INSERT INTO Appointment (appointment_id, claim_id, officer_id, consultant_id, supersedes_appt_id, appointment_type, schedule_date, schedule_time, location, appointment_status, confirm_deadline, created_at) OVERRIDING SYSTEM VALUE VALUES
  (501, 147, 2, 2, NULL, 'Onsite', '2026-10-13', '09:00', 'Building A, Floor 2, Room 210', 'Confirmed', '2026-10-12 09:00', '2026-10-07 10:05'),
  (502, 149, 2, 1, NULL, 'Onsite', '2026-10-14', '13:00', 'Building A, Floor 3, Room 305', 'Rescheduled', '2026-10-13 13:00', '2026-10-08 14:20'),
  (503, 149, 2, 1, 502, 'Onsite', '2026-10-16', '13:00', 'Building A, Floor 3, Room 305', 'Confirmed', NULL, '2026-10-09 12:10'),
  (504, 143, 1, 1, NULL, 'Onsite', '2026-10-16', '10:00', 'Building A, Floor 3, Room 305', 'Confirmed', '2026-10-15 10:00', '2026-10-05 10:30'),
  (505, 155, 1, 3, NULL, 'Onsite', '2026-10-15', '09:00', 'Building C, Floor 1, Room 104', 'Cancelled', '2026-10-14 09:00', '2026-10-08 09:40');

INSERT INTO PhoneCallAttempt (attempt_id, appointment_id, officer_id, attempt_no, called_at, phone_no, call_outcome, remark) OVERRIDING SYSTEM VALUE VALUES
  (701, 501, 2, 1, '2026-10-09 14:00', '0898765432', 'No answer', 'ไม่รับสาย'),
  (702, 501, 2, 2, '2026-10-10 10:00', '0898765432', 'Answered', 'ผู้ใช้งานยืนยันนัดหมาย'),
  (703, 502, 2, 1, '2026-10-09 11:30', '0865551234', 'Answered', 'แนะนำให้ขอเปลี่ยนวันในแอปพลิเคชัน');

INSERT INTO ConsultationSession (session_id, appointment_id, consultant_id, officer_id, started_at, ended_at, attendance, findings, diagnosis, recommended_treatment, session_status) OVERRIDING SYSTEM VALUE VALUES
  (301, 501, 2, 2, '2026-10-13 09:00', '2026-10-13 09:40', 'Attended', 'Healing burn, no infection', 'Second-degree burn, left hand', 'None', 'Completed'),
  (302, 503, 1, 2, '2026-10-16 13:00', '2026-10-16 13:50', 'Attended', 'Swelling of the left foot', 'Crush injury, left foot', 'Occupational therapy', 'Completed'),
  (303, 504, 1, 1, '2026-10-16 10:00', '2026-10-16 10:45', 'Attended', 'Stiff right wrist after cast', 'Distal radius fracture', 'Physiotherapy', 'Completed');

INSERT INTO ConsultationReport (report_id, session_id, consultant_id, version_no, report_content, signed_at, delivered_at, read_at, is_superseded) OVERRIDING SYSTEM VALUE VALUES
  (85, 301, 2, 1, 'Second-degree burn on the left hand, healing well. No further treatment required.', '2026-10-15 16:00', '2026-10-15 16:10', '2026-10-15 17:30', FALSE),
  (86, 302, 1, 1, 'Crush injury of the left foot with soft tissue swelling. Occupational therapy twice a week for 4 weeks.', '2026-10-16 15:05', '2026-10-16 15:10', '2026-10-17 09:00', FALSE),
  (87, 303, 1, 1, 'Closed fracture of the distal radius, right wrist. Physiotherapy twice a week for 6 weeks.', '2026-10-16 11:20', '2026-10-16 11:25', NULL, FALSE);

INSERT INTO Treatment (treatment_id, claim_id, report_id, officer_id, treatment_type, facility_name, scheduled_date, scheduled_time, treatment_status, created_at) OVERRIDING SYSTEM VALUE VALUES
  (401, 143, 87, 1, 'Physiotherapy', 'SSO Rehabilitation Center', '2026-10-23', '13:00', 'Accepted', '2026-10-17 09:30'),
  (402, 149, 86, 2, 'Occupational therapy', 'SSO Rehabilitation Center', '2026-10-19', '10:00', 'Cancelled', '2026-10-17 10:15'),
  (403, 149, 86, 2, 'Occupational therapy', 'SSO Rehabilitation Center', '2026-10-26', '10:00', 'Pending', '2026-10-19 11:00');

INSERT INTO Notification (notification_id, claim_id, insured_id, consultant_id, subject, body, sent_at, read_at) OVERRIDING SYSTEM VALUE VALUES
  (901, 143, 101, NULL, 'Claim confirmed', 'Your claim SST-2026-000143 is covered under Section 33.', '2026-10-05 09:15', '2026-10-05 12:02'),
  (902, 143, 101, NULL, 'Appointment scheduled', 'Your appointment with นพ. ธนา ศรีสุข is on 16 October 2026 : 10:00 ...', '2026-10-05 10:30', '2026-10-06 08:10'),
  (903, 143, NULL, 1, 'New appointment', 'นาย สมชาย ประเสริฐ (claim SST-2026-000143) is booked with you on 16 October 2026 : 10:00 ...', '2026-10-05 10:30', NULL),
  (904, 151, 104, NULL, 'Application rejected', 'การส่งเงินสมทบไม่ครอบคลุมวันที่ประสบอันตราย... The register shows your contributions ended in May 2026. ...', '2026-10-06 10:40', '2026-10-06 19:03'),
  (905, 149, 103, NULL, 'Treatment cancelled', 'Your treatment at SSO Rehabilitation Center on 19 October 2026 was cancelled because it was not accepted in time.', '2026-10-19 00:05', NULL);

INSERT INTO ClaimStatusHistory (history_id, claim_id, officer_id, from_status, to_status, changed_at, change_reason) OVERRIDING SYSTEM VALUE VALUES
  (1001, 143, NULL, NULL, 'Awaiting verification', '2026-10-02 14:32', 'Submitted by the user'),
  (1002, 143, 1, 'Awaiting verification', 'Covered', '2026-10-05 09:15', NULL),
  (1003, 151, 1, 'Register unavailable', 'Not covered', '2026-10-06 10:40', NULL),
  (1004, 151, 1, 'Not covered', 'Rejected', '2026-10-06 10:40', 'R02'),
  (1005, 147, 2, 'Covered', 'No treatment required', '2026-10-16 09:20', 'Consultation report: no treatment required');

INSERT INTO AppointmentConfirmation (confirmation_id, appointment_id, call_attempt_id, channel, outcome, recorded_at, remark) OVERRIDING SYSTEM VALUE VALUES
  (601, 501, 702, 'phone', 'Confirmed', '2026-10-10 10:05', 'ยืนยันทางโทรศัพท์'),
  (602, 504, NULL, 'application', 'Confirmed', '2026-10-06 08:15', NULL),
  (603, 502, NULL, 'application', 'Requested another date', '2026-10-09 12:10', NULL),
  (604, 505, NULL, 'application', 'Cannot attend', '2026-10-09 18:40', NULL);

SELECT setval(pg_get_serial_sequence('insuredperson', 'insured_id'), (SELECT MAX(insured_id) FROM InsuredPerson));
SELECT setval(pg_get_serial_sequence('employer', 'employer_id'), (SELECT MAX(employer_id) FROM Employer));
SELECT setval(pg_get_serial_sequence('section33coverage', 'coverage_id'), (SELECT MAX(coverage_id) FROM Section33Coverage));
SELECT setval(pg_get_serial_sequence('evaluationofficer', 'officer_id'), (SELECT MAX(officer_id) FROM EvaluationOfficer));
SELECT setval(pg_get_serial_sequence('consultant', 'consultant_id'), (SELECT MAX(consultant_id) FROM Consultant));
SELECT setval(pg_get_serial_sequence('injuryclaim', 'claim_id'), (SELECT MAX(claim_id) FROM InjuryClaim));
SELECT setval(pg_get_serial_sequence('documenttype', 'doc_type_id'), (SELECT MAX(doc_type_id) FROM DocumentType));
SELECT setval(pg_get_serial_sequence('claimdocument', 'document_id'), (SELECT MAX(document_id) FROM ClaimDocument));
SELECT setval(pg_get_serial_sequence('eligibilitycheck', 'check_id'), (SELECT MAX(check_id) FROM EligibilityCheck));
SELECT setval(pg_get_serial_sequence('claimrejection', 'rejection_id'), (SELECT MAX(rejection_id) FROM ClaimRejection));
SELECT setval(pg_get_serial_sequence('appointment', 'appointment_id'), (SELECT MAX(appointment_id) FROM Appointment));
SELECT setval(pg_get_serial_sequence('appointmentconfirmation', 'confirmation_id'), (SELECT MAX(confirmation_id) FROM AppointmentConfirmation));
SELECT setval(pg_get_serial_sequence('phonecallattempt', 'attempt_id'), (SELECT MAX(attempt_id) FROM PhoneCallAttempt));
SELECT setval(pg_get_serial_sequence('consultationsession', 'session_id'), (SELECT MAX(session_id) FROM ConsultationSession));
SELECT setval(pg_get_serial_sequence('consultationreport', 'report_id'), (SELECT MAX(report_id) FROM ConsultationReport));
SELECT setval(pg_get_serial_sequence('treatment', 'treatment_id'), (SELECT MAX(treatment_id) FROM Treatment));
SELECT setval(pg_get_serial_sequence('notification', 'notification_id'), (SELECT MAX(notification_id) FROM Notification));
SELECT setval(pg_get_serial_sequence('claimstatushistory', 'history_id'), (SELECT MAX(history_id) FROM ClaimStatusHistory));
