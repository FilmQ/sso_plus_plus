# Data dictionary (SA report section 2.17)

Every table of the system with its attributes, keys, NOT NULL flag, type and the range / validation rule (Thai, as in the report). `schema.sql` is generated from this; `seed.sql` holds the report's five sample rows per table.

## InsuredPerson

| Attribute | Description | Key | Not Null | Type | Range / validation |
|---|---|---|---|---|---|
| insured_id | รหัสผู้ประกันตน | PK | Y | INT | เลขลำดับที่ระบบสร้าง ค่ามากกว่า 0 |
| national_id | เลขประจำตัวประชาชน 13 หลัก | UK | Y | CHAR(13) | ตัวเลข 13 หลัก ห้ามซ้ำ (Q1.2) |
| title_name | คำนำหน้าชื่อ |  | Y | VARCHAR(20) | นาย, นาง หรือ นางสาว |
| first_name | ชื่อ |  | Y | VARCHAR(80) | ตัวอักษร 1 ถึง 80 ตัว |
| last_name | นามสกุล |  | Y | VARCHAR(80) | ตัวอักษร 1 ถึง 80 ตัว |
| date_of_birth | วันเกิด |  | Y | DATE | ก่อนวันที่ลงทะเบียน และอายุไม่ต่ำกว่า 15 ปี |
| gender | เพศ |  | Y | CHAR(1) | M, F หรือ O (อื่น ๆ) |
| phone_no | เบอร์โทรศัพท์ |  | Y | VARCHAR(20) | ตัวเลข 9 ถึง 10 หลัก ขึ้นต้นด้วย 0 |
| email | อีเมล |  | N | VARCHAR(120) | รูปแบบ name@domain |
| address | ที่อยู่ |  | Y | VARCHAR(255) | ไม่เกิน 255 ตัวอักษร |
| created_at | วันและเวลาที่ลงทะเบียน |  | Y | TIMESTAMP | ระบบใส่ NOW() เมื่อเพิ่มข้อมูล (Q1.3) |

## Employer

| Attribute | Description | Key | Not Null | Type | Range / validation |
|---|---|---|---|---|---|
| employer_id | รหัสนายจ้าง | PK | Y | INT | เลขลำดับที่ระบบสร้าง ค่ามากกว่า 0 |
| sso_account_no | เลขที่บัญชีนายจ้างของสำนักงานประกันสังคม | UK | Y | VARCHAR(20) | ตัวเลข 10 หลัก ห้ามซ้ำ |
| employer_name | ชื่อนายจ้าง |  | Y | VARCHAR(160) | ไม่เกิน 160 ตัวอักษร ปรับตามทะเบียนเมื่อซ้ำ (Q1.4) |
| branch_name | ชื่อสาขา |  | N | VARCHAR(80) | ไม่เกิน 80 ตัวอักษร |
| phone_no | เบอร์โทรศัพท์ |  | N | VARCHAR(20) | ตัวเลข 9 ถึง 10 หลัก ขึ้นต้นด้วย 0 |
| address | ที่อยู่ |  | N | VARCHAR(255) | ไม่เกิน 255 ตัวอักษร |

## Section33Coverage

| Attribute | Description | Key | Not Null | Type | Range / validation |
|---|---|---|---|---|---|
| coverage_id | รหัสความคุ้มครอง | PK | Y | INT | เลขลำดับที่ระบบสร้าง ค่ามากกว่า 0 |
| insured_id | รหัสผู้ประกันตน | FK | Y | INT | ต้องมีใน InsuredPerson.insured_id |
| employer_id | รหัสนายจ้าง | FK | Y | INT | ต้องมีใน Employer.employer_id |
| registration_date | วันที่ขึ้นทะเบียน |  | Y | DATE | ไม่เกินวันปัจจุบัน |
| contribution_start | วันที่เริ่มส่งเงินสมทบ |  | Y | DATE | ไม่ก่อน registration_date |
| contribution_end | วันที่สิ้นสุดการส่งเงินสมทบ |  | N | DATE | ไม่ก่อน contribution_start ค่าว่างคือยังส่งอยู่ |
| contribution_months | จำนวนเดือนที่ส่งเงินสมทบ |  | Y | INT | 0 ขึ้นไป |
| coverage_status | สถานะความคุ้มครอง |  | Y | VARCHAR(20) | ACTIVE หรือ INACTIVE |

## EvaluationOfficer

