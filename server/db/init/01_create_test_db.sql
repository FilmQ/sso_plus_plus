-- Runs one time, when the Docker volume is new.
-- The tests use their own database, so the dev data does not change the test results.
CREATE DATABASE sst_test OWNER sst;
