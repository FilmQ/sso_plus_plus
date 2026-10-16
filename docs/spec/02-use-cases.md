# Use cases (from SA report sections 2.11 and 2.13)

Source: SA Documents, section 2.11 (use case list) and 2.13 (use case descriptions). The descriptions are in Thai, as in the report; button labels, page names and SQL are in English. `Qx.y` blocks are the exact SQL the step runs (same IDs as `database/queries.sql`).

## Use case list

| ID | Use case | Actor | Description |
|---|---|---|---|
| U1 | ยื่นคำร้องกรณีประสบอันตราย (Submit Injury Application) | ผู้ใช้งาน | กรอกแบบฟอร์มการประสบอันตรายและเอกสารประกอบ แล้วยื่นคำร้องผ่านแอปพลิเคชัน |
| U2 | ดูข้อความแจ้งเตือน (View Notify Message) | ผู้ใช้งาน | ดูข้อความแจ้งผลจากเจ้าหน้าที่ประเมิน เช่น เหตุผลที่คำร้องถูกปฏิเสธ หรือวันนัดหมาย |
| U3 | ยืนยันนัดหมาย (Appointment Confirmation) | ผู้ใช้งาน | ตอบรับนัดหมายที่เจ้าหน้าที่ประเมินสร้างไว้ แยกเป็น U3.1 ยืนยันนัดหมาย, U3.2 ขอเปลี่ยนวันนัดหมาย และ U3.3 ไม่สามารถเข้าร่วมได้ |
| U4 | ยืนยันการรักษา (Treatment Confirmation) | ผู้ใช้งาน | ตอบรับวันรักษา แยกเป็น U4.1 ยอมรับ, U4.2 ขอเปลี่ยนวัน และ U4.3 ระบบยกเลิกเมื่อไม่ตอบรับภายในกำหนด |
| U5 | ดูตารางนัดหมาย (View Appointment Schedule) | ผู้ใช้งาน | ดูตารางนัดหมายกับที่ปรึกษา |
| U6 | ดูตารางการรักษา (View Treatment Schedule) | ผู้ใช้งาน | ดูตารางการรักษาที่เจ้าหน้าที่ประเมินจองไว้ |
| O1 | ดูคำร้องกรณีประสบอันตราย (View Injury Application) | เจ้าหน้าที่ประเมิน | ดูคำร้อง เอกสารแนบ และผลตรวจสอบสิทธิ์อัตโนมัติ |
| O2 | อนุมัติคำร้อง (Approve Injury Application) | เจ้าหน้าที่ประเมิน | ยืนยันว่าคำร้องอยู่ในความคุ้มครองตามมาตรา 33 |
| O3 | ปฏิเสธคำร้อง (Reject Injury Application) | เจ้าหน้าที่ประเมิน | ปฏิเสธคำร้องพร้อมเหตุผล และแจ้งผลให้ผู้ใช้งาน |
| O4 | สร้างนัดหมาย (Schedule Appointment) | เจ้าหน้าที่ประเมิน | นัดหมายผู้ใช้งานกับที่ปรึกษาหลังอนุมัติคำร้อง |
| O5 | นัดหมายการรักษา (Schedule Treatment) | เจ้าหน้าที่ประเมิน | นัดหมายการรักษาจากรายงานการให้คำปรึกษา แยกเป็น O5.1 จองการรักษา และ O5.2 ไม่ต้องรับการรักษา |
| O6 | ดูรายงานการให้คำปรึกษา (View Consultation Report) | เจ้าหน้าที่ประเมิน | ดูรายงานที่ที่ปรึกษายื่นมา |
| C1 | ดูตารางนัดหมาย (View Appointment Schedule) | ที่ปรึกษา | ดูวันนัดหมายและข้อมูลผู้ใช้งานที่นัดไว้ |
| C2 | สร้างรายงานการให้คำปรึกษา (Create Consultation Report) | ที่ปรึกษา | เขียนรายงานหลังการให้คำปรึกษา แยกเป็น C2.1 แก้ไขฉบับร่าง, C2.2 ลงลายมือชื่อ และ C2.3 ยื่นรายงาน |

## U1: ยื่นคำร้องกรณีประสบอันตราย (Submit Injury Application)

**Use Case Name:** ยื่นคำร้องกรณีประสบอันตราย (Submit Injury Application)  
**Use Case Description:** ผู้ใช้งานกรอกแบบฟอร์มการประสบอันตรายและแบบฟอร์มประกอบ แล้วยื่นคำร้องผ่านแอปพลิเคชัน  
**Actor:** ผู้ใช้งาน (User)  
**Preconditions:** ผู้ใช้งานยังไม่ได้ลงทะเบียนในแอปพลิเคชัน และยังไม่เคยยื่นแบบฟอร์มการประสบอันตราย  

**Steps** (Actor / System):

**Actor:**

1. ผู้ใช้งานคลิก "Register" เพื่อสร้างบัญชีผู้ใช้งาน

**System:**

2. ระบบ Redirect จากหน้า "Register Page" ไปยังหน้า "Fill in Injury Forms Page"

**Actor:**

3. ผู้ใช้งานกรอกข้อมูลดังต่อไปนี้
ข้อมูลทั่วไป
- ชื่อ และนามสกุล
- ที่อยู่
- เลขประจำตัวประชาชน
- วันเกิด
- เบอร์โทรศัพท์
- คำนำหน้าชื่อ (เลือกได้เฉพาะคำนำหน้าที่ระบบกำหนด)
- เพศ (เลือกได้เฉพาะ ชาย หญิง และอื่น ๆ)
ข้อมูลการประสบอันตราย
- วันและเวลาที่ประสบอันตราย
- สถานที่ประสบอันตราย
- สาเหตุการประสบอันตราย
- อวัยวะที่บาดเจ็บ
- ประเภทการบาดเจ็บ (เลือกได้เฉพาะประเภทที่ระบบกำหนด เช่น Fracture, Burn, Sprain)
อัปโหลดไฟล์
- รูปภาพบัตรประจำตัวประชาชน
- ไฟล์เวชระเบียน (Medical Record)
- ไฟล์แบบฟอร์มการประสบอันตราย (Injury Form)
รหัสผ่าน และยืนยันรหัสผ่าน
เมื่อกรอกข้อมูลครบถ้วนแล้ว คลิก "Submit Injury Forms"

**System:**

4. ระบบตรวจสอบข้อมูลดังนี้
ตรวจสอบสิทธิ์ตามมาตรา 33
- ตรวจสอบเลขประจำตัวประชาชนกับตารางข้อมูลหลักของสำนักงานประกันสังคม (master_table) ว่ามีสถานะความคุ้มครอง ACTIVE ตาม Q1.1 พร้อมอ่านข้อมูลนายจ้างและการส่งเงินสมทบจากทะเบียนเพื่อใช้ใน Q1.4 และ Q1.5
```sql
-- Q1.1
SELECT national_id, title_name, first_name, last_name,
  employer_account_no, employer_name, registration_date,
  contribution_start, contribution_end, contribution_months
FROM master_table
WHERE national_id = :national_id
  AND coverage_status = 'ACTIVE';
```

ตรวจสอบค่าว่างและตรงตามรูปแบบ (Model)
- ชื่อ และนามสกุล ห้ามค่าว่าง และต้องเป็นตัวอักษรภาษาไทย (ตรวจสอบผ่านฟังก์ชัน isThaiEncoding())
- เลขประจำตัวประชาชน ห้ามค่าว่าง เป็นตัวเลขเท่านั้น จำนวน 13 หลัก (ตรวจสอบผ่าน RE: ^\d{13}$)
- รหัสผ่าน ห้ามค่าว่าง ความยาวไม่น้อยกว่า 8 ตัวอักษร ใช้ได้เฉพาะตัวอักษรภาษาอังกฤษพิมพ์เล็ก พิมพ์ใหญ่ และตัวเลข (ตรวจสอบผ่าน RE: ^[A-Za-z0-9]{8,}$)
- ยืนยันรหัสผ่าน ต้องตรงกับรหัสผ่าน (ตรวจสอบผ่านฟังก์ชัน passwordMatches())
- เบอร์โทรศัพท์ ห้ามค่าว่าง เป็นตัวเลข 9 ถึง 10 หลักและขึ้นต้นด้วย 0 หลังตัดช่องว่าง จุด ขีด และวงเล็บออก (ตรวจสอบผ่าน RE: ^0\d{8,9}$)
- คำนำหน้าชื่อ ต้องเป็น นาย, นาง หรือ นางสาว
- วันเกิด ห้ามค่าว่าง และผู้ใช้งานต้องมีอายุไม่ต่ำกว่า 15 ปี
- ข้อมูลการประสบอันตราย ห้ามค่าว่างทุกช่อง และวันและเวลาที่ประสบอันตรายต้องไม่หลังเวลาที่ยื่นคำร้อง
- ไฟล์ที่อัปโหลด ต้องเป็นไฟล์ .jpg, .png หรือ .pdf ขนาด 1 ไบต์ถึง 10 MB
ตรวจสอบค่าซ้ำ (Database)
- เลขประจำตัวประชาชนห้ามซ้ำ โดยนับจำนวนเลขประจำตัวประชาชนในตาราง InsuredPerson ตาม Q1.2 หากมีค่ามากกว่า 0 แสดงว่ามีเลขประจำตัวประชาชนนี้ในระบบแล้ว
```sql
-- Q1.2
SELECT COUNT(*) AS cnt
FROM InsuredPerson
WHERE national_id = :national_id;
```