| Attribute | Description | Key | Not Null | Type | Range / validation |
|---|---|---|---|---|---|
| officer_id | รหัสเจ้าหน้าที่ประเมิน | PK | Y | INT | เลขลำดับที่ระบบสร้าง ค่ามากกว่า 0 |
| employee_no | รหัสพนักงาน | UK | Y | VARCHAR(20) | รูปแบบ EO- ตามด้วยตัวเลข 5 หลัก ห้ามซ้ำ |
| first_name | ชื่อ |  | Y | VARCHAR(80) | ตัวอักษร 1 ถึง 80 ตัว |
| last_name | นามสกุล |  | Y | VARCHAR(80) | ตัวอักษร 1 ถึง 80 ตัว |
| phone_no | เบอร์โทรศัพท์ |  | Y | VARCHAR(20) | ตัวเลข 9 ถึง 10 หลัก ขึ้นต้นด้วย 0 |
| email | อีเมล |  | Y | VARCHAR(120) | รูปแบบ name@domain |

## Consultant

| Attribute | Description | Key | Not Null | Type | Range / validation |
|---|---|---|---|---|---|
| consultant_id | รหัสที่ปรึกษา | PK | Y | INT | เลขลำดับที่ระบบสร้าง ค่ามากกว่า 0 |
| license_no | เลขที่ใบอนุญาต | UK | Y | VARCHAR(30) | รูปแบบ ว. ตามด้วยตัวเลข ห้ามซ้ำ |
| title_name | คำนำหน้าชื่อ |  | Y | VARCHAR(20) | เช่น นพ. หรือ พญ. |
| first_name | ชื่อ |  | Y | VARCHAR(80) | ตัวอักษร 1 ถึง 80 ตัว |
| last_name | นามสกุล |  | Y | VARCHAR(80) | ตัวอักษร 1 ถึง 80 ตัว |
| office_location | สถานที่ทำงาน |  | Y | VARCHAR(80) | อาคาร ชั้น และห้อง |
| phone_no | เบอร์โทรศัพท์ |  | N | VARCHAR(20) | ตัวเลข 9 ถึง 10 หลัก ขึ้นต้นด้วย 0 |
| email | อีเมล |  | N | VARCHAR(120) | รูปแบบ name@domain |

## InjuryClaim

| Attribute | Description | Key | Not Null | Type | Range / validation |
|---|---|---|---|---|---|
| claim_id | รหัสคำร้อง | PK | Y | INT | เลขลำดับที่ระบบสร้าง ค่ามากกว่า 0 |
| claim_no | เลขที่คำร้อง | UK | N | VARCHAR(20) | รูปแบบ SST-ปปปป-เลข 6 หลัก ระบบสร้างหลังเพิ่มคำร้อง (Q1.7) |
| insured_id | รหัสผู้ประกันตน | FK | Y | INT | ต้องมีใน InsuredPerson.insured_id |
| employer_id | รหัสนายจ้าง | FK | N | INT | ต้องมีใน Employer.employer_id |
| injury_datetime | วันและเวลาที่ประสบอันตราย |  | Y | TIMESTAMP | ไม่เกินวันและเวลาที่ยื่นคำร้อง |
| injury_place | สถานที่ประสบอันตราย |  | Y | VARCHAR(255) | ไม่เกิน 255 ตัวอักษร |
| injury_cause | สาเหตุการบาดเจ็บ |  | Y | VARCHAR(255) | ไม่เกิน 255 ตัวอักษร |
| body_part | อวัยวะที่บาดเจ็บ |  | Y | VARCHAR(80) | ไม่เกิน 80 ตัวอักษร |
| injury_category | ประเภทการบาดเจ็บ |  | Y | VARCHAR(60) | เช่น Fracture, Burn, Sprain |
| claim_status | สถานะคำร้อง |  | Y | VARCHAR(30) | Awaiting verification, Register unavailable, Covered, Not covered, Rejected หรือ No treatment required |
| submitted_at | วันและเวลาที่ยื่นคำร้อง |  | Y | TIMESTAMP | ระบบใส่ NOW() (Q1.6) |
| created_at | วันและเวลาที่สร้างข้อมูล |  | Y | TIMESTAMP | ระบบใส่ NOW() (Q1.6) |

## DocumentType

