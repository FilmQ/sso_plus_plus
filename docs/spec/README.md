# SST spec pack

Extract of the SA report **SA Documents** for building the SST Injury Claim & Treatment Application
(ระบบยื่นคำร้องและนัดหมายการรักษากรณีประสบอันตราย, ศูนย์ฟื้นฟูผู้ป่วย สำนักงานประกันสังคม).
Generated on 2026-10-15 (evening, U3 round) from the report as it stood that day. The report is the source of truth: if this pack
and the report disagree, the report wins, and the difference should be raised with the team.

Report: https://docs.google.com/document/d/1qg-tSl0xflyYIMIpSg_7QGSjlLTMwYC9Z2lKpnLsHHk/edit

| File | What it holds | Report section |
|---|---|---|
| `01-business-process.md` | To-be swimlane: 22 processes, which use case each one is, the decisions in the flow | 2.4 to 2.7 |
| `02-use-cases.md` | Use case list and every use case description, step by step, with the SQL each step runs (Thai) | 2.11, 2.13 |
| `03-sequence-flows.md` | Every sequence diagram as a numbered message list (participants, methods, Query IDs, alternate cases) | 2.13 |
| `04-classes.md` | MVC classes: abstract bases, pages, controllers, models, repositories, DBConnector, with attributes and methods | 2.18 |
| `05-states.md` | State machines of InjuryClaim, Appointment, Treatment and ConsultationReport, with the SQL of every transition | 2.19 |
| `06-screens.md` | The 52 screens (codes U1-1 ... C2.3-2), the login and profile frames, Figma links, site map notes, the two output reports | 2.20 to 2.23 |
| `07-open-questions.md` | Gaps the report leaves open (login, file storage, signatures, ...) and how the seed data was cleaned | n/a |
| `database/schema.sql` | PostgreSQL 16 DDL for the 19 tables, plus a stub of the external SSO register (`master_table`) | 2.17 |
| `database/seed.sql` | The report's sample rows (5 per table, minus 13 rows whose parents are not among the samples), plus a marked block of development rows | 2.17 |
| `database/queries.sql` | All 58 SQL statements with Query ID, use case ID and name | 2.16 |
| `database/data-dictionary.md` | Every attribute with key, NOT NULL, type and range / validation rule (Thai) | 2.17 |
| `diagrams/` | Use case diagram, CRUD table, business process, ER with queries, class, state, sequence and site map diagrams | various |

Checked on 2026-10-15 against PostgreSQL 16.15: `schema.sql` and `seed.sql` load without errors, every
statement in `queries.sql` prepares against that schema with untyped parameters, and the U3 flows (confirm,
reschedule, cannot attend, QN.5) were run against the seed inside rolled-back transactions.

## Naming that ties code to the report

- **Use case IDs:** U1 to U6 (User), O1 to O6 (Evaluation Officer), C1 and C2 (Consultant). Sub-cases such as U3.1 to U3.3 are separate use case descriptions.
- **Query IDs:** Q1.1 to Q1.10 (U1), Q2.1 to Q2.4 (U2), Q3.1 to Q3.7 (U3), QU4.1 to QU4.3 (U4), QU5.1 (U5), Q6.1 (U6), QO1.1 to QO6.3 (officer), QC1.1 and QC2.1 to QC2.7 (consultant), QN.1 to QN.5 (notifications: QN.1 to QN.4 written by officer use cases, QN.5 by U3.1 to U3.3). Mixed prefixes (Q6.1 vs QU5.1) are as in the report; keep them.
- **Screen codes:** `<use case>-<n>`, for example U1-2 or O4-3, matching the Figma frame names.
- **Class names** come from the sequence diagrams (`InjuryFormPage`, `InsuredFormController`, `InsuredPersonModel`, `InsuredPersonRepository`, `DBConnector`, ...).

## Changes since the 2026-10-15 morning pack (report-back 2, U3)

Business decisions from the team (R-014, R-016, R-018, R-019) and documentation decisions on the rest; the full
list is in `07-open-questions.md`, "Settled on 2026-10-15 (U3)".