หากไม่ผ่านเงื่อนไข ระบบแสดงข้อความแจ้งข้อผิดพลาดในฟอร์มที่ไม่ผ่านเงื่อนไข (Alternate Case 1 [Validation Failed])

**System:**

5. เมื่อผ่านเงื่อนไข (4) ระบบบันทึกข้อมูลดังนี้
5.1 เพิ่มข้อมูลผู้ใช้งานลงตาราง InsuredPerson ตาม Q1.3
```sql
-- Q1.3
INSERT INTO InsuredPerson
  (national_id, title_name, first_name, last_name,
   date_of_birth, gender, phone_no, address, created_at)
VALUES (:national_id, :title_name, :first_name, :last_name,
   :date_of_birth, :gender, :phone_no, :address, NOW())
RETURNING insured_id;
```

5.2 เพิ่มหรือปรับปรุงข้อมูลนายจ้างจากทะเบียน ตาม Q1.4
```sql
-- Q1.4
INSERT INTO Employer (sso_account_no, employer_name)
VALUES (:employer_account_no, :employer_name)
ON CONFLICT (sso_account_no) DO UPDATE
  SET employer_name = EXCLUDED.employer_name
RETURNING employer_id;
```

**System:**

5.3 บันทึกข้อมูลการส่งเงินสมทบลงตารางกลาง Section33Coverage ตาม Q1.5
```sql
-- Q1.5
INSERT INTO Section33Coverage
  (insured_id, employer_id, registration_date,
   contribution_start, contribution_end,
   contribution_months, coverage_status)
VALUES (:insured_id, :employer_id, :registration_date,
   :contribution_start, :contribution_end,
   :contribution_months, 'ACTIVE')
RETURNING coverage_id;
```

5.4 สร้างคำร้อง ตาม Q1.6
```sql
-- Q1.6
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
```

**System:**

5.5 กำหนดเลขที่คำร้อง ตาม Q1.7 และส่งเลขที่คำร้องกับเวลาที่ยื่นกลับไปแสดงในหน้า Injury forms submitted
```sql
-- Q1.7
UPDATE InjuryClaim
SET claim_no = 'SST-' || TO_CHAR(submitted_at, 'YYYY') || '-'
            || LPAD(claim_id::text, 6, '0')
WHERE claim_id = :claim_id
RETURNING claim_no, submitted_at;
```

5.6 บันทึกไฟล์ที่อัปโหลด ตาม Q1.8
```sql
-- Q1.8
INSERT INTO ClaimDocument
  (claim_id, doc_type_id, file_name, file_uri, mime_type,
   file_size_bytes, uploaded_at, check_status)
VALUES (:claim_id, :doc_type_id, :file_name, :file_uri,
   :mime_type, :file_size_bytes, NOW(), 'Pending');
```

**System:**

5.7 บันทึกผลการตรวจสอบสิทธิ์อัตโนมัติ ตาม Q1.9 โดย evidence_ref คือเลขอ้างอิงผลการตรวจจากทะเบียน ในรูปแบบ REG-[ปปปปดดวว]-[claim_id 4 หลัก] และเป็นค่าว่างเมื่อทะเบียนไม่พร้อมใช้งาน
```sql
-- Q1.9
INSERT INTO EligibilityCheck
  (claim_id, coverage_id, checked_at, result,
   is_override, evidence_ref)
VALUES (:claim_id, :coverage_id, NOW(), :register_result,
   FALSE, :evidence_ref);
```

5.8 บันทึกสถานะแรกของคำร้อง ตาม Q1.10
```sql
-- Q1.10
INSERT INTO ClaimStatusHistory
  (claim_id, to_status, changed_at, change_reason)
SELECT claim_id, claim_status, NOW(), 'Submitted by the user'
FROM InjuryClaim
WHERE claim_id = :claim_id;
```

**System:**

6. ระบบแสดงข้อความยื่นคำร้องสำเร็จ พร้อมเลขที่คำร้อง (claim_no) และเวลาที่ยื่น (submitted_at)


## U2: ดูข้อความแจ้งเตือน (View Notify Message)

**Use Case Name:** ดูข้อความแจ้งเตือน (View Notify Message)  
**Use Case Description:** ผู้ใช้งานรอการตอบกลับจากเจ้าหน้าที่ประเมิน ซึ่งระบบจะแจ้งให้ผู้ใช้งานทราบในรูปแบบข้อความแจ้งเตือน  
**Actor:** ผู้ใช้งาน (User)  
**Preconditions:** ผู้ใช้งานลงทะเบียนและกรอกแบบฟอร์มที่เกี่ยวข้องครบถ้วนแล้ว (U1)  

**Steps** (Actor / System):

**Actor:**

1. ผู้ใช้งานเข้าสู่หน้าหลัก (Home Page)

**System:**

2. ระบบแสดงไอคอนกระดิ่ง โดยนับจำนวนข้อความแจ้งเตือนที่ผู้ใช้งานยังไม่ได้อ่าน ตาม Q2.1
```sql
-- Q2.1
SELECT COUNT(*) AS unread
FROM Notification
WHERE insured_id = :insured_id
  AND read_at IS NULL;
```

- หากมีข้อความที่ยังไม่ได้อ่าน แสดงจุดสีแดงที่มุมขวาบนของไอคอนกระดิ่ง
- หากไม่มี ไม่แสดงจุดสีแดง (Alternate Case 1 [unread = 0])
ระบบแสดงการ์ดคำร้องล่าสุดของผู้ใช้งาน ได้แก่ เลขที่คำร้อง การบาดเจ็บ สถานะคำร้อง ขั้นตอนของคำร้อง (วันและเวลาที่ยื่น วันและเวลาที่เจ้าหน้าที่ประเมินยืนยันสิทธิ์ สถานะนัดหมาย และสถานะการรักษา) และนัดหมายถัดไป (วันและเวลา ที่ปรึกษา และสถานที่) ตาม Q2.4
```sql
-- Q2.4
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
```

**Actor:**

3. ผู้ใช้งานคลิกไอคอนกระดิ่งที่มุมขวาบนของหน้า "Home Page"

**System:**

4. ระบบแสดงหน้าต่าง Pop-up รายการข้อความแจ้งเตือน แต่ละข้อความประกอบด้วยข้อมูลอย่างใดอย่างหนึ่งดังนี้
- ข้อความแจ้งการปฏิเสธ (Rejection Message) แสดงคำอธิบายหรือเหตุผลที่แบบฟอร์มการประสบอันตรายถูกปฏิเสธ
- ข้อความแจ้งนัดหมาย (Appointment scheduled) แสดงวันและเวลานัดหมาย ที่ปรึกษา สถานที่ และกำหนดยืนยัน ตาม QN.3
- ข้อความแจ้งผลการตรวจสอบสิทธิ์ (Claim confirmed) หรือการนัดหมายการรักษา (Treatment booked) ตาม QN.1
- ข้อความแจ้งว่าไม่ต้องรักษา (No treatment required) ตาม QN.4 หรือแจ้งยกเลิกการรักษา (Treatment cancelled) ตาม QU4.3
ระบบดึงข้อมูลข้อความแจ้งเตือน ตาม Q2.2
```sql
-- Q2.2
SELECT notification_id, claim_id, subject, body,
  TO_CHAR(sent_at, 'FMDD FMMonth YYYY" : "HH24:MI') AS sent_time,
  read_at IS NOT NULL AS is_read
FROM Notification
WHERE insured_id = :insured_id
ORDER BY sent_at DESC;
```

**Actor:**

5. ผู้ใช้งานคลิกเลือกข้อความแจ้งเตือน

**System:**