| Attribute | Description | Key | Not Null | Type | Range / validation |
|---|---|---|---|---|---|
| doc_type_id | รหัสประเภทเอกสาร | PK | Y | INT | เลขลำดับที่ระบบสร้าง ค่ามากกว่า 0 |
| form_code | รหัสแบบฟอร์ม | UK | Y | VARCHAR(20) | ตัวอักษรภาษาอังกฤษและตัวเลข ห้ามซ้ำ |
| name_th | ชื่อเอกสารภาษาไทย |  | Y | VARCHAR(160) | ไม่เกิน 160 ตัวอักษร |
| name_en | ชื่อเอกสารภาษาอังกฤษ |  | Y | VARCHAR(160) | ไม่เกิน 160 ตัวอักษร |
| is_required | เป็นเอกสารที่ต้องแนบหรือไม่ |  | Y | BOOLEAN | TRUE หรือ FALSE |

## ClaimDocument

| Attribute | Description | Key | Not Null | Type | Range / validation |
|---|---|---|---|---|---|
| document_id | รหัสเอกสาร | PK | Y | INT | เลขลำดับที่ระบบสร้าง ค่ามากกว่า 0 |
| claim_id | รหัสคำร้อง | FK | Y | INT | ต้องมีใน InjuryClaim.claim_id |
| doc_type_id | รหัสประเภทเอกสาร | FK | Y | INT | ต้องมีใน DocumentType.doc_type_id |
| file_name | ชื่อไฟล์ |  | Y | VARCHAR(255) | นามสกุล .jpg, .png หรือ .pdf |
| file_uri | ตำแหน่งที่เก็บไฟล์ |  | Y | VARCHAR(500) | Path ที่ระบบสร้างเมื่ออัปโหลด |
| mime_type | ชนิดไฟล์ |  | Y | VARCHAR(60) | image/jpeg, image/png หรือ application/pdf |
| file_size_bytes | ขนาดไฟล์ (ไบต์) |  | Y | INT | 1 ถึง 10,485,760 (10 MB) |
| uploaded_at | วันและเวลาที่อัปโหลด |  | Y | TIMESTAMP | ระบบใส่ NOW() (Q1.8) |
| check_status | สถานะการตรวจเอกสาร |  | Y | VARCHAR(20) | Pending, Accepted หรือ Rejected เริ่มต้น Pending |
| checked_at | วันและเวลาที่ตรวจเอกสาร |  | N | TIMESTAMP | ไม่ก่อน uploaded_at |
| remark | หมายเหตุ |  | N | VARCHAR(255) | ไม่เกิน 255 ตัวอักษร |

## EligibilityCheck

| Attribute | Description | Key | Not Null | Type | Range / validation |
|---|---|---|---|---|---|
| check_id | รหัสการตรวจสอบ | PK | Y | INT | เลขลำดับที่ระบบสร้าง ค่ามากกว่า 0 |
| claim_id | รหัสคำร้อง | FK | Y | INT | ต้องมีใน InjuryClaim.claim_id |
| coverage_id | รหัสความคุ้มครอง | FK | N | INT | ต้องมีใน Section33Coverage.coverage_id ค่าว่างเมื่อทะเบียนไม่พร้อมใช้งาน |
| officer_id | รหัสเจ้าหน้าที่ประเมิน | FK | N | INT | ต้องมีใน EvaluationOfficer.officer_id ค่าว่างคือผลอัตโนมัติ |
| checked_at | วันและเวลาที่ตรวจสอบ |  | Y | TIMESTAMP | ระบบใส่ NOW() (Q1.9, QO2.1, QO3.1) |
| result | ผลการตรวจสอบ |  | Y | VARCHAR(20) | Covered, Not covered, Needs review หรือ Register unavailable |
| is_override | เจ้าหน้าที่ประเมินแก้ไขผลอัตโนมัติหรือไม่ |  | Y | BOOLEAN | TRUE เมื่อผลต่างจากผลอัตโนมัติ |
| override_reason | เหตุผลการแก้ไขผล |  | N | VARCHAR(255) | ต้องมีเมื่อ is_override เป็น TRUE |
| evidence_ref | อ้างอิงหลักฐานจากทะเบียน |  | N | VARCHAR(120) | ไม่เกิน 120 ตัวอักษร |

## RejectionReason

