// GENERATED from docs/spec/database/queries.sql. Do not edit by hand.
// The test queries_match_report_test.dart makes sure that this text stays the same as the report.
// ignore_for_file: constant_identifier_names

/// SQL of [NotificationRepository]. Each constant has the name of its Query ID.
abstract final class NotificationSql {
  // Q2.1 [U2] ดูข้อความแจ้งเตือน (View Notify Message)
  static const q2_1 = r'''
SELECT COUNT(*) AS unread
FROM Notification
WHERE insured_id = :insured_id
  AND read_at IS NULL
''';

  // Q2.2 [U2] ดูข้อความแจ้งเตือน (View Notify Message)
  static const q2_2 = r'''
SELECT notification_id, claim_id, subject, body,
  TO_CHAR(sent_at, 'FMDD FMMonth YYYY" : "HH24:MI') AS sent_time,
  read_at IS NOT NULL AS is_read
FROM Notification
WHERE insured_id = :insured_id
ORDER BY sent_at DESC
''';

  // Q2.3 [U2] ดูข้อความแจ้งเตือน (View Notify Message)
  static const q2_3 = r'''
UPDATE Notification
SET read_at = NOW()
WHERE notification_id = :notification_id
  AND insured_id = :insured_id
  AND read_at IS NULL
''';

  // Q3.1 [U3.1] ยืนยันนัดหมาย (Confirm Appointment)
  static const q3_1 = r'''
SELECT COUNT(*) AS unread
FROM Notification
WHERE insured_id = :insured_id
  AND read_at IS NULL
''';

  // Q3.7 [U3.1, U3.2, U3.3] ยืนยันนัดหมาย (Confirm Appointment) / ยืนยันนัดหมาย (Request Another Date) / ยืนยันนัดหมาย (I cannot attend)
  static const q3_7 = r'''
UPDATE Notification
SET read_at = NOW()
WHERE notification_id = :notification_id
  AND insured_id = :insured_id
  AND read_at IS NULL
''';

  // QN.1 [O2, O5.1] อนุมัติคำร้อง (Approve Injury Application) / นัดหมายการรักษา (Book Treatment)
  static const qN_1 = r'''
INSERT INTO Notification
  (claim_id, insured_id, subject, body, sent_at)
SELECT claim_id, insured_id, :subject, :body, NOW()
FROM InjuryClaim
WHERE claim_id = :claim_id
''';

  // QN.2 [O3] ปฏิเสธคำร้อง (Reject Injury Application)
  static const qN_2 = r'''
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
  AND cr.is_superseded = FALSE
''';

  // QN.3 [O4] สร้างนัดหมาย (Schedule Appointment)
  static const qN_3 = r'''
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
FROM appt
''';

  // QN.4 [O5.2] นัดหมายการรักษา (No Treatment Required)
  static const qN_4 = r'''
INSERT INTO Notification
  (claim_id, insured_id, subject, body, sent_at)
SELECT claim_id, insured_id, 'No treatment required',
  CONCAT('The consultation report for your claim ', claim_no,
  ' says no treatment is required, so your claim is now closed.'),
  NOW()
FROM InjuryClaim
WHERE claim_id = :claim_id
  AND claim_status = 'No treatment required'
''';

  /// Every Query ID of this class, for the test that compares the SQL with the report.
  static const all = <String, List<String>>{
    'Q2.1': [q2_1],
    'Q2.2': [q2_2],
    'Q2.3': [q2_3],
    'Q3.1': [q3_1],
    'Q3.7': [q3_7],
    'QN.1': [qN_1],
    'QN.2': [qN_2],
    'QN.3': [qN_3],
    'QN.4': [qN_4],
  };
}
