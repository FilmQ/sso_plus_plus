# Implementation Plan — SSO Plus Plus

SST — Injury Claim and Treatment Application.

This document tells you how to build the application. Read it before you write code.
It is written in ASD-STE100 Simplified Technical English, as `CLAUDE.md` demands.

## 1. Sources

Three sources hold the requirements. The code holds none of them yet.

| Source | Content |
| --- | --- |
| `CLAUDE.md` | Material 3, web and mobile, short files, component reuse, repository rule |
| Figma, page `01 · Mobile — User App` | 9 patient screens, M1 to M9 |
| Figma, page `02 · Desktop — Officer & Consultant Console` (node `6:2`) | 8 console screens, D1 to D8, at 1440x900 |
| Google Slides deck | 11 use cases (UC-01 to UC-11), 3 actors, rules BR-01 to BR-33 |

## 2. Actors, surfaces and scope

The application has **two separate surfaces**. Each actor uses one surface only.

| Actor | Surface | Platform |
| --- | --- | --- |
| User (the injured insured worker) | Patient app | Mobile only. **No web.** |
| Evaluation Officer | Staff console | Web only |
| Consultant | Staff console | Web only |

A patient never uses a browser. An officer and a consultant never use the mobile app. The
officer and the consultant share one console and one set of console widgets. They see
different route sets in it.

Build all 11 use cases as service classes. The Figma file supplies every screen: page 01
holds the 9 patient screens (M1 to M9) and page 02 holds the 8 console screens (D1 to D8).
The 17 screens cover the 11 use cases with nothing left to invent.

## 3. Architecture

### 3.1 The dependency rule

```
pages  →  providers  →  use-cases  →  repository interfaces
                                              ↑
                                    in-memory implementations
```

Dependencies point one way only. Only `lib/providers/` imports Riverpod **and** a concrete
repository. This one rule keeps the layers apart.

### 3.2 The repository seam

`CLAUDE.md` says to decouple the service layer from the repository layer, because the table
schemas are not complete. The seam is this:

- `lib/use-cases/` **must not import Flutter or Riverpod.** It must not import a concrete
  repository. It imports repository interfaces only.
- Each use-case class takes its repository interfaces through its constructor.
- `lib/repository/` holds the abstract interface **and** the hardcoded implementation.
  `CLAUDE.md` makes this folder the home of the data. Do not add a `lib/domain/` folder.

When the schemas become complete, write a new class against the same interface. Then change
one line in `lib/providers/repository_providers.dart`. The use cases, the models and the
pages do not change.

### 3.3 Repositories

Split the repositories by aggregate, not by use case. Five interfaces:

| Interface | Holds |
| --- | --- |
| `ClaimRepository` | Claims, documents, drafts |
| `InsuredRegisterRepository` | The SSO Section 33 register (UC-02) |
| `SchedulingRepository` | Consultants, slots, appointments, treatment dates |
| `ConsultationRepository` | Sessions and reports |
| `NoticeRepository` | The user inbox |

An earlier draft of this plan named a sixth interface, `TreatmentRepository`.
It is not necessary. One `Appointment` entity carries the `kind` field, so
`SchedulingRepository` holds a treatment date and a consultation date in the
same way.

All six hardcoded implementations share one mutable `DemoStore`. Put them in
`lib/repository/memory/`. Put the seed data in `lib/repository/memory/seed_data.dart`.

**Both surfaces boot the same seed data.** Section 13 explains why this matters.

### 3.4 Two entry points, one codebase

The two surfaces are two builds from one `lib/`. The models, the repositories and the 11
use cases are shared. The pages, the widgets and the router are not.

| Entry point | Surface | Build command |
| --- | --- | --- |
| `lib/main.dart` | Patient app | `flutter build apk` (the default target) |
| `lib/main_console.dart` | Staff console | `flutter build web --release -t lib/main_console.dart` |

The mobile build carries no console code. The web build carries no patient screens. Each
entry point holds its own `MaterialApp.router` and its own `GoRouter`. Neither router needs
a role redirect, because the platform already decides the surface.

Do not make two Flutter projects. That would duplicate the models, the repositories and the
11 use-case classes.

### 3.5 Directory layout