| Attribute | Description | Key | Not Null | Type | Range / validation |
|---|---|---|---|---|---|
| reason_code | รหัสเหตุผล | PK | Y | VARCHAR(10) | รูปแบบ R ตามด้วยตัวเลข 2 หลัก |
| name_th | ชื่อเหตุผลภาษาไทย |  | Y | VARCHAR(160) | ไม่เกิน 160 ตัวอักษร |
| description | คำอธิบายเหตุผล |  | Y | VARCHAR(255) | ไม่เกิน 255 ตัวอักษร ส่งถึงผู้ใช้งาน (QN.2) |
| is_automatic | เป็นเหตุผลที่ระบบใช้อัตโนมัติหรือไม่ |  | Y | BOOLEAN | TRUE หรือ FALSE |

## ClaimRejection

| Attribute | Description | Key | Not Null | Type | Range / validation |
|---|---|---|---|---|---|
| rejection_id | รหัสการปฏิเสธ | PK | Y | INT | เลขลำดับที่ระบบสร้าง ค่ามากกว่า 0 |
| claim_id | รหัสคำร้อง | FK | Y | INT | ต้องมีใน InjuryClaim.claim_id |
| reason_code | รหัสเหตุผล | FK | Y | VARCHAR(10) | ต้องมีใน RejectionReason.reason_code |
| officer_id | รหัสเจ้าหน้าที่ประเมิน | FK | Y | INT | ต้องมีใน EvaluationOfficer.officer_id |
| officer_message | ข้อความจากเจ้าหน้าที่ประเมินถึงผู้ใช้งาน |  | N | TEXT | ไม่เกิน 1,000 ตัวอักษร |
| rejection_timestamp | วันและเวลาที่ปฏิเสธ |  | Y | TIMESTAMP | ระบบใส่ NOW() (QO3.2) |
| appeal_deadline | วันสุดท้ายของการอุทธรณ์ |  | N | DATE | หลัง rejection_timestamp |
| is_superseded | ถูกแทนที่ด้วยคำวินิจฉัยใหม่หรือไม่ |  | Y | BOOLEAN | TRUE หรือ FALSE เริ่มต้น FALSE |

## Appointment

| Attribute | Description | Key | Not Null | Type | Range / validation |
|---|---|---|---|---|---|
| appointment_id | รหัสนัดหมาย | PK | Y | INT | เลขลำดับที่ระบบสร้าง ค่ามากกว่า 0 |
| claim_id | รหัสคำร้อง | FK | Y | INT | ต้องมีใน InjuryClaim.claim_id ที่สถานะ Covered (QO4.1) |
| officer_id | รหัสเจ้าหน้าที่ประเมินผู้สร้างนัดหมาย | FK | Y | INT | ต้องมีใน EvaluationOfficer.officer_id |
| consultant_id | รหัสที่ปรึกษา | FK | Y | INT | ต้องมีใน Consultant.consultant_id |
| supersedes_appt_id | รหัสนัดหมายเดิมที่ถูกแทนที่ | FK | N | INT | ต้องมีใน Appointment.appointment_id |
| appointment_type | ประเภทนัดหมาย |  | Y | VARCHAR(20) | Onsite หรือ Online |
| schedule_date | วันนัดหมาย |  | Y | DATE | หลังวันปัจจุบัน |
| schedule_time | เวลานัดหมาย |  | Y | TIME | 09:00 ถึง 16:00 ทุก 1 ชั่วโมง |
| location | สถานที่นัดหมาย |  | Y | VARCHAR(160) | ไม่เกิน 160 ตัวอักษร |
| appointment_status | สถานะนัดหมาย |  | Y | VARCHAR(30) | Pending, Confirmed, Rescheduled หรือ Cancelled |
| confirm_deadline | กำหนดเวลายืนยันนัดหมาย |  | N | TIMESTAMP | 24 ชั่วโมงก่อนเวลานัดหมาย (QO4.3) |
| created_at | วันและเวลาที่สร้างนัดหมาย |  | Y | TIMESTAMP | ระบบใส่ NOW() (QO4.3, Q3.5) |

## AppointmentConfirmation

| Attribute | Description | Key | Not Null | Type | Range / validation |
|---|---|---|---|---|---|
| confirmation_id | รหัสการยืนยัน | PK | Y | INT | เลขลำดับที่ระบบสร้าง ค่ามากกว่า 0 |
| appointment_id | รหัสนัดหมาย | FK | Y | INT | ต้องมีใน Appointment.appointment_id |
| call_attempt_id | รหัสการโทรติดตาม | FK | N | INT | ต้องมีใน PhoneCallAttempt.attempt_id ต้องมีเมื่อ channel เป็น phone |
| channel | ช่องทางที่ใช้ตอบ |  | Y | VARCHAR(20) | application หรือ phone |
| outcome | ผลการตอบ |  | Y | VARCHAR(30) | Confirmed, Requested another date หรือ Cannot attend |
| recorded_at | วันและเวลาที่บันทึก |  | Y | TIMESTAMP | ระบบใส่ NOW() (Q3.3, Q3.5, Q3.6) |
| remark | หมายเหตุ |  | N | VARCHAR(255) | ไม่เกิน 255 ตัวอักษร |

