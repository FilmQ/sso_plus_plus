# Brief: build the SST Injury Claim & Treatment Application

You are starting the implementation of a system our team has already analysed and designed in a systems analysis
report (Thai, university SA course). The report is graded together with the code, so the code must follow the
report closely: same use cases, same SQL (by Query ID), same classes, same screens. Your job in this first session
is a solid head start, not the whole system. Scope and stopping point are at the end of this brief.

## 1. The system in one paragraph

SST (ระบบยื่นคำร้องและนัดหมายการรักษากรณีประสบอันตราย, ศูนย์ฟื้นฟูผู้ป่วย สำนักงานประกันสังคม) lets an insured worker
who was injured file a claim in an app. The system checks Social Security Section 33 coverage automatically.
An Evaluation Officer reviews the claim, approves or rejects it, and books an appointment with a Consultant. The user
confirms, picks another slot, or cancels in the app (a phone call by the officer is only a manual fallback). After
the consultation the Consultant writes, signs and files a report; the officer reads it and books treatment (or closes
the claim when no treatment is needed). The user accepts the treatment date or picks another one; an unaccepted
treatment is cancelled automatically.

Actors and use cases (14, some split into sub-cases):

- **User (ผู้ใช้งาน)**, phone app: U1 Submit Injury Application, U2 View Notify Message, U3 Appointment Confirmation
  (U3.1 Confirm, U3.2 Request Another Date, U3.3 I cannot attend), U4 Treatment Confirmation (U4.1 Accept,
  U4.2 Change Date, U4.3 automatic cancel), U5 View Appointment Schedule, U6 View Treatment Schedule.
- **Evaluation Officer (เจ้าหน้าที่ประเมิน)**, desktop console: O1 View Injury Application, O2 Approve, O3 Reject,
  O4 Schedule Appointment, O5 Schedule Treatment (O5.1 Book Treatment, O5.2 No Treatment Required),
  O6 View Consultation Report.
- **Consultant (ที่ปรึกษา)**, desktop console: C1 View Appointment Schedule, C2 Create Consultation Report
  (C2.1 Amend the Draft, C2.2 Sign the Signature, C2.3 File the Report).

## 2. Where the specification is

**In this repository: `docs/spec/`.** It is an extract of the report made for you. Read
`docs/spec/README.md` first, then the files in this order before writing code:

1. `01-business-process.md`: the to-be flow, 22 processes, which use case each one is.
2. `02-use-cases.md`: every use case description step by step, with the exact SQL each step runs (Thai text;
   button labels, page names and SQL are English).
3. `03-sequence-flows.md`: every sequence diagram as a numbered message list (who calls whom, method names,
   Query IDs, alternate cases).
4. `04-classes.md`: the MVC classes with attributes and methods.
5. `05-states.md`: state machines for InjuryClaim, Appointment, Treatment and ConsultationReport.
6. `06-screens.md`: the 52 screens, their codes and the Figma pages.
7. `07-open-questions.md`: gaps the report leaves open. Several affect the first session.
8. `database/schema.sql`, `database/seed.sql`, `database/queries.sql`, `database/data-dictionary.md`.
9. `diagrams/`: use case, business process, ER, class, state, sequence and site map diagrams as PNG.

`schema.sql` and `seed.sql` load cleanly into PostgreSQL 16, and all 58 statements in `queries.sql` prepare
against that schema. `docs/spec/README.md` ends with what changed since the previous pack. If `docs/spec/` is missing, stop and ask me for it.

**Live sources (links).** They need our team's Google, Figma or Canva sign-in, so you may not be able to open
them. Use them only through a connected MCP server (Google Drive, Figma) or ask me for an export. `docs/spec/` is
enough for this session.

