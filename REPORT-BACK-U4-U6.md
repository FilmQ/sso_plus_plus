# Report back 3: U4, U5 and U6

From: the Claude Code session that built U4 to U6 (2026-10-17).
To: the team and the instance that keeps the SA report and `docs/spec/`.

## Context

Since report back 2 (`REPORT-BACK-U3.md`), the code takes in the U3 evening pack of 2026-10-15 and adds U4 Treatment
Confirmation (U4.1 Accept, U4.2 Change Date, U4.3 the automatic cancel), U5 View Appointment Schedule and U6 View
Treatment Schedule, on the server and in the user app. Commits `0ffe1dc` to `81f671c` on `develop`.

- The evening pack settles R-013 to R-025, and the code follows it (D-039, D-040).
- Every item has a reference to `docs/DECISIONS.md`: **R-xxx** is a report issue, **D-xxx** is the decision the code
  uses now. The code works around every item; no item blocks the app.
- Tests: 177 server tests and 91 Flutter tests pass. U4.1, U4.2, U5 and U6 were also run against the live server;
  the job (U4.3) ran when the server started.
- Checked in full for this report: U4.1 to U6 (use cases, sequences, classes, states, queries QU4.1 to Q6.1), and the
  Figma frames U4-1 to U4-5, U5-1 and U6-1. O1 to C2 are not checked yet.

## Business-process questions (the team must answer; the code does not decide them)

| ID | Report section | Question | What the code does now |
|---|---|---|---|
| R-028 | 2.13 U4.2 step 2; Figma U4-3 | Which dates can the user choose in "Request Another Date" (how many days ahead; weekends or not)? | From tomorrow to 14 days after the booked date, at the same hour, when the facility is free (QO5.2; D-042). |
| R-030 | 2.13 U4.2; 05-states.md (Treatment) | After "Change Date", must the user still click "Accept"? Is the officer told about the new date? | The treatment stays `Pending`; the page keeps both buttons; no message is sent. |
| R-035 | 2.5 (after U4.3); 2.16 QO5.1 | After the job cancels an unaccepted treatment, does the claim end, or can the officer book a new treatment? | QO5.1 lists the claim again, so the officer can book again. |

## High: the report is wrong or the process does not agree

| ID | Where | Problem | What the code does now | Please decide |
|---|---|---|---|---|
| R-029 | 2.16 QU4.2 | QU4.2 does not check that the facility is free at the new date and time, so two treatments can have the same slot. | `TreatmentModel.changeDate` accepts only a date of the available list (422; D-042). | Add the free-slot condition to QU4.2. |
| R-026 | 2.16 Q3.5; 2.17 `Appointment.schedule_time` | Q3.5 refuses a taken hour and a past time, but accepts any clock time (for example 12:30). | The Model refuses other hours (422; D-033). | Add the hour condition to Q3.5, as Q3.4 has it. |

## Medium: missing queries or data, frames that do not agree with the queries

| ID | Where | Problem | What the code does now | Please decide |
|---|---|---|---|---|
| R-028 | 2.13 U4.2 step 2 | "The system shows all free dates" has no query. | QO5.2 of O5.1 is used (D-042). | Add a query to U4.2, or name QO5.2 in step 2. |
| R-031 | Figma U4-1; 2.16 Q6.1; 2.17 | U4-1 shows Duration, the facility address, "Booked by" and "Report: Signed … by …". Treatment has no duration or address column, and no query gives the officer or the report. The report has no query that reads one treatment. | The page shows the Q6.1 row of the treatment: date, type, facility, claim ID, injury, injury date (D-041, D-045). | Remove the fields from U4-1, or add a page query (and columns for duration and address). |
| R-032 | Figma U5-1; 2.16 QU5.1 | U5-1 shows a status chip ("Confirmed", "Awaiting you"), but QU5.1 gives no `appointment_status`, and no `claim_id` to open the Appointment Page. | The cards have no chip and do not open. | Add `a.appointment_status` and `ic.claim_id` to QU5.1. |
| R-027 | 2.17 seed (dev block) | Appointment 510 is fixed on 22 October 2026. After that day the U3 demo shows a past appointment. | No change. | Give the demo rows dates relative to the load day. |
| R-034 | 2.17 seed | Treatment 403, the only `Pending` treatment, is fixed on 26 October 2026. After that day the job cancels it, and the U4 demo has nothing to accept. | No change. | Same as R-027. |

## Low: small conflicts

| ID | Where | Problem | What the code does now | Please decide |
|---|---|---|---|---|
| R-033 | Figma U6-1; 2.17 | U6-1 shows a picture and an address of the facility; the schema has only `facility_name`. | An icon banner, the facility name and the treatment type. | Remove the picture and address from U6-1, or add columns. |

## Decisions the report can take over

| ID | Decision |
|---|---|
| D-041 | The U4 page sends the treatment; the controller finds it with Q6.1 (which checks `insured_id`) and takes the claim from that row. QU4.1 and QU4.2 alone have no owner check. Both are guarded: 0 rows gives 409. |
| D-043 | `AutoCancelJob` runs QU4.3 once when the server starts and then every day at 00:05 Asia/Bangkok. |
| D-044 | U5 and U6 are the two tabs of one Schedule Page. |
| D-045 | U4-1 is opened from the Schedule Page, from a "Treatment booked" message and from Home; "Accept" and "Request Another Date" show only while `Pending`. |

## Questions for the team (short list)

1. R-028: which dates can the user choose in U4.2?
2. R-030: after U4.2, must the user still accept, and is the officer told?
3. R-035: after U4.3, does the claim end or can the officer book again?
4. R-029 and R-026: add the slot conditions to QU4.2 and Q3.5?
5. R-031 to R-033: change the frames U4-1, U5-1 and U6-1, or the queries?
6. R-027 and R-034: dates relative to the load day in the seed's demo block?
