# SST Injury Claim & Treatment Application: run, lint and test commands.
# Read README.md for the first-time setup.

API_BASE_URL ?= http://localhost:8080

.PHONY: db-up db-down db-reset db-reset-test server app console lint test test-server test-app

db-up:            ## Start PostgreSQL 16 (Docker Compose).
	docker compose up -d --wait

db-down:          ## Stop PostgreSQL. The data stays in the Docker volume.
	docker compose down

db-reset:         ## Load the schema and the seed into the dev database again.
	cd server && dart run bin/migrate.dart

db-reset-test:    ## Load the schema and the seed into the test database again.
	cd server && dart run bin/migrate.dart --test

server:           ## Start the API server on port 8080.
	cd server && dart run bin/server.dart

app:              ## Start the user app (phone layout) in Chrome.
	flutter run -d chrome -t lib/main.dart --dart-define=API_BASE_URL=$(API_BASE_URL)

console:          ## Start the officer and consultant console in Chrome.
	flutter run -d chrome -t lib/main_console.dart --dart-define=API_BASE_URL=$(API_BASE_URL)

lint:             ## Static analysis of the server and the Flutter app.
	cd server && dart analyze
	flutter analyze

test: test-server test-app

test-server:      ## Server tests. They need `make db-up`. They reset the test database.
	cd server && dart test

test-app:         ## Flutter widget tests.
	flutter test