6. ระบบบันทึกว่าข้อความแจ้งเตือนนั้นถูกอ่านแล้ว ตาม Q2.3 และแสดงรายละเอียดข้อความ
```sql
-- Q2.3
UPDATE Notification
SET read_at = NOW()
WHERE notification_id = :notification_id
  AND insured_id = :insured_id
  AND read_at IS NULL;
```


## U3.1: ยืนยันนัดหมาย (Confirm Appointment)

**Use Case Name:** ยืนยันนัดหมาย (Appointment Confirmation: Confirm Appointment)  
**Use Case Description:** ผู้ใช้งานยืนยันนัดหมายที่เจ้าหน้าที่ประเมินสร้างไว้  
**Actor:** ผู้ใช้งาน (User)  
**Preconditions:** ผู้ใช้งานลงทะเบียนในแอปพลิเคชันแล้ว แบบฟอร์มการประสบอันตรายได้รับการอนุมัติ และเจ้าหน้าที่ประเมินส่งนัดหมายให้ผู้ใช้งานแล้ว (O4)  

**Steps** (Actor / System):

**System:**

1. ระบบแจ้งผู้ใช้งานที่หน้าแจ้งเตือน (Notification Page) ว่าเจ้าหน้าที่ประเมินสร้างนัดหมายแล้ว โดยแสดงจุดสีแดงที่หน้าแจ้งเตือน และตรวจสอบข้อความที่ยังไม่ได้อ่าน ตาม Q3.1 และแสดงรายการข้อความแจ้งเตือน ตาม Q2.2 (เช่นเดียวกับ U2)
```sql
-- Q3.1
SELECT COUNT(*) AS unread
FROM Notification
WHERE insured_id = :insured_id
  AND read_at IS NULL;
```

**Actor:**

2. ผู้ใช้งานไปที่หน้าแจ้งเตือน และคลิกที่กล่องข้อความแจ้งเตือน

**System:**

3. ระบบเปิดหน้านัดหมาย (Appointment Page) และแสดงข้อมูลดังนี้
- สถานะนัดหมาย: Awaiting your confirmation หรือ Confirmed
- วันที่นัดหมาย: [วัน] / [เดือน] / [ปี] : [เวลา]
- ชื่อเจ้าหน้าที่ประเมินผู้สร้างนัดหมาย
- ประเภทนัดหมาย: Onsite (ที่ศูนย์ฟื้นฟูสมรรถภาพ ห้องของที่ปรึกษา) หรือ Online
- ข้อมูลที่ปรึกษา: คำนำหน้า ชื่อ นามสกุล และสถานที่ทำงาน (Office Location)
- รายละเอียดคำร้อง: Claim ID การบาดเจ็บ และวันที่บาดเจ็บ
- ปุ่ม 3 ปุ่ม: "Confirm Appointment", "Request Another Date" และ "I cannot attend" (ปฏิเสธนัดหมายนี้และไม่เข้าร่วมอีก)
ระบบดึงข้อมูลนัดหมาย ตาม Q3.2
```sql
-- Q3.2
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
```

**Actor:**

4. ผู้ใช้งานเลือกคลิกปุ่มใดปุ่มหนึ่ง
4.1 Confirm Appointment
4.2 Request Another Date (ดู U3.2)
4.3 I cannot attend (ดู U3.3)
กรณีนี้ผู้ใช้งานเลือก 4.1 Confirm Appointment

**System:**

5. เมื่อผู้ใช้งานคลิก "Confirm Appointment" ระบบดำเนินการดังนี้
- แสดงกล่องข้อความ Pop-up เตือนความจำ "สิ่งที่ต้องเตรียม" และ "บัตรประชาชนตัวจริง" พร้อมแสดง [วัน] / [เดือน] / [ปี] : [เวลา]
- เปลี่ยนสถานะนัดหมายใน Appointment Schedule จาก "Pending" เป็น "Confirmed" ตาม Q3.3
```sql
-- Q3.3
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
```

ระบบส่งข้อความแจ้งที่ปรึกษาว่าผู้ใช้งานยืนยันนัดหมายแล้ว ตาม QN.5
```sql
-- QN.5
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
```

**System:**

6. ไม่ว่าผู้ใช้งานจะเลือกตัวเลือกใด หลังการดำเนินการนี้ ระบบบันทึกว่าข้อความแจ้งเตือนถูกอ่านแล้ว ตาม Q3.7 (เฉพาะเมื่อผู้ใช้งานเปิดหน้านัดหมายจากข้อความแจ้งเตือน)
```sql
-- Q3.7
UPDATE Notification
SET read_at = NOW()
WHERE notification_id = :notification_id
  AND insured_id = :insured_id
  AND read_at IS NULL;
```


## U3.2: ยืนยันนัดหมาย (Request Another Date)

**Use Case Name:** ยืนยันนัดหมาย (Appointment Confirmation: Request Another Date)  
**Use Case Description:** ผู้ใช้งานขอเปลี่ยนวันและเวลานัดหมายที่เจ้าหน้าที่ประเมินสร้างไว้  
**Actor:** ผู้ใช้งาน (User)  
**Preconditions:** ผู้ใช้งานลงทะเบียนในแอปพลิเคชันแล้ว แบบฟอร์มการประสบอันตรายได้รับการอนุมัติ และเจ้าหน้าที่ประเมินส่งนัดหมายให้ผู้ใช้งานแล้ว (O4)  

**Steps** (Actor / System):

**System:**

1-3. ดำเนินการเช่นเดียวกับ U3.1 ขั้นตอนที่ 1 ถึง 3 ระบบแจ้งเตือนผู้ใช้งาน ผู้ใช้งานเปิดข้อความแจ้งเตือน และระบบแสดงหน้านัดหมาย (Appointment Page)

**Actor:**

4. ผู้ใช้งานเลือกคลิกปุ่มใดปุ่มหนึ่ง
4.1 Confirm Appointment (ดู U3.1)
4.2 Request Another Date
4.3 I cannot attend (ดู U3.3)
กรณีนี้ผู้ใช้งานเลือก 4.2 Request Another Date

**System:**

5. เมื่อผู้ใช้งานคลิก "Request Another Date" ระบบแสดงกล่องข้อความ Pop-up ดังนี้
- ช่องเลือกวันที่
- ปุ่ม "Confirm" (คลิกได้หลังเลือกวันที่)
- ปุ่ม "Cancel" (คลิกได้ทุกเมื่อ)
ระบบค้นหาช่วงเวลาว่างของที่ปรึกษาในวันที่เลือก (09:00 ถึง 15:00 ทุก 1 ชั่วโมง ยกเว้น 12:00) ตาม Q3.4
```sql
-- Q3.4
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
```

**Actor:**

6. ผู้ใช้งานเลือกวันและเวลาจากตารางเวลาว่าง แล้วเลือกคลิกปุ่มใดปุ่มหนึ่ง
- "Confirm"
- "Cancel"

**System:**

7. ระบบดำเนินการตามปุ่มที่ผู้ใช้งานเลือก
7.1 คลิก "Confirm"
- บันทึกนัดหมายใหม่ใน Appointment Schedule และเปลี่ยนสถานะนัดหมายเดิมเป็น "Rescheduled" ตาม Q3.5 โดยเวลาใหม่ต้องยังว่างและอยู่ในอนาคต หากเวลานั้นไม่ว่างแล้ว ระบบไม่บันทึกและให้ผู้ใช้งานเลือกเวลาใหม่
- Redirect กลับไปหน้ายืนยันนัดหมาย (Appointment Confirmation Page)
- แสดงกล่องข้อความแจ้ง "เวลานัดหมายถูกเปลี่ยนเป็น [วัน] [เดือน] [ปี] : [เวลา]"
```sql
-- Q3.5
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
```

ระบบส่งข้อความแจ้งที่ปรึกษาว่าผู้ใช้งานเปลี่ยนวันและเวลานัดหมาย ตาม QN.5 โดยใช้ appointment_id ของนัดหมายใหม่ที่ได้จาก Q3.5
```sql
-- QN.5
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
```

**System:**

7.2 คลิก "Cancel" ระบบ Redirect กลับไปหน้ายืนยันนัดหมาย โดยไม่เปลี่ยนแปลงข้อมูล (Alternate Case 1 [Cancel])

**System:**

8. ไม่ว่าผู้ใช้งานจะเลือกตัวเลือกใด หลังการดำเนินการนี้ ระบบบันทึกว่าข้อความแจ้งเตือนถูกอ่านแล้ว ตาม Q3.7 (เช่นเดียวกับ U3.1 ขั้นตอนที่ 6)
```sql
-- Q3.7
UPDATE Notification
SET read_at = NOW()
WHERE notification_id = :notification_id
  AND insured_id = :insured_id
  AND read_at IS NULL;
```


