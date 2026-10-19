# Report back 5: C1 and C2 (consultant console)

From: the Claude Code session that built C1 and C2 (2026-10-18 and 2026-10-19).
To: the team and the instance that keeps the SA report and `docs/spec/`.

Working rule (from the answer to report back 2): when an item below is a business-process question, the
documentation agent asks the prompter directly with the question tool before it decides.

## Context

Since report back 4 (`REPORT-BACK-O1-O6.md`), the code takes in the O1 to O6 pack of 2026-10-18 and adds the
Consultant console: C1 View Appointment Schedule and C2.1 to C2.3 Create Consultation Report, on the server and in
the console app. Commits `7eb675a` to `07440fb` on `develop`.

- The O1 to O6 pack settles R-036 to R-046, and the code follows it (D-048, D-050 to D-056).
- Every item has a reference to `docs/DECISIONS.md`: **R-xxx** is a report issue, **D-xxx** is the decision the code
  uses now. The code works around every item; no item blocks the app. R-050 is a fault that a user can see.
- Tests: 210 server tests and 113 Flutter tests pass (the counts of the last commits). The server tests run each
  consultant use case through the HTTP routes against PostgreSQL; the widget tests run each console page against a
  fake server. The console was not run in a browser for this report.
- Checked in full for this report: C1 and C2.1 to C2.3 (use cases, sequences, the class CreateReportPage, the
  ConsultationReport states, queries QC1.1 to QC2.7), the Figma frames C1-1 to C2.3-2, `07-open-questions.md` item 5
  and the seed rows of the consultants.

## Business-process questions (the team must answer; the code does not decide them)

| ID | Report section | Question | What the code does now |
|---|---|---|---|
| R-048 | 2.13 C2.2; 2.18 CreateReportPage (`signature: Image`, `confirmSignature(signature)`); 07 item 5 | Must the system keep the drawn signature, and must O6 show it? QC2.6 saves only `signed_at`, and ConsultationReport has no column for the drawing. | The drawing shows on the page during the visit only. After a reload, the page shows "Signed on <date>" (D-059). |
| R-049 | 2.13 C2.3 step 4 ("แจ้งเจ้าหน้าที่ประเมิน") | How is the Evaluation Officer told about a filed report? QC2.7 sends no message, and `Notification` has no officer recipient. | The officer sees the report in the O6 list (QO6.1). The page shows the frame text "Filed · officer notified" (D-059). |
| R-051 | 2.13 C2.1 (QC2.1, QC2.2); 2.17 ConsultationSession | What does the consultant do when the user does not come to a Confirmed appointment? QC2.2 always writes `attendance = 'Attended'` and `session_status = 'Completed'`. | The appointment stays in the C2 list until the consultant files a report. There is no "did not attend" path. |
| R-052 | 2.13 U3.1 to U3.3 (QN.5); 2.20 consultant site map | Where does the consultant read the QN.5 messages (the user confirmed, changed or cancelled)? No consultant use case, query or frame reads `Notification.consultant_id`. | The server saves the QN.5 messages. The console does not show them. |

## High: the report is wrong or the process does not agree

| ID | Where | Problem | What the code does now | Please decide |
|---|---|---|---|---|
| R-050 | 2.13 C2.1; 2.16 QC2.2, QO5.1; Figma O5.2-1 | No step of C2 writes `ConsultationSession.recommended_treatment` (or `findings` and `diagnosis`). QC2.2 makes the session without them. QO5.1 reads `recommended_treatment`, so for a report from C2 the value is NULL. | **Fault:** the O5 Booking Summary takes NULL as "None" and shows "Recommended treatment in the report from <consultant>: None. No treatment is required for this claim." This is not true for a C2 report. Only the seed reports have a value. | Add a "Recommended treatment" field to C2.1 (QC2.4 and QC2.5 also write the session), or let QO5.1 and the frame O5.2-1 do without it. |
| R-047 | 2.17 seed; `server/db/seeds/001_user_accounts.sql` | Only consultant 1 (`thana.s@ssorehab.go.th`) has an account, and the seed has no rows for C1 or C2 for consultant 1: appointments 503 and 504 are in the past, and their reports 86 and 87 are filed. The U3 demo appointment 510 is for consultant 2, who has no account. | The Schedule Page and the report list are empty with the seed. The README gives an SQL block that adds two Confirmed appointments for consultant 1 (one future, one past) for a demo. | Add these two rows to the dev block of the seed, or move appointment 510 to consultant 1. |