```
lib/
  main.dart                        Patient app entry. Mobile.
  main_console.dart                Staff console entry. Web.
  models/                          Immutable entities. Pure Dart. Shared.
  repository/
    claim_repository.dart          Abstract interface
    ...                            The other five interfaces
    memory/
      demo_store.dart              One mutable store
      seed_data.dart               Demo data for both surfaces
      in_memory_*.dart             The six implementations
  use-cases/
    claim_rules.dart               The BR-xx values and predicates
    uc_01_submit_injury_application.dart
    ...                            One file for each use case
    uc_11_schedule_treatment.dart
  providers/
    repository_providers.dart      Shared. The only place a backend swap touches.
    use_case_providers.dart        Shared. All 11.
    session_provider.dart          Console only. Officer or consultant.
    patient_router.dart
    console_router.dart
    *_provider.dart                One read model for each screen group
  pages/
    patient/                       M1 to M9
    console/
      officer/                     The officer worklists
      clinic/                      The consultant pages
  widgets/
    app_theme.dart                 Shared by both entry points
    shared/                        Components both surfaces use
    patient/                       Patient-only components
    console/                       Console-only components
```

Keep the hyphen in `use-cases`. A rename changes the CI and `CLAUDE.md` for no gain.

## 4. Domain model

### 4.1 Entities

`Actor`, `InsuredRegistration`, `Claim`, `InjuryDetails`, `ClaimDocument`,
`EligibilityVerification`, `RejectionNotice`, `Consultant`, `AppointmentSlot`,
`Appointment`, `ContactAttempt`, `ConsultationSession`, `ConsultationReport`,
`TreatmentBooking`, `Notice`, `WaitingListEntry`.

Rules for entities:

- Make them immutable. Give each one `copyWith`, `==` and `hashCode`.
- Riverpod 3 uses `==` to find a change. An entity without `==` causes unnecessary builds.
- Keep Flutter out of `lib/models/`. Keep JSON out of it too.
- `InjuryDetails.category` controls the specialty match in UC-04 (BR-11).

Use **one** `Appointment` entity with a `kind` field for the consultation and for the
treatment. UC-11 says the UC-05 confirmation cycle also applies to the treatment. Two
entities would repeat that cycle.

### 4.2 State machines

Write each machine as an enum and a `canTransition` table. An illegal transition must throw.

**Claim**

```
draft → submitted → awaitingVerification → verified{covered | notCovered | needsReview}
notCovered → rejected → appealed | resubmitted
covered → appointmentProposed → confirmed → consultationCompleted
        → reportSigned → treatmentScheduled → closed
```

**Appointment**

```
awaitingConfirmation[provisional] → confirmed | anotherDateRequested | expired
expired → phoneAttempted* → unreachable → rescheduled(n++) → escalated
```

**Slot**: `open → held → booked → released`. A slot may be held against one claim only (BR-12).

**Report**: `draft → signed(v1) → superseded(v2)`. A signed report is immutable (BR-28).

## 5. The use-case layer

One file for each use case. Each file holds one class, one public method, and one
`sealed class UcNNResult`. The subclasses of that result are the alternate flows from the
deck. For example, UC-01 returns `Submitted`, `SavedAsDraft`, `MissingRequiredField` or
`DuplicateOpenClaim`.

Give each use case an injected `DateTime Function() clock`. Section 13 explains why.

All 11 classes are in the shared `lib/use-cases/`. Both builds link them. Each build calls
only the ones its actor needs.

| ID | File | Primary actor | Surface and screen |
| --- | --- | --- | --- |
| UC-01 | `uc_01_submit_injury_application.dart` | User | Patient: M2, M3, M4 |
| UC-02 | `uc_02_verify_section_33_eligibility.dart` | Officer | Console: D1, D2 |
| UC-03 | `uc_03_reject_application.dart` | System | Console: D2. Patient: M5 |
| UC-04 | `uc_04_schedule_appointment.dart` | Officer | Console: D3 |
| UC-05 | `uc_05_confirm_appointment.dart` | User | Patient: M6, M7 |
| UC-06 | `uc_06_confirm_appointment_by_phone.dart` | Officer | Console: D4 |
| UC-07 | `uc_07_reschedule_appointment.dart` | Officer | Console: D4 |
| UC-08 | `uc_08_arrange_consultation.dart` | Officer | Console: D5 |
| UC-09 | `uc_09_conduct_consultation.dart` | Consultant | Console: D6 |
| UC-10 | `uc_10_generate_consultation_report.dart` | System | Console: D7. Patient: M8 |
| UC-11 | `uc_11_schedule_treatment.dart` | Consultant | Console: D8. Patient: M9 |