| Source | Link | Use it for |
|---|---|---|
| SA report "SA Documents" (Google Doc, the source of truth, very large) | https://docs.google.com/document/d/1qg-tSl0xflyYIMIpSg_7QGSjlLTMwYC9Z2lKpnLsHHk/edit | Anything `docs/spec/` does not cover; the report wins if they differ |
| Figma "SSO Plus Plus", user app screens (390 x 844) | https://www.figma.com/design/yGZrD3LH6RRn8MVXo1LAwv/SSO-Plus-Plus?node-id=125-2 | Page `03 · Use-case screens · User app`, frames U1-1 to U6-1 |
| Figma "SSO Plus Plus", officer and consultant console (1440 x 900) | https://www.figma.com/design/yGZrD3LH6RRn8MVXo1LAwv/SSO-Plus-Plus?node-id=125-3 | Page `04 · Use-case screens · Officer & Consultant console`, frames O1-1 to C2.3-2 |
| Google Drive "SA Folder" (diagram PNGs) | https://drive.google.com/drive/folders/13PR85yOnQQoQDcvsc-XM0Maqer9Ff9WG | Full-size diagrams; same as `docs/spec/diagrams/` |
| Sequence diagrams folder | https://drive.google.com/drive/folders/1qI1Q2KGpBOMXjMBOwEMYVODAxTPxWmLA | Files named `SD-<use case>.png`; ignore `zOLD-` copies |
| Collaboration diagrams folder | https://drive.google.com/drive/folders/1sZ2s7C83UbTEI_OxzfYPTbxmeNG9IfS6 | Files named `CD-<use case>-<case>.png`; ignore `zOLD-` and `zDEPRECATED-` copies |
| Canva brainstorm board (old to-be flow, historical) | https://www.canva.com/design/DAHTpNGlt28/JrCc_46e4CnCLkxu8dlZ3g/edit | Background only; `01-business-process.md` supersedes it |

In Figma, every frame is named `<screen code> · <screen name>` (for example `U1-2 · Fill in Injury Forms Page`,
`O4-1 · Scheduling page`): 23 frames on the user app page and 29 on the console page, one per screen in
`06-screens.md`, plus the infrastructure frames `L-1 · Login Page`, `P-1 · Profile Page` and
`L-2 · Console Login Page`. A label above each frame names the use case step and the SQL it shows. The September draft pages in the same file (phone M1 to M9, console D1 to D8) are
superseded; do not build from them.

## 3. Rules that keep the code traceable to the report

1. **Layering is the report's MVC:** Page (boundary) -> Controller -> Model -> Repository -> DBConnector, exactly
   as in `04-classes.md` and `03-sequence-flows.md`. Use the report's class and method names
   (`InjuryFormPage`, `InsuredFormController.submitInjuryForm`, `InsuredPersonModel.register`,
   `InsuredPersonRepository.findInSSORegister`, `DBConnector.performQuery`, ...). Adapt casing to the language's
   conventions only where the language forces it.
2. **SQL is the report's SQL.** Every repository method runs the statement from `database/queries.sql` verbatim,
   with a comment naming the Query ID and use case (for example `// Q1.1 [U1]`). Keep the `:name` parameters in the
   SQL text and convert them to driver placeholders in `DBConnector` (careful: `::date` casts are not parameters).
   Statements that belong to one Query ID run in one transaction. No ORM-generated SQL for these queries.
3. **Schema is the report's schema.** Use `database/schema.sql` as the first migration and `seed.sql` as the dev
   seed. Do not rename or add columns in the 19 report tables without asking me. New tables for infrastructure
   (login accounts, file storage) are fine, but log each one.
4. **Status values are exact strings** from `05-states.md` (`Awaiting verification`, `Register unavailable`,
   `Covered`, `Not covered`, `Rejected`, `No treatment required`; `Pending`, `Confirmed`, `Rescheduled`,
   `Cancelled`; `Pending`, `Accepted`, `Cancelled`). Transitions only through the queries listed there.
5. **Screens follow Figma** frame by frame, named by screen code. Labels and messages are those in the Figma frames
   and the use case descriptions (mixed English and Thai, as designed). The user app is phone-first; the console is
   desktop.