## PhoneCallAttempt

| Attribute | Description | Key | Not Null | Type | Range / validation |
|---|---|---|---|---|---|
| attempt_id | รหัสการโทร | PK | Y | INT | เลขลำดับที่ระบบสร้าง ค่ามากกว่า 0 |
| appointment_id | รหัสนัดหมาย | FK | Y | INT | ต้องมีใน Appointment.appointment_id |
| officer_id | รหัสเจ้าหน้าที่ประเมิน | FK | Y | INT | ต้องมีใน EvaluationOfficer.officer_id |
| attempt_no | ครั้งที่โทร |  | Y | INT | 1 ขึ้นไป เรียงตามนัดหมาย |
| called_at | วันและเวลาที่โทร |  | Y | TIMESTAMP | ไม่เกินวันและเวลาปัจจุบัน |
| phone_no | เบอร์โทรศัพท์ที่โทร |  | Y | VARCHAR(20) | ตัวเลข 9 ถึง 10 หลัก ขึ้นต้นด้วย 0 |
| call_outcome | ผลการโทร |  | Y | VARCHAR(20) | Answered, No answer, Busy หรือ Wrong number |
| remark | หมายเหตุ |  | N | VARCHAR(255) | ไม่เกิน 255 ตัวอักษร |

## ConsultationSession

| Attribute | Description | Key | Not Null | Type | Range / validation |
|---|---|---|---|---|---|
| session_id | รหัสการให้คำปรึกษา | PK | Y | INT | เลขลำดับที่ระบบสร้าง ค่ามากกว่า 0 |
| appointment_id | รหัสนัดหมาย | FK | Y | INT | ต้องมีใน Appointment.appointment_id นัดหมายละ 1 แถว (QC2.2) |
| consultant_id | รหัสที่ปรึกษา | FK | Y | INT | ต้องมีใน Consultant.consultant_id |
| officer_id | รหัสเจ้าหน้าที่ประเมิน | FK | Y | INT | ต้องมีใน EvaluationOfficer.officer_id |
| started_at | วันและเวลาเริ่ม |  | Y | TIMESTAMP | เท่ากับวันและเวลานัดหมาย (QC2.2) |
| ended_at | วันและเวลาสิ้นสุด |  | N | TIMESTAMP | หลัง started_at |
| attendance | การเข้าร่วมของผู้ใช้งาน |  | Y | VARCHAR(20) | Attended หรือ No show |
| findings | สิ่งที่ตรวจพบ |  | N | TEXT | ไม่เกิน 2,000 ตัวอักษร |
| diagnosis | การวินิจฉัย |  | N | VARCHAR(255) | ไม่เกิน 255 ตัวอักษร |
| recommended_treatment | การรักษาที่แนะนำ |  | N | TEXT | ไม่เกิน 2,000 ตัวอักษร |
| session_status | สถานะการให้คำปรึกษา |  | Y | VARCHAR(20) | Completed หรือ Cancelled |

## ConsultationReport

| Attribute | Description | Key | Not Null | Type | Range / validation |
|---|---|---|---|---|---|
| report_id | รหัสรายงาน | PK | Y | INT | เลขลำดับที่ระบบสร้าง ค่ามากกว่า 0 |
| session_id | รหัสการให้คำปรึกษา | FK | Y | INT | ต้องมีใน ConsultationSession.session_id |
| consultant_id | รหัสที่ปรึกษา | FK | Y | INT | ต้องมีใน Consultant.consultant_id และเป็นผู้แก้ไขรายงานได้ |
| version_no | หมายเลขฉบับ |  | Y | INT | 1 ขึ้นไป |
| report_content | เนื้อหารายงาน |  | N | TEXT | ต้องมีก่อนลงลายมือชื่อ (QC2.6) |
| signed_at | วันและเวลาที่ลงลายมือชื่อ |  | N | TIMESTAMP | ค่าว่างคือยังไม่ลงลายมือชื่อ |
| delivered_at | วันและเวลาที่ยื่นรายงาน |  | N | TIMESTAMP | ยื่นได้เมื่อ signed_at ไม่ว่าง (QC2.7) |
| read_at | วันและเวลาที่เจ้าหน้าที่ประเมินเปิดดู |  | N | TIMESTAMP | หลัง delivered_at |
| is_superseded | ถูกแทนที่ด้วยฉบับใหม่หรือไม่ |  | Y | BOOLEAN | TRUE หรือ FALSE เริ่มต้น FALSE |

