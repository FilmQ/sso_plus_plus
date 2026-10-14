# Decisions and deviations

Each entry tells what we decided, why, and which part of the SA report it affects, so that the team can write it
back into the report. `docs/spec/` does not change.

| ID | Date | Decision | Why | Report section |
|---|---|---|---|---|
| D-001 | 2026-10-14 | **Stack.** PostgreSQL 16 in Docker Compose; a Dart server (`shelf`, `postgres` package) for Controller, Model, Repository and `DBConnector`; Flutter (Material 3) for the user app and the console, on web and mobile. Tests: `dart test` and `flutter test`. This replaces the Node.js, Express and React default of the brief. | The team chose Flutter. A Flutter web app cannot open a PostgreSQL connection, so a server is necessary. A Dart server keeps one language. | 2.20 (Software platform) |
| D-002 | 2026-10-14 | **Client and server.** The Page classes are Flutter widgets. They call the server over HTTP (JSON). The Controller, Model, Repository and `DBConnector` classes are in the server, with the report's class and method names. | The report's MVC layers stay the same. Only the line between Page and Controller is a network call. | 2.13, 2.18 |
| D-004 | 2026-10-14 | **Migrations.** Migration 001 is `docs/spec/database/schema.sql` without changes. Infrastructure migrations are in `server/db/migrations/`, infrastructure seeds in `server/db/seeds/`. `dart run bin/migrate.dart` deletes the `public` schema and loads all files again. | One copy of the report's schema. The tool works the same for the dev and the test database. | 2.17 |
| D-005 | 2026-10-14 | **Test database.** The tests use a second database, `sst_test`. Each test file loads it again; each test runs in a transaction that rolls back. | The tests always start from the seed rows. Work in the dev database does not change the results. | 2.25 |
| D-006 | 2026-10-14 | **SQL text.** `server/tool/gen_sql.py` copies the 56 statements from `queries.sql` into `server/lib/repository/sql/`. The test `queries_match_report_test.dart` makes sure that they stay the same. A Query ID with more than one statement is a list; the Repository runs the list in one transaction. | Rule 2 of the brief: the SQL is the report's SQL. | 2.16 |
| D-007 | 2026-10-14 | **Parameters.** `DBConnector` changes `:name` to `$n` and sends the values without a type, so PostgreSQL finds the type from the SQL. String literals, comments and `::type` casts do not change. | The SQL text stays as in the report. | 2.16 |
| D-008 | 2026-10-14 | **Guarded Query IDs.** In Q3.3, Q3.5, Q3.6, QO3.2 and QO5.4, one UPDATE (or INSERT ... SELECT) has a status condition, but the other statements of the same Query ID do not. If the guarded statement changes no row, the Repository rolls back all statements and throws `NoRowChangedException`. | Without this, for example Q3.3 on a Confirmed appointment adds a second `AppointmentConfirmation` row. The SQL text does not change. | 2.16, 2.19 |
| D-009 | 2026-10-14 | **Q3.1.** The class list has no method for Q3.1 (the same SQL as Q2.1). It is `NotificationRepository.countUnreadOnNotificationPage`. | Rule: all 56 queries are Repository methods. | 2.18 |
| D-010 | 2026-10-14 | **Session values as parameters.** Methods whose SQL needs `:officer_id` or `:consultant_id` (for example `ClaimRepository.saveResult`, `ReportRepository.updateSignedAt`) have that value as an extra parameter. The Controller takes it from the login session. | The class diagram leaves these parameters out; the SQL needs them. | 2.18 |
| D-011 | 2026-10-14 | **QO5.2 dates.** `findFacilitySlots(facility, dates, officer_id)` takes `dateFrom` and `dateTo`, the `:date_from` and `:date_to` of the SQL. | The SQL has two dates. | 2.18 |

## Report issues found while building

Things in the report that look wrong or do not agree. The code works around them as written here. Please check them
in the report.

| ID | Where | Issue | What the code does |
|---|---|---|---|
| R-001 | 2.16, `queries.sql` Q3.7 and QN.1 | The header of Q3.7 and QN.1 continues on lines without `--` (`ยืนยันนัดหมาย (Request Another Date)`, `นัดหมายการรักษา (Book Treatment)`). The file is not valid SQL there. | The generator and the test skip the lines before the first SQL keyword. |
| R-002 | 2.16, Q3.3, Q3.5, Q3.6, QO3.2, QO5.4 | Only one statement of each block has the status guard (see D-008). | D-008. |
