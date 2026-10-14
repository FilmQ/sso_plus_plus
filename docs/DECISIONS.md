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