## U3.3: ยืนยันนัดหมาย (I cannot attend)

**Use Case Name:** ยืนยันนัดหมาย (Appointment Confirmation: I cannot attend)  
**Use Case Description:** ผู้ใช้งานปฏิเสธนัดหมายที่เจ้าหน้าที่ประเมินสร้างไว้ และแจ้งว่าไม่สามารถเข้าร่วมได้ คำร้องจึงสิ้นสุดลงด้วยสถานะ Withdrawn  
**Actor:** ผู้ใช้งาน (User)  
**Preconditions:** ผู้ใช้งานลงทะเบียนในแอปพลิเคชันแล้ว แบบฟอร์มการประสบอันตรายได้รับการอนุมัติ และเจ้าหน้าที่ประเมินส่งนัดหมายให้ผู้ใช้งานแล้ว (O4)  

**Steps** (Actor / System):

**System:**

1-3. ดำเนินการเช่นเดียวกับ U3.1 ขั้นตอนที่ 1 ถึง 3 ระบบแจ้งเตือนผู้ใช้งาน ผู้ใช้งานเปิดข้อความแจ้งเตือน และระบบแสดงหน้านัดหมาย (Appointment Page)

**Actor:**

4. ผู้ใช้งานเลือกคลิกปุ่มใดปุ่มหนึ่ง
4.1 Confirm Appointment (ดู U3.1)
4.2 Request Another Date (ดู U3.2)
4.3 I cannot attend
กรณีนี้ผู้ใช้งานเลือก 4.3 I cannot attend

**System:**

5. เมื่อผู้ใช้งานคลิก "I cannot attend" ระบบแสดงข้อความเตือนว่าหากยกเลิก คำร้องนี้จะสิ้นสุดลงและระบบจะแจ้งที่ปรึกษา และกล่องยืนยัน "คุณแน่ใจที่จะยกเลิกการนัดหมายหรือไม่" พร้อมปุ่ม "Confirm Cancel Appointment" และ "Go Back"

**Actor:**

6. ผู้ใช้งานอ่านข้อความเตือน แล้วเลือกคลิกปุ่มใดปุ่มหนึ่ง
- "Confirm Cancel Appointment"
- "Go Back"

**System:**

7. ระบบดำเนินการตามปุ่มที่ผู้ใช้งานเลือก
7.1 คลิก "Confirm Cancel Appointment"
- เปลี่ยนสถานะนัดหมายใน Appointment Schedule จาก "Pending" หรือ "Confirmed" เป็น "Cancelled" และเปลี่ยนสถานะคำร้องใน Injury Application จาก "Covered" เป็น "Withdrawn" ตาม Q3.6
- Redirect กลับไปหน้ายืนยันนัดหมาย (Appointment Confirmation Page)
- แสดงกล่องข้อความแจ้ง "เวลานัดหมายถูกยกเลิกแล้ว"
```sql
-- Q3.6
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
```

ระบบส่งข้อความแจ้งที่ปรึกษาว่าผู้ใช้งานไม่สามารถเข้าร่วมนัดหมาย และคำร้องถูกถอน (Withdrawn) ตาม QN.5
```sql
-- QN.5
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
```

**System:**

7.2 คลิก "Go Back" ระบบ Redirect กลับไปหน้ายืนยันนัดหมาย โดยไม่เปลี่ยนแปลงข้อมูล (Alternate Case 1 [Go Back])

**System:**

8. ไม่ว่าผู้ใช้งานจะเลือกตัวเลือกใด หลังการดำเนินการนี้ ระบบบันทึกว่าข้อความแจ้งเตือนถูกอ่านแล้ว ตาม Q3.7 (เช่นเดียวกับ U3.1 ขั้นตอนที่ 6)
```sql
-- Q3.7
UPDATE Notification
SET read_at = NOW()
WHERE notification_id = :notification_id
  AND insured_id = :insured_id
  AND read_at IS NULL;
```


## U4.1: ยืนยันการรักษา (Accept Case)

**Use Case Name:** ยืนยันการรักษา (Treatment Confirmation: Accept Case)  
**Use Case Description:** ผู้ใช้งานยอมรับวันรักษาที่เจ้าหน้าที่ประเมินนัดหมายไว้  
**Actor:** ผู้ใช้งาน (User)  
**Preconditions:** เจ้าหน้าที่ประเมินนัดหมายวันรักษาให้ผู้ใช้งานแล้ว (O5.1)  

**Steps** (Actor / System):

**Actor:**

1. ผู้ใช้งานคลิกปุ่ม "Accept" ในการ์ดหรือหน้า "Confirm Treatment"

**System:**

2. ระบบบันทึกสถานะการยืนยันเป็น "Accepted" ลงฐานข้อมูล ตาม QU4.1
```sql
-- QU4.1
UPDATE Treatment
SET treatment_status = 'Accepted'
WHERE treatment_id = :treatment_id
  AND claim_id = :claim_id
  AND treatment_status = 'Pending';
```

**System:**

3. ระบบแสดงการ์ด Pop-up แจ้งผู้ใช้งานว่ายอมรับการรักษาเรียบร้อยแล้ว


## U4.2: ยืนยันการรักษา (Change Date)

**Use Case Name:** ยืนยันการรักษา (Treatment Confirmation: Change Date)  
**Use Case Description:** ผู้ใช้งานขอเปลี่ยนวันรักษาที่เจ้าหน้าที่ประเมินนัดหมายไว้  
**Actor:** ผู้ใช้งาน (User)  
**Preconditions:** เจ้าหน้าที่ประเมินนัดหมายวันรักษาให้ผู้ใช้งานแล้ว (O5.1)  

**Steps** (Actor / System):

**Actor:**

1. ผู้ใช้งานคลิกปุ่ม "Request Another Date" ในหน้า "Treatment"

**System:**

2. ระบบแสดงกล่องหรือหน้าต่างแสดงวันที่ว่างทั้งหมด

**Actor:**

3. ผู้ใช้งานเลือกวันที่ต้องการ

**System:**

4. ระบบบันทึกวันรักษาใหม่ลงฐานข้อมูล ตาม QU4.2
```sql
-- QU4.2
UPDATE treatment
SET scheduled_date = :new_date
WHERE claim_id = :current_claim_id
  AND treatment_id = :current_treatment_id
  AND treatment_status = 'Pending';
```


## U4.3: ยืนยันการรักษา (Reject)

**Use Case Name:** ยืนยันการรักษา (Treatment Confirmation: Reject)  
**Use Case Description:** ระบบยกเลิกวันรักษาโดยอัตโนมัติเมื่อผู้ใช้งานไม่ตอบรับภายในกำหนด เช่น ไม่เข้ารับการรักษา หรือไม่ตอบกลับการ์ดยืนยัน  
**Actor:** ผู้ใช้งาน (User)  
**Preconditions:** เจ้าหน้าที่ประเมินนัดหมายวันรักษาให้ผู้ใช้งานแล้ว (O5.1)  

**Steps** (Actor / System):

**Actor:**

1. ผู้ใช้งานไม่ดำเนินการตาม U4.1 หรือ U4.2 จนถึงกำหนดเวลา

**System:**

2. ระบบถือว่าผู้ใช้งานปฏิเสธการรักษา (ยกเลิกโดยอัตโนมัติ)

**System:**

3. ระบบยกเลิกวันรักษาในฐานข้อมูลเป็นงานเบื้องหลัง (Subroutine) และส่งข้อความแจ้งเตือนผู้ใช้งานว่าการรักษาถูกยกเลิก ตาม QU4.3
```sql
-- QU4.3
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
```


## U5: ดูตารางนัดหมาย (View Appointment Schedule)

**Use Case Name:** ดูตารางนัดหมาย (View Appointment Schedule)  
**Use Case Description:** ผู้ใช้งานดูตารางนัดหมายที่เจ้าหน้าที่ประเมินสร้างไว้  
**Actor:** ผู้ใช้งาน (User)  
**Preconditions:** เจ้าหน้าที่ประเมินสร้างนัดหมายแล้ว (O4)  

**Steps** (Actor / System):

**Actor:**

1. ผู้ใช้งานคลิก "Schedule Page" ในแถบนำทาง (Navigation Bar) เพื่อดูตารางนัดหมาย

**System:**