Put the shared business rules in `lib/use-cases/claim_rules.dart`. Do not repeat a rule in
11 files. This file holds the confirmation window, the reschedule limit, the call attempt
limit, and the BR-xx predicates.

## 6. State management — Riverpod

The project uses `flutter_riverpod: ^3.4.2`.

### 6.1 Write the providers by hand

Do not add code generation. The pubspec has no `build_runner`. The CI never runs a
generator. `dart format --set-exit-if-changed` fails on generated files. About 20 providers
do not justify a build step.

### 6.2 Riverpod 3 facts

These facts come from the installed `riverpod-3.4.2` package. They are not from memory.

- `StateProvider` and `StateNotifierProvider` moved to
  `package:flutter_riverpod/legacy.dart`. **Do not use them.** Use `Notifier` and
  `AsyncNotifier` with `NotifierProvider` and `AsyncNotifierProvider`.
- `FamilyNotifier` is removed. A family notifier receives its argument through its
  constructor.
- Auto-dispose is a flag: `Provider(..., isAutoDispose: true)`.
- A provider that fails retries automatically. Pass `retry:` to stop the retry.
- `Mutation` is experimental. Do not use it in this project.

### 6.3 Provider topology

| File | Surface | Holds |
| --- | --- | --- |
| `repository_providers.dart` | Both | `demoStoreProvider`, and one provider for each repository |
| `use_case_providers.dart` | Both | 11 providers, one line each |
| `session_provider.dart` | Console | The staff member whom the rail names, and whom a decision is recorded against |
| Patient read models | Patient | `claimListProvider`, `claimDetailProvider` (family), `inboxProvider`, `appointmentProvider` |
| Console read models | Console | `verificationWorklistProvider`, `schedulingWorklistProvider`, `unconfirmedWorklistProvider`, `consultationQueueProvider`, `sessionQueueProvider`, `reportQueueProvider`, `treatmentQueueProvider`, `railCountsProvider` |

`session_provider` supplies the identity that BR-06, BR-13 and BR-29 demand on a record. It
does **not** select the rail, because section 7.2 shows every destination at all times.

`railCountsProvider` supplies the seven numbers that the rail shows.

The patient app needs no `session_provider`. It has one actor.

Make one read model for each screen group. Do not make one for each widget.

**Rule: a provider holds no business logic.** A notifier method calls the use case, then
calls `ref.invalidateSelf()`. The use case does the work.

## 7. Navigation and layout

Each surface has its own router. There is no role redirect between them, and no shared
shell. The platform decides the surface.

### 7.1 Patient app — phone only

`lib/providers/patient_router.dart`. Use `StatefulShellRoute.indexedStack` with four
branches: `/home`, `/claims`, `/appointments`, `/inbox`.

The shell shows a Material 3 `NavigationBar` at the bottom, exactly as the Figma design
shows it. **Build one layout only.** The patient app runs on a phone. Do not build a
`NavigationRail`, and do not build a wide layout. The Figma frames are 390x844 and that is
the target.

### 7.2 Staff console — desktop web only

`lib/providers/console_router.dart`. Figma page 02 fixes the layout. The frames are
1440x900, so the console assumes a window of **1024 pixels or more**. Build one layout.
**Do not build a compact fallback.** Give the console a minimum content width of 1024 and
let the page scroll sideways below that. A narrow window is not a supported case.

**The rail shows every destination at all times.** The design puts two labelled groups in
one extended `NavigationRail`, and each destination carries a count:

| Group | Destinations, with the count in the design |
| --- | --- |
| `EVALUATION OFFICER` | Verification 12, Scheduling 7, Confirmations 4, Consultations 5 |
| `CONSULTANT` | Sessions 3, Reports 2, Treatment 1 |

Above the groups the rail shows the words `SST Console · Social Security Office`. Below
them it shows the person: a round monogram, a name, and the words
`Evaluation Officer · Bangkok 3`, with a sign-out button.

