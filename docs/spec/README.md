# SST spec pack

Extract of the SA report **SA Documents** for building the SST Injury Claim & Treatment Application
(ระบบยื่นคำร้องและนัดหมายการรักษากรณีประสบอันตราย, ศูนย์ฟื้นฟูผู้ป่วย สำนักงานประกันสังคม).
Generated on 2026-10-14 from the report as it stood that day. The report is the source of truth: if this pack
and the report disagree, the report wins, and the difference should be raised with the team.

Report: https://docs.google.com/document/d/1qg-tSl0xflyYIMIpSg_7QGSjlLTMwYC9Z2lKpnLsHHk/edit

| File | What it holds | Report section |
|---|---|---|
| `01-business-process.md` | To-be swimlane: 22 processes, which use case each one is, the decisions in the flow | 2.4 to 2.7 |
| `02-use-cases.md` | Use case list and every use case description, step by step, with the SQL each step runs (Thai) | 2.11, 2.13 |
| `03-sequence-flows.md` | Every sequence diagram as a numbered message list (participants, methods, Query IDs, alternate cases) | 2.13 |
| `04-classes.md` | MVC classes: abstract bases, pages, controllers, models, repositories, DBConnector, with attributes and methods | 2.18 |
| `05-states.md` | State machines of InjuryClaim, Appointment, Treatment and ConsultationReport, with the SQL of every transition | 2.19 |
| `06-screens.md` | The 52 screens (codes U1-1 ... C2.3-2), Figma links, site map notes, the two output reports | 2.21 to 2.23 |
| `07-open-questions.md` | Gaps the report leaves open (login, file storage, signatures, ...) and how the seed data was cleaned | n/a |
| `database/schema.sql` | PostgreSQL 16 DDL for the 19 tables, plus a stub of the external SSO register (`master_table`) | 2.17 |
| `database/seed.sql` | The report's sample rows (5 per table, minus 13 rows whose parents are not among the samples) | 2.17 |
| `database/queries.sql` | All 56 SQL statements with Query ID, use case ID and name | 2.16 |
| `database/data-dictionary.md` | Every attribute with key, NOT NULL, type and range / validation rule (Thai) | 2.17 |
| `diagrams/` | Use case diagram, CRUD table, business process, ER with queries, class, state, sequence and site map diagrams | various |

Checked on 2026-10-14 against PostgreSQL 16.15: `schema.sql` and `seed.sql` load without errors, and every
statement in `queries.sql` passes `EXPLAIN` against that schema (parameters replaced by NULL).

## Naming that ties code to the report

- **Use case IDs:** U1 to U6 (User), O1 to O6 (Evaluation Officer), C1 and C2 (Consultant). Sub-cases such as U3.1 to U3.3 are separate use case descriptions.
- **Query IDs:** Q1.1 to Q1.10 (U1), Q2.1 to Q2.3 (U2), Q3.1 to Q3.7 (U3), QU4.1 to QU4.3 (U4), QU5.1 (U5), Q6.1 (U6), QO1.1 to QO6.3 (officer), QC1.1 and QC2.1 to QC2.7 (consultant), QN.1 to QN.4 (notifications written by officer use cases). Mixed prefixes (Q6.1 vs QU5.1) are as in the report; keep them.
- **Screen codes:** `<use case>-<n>`, for example U1-2 or O4-3, matching the Figma frame names.
- **Class names** come from the sequence diagrams (`InjuryFormPage`, `InsuredFormController`, `InsuredPersonModel`, `InsuredPersonRepository`, `DBConnector`, ...).
