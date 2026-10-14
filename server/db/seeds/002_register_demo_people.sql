-- Demo rows for the SSO register stub (docs/DECISIONS.md, D-018). Development data only.
-- Every ACTIVE person of seed.sql is already registered, so U1 needs new ACTIVE people to succeed.
INSERT INTO master_table (national_id, title_name, first_name, last_name, coverage_status, employer_account_no, employer_name, registration_date, contribution_start, contribution_end, contribution_months) VALUES
  ('1555500011122', 'นาย', 'ทดลอง', 'ใจดี', 'ACTIVE', '1000123456', 'Siam Precision Parts Co., Ltd.', '2020-01-10', '2020-02-01', NULL, 80),
  ('2555500022233', 'นางสาว', 'มาลัย', 'รักงาน', 'ACTIVE', '1000888888', 'Rangsit Food Packing Co., Ltd.', '2022-04-01', '2022-05-01', NULL, 53);