- **SQL (58 statements):**
  - New **QN.5**: after Q3.3, Q3.5 (with the new `appointment_id` it returns) or Q3.6, a message to the
    consultant (`Notification.consultant_id`, `insured_id` NULL), subject `Appointment confirmed`,
    `Appointment rescheduled` or `Appointment cancelled`.
  - **Q3.6** also sets the claim from `Covered` to the new status **`Withdrawn`** and writes a
    `ClaimStatusHistory` row (`officer_id` NULL). QO4.1 lists `Covered` claims only, so a withdrawn claim leaves
    the officer's list.
  - **Q3.4 and QO4.2:** bookable consultation hours are 09:00, 10:00, 11:00, 13:00, 14:00 and 15:00 (no 12:00).
  - **Q3.5** refuses a new hour that is in the past or already taken by the consultant (0 rows).
  - **Q3.2** returns `consultant_name` with the title (`นพ. ธนา ศรีสุข`).
  - **QO2.1 and QO3.1** write the officer's EligibilityCheck row even when there is no automatic row, so
    1 row = decided and 0 rows = refused.
- **Use cases (02):** U3.1 step 1 names Q2.2 for the message list; step 3 says "Onsite (ที่ศูนย์ฟื้นฟูสมรรถภาพ
  ห้องของที่ปรึกษา)" and the consultant's title; step 6 runs Q3.7 only when the page was opened from a message.
  U3.2: Cancel is always available, the hours are stated, the new time must still be free. U3.3: the warning says
  the claim ends and the consultant is told; the claim becomes `Withdrawn`. Each of U3.1 to U3.3 ends with QN.5.
- **Data dictionary:** `claim_status` adds `Withdrawn`; `schedule_time` is 09:00 to 15:00 every hour except
  12:00; `Notification.consultant_id` (QN.3, QN.5); `ClaimStatusHistory.officer_id` NULL means the system or the user.
- **States (05):** InjuryClaim `Covered` to `Withdrawn` (U3.3, Q3.6).
- **Classes (04):** NotificationModel `getNotifications`, `notifyConsultant`; NotificationRepository
  `insertConsultantMessage {QN.5}`.
- **Diagrams:** sequence, collaboration and class diagrams of U3.1 to U3.3, the InjuryClaim state diagram, the
  CRUD table (U3 also updates Injury Application) and the ER diagram with queries.
- **Screens (06):** see "Screen rules from the U3 decisions" there.
- **Seed:** claim 155 is `Withdrawn` with its check and history rows; the dev block adds person 106, claim 160
  and a `Pending` appointment 510 with its QN.1 and QN.3 messages, so U3.1 to U3.3 can be shown from the seed.

## Changes since the 2026-10-14 pack

- **SQL:** 57 statements (new Q2.4 for the Home page claim card). Q3.3, Q3.5, Q3.6, QO3.2 and QO5.4 are single
  guarded statements (`UPDATE ... RETURNING` inside a `WITH`, then `INSERT ... SELECT` from it), so a 0-row result
  means the state did not allow the change. QO2.1 and QO3.1 only decide a claim that is still `Awaiting
  verification`, `Needs review` or `Register unavailable`. Q1.1 also returns the register's employer and
  contribution columns, and Q1.7 returns `submitted_at`. Every comment line in `queries.sql` is now valid SQL.
- **Use cases:** U1 step 3 lists the injury fields and step 4 the data dictionary checks (phone `^0\d{8,9}$`
  after removing spaces, dots, dashes and brackets; age at least 15; files .jpg/.png/.pdf up to 10 MB); step 5.7
  says where `evidence_ref` comes from; step 6 shows `claim_no` and `submitted_at`. U2 reads the claim card (Q2.4)
  and lists the notification kinds by the query that writes them (QN.1 to QN.4, QU4.3).
- **Data dictionary:** `InsuredPerson.gender` allows `O` (อื่น ๆ).
- **Diagrams:** sequence, collaboration and class diagrams of U1, U2, U3.1 and O5.1 are redrawn (U2 with
  ClaimRepository and Q2.4; U3.1 starts with Q3.1 `countUnread` through AppointmentController; O5.1 passes
  `date_from` and `date_to`), and so are the CRUD table and the ER diagram with queries for group A.
- **Screens:** U1-2 has an Injury details section; U2-2, U2-3, U3-1 and U4-5 show the QN.1 and QN.3 texts and no
  longer show an "Injury forms received" message (no query writes it); new L-1, P-1 and L-2 frames.
- **Seed:** a marked block of development rows (see `07-open-questions.md`).
