# Report back 2: the 2026-10-15 spec pack and U3

From: the Claude Code session that built U3 (2026-10-15).
To: the team and the instance that keeps the SA report and `docs/spec/`.

## Context

Since the first report (`REPORT-BACK.md`), the code takes in the spec pack of 2026-10-15 and adds U3 Appointment
Confirmation (U3.1, U3.2, U3.3) on the server and in the user app. Commits `4388f13` to `03028ff` on `develop`.

- The pack settles R-001 to R-012, and the code follows it: 57 queries, the guarded single statements, Q1.1 with the
  register columns, Q1.7 with `submitted_at`, Q2.4 for the Home claim card, gender `O`, the phone rule
  `^0\d{8,9}$`, the injury fields of U1, and the L-1, P-1 and L-2 frames. The three temporary extra queries are
  removed; only the login SQL (D-003) stays outside the report.
- Every item has a reference to `docs/DECISIONS.md`: **R-xxx** is a report issue, **D-xxx** is the decision the code
  uses now. The code works around every item; no item blocks the app.
- Tests: 163 server tests and 82 Flutter tests pass. U3.1 was also run against the live server.
- Checked in full for this report: U3.1 to U3.3 (use cases, sequences, classes, queries Q3.1 to Q3.7), the Figma
  frames U3-1 to U3-7, L-1, P-1, L-2, and the changed U2 frames. U4 to C2 are not checked yet.

## How the pack arrived (please change for next time)

| Problem | Effect | Please do |
|---|---|---|
| `sst-spec.zip` holds a whole `docs/` folder. Unpacking it replaced the folder. | `docs/DECISIONS.md` and `docs/legacy/IMPLEMENTATION.md` were deleted. They are restored from git. | Send only `docs/spec/` and `docs/CLAUDE_CODE_BRIEF.md`, or tell the user to unpack without removing other files. |
| The brief of the pack says "Playwright flows" in section 7. | It undid the change to Flutter `integration_test` (stack D-001). Restored. | Keep section 7 as Flutter `integration_test`. |

## High: the report is wrong or the process does not agree

| ID | Where | Problem | What the code does now | Please decide |
|---|---|---|---|---|
| R-013 | 2.16 QO2.1, QO3.1 | The status UPDATE runs in a WITH clause, but the result counts only the final EligibilityCheck INSERT. For a claim without an automatic check row (seed claim 155, which is `Covered` with no EligibilityCheck rows), the claim status and the history change, but the result is 0 rows, the same as a refused claim. | The Model runs the query in a transaction and rolls back on 0 rows (409). So the officer cannot decide such a claim (D-029, D-031). | Let the last statement return the claim (for example `SELECT claim_id FROM decided`), or insert the officer's EligibilityCheck row also when there is no automatic row. |
| R-019 | 2.5 process 10; 2.16 QO4.1 | After U3.3 "I cannot attend", the process ends ("treatment abandoned"). But the claim stays `Covered` with no Pending or Confirmed appointment, so QO4.1 lists it again for a new appointment. | No change. | Decide one: U3.3 changes the claim status (a new status?), or QO4.1 leaves out a claim whose last confirmation is `Cannot attend`. |
| R-022 | 2.16 Q3.4, Q3.5 | Q3.4 lists the free hours, but Q3.5 does not check that the new hour is still free. Two users can take the same hour of one consultant. | `AppointmentModel.reschedule` checks the hour against Q3.4 first and refuses with 409 (D-033). | Add the condition to Q3.5 (`AND NOT EXISTS` an appointment of the consultant at the new hour), as Q3.4 does. |
| R-018 | Figma U3-6; 2.13 U3.3 | The warning says "the officer will be informed", but U3.3 writes no notification, and no query informs the officer or the consultant. The consultant's QN.3 message ("Waiting for the patient to confirm") also never changes after U3.1, U3.2 or U3.3. | Nothing is sent. The officer sees the change only on the Scheduling page (QO4.2). | Add a notification query to U3.1 to U3.3 (to the consultant; officers have no Notification column), or change the text of U3-6. |

## Medium: missing queries or data, frames that do not agree with the queries

