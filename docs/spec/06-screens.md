# Screens (SA report sections 2.21 and 2.22, Figma "SSO Plus Plus")

- User app (phone, 390 x 844 frames): Figma page `03 · Use-case screens · User app`, https://www.figma.com/design/yGZrD3LH6RRn8MVXo1LAwv/SSO-Plus-Plus?node-id=125-2
- Evaluation Officer and Consultant console (desktop, 1440 x 900 frames): Figma page `04 · Use-case screens · Officer & Consultant console`, https://www.figma.com/design/yGZrD3LH6RRn8MVXo1LAwv/SSO-Plus-Plus?node-id=125-3
- Each Figma frame is named `<screen code> · <screen name>` (for example `U1-2 · Fill in Injury Forms Page`), 23 on the user app page and 29 on the console page, and has a label above it naming the use case step and the SQL it shows. Both pages also hold infrastructure frames that are not use case screens: `L-1 · Login Page` and `P-1 · Profile Page` on the user app page, `L-2 · Console Login Page` on the console page (see the last table).
- Older September draft pages (0:1 phone M1 to M9, 6:2 console D1 to D8) are superseded; use pages 125:2 and 125:3.
- Site map: `diagrams/sitemap-user.png`, `diagrams/sitemap-officer.png`, `diagrams/sitemap-consultant.png`. Login is the root; solid boxes are pages, dashed boxes are pop-ups, confirmation cards and result messages.
- Sample data used on the screens: claim SST-2026-000143, นาย สมชาย ประเสริฐ, officer กัญญา วงศ์ศิริ, consultant นพ. ธนา ศรีสุข.
- Screen rules from the U3 decisions (2026-10-15):
  - U3-2 to U3-7: type `Onsite (at the rehabilitation center)` or `Online`; the consultant line shows the title,
    name and `Office: <Consultant.office_location as stored>` (for example `Office: Building A, Floor 3, Room 305`).
    O4-1 to O4-3 and U5-1 show stored locations the same way.
  - A `Confirmed` appointment (U3-3 behind the dialog, U3-5) keeps "Request Another Date" and "I cannot attend";
    "Confirm Appointment" shows only while `Pending`.
  - U3-4: Cancel can be pressed at any time; the free times are 09:00, 10:00, 11:00, 13:00, 14:00, 15:00.
  - U3-6: "If you cancel, your claim will be withdrawn and the consultant will be informed."
  - O4-1 to O4-3: each consultant row shows the same six hours (no 12:00 or 16:00).