This corrects an earlier assumption in this plan. The rail does **not** change with the
role, and `session_provider` does **not** hide a group. Access control stays where section
13 puts it, in the repository (BR-22). The person is a label in the rail, not a filter on
it.

Routes, one for each destination and its detail:

| Route | Screen |
| --- | --- |
| `/officer/verification` | D1 |
| `/officer/verification/:claimNumber` | D2 |
| `/officer/scheduling` and `/officer/scheduling/:claimNumber` | D3 |
| `/officer/confirmations` | D4 |
| `/officer/consultations/:claimNumber` | D5 |
| `/clinic/sessions/:sessionId` | D6 |
| `/clinic/reports/:reportId` | D7 |
| `/clinic/treatment/:claimNumber` | D8 |

### 7.3 The two console page shapes

Every console screen is the rail, a top bar, and one of two bodies.

The **top bar** holds a title and a subtitle. A worklist adds a search box. Every screen
ends the bar with a notification button and a help button.

**A worklist** (D1, D4) holds a row of KPI tiles, then one full-width panel. The panel has
a heading, filter chips, a table, and a footer that reads
`Showing 5 of 12 · sorted by oldest submission` with a page control.

**A detail page** (D2, D3, D5, D6, D7, D8) starts with a breadcrumb, for example
`← Verification › CLM-2569-0143`. Below it two columns stand side by side:

- The **left column is the context**, and it is the wider one. It holds the claim summary,
  the documents and the case file.
- The **right column is the action**. It holds the decision, the slot picker or the form,
  and it ends with a filled button and an outlined or red button.

A worklist and its detail are **two pages, not two panes**. The earlier plan named a
`TwoPaneScaffold` that holds a list beside a detail. The design does not work that way.
The two columns of a detail page are context and action, not list and detail.

### 7.4 The eight console screens

Figma page 02 is `02 · Desktop — Officer & Consultant Console`. It holds eight frames at
1440x900. They cover the eight use cases that the patient application does not.

**D1 · Officer — verification worklist (UC-02).** Four KPI tiles: `Awaiting verification`,
`Needs review`, `Register unavailable`, `Verified this week`. Then the panel
`Claims awaiting verification` with the chips All, Needs review and Overdue, and a table.
The columns are Claim / claimant, Injury date, Submitted, Docs, Register result, Status and
an `Open` button. `Docs` reads `3 / 3` or `2 / 3`. `Register result` is a badge: Covered,
Needs review, Not covered or Register down.

**D2 · Officer — eligibility decision (UC-02 → UC-03).** Left: a `Claim summary` card with
National ID, Employer on claim, Date of injury, Place, Cause and Part of body; then
`Documents lodged with the claim`, each row with its file name, its size and a `View`
button. Right: `Section 33 eligibility` with the automatic result and its evidence
(contribution period, employer in register, when the register answered and how long it
took). Below it `Officer decision` offers three choices — **Confirm — covered under Section
33**, **Not covered**, **Needs review** — each with a line that says what follows, then an
`Override reason` field and the buttons `Confirm result` and `Reject claim`.

**D3 · Officer — schedule appointment (UC-04).** A `claim context` card that names the
consultant specialty the injury needs, an `availability` panel of open slots, and an
`offer` card that holds the appointment to offer.

**D4 · Officer — phone confirmation fallback (UC-06 → UC-07).** A banner that reads
`31 of 38 appointments…`, which is the measure the deck asks for. Then an `unconfirmed`
table, and a `call panel` card with the claimant and the telephone number, an
`Attempt history`, a `Reply as the claimant` part, a `Note` field, and two buttons.

**D5 · Officer — arrange consultation (UC-08).** Cards for the confirmed appointment, the
case file, the `Session` (with a segmented button for the format, room or
tele-consultation) and `Assigned consultant`, with a release button.

**D6 · Consultant — consultation session (UC-09).** A `In progress · 00:1…` badge that
counts the session time. Cards for the patient, the injury and the case file. Then a
`record` card that says `Only the attending…` (BR-25) with the fields `Findings *`,
`Diagnosis *`, `Recommended treatment *` and `Fitness for work`. The star marks a mandatory
field. An `Other outcomes` card carries non-attendance and referral back.