2. ระบบแสดงหน้าตารางนัดหมายในรูปแบบรายการ (List View) แต่ละรายการประกอบด้วย
- ข้อมูลที่ปรึกษา: คำนำหน้าชื่อ ชื่อ และนามสกุล
- สถานที่ทำงาน (Office Location)
- วันนัดหมาย: [วัน] [เดือน] [ปี] : [เวลา]
- รายละเอียดคำร้อง: Claim ID การบาดเจ็บ และวันที่บาดเจ็บ
ระบบดึงตารางนัดหมายจากฐานข้อมูล ตาม QU5.1
```sql
-- QU5.1
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
```


## U6: ดูตารางการรักษา (View Treatment Schedule)

**Use Case Name:** ดูตารางการรักษา (View Treatment Schedule)  
**Use Case Description:** ผู้ใช้งานดูตารางการรักษาที่เจ้าหน้าที่ประเมินจองไว้  
**Actor:** ผู้ใช้งาน (User)  
**Preconditions:** เจ้าหน้าที่ประเมินนัดหมายการรักษาแล้ว (O5)  

**Steps** (Actor / System):

**Actor:**

1. ผู้ใช้งานคลิก "Schedule Page" ในแถบนำทาง (Navigation Bar) เพื่อดูตารางการรักษา

**System:**

2. ระบบแสดงหน้าตารางการรักษาในรูปแบบรายการ (List View) แต่ละรายการประกอบด้วย
- ข้อมูลสถานพยาบาล: ชื่อ รูปภาพ และที่ตั้ง
- วันรักษา: [วัน] [เดือน] [ปี] : [เวลา]
- รายละเอียดคำร้อง: Claim ID การบาดเจ็บ และวันที่บาดเจ็บ
ระบบดึงตารางการรักษาจากฐานข้อมูล ตาม Q6.1
```sql
-- Q6.1
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
```


## O1: ดูคำร้องกรณีประสบอันตราย (View Injury Application)

**Use Case Name:** ดูคำร้องกรณีประสบอันตราย (View Injury Application)  
**Use Case Description:** เจ้าหน้าที่ประเมินดูแบบฟอร์มการประสบอันตรายที่ผู้ใช้งานยื่นมา  
**Actor:** เจ้าหน้าที่ประเมิน (Evaluation Officer)  
**Preconditions:** ผู้ใช้งานยื่นแบบฟอร์มการประสบอันตรายแล้ว (U1)  

**Steps** (Actor / System):

**Actor:**

1. เจ้าหน้าที่ประเมินคลิก "Verification" ที่แถบนำทางด้านซ้าย

**System:**

2. ระบบแสดงหน้า Verification Page ประกอบด้วย
- จำนวนคำร้องแยกตามสถานะ: Awaiting verification, Reviews needed และ Register unavailable
- รายการคำร้องที่รอตรวจสอบ แต่ละรายการแสดง Claim ID ชื่อผู้ใช้งาน การบาดเจ็บ วันที่บาดเจ็บ วันที่ยื่น จำนวนเอกสารที่ส่ง และสถานะการตรวจสอบ
- ปุ่ม "Open" ที่ด้านขวาสุดของแต่ละรายการ
ระบบดึงรายการคำร้อง ตาม QO1.1 และนับจำนวนคำร้องตามสถานะ ตาม QO1.2
```sql
-- QO1.1
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
```

```sql
-- QO1.2
SELECT
  COUNT(*) FILTER (WHERE claim_status = 'Awaiting verification')
    AS awaiting_verification,
  COUNT(*) FILTER (WHERE claim_status = 'Needs review')
    AS reviews_needed,
  COUNT(*) FILTER (WHERE claim_status = 'Register unavailable')
    AS register_unavailable
FROM InjuryClaim;
```

**Actor:**

3. เจ้าหน้าที่ประเมินคลิก "Open" ที่รายการคำร้องที่ต้องการ

**System:**

4. ระบบแสดงหน้า Eligibility Decision Page ประกอบด้วย
- ส่วนหัว (Header): Claim ID ชื่อและนามสกุลผู้ใช้งาน วันที่ยื่นคำร้อง และปุ่ม Back สำหรับกลับไปหน้า Verification Page
- การ์ดสรุปคำร้อง (Claim Summary Card): เลขประจำตัวประชาชน นายจ้างตามคำร้อง วันที่บาดเจ็บ สถานที่ สาเหตุการบาดเจ็บ และอวัยวะที่บาดเจ็บ
- การ์ดเอกสารประกอบคำร้อง (Documents lodged with the claim): รายการเอกสารที่ส่งมา แต่ละรายการแสดงชื่อไฟล์ ขนาดไฟล์ และปุ่ม "View" ที่ด้านขวา
ระบบดึงส่วนหัวและสรุปข้อมูลคำร้อง ตาม QO1.3
```sql
-- QO1.3
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
```

**System:**

4.1 ระบบดึงรายการเอกสารประกอบคำร้อง ตาม QO1.4
```sql
-- QO1.4
SELECT file_name,
  pg_size_pretty(file_size_bytes::bigint) AS file_size,
  file_uri
FROM ClaimDocument
WHERE claim_id = :claim_id
ORDER BY uploaded_at;
```

4.2 ระบบดึงผลการตรวจสอบสิทธิ์อัตโนมัติและหลักฐาน แสดงที่แถบด้านขวา ตาม QO1.5
```sql
-- QO1.5
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
```

**Actor:**

5. เจ้าหน้าที่ประเมินคลิก "View" ที่เอกสารที่ต้องการ

**System:**

6. ระบบเปิดไฟล์เอกสารจาก file_uri ที่ได้จาก QO1.4 (ไม่มีคำสั่ง SQL เพิ่มเติม)


## O2: อนุมัติคำร้อง (Approve Injury Application)

**Use Case Name:** อนุมัติคำร้อง (Approve Injury Application)  
**Use Case Description:** เจ้าหน้าที่ประเมินอนุมัติแบบฟอร์มการประสบอันตรายที่ผู้ใช้งานยื่นมา หลังจากตรวจสอบคำร้องแล้ว  
**Actor:** เจ้าหน้าที่ประเมิน (Evaluation Officer)  
**Preconditions:** ผู้ใช้งานยื่นแบบฟอร์มการประสบอันตรายแล้ว (U1) และเจ้าหน้าที่ประเมินดูคำร้องแล้ว (O1)  

**Steps** (Actor / System):

**Actor:**

1. ในหน้า Verification Page เจ้าหน้าที่ประเมินคลิก "Open" ที่ด้านขวาสุดของรายการ เพื่อไปยังหน้า Eligibility Decision Page

**System:**

2. ระบบแสดงหน้า Eligibility Decision Page เช่นเดียวกับ O1 ขั้นตอนที่ 4 (ตาม QO1.1 ถึง QO1.5)
แถบด้านขวา (Right Side Bar) ประกอบด้วย
- ส่วนที่ 1: หัวข้อ "Section 33 eligibility" สถานะ "Is covered" และข้อความ "Automatic result from the SSO insured register"
- ส่วนที่ 2: ระยะเวลาส่งเงินสมทบ (Contribution period) นายจ้างในทะเบียน (Employer in register) และวันที่ตรวจสอบทะเบียน (Register queried)
- ส่วนที่ 3: ตัวเลือก (เลือกได้ 1 ข้อ) Confirm, Not Covered และ Needs review พร้อมช่องกรอกเหตุผลการแก้ไขผล (Override reason) ซึ่งไม่บังคับกรอก
- ส่วนที่ 4: ปุ่ม "Confirm Result"

**Actor:**

3. เจ้าหน้าที่ประเมินเลือก "Confirm" แล้วคลิก "Confirm Result"

**System:**

4. ระบบแสดงการ์ดยืนยัน (Confirmation Card) ข้อความ "Do you confirm the result" พร้อมปุ่ม "Confirm" และ "Cancel"

**Actor:**

5. เจ้าหน้าที่ประเมินคลิก "Confirm" หรือ "Cancel"

**System:**

6.1 คลิก "Confirm" ระบบบันทึกผลการตรวจสอบสิทธิ์และเปลี่ยนสถานะคำร้อง ตาม QO2.1
```sql
-- QO2.1
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
```

**System:**

จากนั้นระบบส่งข้อความแจ้งเตือนผู้ใช้งาน ตาม QN.1 (ทำงานต่อจาก QO2.1 ทันที)
```sql
-- QN.1
INSERT INTO Notification
  (claim_id, insured_id, subject, body, sent_at)
SELECT claim_id, insured_id, :subject, :body, NOW()
FROM InjuryClaim
WHERE claim_id = :claim_id;
```

**System:**

6.2 คลิก "Cancel" ระบบปิดการ์ดยืนยัน (Alternate Case 1 [Cancel])


## O3: ปฏิเสธคำร้อง (Reject Injury Application)