| ID | Where | Problem | What the code does now | Please decide |
|---|---|---|---|---|
| R-021 | 2.13 U3.1 steps 1 and 2; 2.18 NotificationPage | The Notification Page (U3-1) lists the messages, but U3 has no list query: only Q3.1 (the count) and Q3.2 (the appointment). | The page uses Q2.2 (D-035). | Name Q2.2 in U3.1 step 1, or add a query. |
| R-020 | 2.13 U3.1 step 6; 2.18 | Q3.7 needs `:notification_id`, but the Appointment Page also opens from the Home page ("View appointment", no message) and from U2-3 "Open appointment" (Q2.3 already marked the message read, so Q3.7 changes 0 rows). | Q3.7 runs only when the page came from a message (D-034). | Write this rule into U3.1 step 6, or let Q3.7 mark the newest unread QN.3 message of the claim. |
| R-017 | 2.16 Q3.2; Figma U3-7 | Q3.2 reads only `Pending` or `Confirmed` appointments, but U3-7 shows the page again with the status `Cancelled`. After a reload the page has nothing to show. | The cancel answer gives the data from before Q3.6 with the status `Cancelled`; a reload says "There is no open appointment for this claim." | Accept this, or let Q3.2 also read the newest `Cancelled` appointment. |
| R-014 | 2.13 U3.1 step 3; Figma U3-2; 2.17 | "Onsite (at your house)", but `Appointment.location` (seed and QO4.3) is the consultant's office room, and the Consultant card shows that office. | The page shows "Onsite (at your house)" as written. | Decide what Onsite means, and change the text or the data. |
| R-016 | Figma U3-4; 2.16 Q3.4 | U3-4 shows six hours (no 12:00 and no 16:00) and grey taken hours, but Q3.4 gives only the free hours from 09:00 to 16:00. | The pop-up shows all eight hours; an hour that Q3.4 does not give is grey (D-037). | Make the frame and the query agree (lunch hour? last hour?). |
| R-025 | 2.17 seed | The seed has no `Pending` appointment, so U3.1 and U3.2 cannot be shown with the seed alone (an officer makes one with O4, which is not built yet). Seed claim 155 is also `Covered` with no EligibilityCheck or ClaimStatusHistory rows, so its Home card has no officer date and R-013 applies to it. | For the demo, a Pending appointment and its QN.3 message were added to the dev database by hand. | Add to the marked block of `seed.sql`: one Pending appointment with its QN.3 messages, and the check rows of claim 155. |

## Low: small conflicts

| ID | Where | Problem | What the code does now | Please decide |
|---|---|---|---|---|
| R-015 | 2.16 Q3.2; Figma U3-2 | Q3.2 gives `consultant_name` without `title_name` ("ธนา ศรีสุข"); U3-2 shows "นพ. ธนา ศรีสุข". U3-2 also shows "Office: SSO Rehabilitation Center, Building A, …", but `office_location` is only "Building A, Floor 3, Room 305". The Home card (Q2.4) does have the title. | The page shows the Q3.2 values. | Add `c.title_name` to Q3.2, and change the frame text. |
| R-023 | Figma U3-5; 05-states.md | U3-5 shows a Confirmed appointment with no buttons, but the state machine lets the user reschedule or cancel a Confirmed appointment, and Q3.5 and Q3.6 accept it. | Confirmed shows "Request Another Date" and "I cannot attend" (D-036). | Add the two buttons to U3-5, or remove the transitions from the state machine. |
| R-024 | 2.13 U3.2 step 5 | "Cancel" can be clicked only after a date is chosen, so a user who opens the pop-up by mistake cannot close it. | "Cancel" can always be clicked (D-037). | Change step 5. |

## Decisions the report can take over

| ID | Decision |
|---|---|
| D-008, D-028 | A guarded query that changes 0 rows answers HTTP 409. |
| D-029, D-031 | Officer decisions run in one transaction; inner transactions are SAVEPOINTs, so a refused decision leaves no half change. |
| D-032 | The U3 pages send the claim, and the controller finds the appointment with Q3.2 (which checks `insured_id`). Q3.3, Q3.5 and Q3.6 alone have no owner check. |
| D-035 | U3-1: a QN.3 message opens the Appointment Page and stays unread until the user chooses; other messages open as in U2. |
| D-036, D-037 | U3-2 buttons by status; U3-4 shows all hours with taken hours grey. |

## Notes (tools, not the spec)

- Flutter web loads the Thai font (Noto Sans Thai) from Google at run time. Without a network, Thai text shows as
  boxes. If the app must work offline, the font should be an asset of the app.
- In headless Chrome screenshots, a page sometimes shows before its data or its font arrives. The data and the
  routes were checked separately; they are correct.

## Questions for the team (short list)

1. R-013: change QO2.1 and QO3.1 so that 0 rows means only "refused"?
2. R-019: what happens to the claim after "I cannot attend"?
3. R-022: add the free-hour condition to Q3.5?
4. R-018: who is told about U3.1 to U3.3, and with which query?
5. R-014 and R-016: what does Onsite mean, and which hours can be booked?
6. R-025: add a Pending appointment and the check rows of claim 155 to the seed?
