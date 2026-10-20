# Report back 6: the C1 and C2 pack of 2026-10-19

From: the Claude Code session that applied the C1 and C2 pack (2026-10-20).
To: the team and the instance that keeps the SA report and `docs/spec/`.

Working rule: when an item below is a business-process question, the documentation agent asks the team before it
decides.

## Context

The code now follows the pack `sst-spec-c1.zip` (answer to report back 5). The pack is in `docs/spec/` and
`docs/CLAUDE_CODE_BRIEF.md`. `docs/DECISIONS.md` marks R-047 to R-055 as settled and has the new decisions D-060 to
D-062 and the new report issues R-056 to R-059.

- **Server:** the 62 statements of `queries.sql` (new QC1.2 and QC2.8; changed QC2.2 to QC2.7, QO5.1, QO6.1, QO6.2).
  New routes: `POST /c2/consultations/<id>/no-show`, `GET /c2/consultations/<id>/signature`,
  `GET /o6/reports/<id>/signature`. `GET /c1/appointments` also gives `recent_changes`. `.../draft` takes
  `recommended_treatment`; `.../sign` takes the signature as a PNG file.
- **Console:** C1-1 "Recent changes" card; C2.1 "Recommended treatment" field and "User did not attend" (C2.1-5,
  C2.1-6); C2.2 stores and shows the signature image; C2.3 says "Filed"; no version on any page; O6-2 and O6-3 show
  the signature image.
- **Seed:** the dev block of the pack (appointments 512 and 513, message 909). `make db-reset` also copies made-up
  signature images for the filed seed reports into `server/storage/reports/` (D-056).
- **Tests:** 221 server tests and 115 Flutter tests pass. `flutter analyze` and `dart analyze` find no issues. The
  real server was checked with curl against the dev database (C1, C2 list, O6 signature image). The console was not
  run in a browser.

## Business-process questions (the team must answer; the code does not decide them)

| ID | Report section | Question | What the code does now |
|---|---|---|---|
| R-056 | 2.13 C1 step 2.1; 2.16 QC1.2, QN.3 | C1 says that the "Recent changes" card shows the QN.5 messages (the user confirmed, moved or cancelled). QC1.2 reads every message to the consultant, so the QN.3 "New appointment" messages of O4 are in the card too. Is this correct, or must QC1.2 show only QN.5? | The card shows every QC1.2 row. "New appointment" has its own icon. |
| R-059 | 2.19 Appointment; 2.13 C2.1 Alternate Case 3 | `No show` is final. What happens when the consultant marks a no-show by mistake? | Nothing can undo it. The confirmation card (C2.1-5) is the only check. |
| R-060 | 2.13 C2.1 step 12.1; 2.16 QN.x | Must somebody be told about a no-show? QC2.8 sends no message. The user sees no change in the app (the claim stays `Covered`), and the officer sees the claim again only in the Scheduling list. | No message. The claim is in QO4.1 again. |
| R-061 | 2.5 business process; 2.13 O4 | Is there a limit on no-shows for one claim? A claim can go from O4 to a no-show and back to O4 with no end. | No limit. |
| D-061 | 2.13 C2.1 step 6.2; 2.16 QC2.4, QC2.5 | The field is "required". Is it required when the consultant saves the draft, or only when the report is filed? | The draft can be saved without a choice (QC2.4 and QC2.5 accept it). Filing needs it (QC2.7). |

## Report issues (documentation; the code works around them)

| ID | Where | Problem | What the code does now |
|---|---|---|---|
| R-057 | 2.13 C2.1 step 10; 2.16 QC2.1, QC2.3; Figma C2.1-5, C2.1-6 | The C2.1-5 text needs "[คำนำหน้าชื่อ ชื่อ และนามสกุลผู้ใช้งาน]" (Figma shows "นาย สมชาย ประเสริฐ"), but QC2.1 and QC2.3 give only `user_name` without the title. | The texts show the name without the title. Please add `ip.title_name` to QC2.3, or change the text. |
| R-058 | 2.16 QC2.5 | QC2.5 sets `recommended_treatment` to NULL when the parameter is empty. A save without a choice removes an earlier choice. | The page always sends the choice on the card. |
| - | `message-c1-pack.md`; README "Changes since the 2026-10-18 pack" | The pack lists QC2.3, QO6.1 and QO6.2 as the queries without `version_no`. QO5.1 also lost `version_no`. | The code follows `queries.sql`: O5.1 shows "Consultation report CR-0087" with no version. |

## Technical notes (no answer needed)

- **Signature file (D-060).** QC2.5 clears `signature_uri`, but the file `/reports/<session_id>/signature.png` stays in
  the file store until the next signature replaces it. A replaced report file also stays (as before). The file
  store is not part of the database transaction. The server refuses a signed report before it writes the file, so
  the image of a signed report does not change.
- **File report and recommendation (D-061).** "Finish the draft" with no text and no new file keeps the saved file
  of a file report. Thus the consultant can change only the recommendation. Every save runs QC2.5, so the
  consultant must sign again.
- **No-show and the open page (D-062).** The page runs QC2.2 when it opens a consultation, so a session row is
  there before the no-show. QC2.8 changes that row with `ON CONFLICT DO UPDATE`, as the pack says.
- **Test fix.** The Q3.5 repository test used the date "today + 12". On 2026-10-20 that date is a Sunday, and
  Q3.5 refuses weekends. The test now uses the next weekday. The test, not the code, was wrong.
- **Dev seed dates.** Appointment 512 is on the next weekday after the load day. After that day, the Schedule Page
  is empty until `make db-reset`.