| Code | Screen (use case: page or state) | User | Report figure |
|---|---|---|---|
| U1-1 | ยื่นคำร้องกรณีประสบอันตราย (Submit Injury Application): Register Page | ผู้ใช้งาน | 2-9 |
| U1-2 | ยื่นคำร้องกรณีประสบอันตราย (Submit Injury Application): Fill in Injury Forms Page | ผู้ใช้งาน | 2-10 |
| U1-3 | ยื่นคำร้องกรณีประสบอันตราย (Submit Injury Application): Validation failed | ผู้ใช้งาน | 2-11 |
| U1-4 | ยื่นคำร้องกรณีประสบอันตราย (Submit Injury Application): National ID already registered | ผู้ใช้งาน | 2-12 |
| U1-5 | ยื่นคำร้องกรณีประสบอันตราย (Submit Injury Application): Injury forms submitted | ผู้ใช้งาน | 2-13 |
| U2-1 | ดูข้อความแจ้งเตือน (View Notify Message): Home page (unread message) | ผู้ใช้งาน | 2-17 |
| U2-2 | ดูข้อความแจ้งเตือน (View Notify Message): Notification pop-up | ผู้ใช้งาน | 2-18 |
| U2-3 | ดูข้อความแจ้งเตือน (View Notify Message): Message opened (marked as read) | ผู้ใช้งาน | 2-19 |
| U2-4 | ดูข้อความแจ้งเตือน (View Notify Message): Rejection message | ผู้ใช้งาน | 2-20 |
| U3-1 | ยืนยันนัดหมาย (Confirm Appointment): Notification Page (red dot) | ผู้ใช้งาน | 2-23 |
| U3-2 | ยืนยันนัดหมาย (Confirm Appointment): Appointment Page | ผู้ใช้งาน | 2-24 |
| U3-3 | ยืนยันนัดหมาย (Confirm Appointment): Confirm Appointment reminder | ผู้ใช้งาน | 2-25 |
| U3-4 | ยืนยันนัดหมาย (Request Another Date): Request Another Date pop-up | ผู้ใช้งาน | 2-29 |
| U3-5 | ยืนยันนัดหมาย (Request Another Date): Date changed | ผู้ใช้งาน | 2-30 |
| U3-6 | ยืนยันนัดหมาย (I cannot attend): I cannot attend warning | ผู้ใช้งาน | 2-34 |
| U3-7 | ยืนยันนัดหมาย (I cannot attend): Appointment cancelled | ผู้ใช้งาน | 2-35 |
| U4-1 | ยืนยันการรักษา (Accept Case): Confirm Treatment page | ผู้ใช้งาน | 2-38 |
| U4-2 | ยืนยันการรักษา (Accept Case): Treatment accepted | ผู้ใช้งาน | 2-39 |
| U4-3 | ยืนยันการรักษา (Change Date): Available dates window | ผู้ใช้งาน | 2-42 |
| U4-4 | ยืนยันการรักษา (Change Date): New treatment date saved | ผู้ใช้งาน | 2-43 |
| U4-5 | ยืนยันการรักษา (Reject): Treatment cancelled message | ผู้ใช้งาน (ระบบทำอัตโนมัติ) | 2-46 |
| U5-1 | ดูตารางนัดหมาย (View Appointment Schedule): Schedule Page · Appointments | ผู้ใช้งาน | 2-49 |
| U6-1 | ดูตารางการรักษา (View Treatment Schedule): Schedule Page · Treatments | ผู้ใช้งาน | 2-52 |
| O1-1 | ดูคำร้องกรณีประสบอันตราย (View Injury Application): Verification Page | เจ้าหน้าที่ประเมิน | 2-55 |
| O1-2 | ดูคำร้องกรณีประสบอันตราย (View Injury Application): Eligibility Decision Page | เจ้าหน้าที่ประเมิน | 2-56 |
| O1-3 | ดูคำร้องกรณีประสบอันตราย (View Injury Application): Document opened (View) | เจ้าหน้าที่ประเมิน | 2-57 |
| O2-1 | อนุมัติคำร้อง (Approve Injury Application): Confirm selected | เจ้าหน้าที่ประเมิน | 2-61 |
| O2-2 | อนุมัติคำร้อง (Approve Injury Application): Confirmation card | เจ้าหน้าที่ประเมิน | 2-62 |
| O2-3 | อนุมัติคำร้อง (Approve Injury Application): Result saved | เจ้าหน้าที่ประเมิน | 2-63 |
| O3-1 | ปฏิเสธคำร้อง (Reject Injury Application): Not Covered and rejection reason | เจ้าหน้าที่ประเมิน | 2-67 |
| O3-2 | ปฏิเสธคำร้อง (Reject Injury Application): Confirmation card | เจ้าหน้าที่ประเมิน | 2-68 |
| O3-3 | ปฏิเสธคำร้อง (Reject Injury Application): Claim rejected | เจ้าหน้าที่ประเมิน | 2-69 |
| O4-1 | สร้างนัดหมาย (Schedule Appointment): Scheduling page | เจ้าหน้าที่ประเมิน | 2-73 |
| O4-2 | สร้างนัดหมาย (Schedule Appointment): Confirmation card | เจ้าหน้าที่ประเมิน | 2-74 |
| O4-3 | สร้างนัดหมาย (Schedule Appointment): Appointment Scheduled | เจ้าหน้าที่ประเมิน | 2-75 |
| O5.1-1 | นัดหมายการรักษา (Book Treatment): Treatment page | เจ้าหน้าที่ประเมิน | 2-79 |
| O5.1-2 | นัดหมายการรักษา (Book Treatment): Confirmation card | เจ้าหน้าที่ประเมิน | 2-80 |
| O5.1-3 | นัดหมายการรักษา (Book Treatment): Treatment Booked | เจ้าหน้าที่ประเมิน | 2-81 |
| O5.2-1 | นัดหมายการรักษา (No Treatment Required): No treatment require confirmation | เจ้าหน้าที่ประเมิน | 2-85 |
| O5.2-2 | นัดหมายการรักษา (No Treatment Required): No Treatment Required | เจ้าหน้าที่ประเมิน | 2-86 |
| O6-1 | ดูรายงานการให้คำปรึกษา (View Consultation Report): Consultation Reports list | เจ้าหน้าที่ประเมิน | 2-90 |
| O6-2 | ดูรายงานการให้คำปรึกษา (View Consultation Report): Consultation Report Page | เจ้าหน้าที่ประเมิน | 2-91 |
| O6-3 | ดูรายงานการให้คำปรึกษา (View Consultation Report): Report opened (View) | เจ้าหน้าที่ประเมิน | 2-92 |
| C1-1 | ดูตารางนัดหมาย (View Appointment Schedule): Schedule Page | ที่ปรึกษา | 2-95 |
| C2.1-1 | สร้างรายงานการให้คำปรึกษา (Amend the Draft): Report page | ที่ปรึกษา | 2-100 |
| C2.1-2 | สร้างรายงานการให้คำปรึกษา (Amend the Draft): Amend the draft | ที่ปรึกษา | 2-101 |
| C2.1-3 | สร้างรายงานการให้คำปรึกษา (Amend the Draft): Attach: file explorer | ที่ปรึกษา | 2-102 |
| C2.1-4 | สร้างรายงานการให้คำปรึกษา (Amend the Draft): Draft finished, File Attached | ที่ปรึกษา | 2-103 |
| C2.2-1 | สร้างรายงานการให้คำปรึกษา (Sign the Signature): Sign the signature | ที่ปรึกษา | 2-107 |
| C2.2-2 | สร้างรายงานการให้คำปรึกษา (Sign the Signature): Signed | ที่ปรึกษา | 2-108 |
| C2.3-1 | สร้างรายงานการให้คำปรึกษา (File the Report): File the report [Validation failed] | ที่ปรึกษา | 2-112 |
| C2.3-2 | สร้างรายงานการให้คำปรึกษา (File the Report): Report filed [Validation passed] | ที่ปรึกษา | 2-113 |