**D7 · Consultant — report sign-off (UC-10).** A `Draft · unsigned` badge and a report
preview with Findings, Diagnosis, Recommended treatment and **Fitness for work**. A
`Before signing` card of checks, then sign and amend buttons. Two banners state that
signing locks the version and that the patient then sees it.

**D8 · Consultant — schedule treatment (UC-11).** A `recommendation` card that quotes the
signed report, a `booking` card with a `Facility` field and slots, and a `Booking summary`.
Banners state what happens when no slot falls inside the period, that the date is written
into the application at once (BR-32), and that the UC-05 cycle applies if the patient
cannot attend.

**The design names its own rules.** D2 quotes BR-05 and BR-06, D6 quotes BR-25 and D8
quotes BR-32. Keep that text. It agrees with `claim_rules.dart`.

**One field is new.** `Fitness for work` appears on D6 and D7. The deck does not name it
and `ConsultationReport` does not hold it. Add it in P5.

### 7.5 Breakpoints

There are none. Each surface has one layout. No file needs a width check.

This replaces an earlier plan for a responsive shell. The split by platform removed the
need for it.

## 8. Shared widgets

`CLAUDE.md` demands component reuse and short files. Build these widgets first. Then build
the screens from them.

### 8.1 `widgets/shared/` — both surfaces

| Widget | Used by |
| --- | --- |
| `InfoCard` | All screens on both surfaces |
| `DetailRow` (icon, label, value) | M1, M4, M5, M6, M7, M9, and the console claim detail |
| `ClaimStatusBadge` | M1, M5, M7, M8, M9, and every console worklist |
| `SectionHeading` | M1, M4, M5, M7, M9, and the console detail pages |
| `ProgressStepper` and `ProgressStep` | M1, and the console audit trail |
| `DocumentChecklistRow` | M3, and the console claim detail |
| `ReportSection` (title and body) | M8 three times, and the consultant form |
| `AsyncValueView<T>` | Everywhere |
| `EmptyState` | Everywhere |

### 8.2 `widgets/patient/` — mobile only

| Widget | Screens |
| --- | --- |
| `AppointmentCard` (a `kind` field covers the treatment) | M6, M7, M9 |
| `NoticeBanner` | M3 to M9 |
| `StepProgressHeader` (step text and `LinearProgressIndicator`) | M2, M3 |
| `FormTextField` (label and helper text) | M2, six times |
| `ActionBar` (a text button and a filled button) | M2, M3, M5 |
| `ActionStack` (filled, outlined, text, caption) | M6, M9 |
| `PatientAppBar` | All patient screens |

### 8.3 `widgets/console/` — web only

Figma page 02 fixes this list. Build the frame widgets first, then the four screens of each
role are mostly an arrangement of them.

| Widget | Screens |
| --- | --- |
| `ConsoleRail` (brand, two labelled groups, counts, person card) | All |
| `ConsoleTopBar` (title, subtitle, optional search, two icon buttons) | All |
| `WorklistScaffold` (KPI row and one panel) | D1, D4 |
| `DetailScaffold` (breadcrumb, then a context column and an action column) | D2, D3, D5, D6, D7, D8 |
| `KpiTile` (label, large number, tone) | D1, four of them |
| `WorklistTable`, with its header, rows and footer | D1, D4 |
| `FilterChipRow` | D1 |
| `TablePager` (`Showing 5 of 12` and the page control) | D1, D4 |
| `DecisionCard` (choices, reason field, confirm and reject) | D2 |
| `DocumentRow` (name, size, `View`) | D2, D5, D6 |
| `SlotPicker` | D3, D8 |
| `CallAttemptLog` | D4 |
| `ClinicalFieldsForm` (the four fields of D6, with the mandatory mark) | D6 |
| `ReportPreview` | D7 |

`DetailScaffold` has one layout. It needs no compact branch.

**Move `NoticeBanner` from `widgets/patient/` to `widgets/shared/`.** Every console screen
carries at least one banner, and D7 and D8 carry two. The widget does not change, only its
folder and the imports of the nine patient screens.

## 9. Theme

Put the theme in `lib/widgets/app_theme.dart`. Both entry points use it. Build it from the
deep purple seed colour that `main.dart` uses now. That colour agrees with the Figma design.

Figma declares no variables or tokens. The seed colour is therefore the only source. Supply
a light theme and a dark theme. Use `ColorScheme.fromSeed`.

