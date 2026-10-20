# SST spec pack

Extract of the SA report **SA Documents** for building the SST Injury Claim & Treatment Application
(ระบบยื่นคำร้องและนัดหมายการรักษากรณีประสบอันตราย, ศูนย์ฟื้นฟูผู้ป่วย สำนักงานประกันสังคม).
Generated on 2026-10-19 (C1 and C2 round) from the report as it stood that day. The report is the source of truth: if this pack
and the report disagree, the report wins, and the difference should be raised with the team.

Report: https://docs.google.com/document/d/1qg-tSl0xflyYIMIpSg_7QGSjlLTMwYC9Z2lKpnLsHHk/edit

| File | What it holds | Report section |
|---|---|---|
| `01-business-process.md` | To-be swimlane: 22 processes, which use case each one is, the decisions in the flow | 2.4 to 2.7 |
| `02-use-cases.md` | Use case list and every use case description, step by step, with the SQL each step runs (Thai) | 2.11, 2.13 |
| `03-sequence-flows.md` | Every sequence diagram as a numbered message list (participants, methods, Query IDs, alternate cases) | 2.13 |
| `04-classes.md` | MVC classes: abstract bases, pages, controllers, models, repositories, DBConnector, with attributes and methods | 2.18 |
| `05-states.md` | State machines of InjuryClaim, Appointment, Treatment and ConsultationReport, with the SQL of every transition | 2.19 |
| `06-screens.md` | The 54 screens (codes U1-1 ... C2.3-2), the login and profile frames, Figma links, site map notes, the two output reports | 2.20 to 2.23 |
| `07-open-questions.md` | Gaps the report leaves open (login, file storage, signatures, ...) and how the seed data was cleaned | n/a |
| `database/schema.sql` | PostgreSQL 16 DDL for the 19 tables, plus a stub of the external SSO register (`master_table`) | 2.17 |
| `database/seed.sql` | The report's sample rows (5 per table, minus 13 rows whose parents are not among the samples), plus a marked block of development rows | 2.17 |
| `database/queries.sql` | All 62 SQL statements with Query ID, use case ID and name | 2.16 |
| `database/data-dictionary.md` | Every attribute with key, NOT NULL, type and range / validation rule (Thai) | 2.17 |
| `diagrams/` | Use case diagram, CRUD table, business process, ER with queries, class, state, sequence and site map diagrams | various |

Checked on 2026-10-19 against PostgreSQL 16.15: `schema.sql` and `seed.sql` load without errors, every
statement in `queries.sql` (62) prepares against that schema with untyped parameters, and the consultant flows were
run against the seed inside rolled-back transactions: QC1.2 returns the consultant's own QN.5 messages; QC2.2 and
QC2.4 do nothing on a second session or a second draft (ON CONFLICT); QC2.4 refuses a recommendation outside
Physiotherapy, Occupational therapy and None and another consultant's session; QC2.5 on a signed draft clears
`signed_at` and `signature_uri`; QC2.6 refuses an empty signature file; QC2.7 refuses an unsigned report and a
session without `recommended_treatment`; QC2.8 marks a past `Confirmed` appointment `No show` (and its session
`No show` / `Cancelled`) and refuses a future one, one with a draft and another consultant's; after a no-show QO4.1
lists the claim again and QC2.1 no longer lists the appointment; the schema refuses a second session for one
appointment and a signed report without a signature file. The officer checks of 2026-10-18 still pass.

## Naming that ties code to the report

- **Use case IDs:** U1 to U6 (User), O1 to O6 (Evaluation Officer), C1 and C2 (Consultant). Sub-cases such as U3.1 to U3.3 are separate use case descriptions.
- **Query IDs:** Q1.1 to Q1.10 (U1), Q2.1 to Q2.4 (U2), Q3.1 to Q3.7 (U3), QU4.1 to QU4.5 (U4), QU5.1 (U5), Q6.1 (U6), QO1.1 to QO6.3 (officer), QC1.1 and QC1.2, QC2.1 to QC2.8 (consultant), QN.1 to QN.5 (notifications: QN.1 to QN.4 written by officer use cases, QN.5 by U3.1 to U3.3). Mixed prefixes (Q6.1 vs QU5.1) are as in the report; keep them.
- **Screen codes:** `<use case>-<n>`, for example U1-2 or O4-3, matching the Figma frame names.
- **Class names** come from the sequence diagrams (`InjuryFormPage`, `InsuredFormController`, `InsuredPersonModel`, `InsuredPersonRepository`, `DBConnector`, ...).

## Changes since the 2026-10-18 pack (report-back 5, C1 and C2)

Business decisions from the team (R-048 to R-052, R-055) and documentation decisions on the rest; the full list is
in `07-open-questions.md`, "Settled on 2026-10-19 (C1 and C2)".