## Infrastructure screens (not use cases)

Login and sign-out are platform infrastructure (report 2.20 and 2.21): no use case, no report query, not counted in the 52 screens and no figure in 2.13. Accounts live outside the 19 report tables (`UserAccount`, decision D-003).

| Code | Screen | User | Figma |
|---|---|---|---|
| L-1 | Login Page: national ID and password, "New here? Register" opens U1-1 | ผู้ใช้งาน | page 125:2, frame `L-1 · Login Page` (node 146:8) |
| P-1 | Profile Page: the Profile tab of the navigation bar; name, national ID, phone, address and Sign out | ผู้ใช้งาน | page 125:2, frame `P-1 · Profile Page` (node 146:50) |
| L-2 | Console Login Page: staff e-mail and password; the role decides which console opens. Sign out is the icon beside the user in the navigation rail | เจ้าหน้าที่ประเมิน, ที่ปรึกษา | page 125:3, frame `L-2 · Console Login Page` (node 146:125) |

## Output design (SA report section 2.23)

ระบบมีรายงาน 2 รายงาน ได้แก่ รายงานการให้คำปรึกษา ซึ่งที่ปรึกษาสร้างและเจ้าหน้าที่ประเมินใช้นัดหมายการรักษา และรายงานคำร้องที่รอตรวจสอบสิทธิ์ ซึ่งเจ้าหน้าที่ประเมินใช้ติดตามคำร้องที่ยังไม่ได้ตัดสิน แต่ละรายงานแสดงโครงสร้าง แหล่งข้อมูล Use Case ที่บันทึกข้อมูล และตัวอย่างรายงาน

2.23.1 รายงานการให้คำปรึกษา (Consultation Report)

ที่ปรึกษาบันทึกรายงานผ่าน Use Case C2.1 ถึง C2.3 และเจ้าหน้าที่ประเมินเปิดดูผ่าน Use Case O6 ซึ่งดึงข้อมูลด้วยคำสั่ง QO6.2 โครงสร้างรายงานแสดงในตารางที่ 2-66 และตัวอย่างรายงานของคำร้อง SST-2026-000143 แสดงในตารางที่ 2-67

*ตารางที่ 2-66 แสดงโครงสร้างรายงานการให้คำปรึกษา*

| ส่วนของรายงาน | ข้อมูล | แหล่งข้อมูล | บันทึกโดย Use Case |
|---|---|---|---|
| หัวรายงาน | เลขที่คำร้อง | InjuryClaim.claim_no | U1 (Q1.7) |
| หัวรายงาน | ชื่อผู้ใช้งาน และอายุ | InsuredPerson.first_name, last_name, date_of_birth | U1 (Q1.3) |
| หัวรายงาน | วันและเวลาที่ให้คำปรึกษา | ConsultationSession.started_at | C2.1 (QC2.2) |
| หัวรายงาน | ชื่อที่ปรึกษา | Consultant.title_name, first_name, last_name | ข้อมูลหลัก |
| เนื้อหา | ผลการให้คำปรึกษาและการรักษาที่แนะนำ | ConsultationReport.report_content | C2.1 (QC2.4, QC2.5) |
| ท้ายรายงาน | ฉบับที่ | ConsultationReport.version_no | C2.1 (QC2.4) |
| ท้ายรายงาน | สถานะและวันที่ลงลายมือชื่อ | ConsultationReport.signed_at | C2.2 (QC2.6) |
| ท้ายรายงาน | วันที่ยื่นรายงาน | ConsultationReport.delivered_at | C2.3 (QC2.7) |
| ท้ายรายงาน | สถานะการเปิดดู | ConsultationReport.read_at | O6 (QO6.3) |

