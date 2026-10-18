# Report back 4: O1 to O6 (officer console)

From: the Claude Code session that built O1 to O6 (2026-10-18).
To: the team and the instance that keeps the SA report and `docs/spec/`.

Working rule (from the answer to report back 2): when an item below is a business-process question, the
documentation agent asks the prompter directly with the question tool before it decides.

## Context

Since report back 3 (`REPORT-BACK-U4-U6.md`), the code takes in the U4 to U6 pack of 2026-10-17 and adds the
Evaluation Officer console: O1 View Injury Application, O2 Approve, O3 Reject, O4 Schedule Appointment, O5.1 Book
Treatment, O5.2 No Treatment Required and O6 View Consultation Report, on the server and in the console app. Commits
`b57609a` to `9b24350` on `develop`.

- The U4 to U6 pack settles R-026 to R-035, and the code follows it (D-041, D-042, D-045 to D-047).
- Every item has a reference to `docs/DECISIONS.md`: **R-xxx** is a report issue, **D-xxx** is the decision the code
  uses now. The code works around every item; no item blocks the app.
- Tests: 199 server tests and 104 Flutter tests pass. The server tests run each officer use case through the HTTP
  routes against PostgreSQL; the widget tests run each console page against a fake server. The console was not run
  in a browser for this report.
- Checked in full for this report: O1 to O6 (use cases, sequences, classes, states, queries QO1.1 to QO6.3 and QN.1
  to QN.4) and the Figma frames O1-1 to O6-3. C1 and C2 are not checked yet.
- Also fixed: `server/.gitignore` ignored `server/lib/storage/`, so `file_storage.dart` was not in git (D-049).

## Business-process questions (the team must answer; the code does not decide them)

| ID | Report section | Question | What the code does now |
|---|---|---|---|
| R-037 | 2.17 `EligibilityCheck.override_reason`; 2.13 O2, O3 | Must the officer give an override reason when the decision is not the automatic result? The data dictionary says yes; O2 and O3 say the field is optional. | Optional. O2 saves no reason when the field is empty; O3 saves the reason code (D-048). |
| R-042 | 2.13 O4 step 2.2; Figma O4-1 | What is "Add to waiting list"? No use case, table or query defines a waiting list. | The button is shown but disabled. |
| R-043 | 2.13 O4; 2.16 QO4.2 | Can an appointment be on Saturday or Sunday (QO4.2 offers them, QO5.2 does not)? Does the officer choose the type (`Onsite` or `Online`) and the location? | Weekends are offered; the type is `Onsite` at the consultant's office (D-051). |
| R-044 | 2.13 O5.1 step 2.1; 2.17 Treatment | Which treatment types, durations and facilities can the officer choose? Does a treatment of 90 or 120 minutes block the next hours? | Physiotherapy and Occupational therapy; 30, 45, 60, 90 and 120 minutes; SSO Rehabilitation Center. Only the start hour is blocked (D-052). |
| R-046 | 2.13 O6 step 2.1; 2.17 ConsultationReport | Can a consultation report be a file (O6 Alternate Case 1 [File], "Attached file" on O6-2)? | Text only: ConsultationReport has no file column. |

## High: the report is wrong or the process does not agree

| ID | Where | Problem | What the code does now | Please decide |
|---|---|---|---|---|
| R-043 | 2.16 QO4.3 | QO4.3 saves any date, hour, claim and consultant without a check, so two appointments can have the same hour and a past date can be saved. | `AppointmentModel.createAppointment` first checks: date after today (422), claim in QO4.1 (409), hour `free` in QO4.2 (409) (D-051). | Add the conditions to QO4.3, as QU4.2 has them since the U4 pack. |
| R-044 | 2.16 QO5.3 | QO5.3 also checks nothing: claim, report and hour. | `TreatmentModel.bookTreatment` first checks: the fields (422), the claim and report are a QO5.1 row (409), the hour is `free` in QO5.2 (409) (D-052). | Add the conditions to QO5.3. |
| R-037 | 2.17; 2.16 QO2.1 | QO2.1 saves `is_override = TRUE` with an empty `override_reason`, which the data dictionary does not allow (for example when the officer confirms a `Register unavailable` claim). | See the business question above. | Make the field necessary in O2 and O3 when the result changes, or change the data dictionary. |

## Medium: missing queries or data, frames that do not agree with the queries