- **SQL (62 statements):**
  - **QC1.2 (new):** the consultant's QN.5 messages of the last 14 days, newest first, for the "Recent changes" card
    on the Schedule Page (R-052).
  - **QC2.2 and QC2.4** use `ON CONFLICT DO NOTHING` (one session per appointment, one report per session, R-053);
    0 rows from QC2.4 means a draft exists, so the page uses QC2.5.
  - **QC2.4 and QC2.5** also write `ConsultationSession.recommended_treatment` (Physiotherapy, Occupational therapy
    or None) in one guarded WITH statement; **QC2.7** needs it; **QC2.3** returns it (R-050).
  - **QC2.6** takes `:signature_uri` and saves it with `signed_at`; **QC2.5** clears both; **QC2.3** and **QO6.2**
    return `signature_uri` (R-048).
  - **QC2.8 (new):** "User did not attend": for the consultant's own `Confirmed` appointment whose start time has
    passed and that has no report, it saves the session as `No show` / `Cancelled` and the appointment as `No show`
    (R-051). The claim stays `Covered`, so QO4.1 lists it again.
  - **QC2.3, QO6.1 and QO6.2** no longer return `version_no` (R-055).
- **Schema and data dictionary:** `UNIQUE (appointment_id)` on ConsultationSession and `UNIQUE (session_id)` on
  ConsultationReport; new column `ConsultationReport.signature_uri varchar(255)` with
  `CHECK ((signed_at IS NULL) = (signature_uri IS NULL))`; `Appointment.appointment_status` adds `No show`;
  `version_no` is always 1.
- **Seed (dev block):** persons 109 and 110; `Covered` claims 163 and 164; `Confirmed` appointments 512 (in the future,
  for C1) and 513 (in the past without a session, for C2 and the no-show case) with consultant 1; QN.5 message 909
  for the Recent changes card (R-047).
- **Use cases (02):** C1 shows the Recent changes card; C2.1 has the Recommended treatment field, the upload step
  (D-057) and Alternate Case 3 [User did not attend]; C2.2 saves the signature image; C2.3 says "Filed" and needs
  the recommendation; O5 shows the recommendation; O6 shows the signature and no version.
- **Classes (04):** SchedulePage `recentChanges`; AppointmentRepository `findRecentChanges` {QC1.2};
  CreateReportPage `clickUserDidNotAttend`, `showNoShowConfirmation`, `clickConfirm`,
  `finishDraft(report_content, file, recommended_treatment)`; ReportController and ReportModel `markNoShow`,
  `saveDraft(..., recommended_treatment)`, `signReport(report_id, signature)`; ReportModel `storeFile`,
  `storeSignature`, `recommendedTreatment`, `signatureUri` (no `versionNo`); ReportRepository `updateNoShow` {QC2.8},
  `updateSignedAt(report_id, signature_uri)`; ConsultationReportPage `signatureImage`.
- **States (05):** Appointment `Confirmed` to `No show` (QC2.8); ConsultationReport transitions with the file,
  signature and recommendation conditions.
- **Sequence flows (03) and diagrams:** C1, C2.1 (with Alternate Case 3), C2.2 and C2.3 redrawn; class diagrams of
  O4, O6 and C2; the Appointment and ConsultationReport state diagrams; the CRUD table (C2 updates Appointment);
  the ER diagram with queries.
- **Screens (06):** 54 screens: new C2.1-5 "User did not attend" and C2.1-6 "Marked as no show"; see "Screen rules
  from the C1 and C2 decisions" there. The output report (2.23) shows the recommendation and the signature image and
  no version.

## Changes since the 2026-10-17 pack (report-back 4, O1 to O6)

Business decisions from the team (R-037, R-042, R-043, R-044, R-046) and documentation decisions on the rest; the
full list is in `07-open-questions.md`, "Settled on 2026-10-18 (O1 to O6)".

- **SQL (60 statements):**
  - **QO2.1 and QO3.1** take `:override_reason` and refuse (0 rows) a result that differs from the latest automatic
    EligibilityCheck when the reason is empty (R-037).
  - **QO1.4** also returns the document type name and `uploaded_at` (R-039).
  - **QO4.2** offers weekdays only; **QO4.3** is one guarded statement: a future weekday, one of the six hours, a
    QO4.1 claim, a free consultant; it saves type `Onsite` and the consultant's `office_location` (R-043).
  - **QO5.1** also returns the session's `recommended_treatment` and the user's `title_name` (R-045).
  - **QO5.2** takes `:duration_minutes`: an hour is `busy` when the treatment would overlap a `Pending` or
    `Accepted` treatment at the facility or end after 12:00 (morning) or 17:00 (afternoon). **QO5.3** is guarded
    the same way (the claim and report are a QO5.1 row, the type, duration and facility lists, a future weekday,
    the hours rule, no overlap) (R-044). **QU4.2** and **QU4.5** use the same overlap rule for the user's new date.
  - **QC2.4 and QC2.5** save `:report_content` or `:report_file_uri` (an empty value is NULL); **QC2.6 and QC2.7**
    need one of the two (R-046). **QO6.2** returns `report_file_uri` and `viewed_at` and needs `delivered_at IS NOT NULL` (D-053).
