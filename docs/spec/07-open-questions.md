# Open questions and known gaps

Things the SA report does not settle, or settles in a way the code has to work around. Raise each one with the
team before building the part it affects; record what was decided in `docs/DECISIONS.md` so it can be written
back into the report.

## Decide before or during the first build

1. **Login and accounts.** The site map has *Login* as the root of all three trees, but the report has no login
   use case and no table that stores credentials. U1 collects a password (`^[A-Za-z0-9]{8,}$`, plus a confirmation)
   that no table stores, and `EvaluationOfficer` / `Consultant` have no credentials either. Proposal: add one
   `UserAccount` table (account id, role `USER` / `OFFICER` / `CONSULTANT`, login name, password hash, link to
   `insured_id`, `officer_id` or `consultant_id`) outside the 19 report tables, and treat login as infrastructure,
   not a use case. Officers and consultants are created by seed data only (no admin use case).
2. **One claim per person.** U1 registers the person and submits the claim in one step, and Q1.2 rejects a
   national ID that is already registered. A registered user therefore cannot file a second claim. Keep this for the
   prototype unless the team decides otherwise.
3. **SSO register.** Q1.1 reads `master_table`, the Social Security Office's insured register, which is external.
   `schema.sql` has a stub with the extra employer and contribution columns that Q1.4 and Q1.5 need. If the
   register cannot be reached, Q1.6 saves the claim as `Register unavailable` for the officer to check; if it is
   reached and the person is not `ACTIVE`, U1 fails validation (screen U1-3).
4. **Uploaded files.** `ClaimDocument` keeps `file_uri`, `mime_type` and `file_size_bytes`; where the bytes live
   is not specified. A local folder behind a storage interface is enough for the prototype.
5. **Consultant attachment and signature.** C2.1 Alternate Case 1 attaches a file to the report and C2.2 captures
   a signature, but `ConsultationReport` has no column for either (only `signed_at`). Decide where they go before
   building C2.
6. **Deadlines.**
   - Appointments: QO4.3 sets `Appointment.confirm_deadline` to 24 hours before the appointment. Nothing in the
     system acts on it; the officer sees unconfirmed appointments as purple slots on the Schedule Appointment page
     and phones the user (process 9 of the business process, manual).
   - Treatments: U4.3 cancels a treatment the user has not accepted. It is a scheduled job (`AutoCancelJob` in the
     class list, condition `scheduled_date <= CURRENT_DATE` in the state diagram, SQL QU4.3).
7. **Phone follow-up data.** `PhoneCallAttempt` and `AppointmentConfirmation.channel = 'phone'` exist in the data
   dictionary, but no use case writes them: the phone call is manual work. Leave the tables unused.
8. **Claim status `Needs review`.** QO1.1 and QO1.2 still list and count it, but no transition produces it. Keep the
   queries as they are (the team chose to leave it).
9. **Notifications** are in-app only (`Notification` rows read in U2). No push, e-mail or SMS is specified.
10. **Time zone** is Asia/Bangkok; the report's dates are written `[วัน] / [เดือน] / [ปี] : [เวลา]`.
11. **Software platform.** Section 2.20 of the report is still a placeholder; only PostgreSQL is named. Whatever
    stack is chosen should be written back into 2.20.

## Sample data cleaning

The report's five sample rows per table are a window onto a larger data set, so some rows point at claims,
appointments or reports that are not among the samples. `seed.sql` leaves these rows out so every foreign key holds:

| Table | Row (primary key) | Missing parent |
|---|---|---|
| ClaimRejection | 3002 | claim_id = 146 |
| ClaimRejection | 3003 | claim_id = 148 |
| ClaimRejection | 3004 | claim_id = 153 |
| ClaimRejection | 3005 | claim_id = 138 |
| AppointmentConfirmation | 605 | appointment_id = 506 |
| PhoneCallAttempt | 704 | appointment_id = 506 |
| PhoneCallAttempt | 705 | appointment_id = 506 |
| ConsultationSession | 304 | appointment_id = 506 |
| ConsultationSession | 305 | appointment_id = 507 |
| ConsultationReport | 88 | session_id = 304 |
| ConsultationReport | 89 | session_id = 305 |
| Treatment | 404 | claim_id = 139 |
| Treatment | 405 | claim_id = 150 |

`seed.sql` also adds the `master_table` rows: the five sample people as `ACTIVE`, plus one `INACTIVE` person
(national ID 1909900111222) to exercise the failed Section 33 check.