## 10. Build phases

Each phase must leave both builds runnable and the CI green.

**P0 — Make the CI green and split the entry points.**

Done:
- The default counter test is replaced by a smoke test of the patient app. The CI Linux job
  is green.
- `.github/workflows/flutter.yml` has an `ios` job. It runs on `macos-latest`, because iOS
  needs Xcode and the other job runs on Linux. It runs
  `flutter build ios --debug --no-codesign`, because the CI holds no signing certificate.
  The job waits for the Linux job (`needs: test`), because a macOS runner costs much more.

- `go_router` is in the pubspec, `app_theme.dart` supplies the light and dark themes, and
  `lib/main.dart` is the patient `MaterialApp.router`.

Still to do:
- Add `lib/main_console.dart` with the console `MaterialApp.router`.
- Add `flutter build web --release -t lib/main_console.dart` to the workflow. **Add this
  step only after `lib/main_console.dart` exists.** The step fails without that file. The
  existing APK and appbundle steps already build the patient app from the default target.

**P1 — Data. Done.** The models, the five interfaces, the hardcoded implementations, and
the seed data. The injected `clock` reads from `DemoStore.now`, which a demo can move
forward with `advanceBy`.

**P2 — Patient use cases. Done.** UC-01, UC-03 and UC-05, their providers, and the patient
router. UC-02, UC-04 and UC-06 to UC-11 are officer and consultant work. They arrive with
the console.

**P3 — Patient screens. Done.** All nine screens, M1 to M9, built from the shared widgets
of section 8. The patient application is complete and demonstrable.

**P4 — Officer console. Done.** `lib/main_console.dart`, the console router, `ConsoleRail`,
`ConsoleTopBar`, `WorklistBody` and `DetailBody`. UC-02, UC-04, UC-06, UC-07 and UC-08 with
screens D1 to D5. `NoticeBanner` moved to `widgets/shared/`. The CI now builds the web
console.

**P5 — Clinical console. Done.** UC-09, UC-10 and UC-11 with screens D6, D7 and D8.
`ConsultationSession` and `ConsultationReport` carry the `Fitness for work` field that D6
and D7 show.

Three points where the build is not what this plan first said:

- **`ShellRoute`, not `StatefulShellRoute.indexedStack`.** The console has seven
  destinations and each one has a detail route. An indexed stack of seven branches is a
  large amount of code for one gain: a scroll position that each branch keeps. The rail
  reads the current location instead. The patient application still uses
  `StatefulShellRoute`, where four branches and a bottom bar make it worth the code.
- **Five queue screens are not in the design.** The design draws the detail of D3, D5, D6,
  D7 and D8, but a rail destination must open a list first. `pages/console/queue_pages.dart`
  holds all five, and they share one private layout and the same `WorklistPanel` as D1 and
  D4.
- **The console keeps the Flutter hash URL, for example `/#/officer/verification`.** A path
  URL needs the web server to send every path to `index.html`. A demonstration is served
  from a folder, where that rewrite does not exist and a reload of a deep link gives 404.
  The URL is still readable, and the browser back button works.

**P6 — Finish.** The empty states and error states that remain, and the demo control that
moves the clock forward.

Run `dart format . && flutter analyze && flutter test` before each commit. The CI fails on
format alone.

## 11. Tests

Write these tests:

- One unit test file for each use case. Test the main flow and one alternate flow against
  the hardcoded repositories. About 22 tests. These tests show the guarantees from the deck.
- One transition-table test. An illegal transition must throw.
- One smoke test for each entry point. The patient app must build its `NavigationBar`. The
  console must build its rail and two panes.
- Three to five widget tests for the screens with logic in them. Use
  `ProviderScope(overrides: [...])`.

Do not write these tests: golden tests (the CI fonts drift), tests of presentational cards,
or a responsive test. Each surface has one layout, so there is nothing to test at a second
width. Do not add a mock package. The hardcoded repositories are the mocks.

## 12. Open points

Decide these points and record the decision. The deck does not answer them.

1. What happens to a claim while its result is "Needs review".
2. The confirmation window, the reschedule limit, and the call attempt limit. The deck gives
   no numbers. Choose them in `claim_rules.dart`. Show them in the UI captions.