- **Schema and data dictionary:** `Appointment.appointment_type` is `Onsite` only; new column
  `ConsultationReport.report_file_uri varchar(255)` with `CHECK (num_nonnulls(report_content, report_file_uri) <= 1)`;
  `Treatment.duration_minutes IN (30, 45, 60, 90, 120)`; `EligibilityCheck` `CHECK (NOT is_override OR override_reason IS NOT NULL)`.
- **Seed (dev block):** persons 107 and 108; claim 161 `Awaiting verification` with documents 2006 to 2008 and its
  automatic check (for O1 to O3); claim 162 `Covered` with appointment 511, session 306 and filed report 90 and no
  treatment (for O5) (R-038, R-045). Document files are a dev-setup note in `07-open-questions.md`.
- **Use cases (02):** O2 and O3 say when the override reason is needed; O2 step 6.1 and O5.1 step 6.1 give the QN.1
  texts as the code sends them (R-036); O4 has no waiting list (R-042) and offers weekdays, Onsite at the
  consultant's office; O5.1 lists the durations and the hours rule; O6 and C2.1 cover a report that is a file.
- **Classes (04):** `confirmResult(..., override_reason)`, `rejectApplication(claim_id, reason_code, override_reason)`,
  `saveResult(claim_id, result, override_reason)`; `getAvailableTimes`, `getFacilitySlots` and `findFacilitySlots`
  take `duration`; `finishDraft`, `saveDraft`, `insertDraft`, `updateDraft` take `report_file_uri`; ReportModel `reportFileUri`.
- **Sequence flows (03) and diagrams:** O2, O3, O5.1 and C2.1 redrawn; class diagrams of O1 to O3, O5 and C2; the
  three ER diagrams with queries. The CRUD table and the state diagrams do not change.
- **Screens (06):** see "Screen rules from the O1 to O6 decisions" there (all 29 console frames were redone).

## Changes since the 2026-10-15 evening pack (report-back 3, U4 to U6)

Business decisions from the team (R-028, R-030, R-031, R-033, R-035) and documentation decisions on the rest; the
full list is in `07-open-questions.md`, "Settled on 2026-10-17 (U4 to U6)".

- **SQL (60 statements):**
  - New **QU4.4** (U4.1 and U4.2 page): one treatment of `:insured_id` with `duration_minutes`, `booked_by`
    (officer), `report_signed_date`, `report_author`, `claim_no` and `injury`.
  - New **QU4.5** (U4.2 step 2): the free weekdays from tomorrow to the booked date + 7, at the same hour, without
    the booked date and without days when the facility has another `Pending` or `Accepted` treatment then.
  - **QU4.2** sets `treatment_status = 'Accepted'` with the new date, and refuses (0 rows) a date outside that rule,
    a taken slot or a treatment of another user. It returns `treatment_id, scheduled_date, scheduled_time`.
  - **QU4.1** checks the owner (`:insured_id`) and returns `treatment_id`.
  - **QU4.3** also sets the claims of the cancelled treatments from `Covered` to `Withdrawn`, writes their
    ClaimStatusHistory rows and ends the message with "Your claim <claim_no> is now closed."
  - **QO5.2** offers weekdays only; **QO5.3** saves `:duration_minutes`; **Q6.1** returns `duration_minutes`;
    **QU5.1** returns `appointment_status` and `claim_id`; **Q3.5** accepts only the six bookable hours.
- **Schema and data dictionary:** new column `Treatment.duration_minutes integer NOT NULL CHECK (> 0)`;
  `scheduled_date` is a weekday (QO5.2) and the user may move it up to 7 days later (QU4.2).
- **Seed:** treatments 401 to 403 have durations 60, 45, 45. In the dev block, appointment 510 (and its QN.3
  message) is on `CURRENT_DATE + 5`, and treatment 403 is on the first weekday on or after `CURRENT_DATE + 7`.
- **Use cases (02):** U4.1 starts by opening the Confirm Treatment page (QU4.4); U4.2 lists the dates with QU4.5 and
  a saved date counts as accepting; U4.3 runs at server start and daily at 00:05 and closes the claim; U5 and U6 are
  the two tabs of the Schedule Page and their cards open the Appointment Page and U4-1.
- **States (05):** Treatment `Pending` to `Accepted` also by U4.2 (no self-transition any more); InjuryClaim
  `Covered` to `Withdrawn` also by U4.3.
- **Classes (04):** TreatmentPage `open`, `saveDate`; TreatmentController and TreatmentModel `getTreatment` /
  `getTreatmentDetail`, `getAvailableDates`, and `insured_id` on accept and changeDate; TreatmentRepository
  `findTreatmentDetail {QU4.4}`, `findAvailableDates {QU4.5}`; TreatmentModel `durationMinutes`.
- **Sequence flows (03) and diagrams:** U4.1 to U4.3 redrawn; class diagram of U4, Treatment and InjuryClaim state
  diagrams, the CRUD table (U4 reads and updates Injury Application and reads Consultation Report) and the ER
  diagram with queries.
- **Screens (06):** see "Screen rules from the U4 to U6 decisions" there (U4-1 to U4-5, U5-1, U6-1, O5.1-1 to O5.1-3).

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