**Use Case Name:** ปฏิเสธคำร้อง (Reject Injury Application)  
**Use Case Description:** เจ้าหน้าที่ประเมินปฏิเสธแบบฟอร์มการประสบอันตรายที่ผู้ใช้งานยื่นมา หลังจากตรวจสอบคำร้องแล้ว  
**Actor:** เจ้าหน้าที่ประเมิน (Evaluation Officer)  
**Preconditions:** ผู้ใช้งานยื่นแบบฟอร์มการประสบอันตรายแล้ว (U1) และเจ้าหน้าที่ประเมินดูคำร้องแล้ว (O1)  

**Steps** (Actor / System):

**Actor:**

1. ในหน้า Verification Page เจ้าหน้าที่ประเมินคลิก "Open" ที่ด้านขวาสุดของรายการ เพื่อไปยังหน้า Eligibility Decision Page

**System:**

2. ระบบแสดงหน้า Eligibility Decision Page เช่นเดียวกับ O1 ขั้นตอนที่ 4 (ตาม QO1.1 ถึง QO1.5)
แถบด้านขวา (Right Side Bar) ประกอบด้วย
- ส่วนที่ 1: หัวข้อ "Section 33 eligibility" สถานะ "Is covered" และข้อความ "Automatic result from the SSO insured register"
- ส่วนที่ 2: ระยะเวลาส่งเงินสมทบ (Contribution period) นายจ้างในทะเบียน (Employer in register) และวันที่ตรวจสอบทะเบียน (Register queried)
- ส่วนที่ 3: ตัวเลือก (เลือกได้ 1 ข้อ) Confirm และ Not Covered พร้อมช่องกรอกเหตุผลการแก้ไขผล (Override reason) ซึ่งไม่บังคับกรอก
- ส่วนที่ 4: ปุ่ม "Confirm Result"
ระบบดึงรายการเหตุผลการปฏิเสธมาแสดงในรายการตัวเลือก (Dropdown) ตาม QO1.6
```sql
-- QO1.6
SELECT reason_code, name_th, description
FROM RejectionReason
ORDER BY reason_code;
```

**Actor:**

3. เจ้าหน้าที่ประเมินเลือก "Not Covered" เลือกเหตุผลการปฏิเสธ แล้วคลิก "Confirm Result"

**System:**

4. ระบบแสดงการ์ดยืนยัน (Confirmation Card) ข้อความ "Do you confirm the result" พร้อมปุ่ม "Confirm" และ "Cancel"

**Actor:**

5. เจ้าหน้าที่ประเมินคลิก "Confirm" หรือ "Cancel"

**System:**

6.1 คลิก "Confirm" ระบบบันทึกผลการตรวจสอบสิทธิ์และเปลี่ยนสถานะคำร้อง
- กรณีเลือก "Not Covered" ตาม QO3.1
```sql
-- QO3.1
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
```

**System:**

จากนั้นระบบบันทึกการปฏิเสธลงตาราง ClaimRejection และเปลี่ยนสถานะคำร้องเป็น "Rejected" ตาม QO3.2
```sql
-- QO3.2
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
```

**System:**

จากนั้นระบบส่งข้อความแจ้งการปฏิเสธพร้อมเหตุผลให้ผู้ใช้งาน ตาม QN.2
```sql
-- QN.2
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
```

**System:**

6.2 คลิก "Cancel" ระบบปิดการ์ดยืนยัน (Alternate Case 1 [Cancel])


## O4: สร้างนัดหมาย (Schedule Appointment)

**Use Case Name:** สร้างนัดหมาย (Schedule Appointment)  
**Use Case Description:** เจ้าหน้าที่ประเมินสร้างนัดหมายระหว่างผู้ใช้งานกับที่ปรึกษา หลังจากยืนยันคำร้องแล้ว  
**Actor:** เจ้าหน้าที่ประเมิน (Evaluation Officer)  
**Preconditions:** เจ้าหน้าที่ประเมินอนุมัติคำร้องแล้ว (O2)  

**Steps** (Actor / System):

**Actor:**

1. ที่แถบนำทางด้านซ้าย เจ้าหน้าที่ประเมินคลิก "Scheduling"

**System:**

2. ระบบแสดงหน้า Schedule Appointment Page ประกอบด้วย
- ส่วนหัว: ข้อความ "Scheduling" และข้อความรอง Claim ID ชื่อและนามสกุลผู้ใช้งาน และวันที่ตรวจสอบสิทธิ์ (Verified date)
- ช่องเลือกวันที่สำหรับนัดหมายกับที่ปรึกษา
ระบบดึงคำร้องที่พร้อมนัดหมาย พร้อมข้อมูลส่วนหัว ตาม QO4.1
```sql
-- QO4.1
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
```

**System:**

2.1 ตารางเวลาว่างของที่ปรึกษา (Consultant Availability) แสดงรายชื่อที่ปรึกษา และปุ่มช่วงเวลา เช่น [Mon 09:00] [Tue 11:00] [Thu 14:30] โดยแบ่งสถานะด้วยสี 3 สี
- สีขาว: ว่าง นัดหมายได้
- สีเทา: ไม่ว่าง หรือถูกนัดหมายโดยผู้อื่นแล้ว (คลิกไม่ได้)
- สีม่วง: นัดหมายโดยตนเองแล้วและรอการยืนยัน
ระบบดึงช่วงเวลาว่างของที่ปรึกษาในวันที่เลือก ตาม QO4.2
```sql
-- QO4.2
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
```

**System:**

2.2 แถบด้านขวา แสดงเมื่อคลิกปุ่มช่วงเวลา หัวข้อ "Appointment to offer" ประกอบด้วย
- ข้อมูลที่ปรึกษา: ชื่อ นามสกุล และสถานที่ทำงาน
- วันนัดหมาย: [ชื่อวัน] [วันที่] [เดือน] [ปี] และเวลา: [เวลาเริ่ม] - [เวลาสิ้นสุด]
- สถานที่: อาคาร ชั้น และห้อง
- ปุ่ม "Offer to the Consultant" และ "Add to waiting list"

**Actor:**

3. เจ้าหน้าที่ประเมินเลือกวันและเวลา แล้วคลิก "Offer to the Consultant"

**System:**

4. ระบบแสดงการ์ดยืนยัน ข้อความ "Do you confirm to make an appointment at [Date] and [Time]" พร้อมปุ่ม "Confirm" และ "Cancel"

**Actor:**

5. เจ้าหน้าที่ประเมินคลิก "Confirm" หรือ "Cancel"

**System:**

6.1 คลิก "Confirm" ระบบบันทึกนัดหมาย ตาม QO4.3 และแสดงการ์ด "Appointment Scheduled" เพื่อแจ้งว่าจองนัดหมายสำเร็จ
```sql
-- QO4.3
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
```

**System:**

จากนั้นระบบส่งข้อความแจ้งเตือนผู้ใช้งานและที่ปรึกษา ตาม QN.3 (ทำงานต่อจาก QO4.3 ทันที)
```sql
-- QN.3
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
```

**System:**

6.2 คลิก "Cancel" ระบบปิดการ์ดยืนยัน (Alternate Case 1 [Cancel])


## O5.1: นัดหมายการรักษา (Book Treatment)

**Use Case Name:** นัดหมายการรักษา (Schedule Treatment: Book Treatment)  
**Use Case Description:** เจ้าหน้าที่ประเมินนัดหมายการรักษาให้ผู้ใช้งาน หลังจากที่ปรึกษายื่นรายงานและเจ้าหน้าที่ประเมินอ่านรายงานแล้ว  
**Actor:** เจ้าหน้าที่ประเมิน (Evaluation Officer)  
**Preconditions:** ที่ปรึกษายื่นรายงานการให้คำปรึกษาแล้ว (C2) และเจ้าหน้าที่ประเมินอ่านรายงานแล้ว (O6)  

**Steps** (Actor / System):

**Actor:**

1. ที่แถบนำทางด้านซ้าย เจ้าหน้าที่ประเมินคลิก "Treatment"

**System:**

2. ระบบแสดงหน้า Schedule Treatment Page ประกอบด้วย
- ส่วนหัว: ข้อความ "Treatment" และ Claim ID ข้อความรอง ชื่อและนามสกุลผู้ใช้งาน และวันที่ลงนามรายงาน
- การ์ดทางลัดไปยังรายงานการให้คำปรึกษา: หัวข้อรายงาน สถานะการลงนาม (Signed หรือ Not Signed) โดยหากรายงานยังไม่ลงนาม เจ้าหน้าที่ประเมินไม่สามารถจองการรักษาได้ และปุ่มไปยังหน้า View Consultant Report
ระบบดึงคำร้องที่มีรายงานแล้วและยังไม่มีการรักษา ตาม QO5.1
```sql
-- QO5.1
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
```