*ตารางที่ 2-67 แสดงตัวอย่างรายงานการให้คำปรึกษา*

| รายงานการให้คำปรึกษา (Consultation Report) |  |
|---|---|
| เลขที่คำร้อง | SST-2026-000143 |
| ชื่อผู้ใช้งาน | สมชาย ประเสริฐ (อายุ 41 ปี) |
| วันและเวลาที่ให้คำปรึกษา | 16 October 2026 : 10:00 |
| ที่ปรึกษา | นพ. ธนา ศรีสุข |
| ผลการให้คำปรึกษา | Closed fracture of the distal radius, right wrist. Physiotherapy twice a week for 6 weeks. |
| ฉบับที่ | 1 |
| ลายมือชื่อ | Signature signed (16 October 2026) |
| วันที่ยื่นรายงาน | 16 October 2026 |
| สถานะการเปิดดู | Pending |

2.23.2 รายงานคำร้องที่รอตรวจสอบสิทธิ์ (Verification Report)

ระบบสร้างรายงานจากคำร้องที่ผู้ใช้งานยื่นผ่าน Use Case U1 และแสดงให้เจ้าหน้าที่ประเมินในหน้า Verification ของ Use Case O1 ซึ่งดึงข้อมูลด้วยคำสั่ง QO1.1 และ QO1.2 คำร้องจะออกจากรายงานเมื่อเจ้าหน้าที่ประเมินอนุมัติ (O2) หรือปฏิเสธ (O3) โครงสร้างรายงานแสดงในตารางที่ 2-68 และตัวอย่างรายงานแสดงในตารางที่ 2-69

*ตารางที่ 2-68 แสดงโครงสร้างรายงานคำร้องที่รอตรวจสอบสิทธิ์*

| ส่วนของรายงาน | ข้อมูล | แหล่งข้อมูล | บันทึกโดย Use Case |
|---|---|---|---|
| ส่วนสรุป | จำนวนคำร้องที่รอตรวจสอบ (Awaiting verification) | COUNT ของ InjuryClaim.claim_status | U1 (Q1.6) |
| ส่วนสรุป | จำนวนคำร้องที่ต้องทบทวน (Needs review) | COUNT ของ InjuryClaim.claim_status | U1 (Q1.6) |
| ส่วนสรุป | จำนวนคำร้องที่ทะเบียนไม่พร้อมใช้งาน (Register unavailable) | COUNT ของ InjuryClaim.claim_status | U1 (Q1.6) |
| รายการ | เลขที่คำร้อง | InjuryClaim.claim_no | U1 (Q1.7) |
| รายการ | ชื่อผู้ยื่นคำร้อง | InsuredPerson.title_name, first_name, last_name | U1 (Q1.3) |
| รายการ | การบาดเจ็บและวันที่ประสบอันตราย | InjuryClaim.injury_category, body_part, injury_datetime | U1 (Q1.6) |
| รายการ | วันที่ยื่นคำร้อง | InjuryClaim.submitted_at | U1 (Q1.6) |
| รายการ | จำนวนเอกสารที่แนบ | COUNT ของ ClaimDocument | U1 (Q1.8) |
| รายการ | สถานะการตรวจสอบ | InjuryClaim.claim_status | U1, O2, O3 |

*ตารางที่ 2-69 แสดงตัวอย่างรายงานคำร้องที่รอตรวจสอบสิทธิ์*

| รายงานคำร้องที่รอตรวจสอบสิทธิ์ (Verification Report) |  |  |  |  |  |
|---|---|---|---|---|---|
| ข้อมูล ณ วันที่ 4 October 2026 : 17:00   รอตรวจสอบ 1 รายการ   ต้องทบทวน 0 รายการ   ทะเบียนไม่พร้อมใช้งาน 2 รายการ |  |  |  |  |  |
| เลขที่คำร้อง | ชื่อผู้ยื่นคำร้อง | การบาดเจ็บ | วันที่ยื่น | เอกสาร | สถานะ |
| SST-2026-000143 | นาย สมชาย ประเสริฐ | Fracture, right wrist (28 September 2026) | 2 October 2026 | 3 | Awaiting verification |
| SST-2026-000151 | นางสาว วิภา ใจงาม | Sprain, left ankle (1 October 2026) | 3 October 2026 | 2 | Register unavailable |
| SST-2026-000152 | นาย อนุชา บุญมา | Cut, right forearm (2 October 2026) | 4 October 2026 | 2 | Register unavailable |