## Medium: missing keys, conditions that do not agree

| ID | Where | Problem | What the code does now | Please decide |
|---|---|---|---|---|
| R-053 | 2.17 ConsultationSession, ConsultationReport; 2.16 QC2.2, QC2.4 | No UNIQUE key stops a second session for one appointment or a second current report for one session. QC2.2 checks with NOT EXISTS, which two requests at the same time can both pass, and QC2.4 has no check. Then QC2.3 gives two rows. | `ReportModel` reads the page (QC2.3) and then runs QC2.4 only when there is no report. There is no lock. | Add `UNIQUE (appointment_id)` to ConsultationSession and a unique index on ConsultationReport `(session_id) WHERE is_superseded = FALSE`, or a NOT EXISTS condition in QC2.4. |
| R-048 | 07-open-questions item 5 | Item 5 still says that the attachment and the signature have no column. R-046 settled the attachment (`report_file_uri`); only the signature is open. | See R-048 above. | Change item 5. |

## Low: small conflicts

| ID | Where | Problem | What the code does now | Please decide |
|---|---|---|---|---|
| R-054 | 2.19 ConsultationReport states (Draft to Signed) | The condition is `report_content IS NOT NULL`, but QC2.6 also signs a report that has only a file (`report_file_uri`). | The code follows QC2.6. | Write "report_content or report_file_uri IS NOT NULL" in the state table. |
| R-055 | 2.13 C2.1 step 2.2; 2.17 `version_no`, `is_superseded` | The header shows the version, but no use case makes version 2 or sets `is_superseded = TRUE`. QC2.5 changes the same row. | The header always shows "version 1". | Say that a report has one version, or add the use case. |
| (D-057) | 2.13 sequence C2.1 step 30 | The page sends `report_file_uri` to `saveDraft`, but the page has a file, not an address. The sequence has no upload step. | The page sends the file as multipart; the server keeps it as `/reports/<session_id>/<file name>` and saves that address. | Add the upload to the sequence, or take over D-057. |

## Decisions the report can take over

| ID | Decision |
|---|---|
| D-057 | C1 and C2 routes are for consultants only. QC2.2 makes a session for any appointment, so the Model opens only an appointment that QC2.1 lists for the signed-in consultant (else 404). A draft is text or one file (PDF, JPG or PNG, 10 MB or less, the U1 rules). Sign without a draft gives 422, a second sign 409. When QC2.7 gives no row, the answer says what is missing (`fields.report`, `fields.signature`), or 409 when the report is already filed. |
| D-058 | One console for both roles. After sign-in, an officer goes to Verification and a consultant to the Schedule Page; each role opens only its own pages. The consultant navigation shows the number of QC1.1 and QC2.1 rows. |
| D-059 | One report page at "Create Consultation Report": the first waiting consultation opens automatically. A chosen file replaces the text. The C2.3-1 banner says what is missing. |

## Questions for the team (short list)

1. R-050: must C2.1 have a "Recommended treatment" field, so that O5 can show it? (Until then, O5 shows a wrong "None".)
2. R-048: must the drawn signature be kept, and must O6 show it?
3. R-049: is the O6 list enough to tell the officer about a filed report, or does the officer get a message?
4. R-051: what happens when the user does not come to a Confirmed appointment?
5. R-052: where does the consultant read the QN.5 messages?
6. R-047: demo rows for consultant 1 in the seed (C1 and C2)?
7. R-053: add UNIQUE keys for ConsultationSession and the current ConsultationReport?
8. R-054, R-055: the state condition and the version number.