**System:**

2.1 การ์ด "Treatment to book" ประกอบด้วยช่องกรอกประเภทการรักษา ระยะเวลา (นาทีถึงชั่วโมง) และสถานพยาบาล หัวข้อย่อย "Available Times" แสดงปุ่มวันและเวลา [ชื่อวัน] [วันที่] [เดือน] - [เวลา] โดยแบ่งสถานะด้วยสี 3 สี
- สีขาว: ว่าง นัดหมายได้
- สีเทา: ไม่ว่าง หรือถูกนัดหมายโดยผู้อื่นแล้ว (คลิกไม่ได้)
- สีม่วง: นัดหมายโดยตนเองแล้ว
ระบบดึงช่วงเวลาว่างของสถานพยาบาล ตาม QO5.2
```sql
-- QO5.2
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
```

**System:**

2.2 แถบด้านขวา หัวข้อ "Booking Summary" แสดงเมื่อคลิกปุ่มวันและเวลา ประกอบด้วย
- รายละเอียดการรักษา: ประเภทและระยะเวลา
- วันรักษา: [ชื่อวัน] [วันที่] [เดือน] [ปี] และเวลา: [เวลาเริ่ม] - [เวลาสิ้นสุด]
- สถานที่: อาคาร ชั้น และห้อง (ไม่บังคับ)
- รายละเอียดรายงาน: ลิงก์ไปยังรายงาน [Report ID] วันที่ลงนาม และที่ปรึกษาผู้เขียนรายงาน
- ปุ่ม "Book treatment" และ "No treatment require"

**Actor:**

3. เจ้าหน้าที่ประเมินเลือกประเภทการรักษา ระยะเวลา สถานพยาบาล วันและเวลา แล้วคลิก "Book treatment"

**System:**

4. ระบบแสดงการ์ดยืนยัน ข้อความ "Do you confirm to book this treatment at [Facility] : [Date] - [Time]" พร้อมปุ่ม "Confirm" และ "Cancel"

**Actor:**

5. เจ้าหน้าที่ประเมินคลิก "Confirm" หรือ "Cancel"

**System:**

6.1 คลิก "Confirm" ระบบบันทึกการรักษา ตาม QO5.3 และแสดงการ์ด "Treatment Booked" เพื่อแจ้งว่าจองการรักษาสำเร็จ
```sql
-- QO5.3
INSERT INTO Treatment
  (claim_id, report_id, officer_id, treatment_type,
   facility_name, scheduled_date, scheduled_time,
   treatment_status, created_at)
VALUES (:claim_id, :report_id, :officer_id, :treatment_type,
  :facility_name, :scheduled_date, :scheduled_time, 'Pending',
  NOW())
RETURNING treatment_id;
```

**System:**

จากนั้นระบบส่งข้อความแจ้งเตือนผู้ใช้งาน ตาม QN.1
```sql
-- QN.1
INSERT INTO Notification
  (claim_id, insured_id, subject, body, sent_at)
SELECT claim_id, insured_id, :subject, :body, NOW()
FROM InjuryClaim
WHERE claim_id = :claim_id;
```

**System:**

6.2 คลิก "Cancel" ระบบปิดการ์ดยืนยัน (Alternate Case 1 [Cancel])


## O5.2: นัดหมายการรักษา (No Treatment Required)

**Use Case Name:** นัดหมายการรักษา (Schedule Treatment: No Treatment Required)  
**Use Case Description:** เจ้าหน้าที่ประเมินปิดคำร้องเมื่อรายงานการให้คำปรึกษาระบุว่าผู้ใช้งานไม่ต้องรับการรักษา  
**Actor:** เจ้าหน้าที่ประเมิน (Evaluation Officer)  
**Preconditions:** ที่ปรึกษายื่นรายงานการให้คำปรึกษาแล้ว (C2) และเจ้าหน้าที่ประเมินอ่านรายงานแล้ว (O6)  

**Steps** (Actor / System):

**System:**

1-2. เจ้าหน้าที่ประเมินเปิดหน้า Schedule Treatment Page เช่นเดียวกับ O5.1 ขั้นตอนที่ 1 ถึง 2

**Actor:**

3. เจ้าหน้าที่ประเมินคลิก "No treatment require"

**System:**

4. ระบบแสดงการ์ดยืนยัน ข้อความ "Do you confirm that no treatment require for user [คำนำหน้าชื่อ ชื่อ และนามสกุลผู้ใช้งาน]" พร้อมปุ่ม "Confirm" และ "Cancel"

**Actor:**

5. เจ้าหน้าที่ประเมินคลิก "Confirm" หรือ "Cancel"

**System:**

6.1 คลิก "Confirm" ระบบเปลี่ยนสถานะคำร้องเป็น "No treatment required" ตาม QO5.4 และแสดงการ์ด "No Treatment Required"
```sql
-- QO5.4
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
```

**System:**

จากนั้นระบบส่งข้อความแจ้งเตือนผู้ใช้งาน ตาม QN.4 (ทำงานต่อจาก QO5.4 ทันที)
```sql
-- QN.4
INSERT INTO Notification
  (claim_id, insured_id, subject, body, sent_at)
SELECT claim_id, insured_id, 'No treatment required',
  CONCAT('The consultation report for your claim ', claim_no,
  ' says no treatment is required, so your claim is now closed.'),
  NOW()
FROM InjuryClaim
WHERE claim_id = :claim_id
  AND claim_status = 'No treatment required';
```

**System:**

6.2 คลิก "Cancel" ระบบปิดการ์ดยืนยัน (Alternate Case 1 [Cancel])


## O6: ดูรายงานการให้คำปรึกษา (View Consultation Report)

**Use Case Name:** ดูรายงานการให้คำปรึกษา (View Consultation Report)  
**Use Case Description:** เจ้าหน้าที่ประเมินดูรายงานการให้คำปรึกษาที่ที่ปรึกษายื่นมา  
**Actor:** เจ้าหน้าที่ประเมิน (Evaluation Officer)  
**Preconditions:** ที่ปรึกษายื่นรายงานการให้คำปรึกษาแล้ว (C2)  

**Steps** (Actor / System):

**Actor:**

1. ที่แถบนำทางด้านซ้าย เจ้าหน้าที่ประเมินคลิก "Consultation Reports"

**System:**

2. ระบบแสดงรายการรายงานการให้คำปรึกษา โดยรายงานที่ยังไม่เปิดดูแสดงก่อน ตาม QO6.1
```sql
-- QO6.1
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
```

**System:**

2.1 เมื่อเลือกรายงาน ระบบแสดงหน้ารายงานการให้คำปรึกษา (Consultation Report Page) ประกอบด้วย
- ส่วนหัว: Claim ID ชื่อและนามสกุลผู้ใช้งาน วันที่ลงนามรายงาน และหมายเลขฉบับ (Version)
- ส่วนที่ 1 ข้อมูลผู้ป่วย: ชื่อ นามสกุล อายุ วันและเวลาให้คำปรึกษา วันที่ยื่นรายงาน และคำนำหน้าชื่อ ชื่อ นามสกุล และความเชี่ยวชาญของที่ปรึกษา
- ส่วนที่ 2 รายงาน 2 รูปแบบ: ข้อความ (Text field) หรือไฟล์ (Files) พร้อมปุ่ม "View"
- ส่วนที่ 3 สถานะการลงนาม: Signature pending หรือ Signature signed
- ส่วนที่ 4 สถานะการเปิดดู: Pending หรือ Viewed
ระบบดึงข้อมูลหน้ารายงาน ตาม QO6.2
```sql
-- QO6.2
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
```

**Actor:**

3. เจ้าหน้าที่ประเมินคลิก "View"

**System:**

4. ระบบบันทึกว่ารายงานถูกเปิดดูแล้ว ตาม QO6.3 และแสดงรายงานตามรูปแบบ
4.1 ข้อความ (Text field): แสดงหัวเรื่องและเนื้อหารายงาน
4.2 ไฟล์ (File): แสดงไฟล์ที่ส่งมา (Alternate Case 1 [File])
```sql
-- QO6.3
UPDATE ConsultationReport
SET read_at = NOW()
WHERE report_id = :report_id
  AND read_at IS NULL;
```


## C1: ดูตารางนัดหมาย (View Appointment Schedule)

**Use Case Name:** ดูตารางนัดหมาย (View Appointment Schedule)  
**Use Case Description:** ที่ปรึกษาดูวันนัดหมายและข้อมูลผู้ใช้งานที่นัดไว้  
**Actor:** ที่ปรึกษา (Consultant)  
**Preconditions:** ผู้ใช้งานยืนยันนัดหมายแล้ว (U3.1)  

