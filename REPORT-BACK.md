# Report back: problems found in the spec pack

From: the Claude Code session that built steps 1 to 5 of `docs/CLAUDE_CODE_BRIEF.md` (2026-10-14).
To: the team and the instance that keeps the SA report and `docs/spec/`.

## Context

The session built the scaffold, all 56 queries, login, U1 and U2 (commits `422037e` to `198458e` on `develop`).
While building, the session found places where the report, `docs/spec/`, the data dictionary, the seed and the
Figma frames do not agree, or do not give enough information. This file lists them.

- Every item has a reference to `docs/DECISIONS.md`: **R-xxx** is a report issue, **D-xxx** is the decision that
  the code uses now.
- The code works around every item. No item blocks the app now. But the report and the code are now different in
  these places, and the report is graded together with the code.
- For each item, the column "Please decide" tells what the report (or Figma) must change, or what the team must
  confirm.
- Only the spec parts for U1 and U2, the 56 queries, the schema and the seed were checked in full. The use case
  descriptions U3 to C2 and the console Figma page (`125:3`) were not checked against the code yet.

## High: the report is wrong or does not have enough data

| ID | Where | Problem | What the code does now | Please decide |
|---|---|---|---|---|
| R-003 | 2.13 U1 step 3; Figma U1-2 (`125:40`) | The U1 form has no injury fields. Q1.6 inserts `injury_datetime`, `injury_place`, `injury_cause`, `body_part` and `injury_category`, and all five are NOT NULL in `InjuryClaim`. So U1 cannot run as written. | The form has an extra section "Injury details" (date and time, place, cause, body part, category list) between "General information" and "Upload files". | Add the five fields to the U1 description (step 3), to frame U1-2 and to the field rules of step 4. |
| R-004 | 2.16 Q1.1, Q1.4, Q1.5 | Q1.1 reads only `national_id, title_name, first_name, last_name` from `master_table`. Q1.4 needs `:employer_account_no, :employer_name`, and Q1.5 needs `:registration_date, :contribution_start, :contribution_end, :contribution_months`. No query reads them. | An extra query `findRegisterDetail` reads them (`server/lib/repository/sql/infrastructure_sql.dart`). | Add the six columns to the SELECT list of Q1.1. Then the extra query can go. |
| R-011 | Figma U2-2 (`126:79`); 2.13 U1 | The pop-up of U2-2 shows the message "Injury forms received · Claim SST-2026-000143 is waiting for verification" (2 October 2026 : 14:32). No step of U1 writes a `Notification` row, and the seed has no such row. | Nothing. After U1, the new user has no message. | Add a step and a query to U1 that writes this notification, or remove it from frame U2-2. |
| R-002 | 2.16 Q3.3, Q3.5, Q3.6, QO3.2, QO5.4 | Each of these Query IDs has many statements, but only one statement has the status condition (for example `AND appointment_status = 'Pending'`). The other statements run also when that statement changes no row. Example: Q3.3 on an appointment that is already Confirmed adds a second `AppointmentConfirmation` row. Q3.5 on a Cancelled appointment marks it `Rescheduled` and adds a confirmation row. | The repository runs the statements of one Query ID in one transaction. When the guarded statement changes 0 rows, it rolls back all statements and stops (D-008). The SQL text is unchanged. | Describe this rule in the use case descriptions, or add the status condition to the other statements. |
| R-005 | 2.13 U1 step 3; 2.17 `InsuredPerson.gender` | U1 offers ชาย, หญิง and อื่น ๆ (Figma: Male, Female, Others). The data dictionary allows only `M` or `F`. | "Others" is saved as `O` (the column is `char(1)`, no CHECK). | Add `O` to the data dictionary, or remove "Others" from U1 and Figma. |

## Medium: missing queries, frames or class members

