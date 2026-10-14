// GENERATED from docs/spec/database/queries.sql. Do not edit by hand.
// The test queries_match_report_test.dart makes sure that this text stays the same as the report.
// ignore_for_file: constant_identifier_names

/// SQL of [ReportRepository]. Each constant has the name of its Query ID.
abstract final class ReportSql {
  // QO6.1 [O6] ดูรายงานการให้คำปรึกษา (View Consultation Report)
  static const qO6_1 = r'''
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
ORDER BY cr.read_at IS NOT NULL, cr.delivered_at DESC
''';

  // QO6.2 [O6] ดูรายงานการให้คำปรึกษา (View Consultation Report)
  static const qO6_2 = r'''
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
WHERE cr.report_id = :report_id
''';

  // QO6.3 [O6] ดูรายงานการให้คำปรึกษา (View Consultation Report)
  static const qO6_3 = r'''
UPDATE ConsultationReport
SET read_at = NOW()
WHERE report_id = :report_id
  AND read_at IS NULL
''';

  // QC2.1 [C2.1] สร้างรายงานการให้คำปรึกษา (Amend the Draft)
  static const qC2_1 = r'''
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
ORDER BY a.schedule_date, a.schedule_time
''';

  // QC2.2 [C2.1] สร้างรายงานการให้คำปรึกษา (Amend the Draft)
  static const qC2_2 = r'''
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
        WHERE cs.appointment_id = a.appointment_id)
''';

  // QC2.3 [C2.1] สร้างรายงานการให้คำปรึกษา (Amend the Draft)
  static const qC2_3 = r'''
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
WHERE cs.appointment_id = :appointment_id
''';

  // QC2.4 [C2.1] สร้างรายงานการให้คำปรึกษา (Amend the Draft)
  static const qC2_4 = r'''
INSERT INTO ConsultationReport
  (session_id, consultant_id, version_no, report_content,
   is_superseded)
VALUES (:session_id, :consultant_id, 1, :report_content, FALSE)
RETURNING report_id
''';

  // QC2.5 [C2.1] สร้างรายงานการให้คำปรึกษา (Amend the Draft)
  static const qC2_5 = r'''
UPDATE ConsultationReport
SET report_content = :report_content,
    signed_at = NULL
WHERE report_id = :report_id
  AND consultant_id = :consultant_id
  AND delivered_at IS NULL
''';

  // QC2.6 [C2.2] สร้างรายงานการให้คำปรึกษา (Sign the Signature)
  static const qC2_6 = r'''
UPDATE ConsultationReport
SET signed_at = NOW()
WHERE report_id = :report_id
  AND consultant_id = :consultant_id
  AND report_content IS NOT NULL
  AND signed_at IS NULL
''';

  // QC2.7 [C2.3] สร้างรายงานการให้คำปรึกษา (File the Report)
  static const qC2_7 = r'''
UPDATE ConsultationReport
SET delivered_at = NOW()
WHERE report_id = :report_id
  AND consultant_id = :consultant_id
  AND report_content IS NOT NULL
  AND signed_at IS NOT NULL
  AND delivered_at IS NULL
RETURNING report_id
''';

  /// Every Query ID of this class, for the test that compares the SQL with the report.
  static const all = <String, List<String>>{
    'QO6.1': [qO6_1],
    'QO6.2': [qO6_2],
    'QO6.3': [qO6_3],
    'QC2.1': [qC2_1],
    'QC2.2': [qC2_2],
    'QC2.3': [qC2_3],
    'QC2.4': [qC2_4],
    'QC2.5': [qC2_5],
    'QC2.6': [qC2_6],
    'QC2.7': [qC2_7],
  };
}
