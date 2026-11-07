/// Thai for fixed text from the server. The stored value stays English, and
/// logic compares the English value. The key is the exact English text.
const Map<String, String> thServer = <String, String>{
  // Status values (05-states.md).
  'Awaiting verification': 'รอการตรวจสอบ',
  'Register unavailable': 'ตรวจสอบทะเบียนไม่ได้',
  'Covered': 'ได้รับความคุ้มครอง',
  'Not covered': 'ไม่ได้รับความคุ้มครอง',
  'Rejected': 'ถูกปฏิเสธ',
  'No treatment required': 'ไม่ต้องรับการรักษา',
  'Withdrawn': 'ถอนคำร้องแล้ว',
  'Pending': 'รอดำเนินการ',
  'Confirmed': 'ยืนยันแล้ว',
  'Rescheduled': 'เปลี่ยนวันนัดแล้ว',
  'Cancelled': 'ยกเลิกแล้ว',
  'No show': 'ไม่มาตามนัด',
  'Accepted': 'ยอมรับแล้ว',

  // Fixed values of the schema and the seed.
  'Onsite': 'ที่ศูนย์ฟื้นฟูผู้ป่วย',
  'Physiotherapy': 'กายภาพบำบัด',
  'Occupational therapy': 'กิจกรรมบำบัด',
  'None': 'ไม่มี',
  'SSO Rehabilitation Center': 'ศูนย์ฟื้นฟูผู้ป่วย สำนักงานประกันสังคม',
  'Image of National ID Card': 'สำเนาบัตรประจำตัวประชาชน',
  'Medical Record File': 'ไฟล์เวชระเบียน',
  'Injury Form File': 'ไฟล์แบบแจ้งการประสบอันตราย',
  'Bank Book Copy': 'สำเนาหน้าสมุดบัญชีธนาคาร',
  'Injury Photo': 'ภาพถ่ายบาดแผลหรือสถานที่เกิดเหตุ',
  'Fracture': 'กระดูกหัก',
  'Sprain': 'ข้อเคล็ด',
  'Burn': 'แผลไหม้',
  'Cut': 'บาดแผล',
  'Crush injury': 'บาดเจ็บจากการถูกกดทับ',
  'Back strain': 'กล้ามเนื้อหลังบาดเจ็บ',
  'Laceration': 'แผลฉีกขาด',
  'Contusion': 'ฟกช้ำ',
  'Other': 'อื่น ๆ',

  // Notification subjects (QN.1 to QN.5, QU4.3).
  'Claim confirmed': 'ยืนยันคำร้องแล้ว',
  'Application rejected': 'คำร้องถูกปฏิเสธ',
  'Appointment scheduled': 'สร้างนัดหมายแล้ว',
  'New appointment': 'นัดหมายใหม่',
  'Appointment confirmed': 'ยืนยันนัดหมายแล้ว',
  'Appointment rescheduled': 'เปลี่ยนวันนัดหมายแล้ว',
  'Appointment cancelled': 'ยกเลิกนัดหมายแล้ว',
  'Treatment booked': 'นัดหมายการรักษาแล้ว',
  'Treatment cancelled': 'ยกเลิกการรักษาแล้ว',

  // Field errors of U1 (server FieldRules, frame U1-3).
  'Fill in this field': 'กรุณากรอกช่องนี้',
  'Use Thai characters only, as on your national ID card': 'ใช้ตัวอักษรภาษาไทยเท่านั้น ตามบัตรประจำตัวประชาชน',
  'National ID must be exactly 13 digits': 'เลขประจำตัวประชาชนต้องมี 13 หลัก',
  'No ACTIVE Section 33 coverage was found for this national ID': 'ไม่พบความคุ้มครองมาตรา 33 ที่มีผลอยู่ของเลขประจำตัวประชาชนนี้',
  'This national ID is already registered': 'เลขประจำตัวประชาชนนี้ลงทะเบียนแล้ว',
  'Enter a valid phone number, for example 081 234 5678': 'กรอกหมายเลขโทรศัพท์ให้ถูกต้อง เช่น 081 234 5678',
  'At least 8 characters, English letters and numbers only': 'อย่างน้อย 8 ตัวอักษร ใช้ตัวอักษรภาษาอังกฤษและตัวเลขเท่านั้น',
  'Passwords do not match': 'รหัสผ่านไม่ตรงกัน',
  'Choose one of the provided titles: นาย, นาง, นางสาว': 'เลือกคำนำหน้าชื่อ: นาย, นาง, นางสาว',
  'Choose Male, Female or Others': 'เลือก ชาย หญิง หรืออื่น ๆ',
  'Enter a correct birth date. You must be 15 years old or older': 'กรอกวันเกิดให้ถูกต้อง คุณต้องมีอายุ 15 ปีขึ้นไป',
  'Enter the date and time of the injury. It cannot be in the future': 'กรอกวันและเวลาที่ประสบอันตราย ต้องไม่เป็นเวลาในอนาคต',
  'This text is too long': 'ข้อความนี้ยาวเกินไป',
  'Attach this file': 'กรุณาแนบไฟล์นี้',
  'Use a PDF, JPG or PNG file of 10 MB or less': 'ใช้ไฟล์ PDF, JPG หรือ PNG ขนาดไม่เกิน 10 MB',

  // Field errors of the other use cases.
  'Choose a rejection reason.': 'กรุณาเลือกเหตุผลการปฏิเสธ',
  'Give a reason, because your decision differs from the automatic result.': 'กรุณาระบุเหตุผล เพราะการตัดสินของคุณต่างจากผลอัตโนมัติ',
  'Type the report or attach a file, not both.': 'พิมพ์รายงานหรือแนบไฟล์ อย่างใดอย่างหนึ่ง',
  'Attach a PDF, JPG or PNG file.': 'กรุณาแนบไฟล์ PDF, JPG หรือ PNG',
  'The file must be 10 MB or smaller.': 'ไฟล์ต้องมีขนาดไม่เกิน 10 MB',
  'Choose Physiotherapy, Occupational therapy or None.': 'เลือก กายภาพบำบัด กิจกรรมบำบัด หรือไม่มี',
  'Type the report or attach a file.': 'กรุณาพิมพ์รายงานหรือแนบไฟล์',
  'Draw the signature.': 'กรุณาวาดลายเซ็น',
  'The signature must be a PNG image of 1 MB or smaller.': 'ลายเซ็นต้องเป็นรูปภาพ PNG ขนาดไม่เกิน 1 MB',
  'Finish the draft first: type the report or attach a file.': 'กรุณาทำร่างให้เสร็จก่อน: พิมพ์รายงานหรือแนบไฟล์',
  'Choose the recommended treatment.': 'กรุณาเลือกการรักษาที่แนะนำ',
  'Sign the report.': 'กรุณาลงนามในรายงาน',
  'Choose one of the available dates.': 'กรุณาเลือกวันที่ว่าง',
  'Choose a treatment type.': 'กรุณาเลือกประเภทการรักษา',
  'Choose a duration.': 'กรุณาเลือกระยะเวลา',
  'Choose a facility.': 'กรุณาเลือกสถานที่รักษา',
  'Choose one of the free times.': 'กรุณาเลือกเวลาที่ว่าง',
  'Choose a date after today.': 'กรุณาเลือกวันหลังจากวันนี้',
  'Choose a weekday (Monday to Friday).': 'กรุณาเลือกวันธรรมดา (จันทร์ถึงศุกร์)',

  // Errors from the server and from the API gate of the app.
  'The login name or the password is not correct.': 'ชื่อเข้าสู่ระบบหรือรหัสผ่านไม่ถูกต้อง',
  'Sign in to continue.': 'กรุณาเข้าสู่ระบบเพื่อดำเนินการต่อ',
  'The request failed. Try again later.': 'คำขอไม่สำเร็จ กรุณาลองอีกครั้งภายหลัง',
  'The data changed. Open the page again.': 'ข้อมูลมีการเปลี่ยนแปลง กรุณาเปิดหน้านี้อีกครั้ง',
  'There is no claim with this ID.': 'ไม่พบคำร้องนี้',
  'The file is not available.': 'ไม่พบไฟล์',
  'The message was not found.': 'ไม่พบข้อความ',
  'There is no filed report with this ID.': 'ไม่พบรายงานที่ยื่นแล้ว',
  'The report file is not available.': 'ไม่พบไฟล์รายงาน',
  'The report has no signature image.': 'รายงานนี้ไม่มีรูปลายเซ็น',
  'There is no consultation to report with this ID.': 'ไม่พบการปรึกษาที่ต้องทำรายงาน',
  'The draft has no file.': 'ร่างนี้ไม่มีไฟล์',
  'The report has no signature.': 'รายงานนี้ไม่มีลายเซ็น',
  'There is no open appointment for this claim.': 'คำร้องนี้ไม่มีนัดหมายที่เปิดอยู่',
  'There is no treatment with this ID.': 'ไม่พบการรักษานี้',
  'The claim cannot be closed. Open the page again.': 'ปิดคำร้องไม่ได้ กรุณาเปิดหน้านี้อีกครั้ง',
  'The claim cannot be booked. Open the page again.': 'จองการรักษาของคำร้องนี้ไม่ได้ กรุณาเปิดหน้านี้อีกครั้ง',
  'The claim cannot be scheduled. Open the page again.': 'สร้างนัดหมายของคำร้องนี้ไม่ได้ กรุณาเปิดหน้านี้อีกครั้ง',
  'This time is not free any more. Choose another time.': 'เวลานี้ไม่ว่างแล้ว กรุณาเลือกเวลาอื่น',
  'The claim is already decided.': 'คำร้องนี้ตัดสินแล้ว',
  'The report is filed and cannot change.': 'รายงานนี้ยื่นแล้ว จึงแก้ไขไม่ได้',
  'The report is already signed.': 'รายงานนี้ลงนามแล้ว',
  'The report is already filed.': 'รายงานนี้ยื่นแล้ว',
  'The consultation has a report. Use the report instead.': 'การปรึกษานี้มีรายงานแล้ว กรุณาใช้รายงานนั้น',
  'Cannot connect to the server. Make sure that it runs.': 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ กรุณาตรวจสอบว่าเซิร์ฟเวอร์ทำงานอยู่',
};

