-- Thai text for the typed fields and the employer names of seed.sql (docs/DECISIONS.md, D-068).
-- docs/spec/ is read-only, so this file changes the seed rows after seed.sql loads.
-- Status, category, treatment type, facility, location and message text stay English: the code compares these
-- values, and the language toggle shows them in Thai (D-067).

-- Q1.4 copies the name of the register stub into Employer, so the two tables keep the same names.
UPDATE master_table m SET employer_name = v.name
FROM (VALUES
  ('1000123456', 'บริษัท สยามพรีซิชั่นพาร์ท จำกัด'),
  ('1000234567', 'บริษัท ไทยแพ็คอินดัสตรี้ จำกัด'),
  ('1000345678', 'บริษัท อีสเทิร์นคอยล์สตีล จำกัด'),
  ('1000456789', 'บริษัท บางนาโลจิสติกส์ จำกัด'),
  ('1000567890', 'บริษัท ปทุมโคลด์เชน จำกัด'),
  ('1000678901', 'บริษัท รังสิตออโต้พาร์ท จำกัด')
) v (account_no, name)
WHERE m.employer_account_no = v.account_no;

UPDATE Employer e SET employer_name = m.employer_name
FROM (SELECT DISTINCT employer_account_no, employer_name FROM master_table) m
WHERE e.sso_account_no = m.employer_account_no;

UPDATE InjuryClaim c SET injury_place = v.place, injury_cause = v.cause, body_part = v.body_part
FROM (VALUES
  (143, 'ไลน์ผลิตที่ 3 บางพลี จ.สมุทรปราการ', 'มือติดลูกกลิ้งสายพานลำเลียง', 'ข้อมือขวา'),
  (147, 'ไลน์บรรจุที่ 2 ปากเกร็ด จ.นนทบุรี', 'สัมผัสแผ่นซีลที่ร้อน', 'มือซ้าย'),
  (149, 'แผนกเครื่องปั๊ม บางปู จ.สมุทรปราการ', 'เท้าถูกม้วนเหล็กทับ', 'เท้าซ้าย'),
  (151, 'คลังสินค้า 2 บางนา กรุงเทพฯ', 'ลื่นบนทางลาดขนสินค้าที่เปียก', 'ข้อเท้าซ้าย'),
  (155, 'ห้องเย็น คลองหลวง จ.ปทุมธานี', 'ยกลังสินค้าที่หนัก', 'หลังส่วนล่าง'),
  (160, 'แผนกเครื่องปั๊ม บางปู จ.สมุทรปราการ', 'ถูกขอบแผ่นโลหะบาด', 'แขนท่อนล่างซ้าย'),
  (161, 'ไลน์งานกลึงที่ 1 บางพลี จ.สมุทรปราการ', 'ถูกเหล็กเส้นหล่นใส่', 'ไหล่ขวา'),
  (162, 'คลังสินค้า 1 บางนา กรุงเทพฯ', 'ตกจากบันไดขนสินค้า', 'เข่าซ้าย'),
  (163, 'ไลน์เครื่องปั๊มที่ 2 บางพลี จ.สมุทรปราการ', 'มือถูกเครื่องปั๊มโลหะกดทับ', 'มือซ้าย'),
  (164, 'คลังสินค้า 3 บางนา กรุงเทพฯ', 'ยกกล่องที่หนัก', 'หลังส่วนล่าง')
) v (claim_id, place, cause, body_part)
WHERE c.claim_id = v.claim_id;

-- QN.2 puts the officer message into the rejection message, so message 904 has the same text.
UPDATE ClaimRejection SET officer_message = 'ทะเบียนผู้ประกันตนแสดงว่าการส่งเงินสมทบของท่านสิ้นสุดในเดือนพฤษภาคม 2026 ...'
WHERE rejection_id = 3001;

UPDATE Notification
SET body = 'การส่งเงินสมทบไม่ครอบคลุมวันที่ประสบอันตราย... ทะเบียนผู้ประกันตนแสดงว่าการส่งเงินสมทบของท่านสิ้นสุดในเดือนพฤษภาคม 2026 ...'
WHERE notification_id = 904;

UPDATE ConsultationSession s SET findings = v.findings, diagnosis = v.diagnosis
FROM (VALUES
  (301, 'แผลไหม้กำลังหาย ไม่มีการติดเชื้อ', 'แผลไหม้ระดับ 2 ที่มือซ้าย'),
  (302, 'เท้าซ้ายบวม', 'การบาดเจ็บจากการถูกทับที่เท้าซ้าย'),
  (303, 'ข้อมือขวาติดแข็งหลังถอดเฝือก', 'กระดูกเรเดียสส่วนปลายหัก'),
  (306, 'เข่าซ้ายบวมและปวด', 'เข่าซ้ายแพลง')
) v (session_id, findings, diagnosis)
WHERE s.session_id = v.session_id;

UPDATE ConsultationReport r SET report_content = v.content
FROM (VALUES
  (85, 'แผลไหม้ระดับ 2 ที่มือซ้าย แผลหายดี ไม่ต้องรับการรักษาเพิ่มเติม'),
  (86, 'เท้าซ้ายบาดเจ็บจากการถูกทับ เนื้อเยื่ออ่อนบวม ทำกิจกรรมบำบัดสัปดาห์ละ 2 ครั้ง เป็นเวลา 4 สัปดาห์'),
  (87, 'กระดูกเรเดียสส่วนปลายของข้อมือขวาหักแบบปิด ทำกายภาพบำบัดสัปดาห์ละ 2 ครั้ง เป็นเวลา 6 สัปดาห์'),
  (90, 'เข่าซ้ายแพลงและบวมเล็กน้อย ทำกายภาพบำบัดสัปดาห์ละ 1 ครั้ง เป็นเวลา 4 สัปดาห์')
) v (report_id, content)
WHERE r.report_id = v.report_id;