3. An appeal reads as a reopen and also as a new claim. The fields `reopenedFrom` and
   `supersededBy` support both. Choose one for the demo.
4. Nobody closes the claim after the treatment. Choose the owner of that step.
5. **`Verified this week` counts from the demo clock.** The other six rail counts and
   three KPI tiles count the rows of the screen they point at, so the rail and the screen
   always agree. `Verified this week` has no such source: it counts the claims an officer
   decided in the seven days before `DemoStore.now`. Confirm that the office measures it
   the same way.

### Closed points

**Figma page 02 cannot be read.** Closed. Page 02 is node `6:2` of the same file,
`02 · Desktop — Officer & Consultant Console`. Sections 7.2 to 7.4 and 8.3 come from it.

Keep the lesson. `get_metadata` with no node lists the pages of a document, and it listed
page 01 only, twice, one hour apart. A node identifier from the browser address bar reached
page 02 at once. The listing was incomplete, not the file. **Address a Figma page by its
node identifier. Do not trust the page listing.**

**iOS is not built.** Closed. See section 10, phase P0.

## 13. Risks

| Risk | Answer |
| --- | --- |
| **The two builds cannot share state.** They are separate programs with separate in-memory stores. An officer who verifies a claim in the console will **never** see that change reach the patient app. | Seed both builds from the same `seed_data.dart`, with claims at every stage of the lifecycle. Show the patient submitting a claim, then open the console, where a claim is already waiting in the verification worklist. The story reads end-to-end even though no data crosses. Plan the demo script around this. |
| The console rail shows the work of both roles at once | That is what the design does, so keep it. The rail names one person at its foot, and that identity goes on every record (BR-06, BR-13, BR-29). Add a demo control to change that person. The patient app needs no such control. |
| Free actor changes hide the access control | Enforce BR-22 (a consultant sees only their own claims) **in the repository**, not only in the router. |
| The deadline flow (UC-05 → UC-06 → UC-07) cannot run in real time | Use the injected `clock`. Add a console demo control that expires a deadline. Build this in P1, not in P6. |
| Riverpod 3 retries a failed provider and hides a demo error | The UC-01 connection-loss flow throws on purpose. Set `retry:` to null on those providers. |
| The console state resets on each web reload | Make the seed data rich. Do not build the demo state by clicks. |
| A wrong build target ships the wrong app | The web build **must** pass `-t lib/main_console.dart`. Without the flag it builds the patient app for the browser, which is not a supported surface. |
| STE is not enforceable by the linter | Make short doc comments a review item. One instruction for each sentence. |

## 14. Verification

1. `flutter analyze` — no issues.
2. `flutter test` — all tests pass. The default counter test is gone.
3. `dart format --output=none --set-exit-if-changed .` — no change.
4. `flutter run` on an Android emulator or an iOS simulator — the patient flow runs from M1
   to M9 with the bottom navigation bar. To start an iOS simulator first, use
   `xcrun simctl boot 'iPhone 17 Pro'` and then `open -a Simulator`.
   To open the application at one screen, give the route on the command line:
   `flutter run --dart-define=START_AT=/appointments/APT-0143-1`.
   The seed supplies `/claims/CLM-2569-0143` (waiting), `/claims/CLM-2569-0118` (refused),
   `/claims/CLM-2569-0091/report` (signed) and `/appointments/APT-0091-2` (treatment).
5. `flutter run -d chrome -t lib/main_console.dart` — the console opens on the verification
   worklist. The URL changes with the page and the browser back button works.
6. Walk the console from end to end: open a claim from D1, confirm the result, give the
   claim a date in Scheduling, record a telephone reply in Confirmations, release the case
   file in Consultations, then change the member of staff at the foot of the rail to the
   consultant and complete a session, sign its report and book the treatment.
7. These builds all pass:
   - `flutter build apk --debug`
   - `flutter build ios --debug --no-codesign`
   - `flutter build web --release -t lib/main_console.dart`
8. Compare the console screens against Figma page 02.

## 15. Out of scope

- **A web interface for patients.** Patients use the mobile app only.
- **A mobile interface for staff.** Officers and consultants use the web console only.
- No real backend. No authentication. No database. No push notifications. `CLAUDE.md` holds
  these back until the table schemas are complete.