/// Thai for full texts that the server makes from values. The app matches the
/// English template with the text and takes the values from it.
const Map<String, String> thServerTemplates = <String, String>{
  // Generated message bodies.
  'Your claim {claim} is covered under Section 33.': 'คำร้อง {claim} ของคุณได้รับความคุ้มครองตามมาตรา 33',
  'Your appointment with {consultant} is on {time} at {location}. Please confirm it in the application by {by}.':
      'คุณมีนัดหมายกับ {consultant} วันที่ {time} ที่ {location} กรุณายืนยันในแอปพลิเคชันภายใน {by}',
  'Your appointment with {consultant} is on {time} ...': 'คุณมีนัดหมายกับ {consultant} วันที่ {time} ...',
  '{user} (claim {claim}) is booked with you on {time} at {location}. Waiting for the patient to confirm.':
      '{user} (คำร้อง {claim}) มีนัดหมายกับคุณวันที่ {time} ที่ {location} กำลังรอผู้ป่วยยืนยัน',
  '{user} (claim {claim}) is booked with you on {time} ...': '{user} (คำร้อง {claim}) มีนัดหมายกับคุณวันที่ {time} ...',
  'The consultation report for your claim {claim} says no treatment is required, so your claim is now closed.':
      'รายงานการปรึกษาของคำร้อง {claim} ระบุว่าไม่ต้องรับการรักษา คำร้องของคุณจึงปิดแล้ว',
  '{user} (claim {claim}) cannot attend the appointment on {time}. The appointment is cancelled and the claim is withdrawn.':
      '{user} (คำร้อง {claim}) ไม่สามารถเข้าร่วมนัดหมายวันที่ {time} นัดหมายจึงถูกยกเลิกและคำร้องถูกถอน',
  '{user} (claim {claim}) moved the appointment to {time} at {location}.':
      '{user} (คำร้อง {claim}) เปลี่ยนนัดหมายเป็นวันที่ {time} ที่ {location}',
  '{user} (claim {claim}) confirmed the appointment on {time} at {location}.':
      '{user} (คำร้อง {claim}) ยืนยันนัดหมายวันที่ {time} ที่ {location}',
  '{type} on {time}. Please accept or choose another date.': '{type} วันที่ {time} กรุณายอมรับหรือเลือกวันอื่น',
  'Your treatment at {facility} on {date} was cancelled because it was not accepted in time. Your claim {claim} is now closed.':
      'การรักษาที่ {facility} วันที่ {date} ถูกยกเลิก เพราะไม่ได้ยอมรับภายในกำหนด คำร้อง {claim} ของคุณจึงปิดแล้ว',
  'Your treatment at {facility} on {date} was cancelled because it was not accepted in time.':
      'การรักษาที่ {facility} วันที่ {date} ถูกยกเลิก เพราะไม่ได้ยอมรับภายในกำหนด',

  // The Consultant.office_location and Appointment.location values of the seed.
  'Building {building}, Floor {floor}, Room {room}': 'อาคาร {building} ชั้น {floor} ห้อง {room}',

  // The QO1.5 contribution_period of a coverage that has not ended.
  '{from} - present': '{from} - ปัจจุบัน',

  // The injury text of the queries: the fixed category, then the typed body part.
  'Fracture, {part}': 'กระดูกหัก, {part}',
  'Sprain, {part}': 'ข้อเคล็ด, {part}',
  'Burn, {part}': 'แผลไหม้, {part}',
  'Cut, {part}': 'บาดแผล, {part}',
  'Crush injury, {part}': 'บาดเจ็บจากการถูกกดทับ, {part}',
  'Back strain, {part}': 'กล้ามเนื้อหลังบาดเจ็บ, {part}',
  'Laceration, {part}': 'แผลฉีกขาด, {part}',
  'Contusion, {part}': 'ฟกช้ำ, {part}',
  'Other, {part}': 'อื่น ๆ, {part}',

  // Errors.
  'Use {max} characters or fewer.': 'ใช้ไม่เกิน {max} ตัวอักษร',
  'The request is not correct: {detail}': 'คำขอไม่ถูกต้อง: {detail}',
  'Error {code}': 'ข้อผิดพลาด {code}',
};