| ID | Where | Problem | What the code does now | Please decide |
|---|---|---|---|---|
| R-036 | 2.13 O2 step 6.1; 2.16 QN.1 | O2 does not give the text of its QN.1 message. | Subject "Claim confirmed", body "Your claim <claim_no> is covered under Section 33." (the seed messages 901 and 906; D-048). | Write the text in O2. |
| R-044 | 2.13 O5.1 step 6.1; 2.16 QN.1 | O5.1 does not give the text of its QN.1 message either. | Subject "Treatment booked", body "<type> on <date> : <time>. Please accept or choose another date." (Figma U4-5; D-052). | Write the text in O5.1. |
| R-039 | Figma O1-2, O1-3; 2.16 QO1.4 | The frames show the document type ("Image of National ID Card") and the upload time; QO1.4 gives only `file_name`, `file_size` and `file_uri`. | The rows show the file name and the size. | Add `DocumentType` name and `uploaded_at` to QO1.4. |
| R-041 | Figma O4-1, O6-2; 2.17 Consultant | The frames show a specialty ("Orthopedics"); Consultant has no specialty column. | The consultant rows show the name and the office only. | Add a column, or remove the specialty from the frames. |
| R-045 | Figma O5.2-1; 2.16 QO5.1 | O5.2-1 shows "The report from <consultant> says no treatment is required", and the O5.2 card asks for the user's title. QO5.1 gives neither the report's recommendation nor the title. | The summary shows the report details only; the card uses the QO5.1 name. | Add the recommendation and `title_name` to QO5.1, or change the frame. |
| R-046 | Figma O6-2; 2.16 QO6.2 | O6-2 shows the page count of the report and "Viewed by <officer> on <time>"; `read_at` has no officer and QO6.2 gives only the status. | No page count; the view status says that an officer has opened the report. | Add the reader to the schema and QO6.2, or change the frame. |
| R-038 | 2.17 seed | The seed has no claim to verify (O1), and the seed documents (`/claims/143/...`) have no files. | The O1 demo needs a claim from U1 first (README). | Add a demo claim in `Awaiting verification`. |
| R-045 | 2.17 seed | The seed has no claim for the Treatment page (O5): claim 149 has the Pending treatment 403, and when U4.3 cancels it, the claim becomes `Withdrawn`. | The O5 demo needs a filed report from C2 first. | Add a demo claim with a filed report and no treatment. |

## Low: small conflicts

| ID | Where | Problem | What the code does now | Please decide |
|---|---|---|---|---|
| R-040 | Figma O1-1 and every console frame | The navigation shows the office branch of the officer ("Bangkok 3"), and the top bar has a bell and a help icon. The schema has no branch; no use case says what the icons do. | The branch and the icons are left out (D-050). | Remove them from the frames, or say what they do. |
| (D-050) | Figma O1-1; `ClaimStatusChip` | The console frames show `Register unavailable` in yellow; the user app chip, which the console uses too, is a different colour. | The shared chip keeps its colour. | Say which colour the chip has in both apps. |
| (D-053) | 2.16 QO6.2 | QO6.2 reads a report by ID without the `delivered_at IS NOT NULL` condition of QO6.1. | The Model gives only a report that QO6.1 lists (404 for a draft). | Add the condition to QO6.2. |

## Decisions the report can take over

| ID | Decision |
|---|---|
| D-048 | O1 to O3 run in one transaction each; a decided claim gives 409. O1 step 6 opens the stored file of a QO1.4 row. |
| D-050 | The console has a left navigation with Verification, Scheduling, Treatment and Consultation Reports and the number of rows of QO1.2 (awaiting verification), QO4.1, QO5.1 and QO6.1. The decision panel offers only Confirm and Not Covered (07 item 8). O2-3 and O3-3 show "By <officer> · <time>"; the server gives the time. |
| D-051 | O4: the appointment is `Onsite` at the consultant's office; the result card shows the time by which the user must confirm (24 hours before, as QO4.3 saves it). |
| D-052 | O5.1: "Available Times" shows the next 14 days from tomorrow; the end time in the summary is the start plus the duration. |
| D-053 | O6: "View" runs QO6.3 and then shows the report text; "View Consultant Report" on the Treatment page opens the report of the claim. |

## Questions for the team (short list)

1. R-037: must the officer give an override reason when the decision changes the automatic result?
2. R-042: what is the waiting list of O4, or can the button go?
3. R-043: weekend appointments, and does the officer choose `Onsite` or `Online`?
4. R-044: the lists of treatment types, durations and facilities, and do long treatments block more hours?
5. R-046: can a consultation report be a file?
6. R-043 and R-044: add the checks to QO4.3 and QO5.3?
7. R-036 and R-044: the texts of the QN.1 messages of O2 and O5.1.
8. R-039, R-041, R-045, R-046: change the frames or the queries (document type, specialty, recommendation, reader)?
9. R-038 and R-045: demo rows in the seed for O1 and O5?