## Treatment

| Attribute | Description | Key | Not Null | Type | Range / validation |
|---|---|---|---|---|---|
| treatment_id | รหัสการรักษา | PK | Y | INT | เลขลำดับที่ระบบสร้าง ค่ามากกว่า 0 |
| claim_id | รหัสคำร้อง | FK | Y | INT | ต้องมีใน InjuryClaim.claim_id |
| report_id | รหัสรายงาน | FK | Y | INT | ต้องมีใน ConsultationReport.report_id ที่ยื่นแล้ว (QO5.1) |
| officer_id | รหัสเจ้าหน้าที่ประเมินผู้จอง | FK | Y | INT | ต้องมีใน EvaluationOfficer.officer_id |
| treatment_type | ประเภทการรักษา |  | Y | VARCHAR(80) | เช่น Physiotherapy, Occupational therapy |
| facility_name | ชื่อสถานพยาบาล |  | Y | VARCHAR(160) | ไม่เกิน 160 ตัวอักษร |
| scheduled_date | วันรักษา |  | Y | DATE | หลังวันปัจจุบันเมื่อจอง |
| scheduled_time | เวลารักษา |  | Y | TIME | 09:00 ถึง 16:00 (QO5.2) |
| treatment_status | สถานะการรักษา |  | Y | VARCHAR(30) | Pending, Accepted หรือ Cancelled |
| created_at | วันและเวลาที่จอง |  | Y | TIMESTAMP | ระบบใส่ NOW() (QO5.3) |

## Notification

| Attribute | Description | Key | Not Null | Type | Range / validation |
|---|---|---|---|---|---|
| notification_id | รหัสข้อความแจ้งเตือน | PK | Y | INT | เลขลำดับที่ระบบสร้าง ค่ามากกว่า 0 |
| claim_id | รหัสคำร้อง | FK | Y | INT | ต้องมีใน InjuryClaim.claim_id |
| insured_id | รหัสผู้ประกันตนผู้รับ | FK | N | INT | ต้องมีใน InsuredPerson.insured_id ต้องมีค่าอย่างน้อยหนึ่งช่องระหว่าง insured_id กับ consultant_id |
| consultant_id | รหัสที่ปรึกษาผู้รับ | FK | N | INT | ต้องมีใน Consultant.consultant_id (QN.3) |
| subject | หัวเรื่อง |  | Y | VARCHAR(160) | ไม่เกิน 160 ตัวอักษร |
| body | เนื้อหาข้อความ |  | Y | TEXT | ไม่เกิน 2,000 ตัวอักษร |
| sent_at | วันและเวลาที่ส่ง |  | Y | TIMESTAMP | ระบบใส่ NOW() |
| read_at | วันและเวลาที่อ่าน |  | N | TIMESTAMP | หลัง sent_at ค่าว่างคือยังไม่อ่าน (Q2.3, Q3.7) |

## ClaimStatusHistory

| Attribute | Description | Key | Not Null | Type | Range / validation |
|---|---|---|---|---|---|
| history_id | รหัสประวัติ | PK | Y | INT | เลขลำดับที่ระบบสร้าง ค่ามากกว่า 0 |
| claim_id | รหัสคำร้อง | FK | Y | INT | ต้องมีใน InjuryClaim.claim_id |
| officer_id | รหัสเจ้าหน้าที่ประเมิน | FK | N | INT | ต้องมีใน EvaluationOfficer.officer_id ค่าว่างคือระบบ |
| from_status | สถานะเดิม |  | N | VARCHAR(30) | ค่าเดียวกับ InjuryClaim.claim_status ค่าว่างในแถวแรกของคำร้อง |
| to_status | สถานะใหม่ |  | Y | VARCHAR(30) | ค่าเดียวกับ InjuryClaim.claim_status |
| changed_at | วันและเวลาที่เปลี่ยน |  | Y | TIMESTAMP | ระบบใส่ NOW() |
| change_reason | เหตุผลการเปลี่ยน |  | N | VARCHAR(255) | ไม่เกิน 255 ตัวอักษร |