| ID | Where | Problem | What the code does now | Please decide |
|---|---|---|---|---|
| R-006 | Figma U1-5 (`125:253`), U2-1 (`126:6`) | U1-5 shows the submission time. U2-1 shows the claim card: claim number, injury, status chip, the date of the officer check, and the step "Consultation with a consultant · Waiting for your confirmation". No report query reads these values. U2 has only Q2.1 to Q2.3, and QU5.1 has no appointment status. | An extra query `findHomeClaim` (claim, status, submitted time, officer check time) and the first row of QU5.1 for "Next appointment" (D-022). The consultation step shows the appointment date, not "Waiting for your confirmation". | Add a query for the Home page to U2 (or a new step), and decide where the appointment status of the step comes from. |
| R-008 | Figma U2-3 (`126:181`); 2.16 QN.3, Q2.2 | U2-3 shows "Appointment date and time", "Consultant" and "Office location" as separate fields. QN.3 writes them into one `body` text, and Q2.2 reads only `subject` and `body`. Also, the pop-up text in Figma ("Consultation on … with นพ. ธนา ศรีสุข. Please confirm.") is not the QN.3 text ("Your appointment with … is on … at …"). | The message view shows the body text in one card (D-027). | Change frame U2-3 to show the body text, or give Q2.2 the appointment fields. Make the Figma texts the same as QN.3. |
| — | 2.11, 2.22 site map; Figma | The site map has Login as the root, but there is no login use case, no login frame and no place for passwords. U1 collects a password that no table keeps. (Known: `07-open-questions.md`, item 1.) | New table `UserAccount` (bcrypt hash), login by national ID or staff e-mail, signed token; U1 makes the account in the same transaction (D-003, D-019). The login page copies the style of U1-1 (D-014). | Write the login decision into 2.17 and 2.22, and add a Login frame to Figma. |
| — | Figma U2-1 navigation bar | The bar has a Profile destination, but there is no Profile frame. | A simple page with the user name and "Sign out" (D-024). | Add a frame, or remove the destination. |
| — | 2.18 class list | Q3.1 has no Repository method (all other Query IDs have one). | `NotificationRepository.countUnreadOnNotificationPage` (D-009). | Add the method to the class diagram. |
| — | 2.18 class list | Methods whose SQL needs `:officer_id` or `:consultant_id` do not have that parameter, for example `ClaimRepository.saveResult(claim_id, result)` (QO2.1 needs `:officer_id`) and `ReportRepository.updateSignedAt(report_id)` (QC2.6 needs `:consultant_id`). | The value is an extra parameter; the Controller takes it from the login session (D-010). | Add the parameters, or write that they come from `UserSession`. |
| — | 2.18 `TreatmentRepository.findFacilitySlots(facility, dates, officer_id)` | QO5.2 has two dates, `:date_from` and `:date_to`. | Two parameters, `dateFrom` and `dateTo` (D-011). | Change the signature in the class diagram. |
| — | 2.18 `PopUpController`; sequence U2 | The sequence puts PopUpController between NotificationController and HomePage, as a controller. It only shows a window. | It is on the page side (Flutter) (D-023). | Confirm, or keep it as written and accept the difference. |
| — | 2.13 U1 Q1.9 | `:evidence_ref` has no source. | `REG-<yyyyMMdd>-<claim_id, 4 digits>`, the format of the seed rows; NULL when the register is unavailable (D-017). | Write the source of `evidence_ref` into U1 step 5.7. |
| — | `seed.sql`, `master_table` | All five ACTIVE people of the register stub are already in `InsuredPerson`, so U1 cannot succeed with the seed (Q1.2 stops it). Only the INACTIVE person `1909900111222` is free, and that person fails Q1.1. | An extra seed file adds two ACTIVE, unregistered people: `1555500011122`, `2555500022233` (D-018). | Add one or two such people to `seed.sql`. |
| — | `07-open-questions.md` item 3 | "Register unavailable" happens when the register cannot be reached. The stub is a table in the same database, so it can never be "unreachable". | The path exists in the Model and is tested with a test double only (D-015). | Confirm that this is enough for the prototype. |

## Low: small conflicts and errors

| ID | Where | Problem | What the code does now | Please decide |
|---|---|---|---|---|
| R-007 | 2.13 U1 step 4; 2.17 `InsuredPerson.phone_no` | U1: `^\+?\d[\d ().-]{6,18}\d$` or `^\+?\d{7,15}$`. Data dictionary: 9 to 10 digits that start with 0. They do not agree. | The U1 rule. Spaces, dots, dashes and brackets are removed before the INSERT (D-016). | Use one rule in both places. |
| — | 2.17 data dictionary vs 2.13 U1 | The data dictionary has rules that U1 step 4 does not list: title only นาย, นาง, นางสาว; age 15 or more; file types `.jpg`, `.png`, `.pdf` up to 10 MB; injury time not after submission. | The code checks all of them (D-021). | Add them to U1 step 4. |
| R-001 | `queries.sql` Q3.7 and QN.1 | The header continues on lines without `--` (`ยืนยันนัดหมาย (Request Another Date)`, `ยืนยันนัดหมาย (I cannot attend)`, `นัดหมายการรักษา (Book Treatment)`). The file is not valid SQL there. | The generator and the SQL-text test skip these lines. | Put `--` in front of the lines. |
| R-009 | `seed.sql` | Claim 149 is `Covered`, but it has no officer row in `EligibilityCheck` and no row in `ClaimStatusHistory`. | The Home page shows no date for "Eligibility confirmed by the officer". | Add the rows to the seed. |
| R-010 | 2.13 U2 step 3 | "the bell icon on the Dashboard page", but the page is the Home Page (U2-1, class `HomePage`). | The code uses HomePage. | Change the word. |

## Conflicts between the instructions (already settled)

These were settled with the user in this session; they are here so that the other documents can be made the same.

- The brief had a Node.js, Express and React default stack; `CLAUDE.md` says Flutter. The user chose Flutter with a
  Dart server (D-001). The brief (section 4) now says this.
- An older `CLAUDE.md` told the code to keep hardcoded data in `lib/repository` and not to connect the database. The
  new brief needs the report's SQL through `DBConnector`. The user agreed to the brief. The September draft code is
  now in `lib/legacy/` (D-012).

## Notes on the sources (tools, not the spec)

- Figma: `get_metadata` without a node ID lists only page `0:1` (the September draft). Pages `125:2` and `125:3`
  open when you ask for their IDs directly. The 23 frame names on `125:2` agree with `06-screens.md`.
- `schema.sql`, `seed.sql` and all 56 statements of `queries.sql` load and run on PostgreSQL 16.15, as the README
  of the spec pack says. Every query has a test against the seeded database.

## Questions for the team (short list)

1. R-003: add the injury fields to U1 and frame U1-2? (The code already has them.)
2. R-004: add the six register columns to Q1.1?
3. R-011: should U1 write an "Injury forms received" notification?
4. R-005: add `O` (Others) to the gender rule?
5. R-002: change the guarded multi-statement queries, or describe the rollback rule in the report?
6. R-006 and R-008: add a Home page query, and make frame U2-3 match the Notification data?