6. **Log every decision or deviation** in `docs/DECISIONS.md` (date, what, why, which report section it affects),
   so the team can write it back into the report. `docs/spec/` is read-only for you.
7. **Tests follow the use case descriptions.** Name each test after the use case and case it checks (for example
   `U3.2 Normal Case`, `U3.2 Alternate Case 1 [Cancel]`). The report's section 2.25 needs a test result per use case,
   so keep the results easy to read.
8. Time zone Asia/Bangkok. Only seed or made-up data; never real personal data.

## 4. Stack

Settled with the team on 2026-10-14 (decision D-001 in `docs/DECISIONS.md`):

- PostgreSQL 16 in Docker Compose, schema and seed from `docs/spec/database/`.
- Server in Dart (`shelf`, `postgres` package): Controllers, Models, Repositories and `DBConnector` with the
  report's class and method names. A Flutter web app cannot open a database connection, so the Page classes call the
  server over HTTP (JSON).
- Flutter (Material 3) for the user app and the console, on web and mobile. Page widgets are named after the
  report's Page classes.
- Tests: `dart test` (server, against a seeded test database) and `flutter test`.
- A scheduled job for U4.3 (`AutoCancelJob`, runs QU4.3).
- The September draft code lives in `lib/legacy/` until the officer and consultant slices replace it.

## 5. Questions to ask me first (one message)

1. Stack: settled (section 4); skip this question.
2. Login: settled. Login is infrastructure, kept in a `UserAccount` table outside the 19 report tables
   (`07-open-questions.md`, item 1; report 2.20 and 2.21; Figma frames L-1, P-1 and L-2); skip this question.
3. Uploaded files: OK to store them in a local folder behind a storage interface for now?

Then continue without waiting for anything else; note further assumptions in `docs/DECISIONS.md`.

## 6. Scope for this session

Do these in order, commit after each step, and stop after step 5 with a short summary for me.

1. **Scaffold** the repository with the agreed stack, Docker Compose for PostgreSQL 16, the migration from
   `schema.sql`, the seed from `seed.sql`, lint and test scripts, README and `.env.example`.
2. **Data layer:** `DBConnector` (pool, `performQuery`, transactions, `:name` parameter conversion) and every
   Repository class from `04-classes.md` with **all 58 queries** as methods. Add a test per query that runs it
   against the seeded database inside a rolled-back transaction, with parameters taken from the seed rows.
3. **Login** as agreed in question 2, with seed accounts for one user, one officer and one consultant from the
   seed people.
4. **Vertical slice U1 Submit Injury Application**, end to end: screens U1-1 to U1-5 (Register Page, Fill in
   Injury Forms Page, Validation failed, National ID already registered, Injury forms submitted), the field rules
   in the U1 description (Thai name check, 13-digit national ID, password rule, phone format), the Section 33 check
   against the `master_table` stub (national ID 1909900111222 is the `INACTIVE` test person), and Q1.1 to Q1.10.
   Tests for the Normal Case and Alternate Case 1 [Validation Failed].
5. **Vertical slice U2 View Notify Message**: home page with the unread dot, the notification pop-up, opening a
   message marks it read (Q2.1 to Q2.3), and the claim card on the home page (Q2.4), with tests.

Then report back: what runs, how to run it, what each test covers, decisions you logged, and anything in the
report that looked inconsistent while you built (with the report section). Do not start the officer or consultant
use cases yet.

## 7. Later sessions (for orientation only)

U3 to U6 (user app), O1 to O6 (officer console), C1 and C2 (consultant console), `AutoCancelJob` for U4.3, the two
output reports in `06-screens.md`, and Flutter `integration_test` flows (with the server's own tests for the
SQL) that follow `01-business-process.md` from claim to treatment.

Business-process questions (what the office does, what a status means, who is told what) are the team's to
answer: list them in your report-back with the report section instead of deciding them in code.