**Steps** (Actor / System):

**Actor:**

1. ที่ปรึกษาคลิก "Schedule Page" ในแถบนำทาง (Navigation Bar) เพื่อดูตารางนัดหมาย

**System:**

2. ระบบแสดงหน้าตารางนัดหมายในรูปแบบรายการ (List View) แต่ละรายการประกอบด้วย
- ข้อมูลผู้ใช้งาน: คำนำหน้าชื่อ ชื่อ นามสกุล และรูปโปรไฟล์
- วันนัดหมาย: [วัน] [เดือน] [ปี] : [เวลา]
- รายละเอียดคำร้อง: Claim ID การบาดเจ็บ และวันที่บาดเจ็บ
ระบบอ่านข้อมูลจากฐานข้อมูล ตาม QC1.1
```sql
-- QC1.1
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
```


## C2.1: สร้างรายงานการให้คำปรึกษา (Amend the Draft)

**Use Case Name:** สร้างรายงานการให้คำปรึกษา (Create Consultation Report: Amend the Draft)  
**Use Case Description:** ที่ปรึกษาเขียนรายงานการให้คำปรึกษา และยื่นรายงานให้เจ้าหน้าที่ประเมินเมื่อเสร็จสิ้น  
**Actor:** ที่ปรึกษา (Consultant)  
**Preconditions:** ผู้ใช้งานยืนยันนัดหมายแล้ว (U3.1) และการให้คำปรึกษากับผู้ใช้งานเสร็จสิ้นแล้ว  

**Steps** (Actor / System):

**Actor:**

1. ที่แถบนำทางด้านซ้าย ที่ปรึกษาคลิก "Create Consultation Report"

**System:**

2. ระบบตรวจสอบการให้คำปรึกษาที่ยังไม่มีรายงาน ตาม QC2.1
```sql
-- QC2.1
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
```

2.1 เมื่อเลือกการให้คำปรึกษา ระบบสร้างบันทึกการให้คำปรึกษา (ConsultationSession) หากยังไม่มี ตาม QC2.2
```sql
-- QC2.2
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
```

**System:**

2.2 ระบบแสดงหน้ารายงาน ประกอบด้วย
- ส่วนหัว: Claim ID ชื่อและนามสกุลผู้ใช้งาน วันที่ลงนามรายงาน และหมายเลขฉบับ (Version)
- ส่วนที่ 1 ข้อมูลผู้ป่วย: ชื่อ นามสกุล อายุ วันและเวลาให้คำปรึกษา และคำนำหน้าชื่อ ชื่อ นามสกุล และความเชี่ยวชาญของที่ปรึกษา
- ส่วนที่ 2 รายงาน 2 รูปแบบ: ช่องพิมพ์ข้อความ และไฟล์รายงานแนบ
- ส่วนที่ 3 สถานะการลงนาม: Signature pending หรือ Signature signed
- ส่วนที่ 4 ปุ่ม 3 ปุ่ม: "Amend the draft", "Sign the signature" และ "File the report"
ระบบดึงข้อมูลหน้ารายงาน ตาม QC2.3
```sql
-- QC2.3
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
```

**Actor:**

3. ที่ปรึกษาคลิก "Amend the draft"

**System:**

4. ระบบเปิดให้พิมพ์ในช่องข้อความ และแสดงปุ่ม "Attach" สำหรับแนบไฟล์ (เลือกได้อย่างใดอย่างหนึ่ง) ปุ่ม "Amend the draft" เปลี่ยนเป็น "Finish the draft"

**Actor:**

5.1 ที่ปรึกษาคลิก "Attach" (Alternate Case 1 [Attach file])
5.2 ที่ปรึกษาพิมพ์รายงาน แล้วคลิก "Finish the draft"

**System:**

6.1 (Attach) ระบบเปิด File Explorer
6.2 (Finish the draft) ระบบบันทึกฉบับร่าง
- บันทึกครั้งแรก ตาม QC2.4
```sql
-- QC2.4
INSERT INTO ConsultationReport
  (session_id, consultant_id, version_no, report_content,
   is_superseded)
VALUES (:session_id, :consultant_id, 1, :report_content, FALSE)
RETURNING report_id;
```

- บันทึกครั้งถัดไป ตาม QC2.5 (Alternate Case 2 [Draft already saved])
```sql
-- QC2.5
UPDATE ConsultationReport
SET report_content = :report_content,
    signed_at = NULL
WHERE report_id = :report_id
  AND consultant_id = :consultant_id
  AND delivered_at IS NULL;
```

**Actor:**

7. (File Explorer) ที่ปรึกษาเลือกไฟล์ คลิก "Open" แล้วคลิก "Finish the draft"

**System:**

8. ระบบเปลี่ยนข้อความในช่องเป็น "File Attached" และบันทึกข้อมูล


## C2.2: สร้างรายงานการให้คำปรึกษา (Sign the Signature)

**Use Case Name:** สร้างรายงานการให้คำปรึกษา (Create Consultation Report: Sign the Signature)  
**Use Case Description:** ที่ปรึกษาลงลายมือชื่อในรายงานการให้คำปรึกษา  
**Actor:** ที่ปรึกษา (Consultant)  
**Preconditions:** ผู้ใช้งานยืนยันนัดหมายแล้ว (U3.1) และการให้คำปรึกษากับผู้ใช้งานเสร็จสิ้นแล้ว และที่ปรึกษาบันทึกฉบับร่างแล้ว (C2.1)  

**Steps** (Actor / System):

**System:**

1-2. ที่ปรึกษาเปิดหน้ารายงานเช่นเดียวกับ C2.1 ขั้นตอนที่ 1 ถึง 2

**Actor:**

3. ที่ปรึกษาคลิก "Sign the signature"

**System:**

4. ระบบแสดงการ์ดสำหรับวาดลายมือชื่อ พร้อมปุ่ม "Delete" สำหรับลบและลงลายมือชื่อใหม่ (Alternate Case 1 [Delete]) และปุ่ม "Confirm" สำหรับยืนยันลายมือชื่อ

**Actor:**

5. ที่ปรึกษาลงลายมือชื่อ แล้วคลิก "Confirm"

**System:**

6. ระบบเปลี่ยนสถานะการลงนามจาก "Pending" เป็น "Signed" ตาม QC2.6
```sql
-- QC2.6
UPDATE ConsultationReport
SET signed_at = NOW()
WHERE report_id = :report_id
  AND consultant_id = :consultant_id
  AND report_content IS NOT NULL
  AND signed_at IS NULL;
```


## C2.3: สร้างรายงานการให้คำปรึกษา (File the Report)

**Use Case Name:** สร้างรายงานการให้คำปรึกษา (Create Consultation Report: File the Report)  
**Use Case Description:** ที่ปรึกษายื่นรายงานการให้คำปรึกษาให้เจ้าหน้าที่ประเมิน  
**Actor:** ที่ปรึกษา (Consultant)  
**Preconditions:** ผู้ใช้งานยืนยันนัดหมายแล้ว (U3.1) และการให้คำปรึกษากับผู้ใช้งานเสร็จสิ้นแล้ว และที่ปรึกษาบันทึกรายงานและลงลายมือชื่อแล้ว (C2.1 และ C2.2)  

**Steps** (Actor / System):

**System:**

1-2. ที่ปรึกษาเปิดหน้ารายงานเช่นเดียวกับ C2.1 ขั้นตอนที่ 1 ถึง 2

**Actor:**

3. ที่ปรึกษาคลิก "File the report" โดยรายงานต้องเขียนหรือแนบไฟล์แล้ว และลงลายมือชื่อแล้ว

**System:**

4. ระบบตรวจสอบข้อมูลดังนี้
- มีรายงานที่เขียนหรือแนบไฟล์แล้ว
- สถานะการลงนามเป็น "Signed"
หากผ่านเงื่อนไข ระบบบันทึกการยื่นรายงานและแจ้งเจ้าหน้าที่ประเมิน ตาม QC2.7 หากไม่ผ่านเงื่อนไข (ไม่มีแถวที่ถูกบันทึก) ระบบแจ้งส่วนที่ยังขาด (Alternate Case 1 [Validation Failed])
```sql
-- QC2.7
UPDATE ConsultationReport
SET delivered_at = NOW()
WHERE report_id = :report_id
  AND consultant_id = :consultant_id
  AND report_content IS NOT NULL
  AND signed_at IS NOT NULL
  AND delivered_at IS NULL
RETURNING report_id;
```
