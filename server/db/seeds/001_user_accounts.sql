-- Seed login accounts (docs/DECISIONS.md, D-003). Development data only.
-- The password of every seed account is Password123.
-- Users sign in with the national ID; staff sign in with the e-mail address.
INSERT INTO UserAccount (role, login_name, password_hash, insured_id, officer_id, consultant_id, created_at) VALUES
  ('USER', '1103700123456', crypt('Password123', gen_salt('bf', 8)), 101, NULL, NULL, NOW()),
  ('USER', '3120100234561', crypt('Password123', gen_salt('bf', 8)), 102, NULL, NULL, NOW()),
  ('USER', '1100800345672', crypt('Password123', gen_salt('bf', 8)), 103, NULL, NULL, NOW()),
  ('USER', '1209800456789', crypt('Password123', gen_salt('bf', 8)), 104, NULL, NULL, NOW()),
  ('USER', '1101500567893', crypt('Password123', gen_salt('bf', 8)), 105, NULL, NULL, NOW()),
  ('OFFICER', 'kanya.w@sso.go.th', crypt('Password123', gen_salt('bf', 8)), NULL, 1, NULL, NOW()),
  ('CONSULTANT', 'thana.s@ssorehab.go.th', crypt('Password123', gen_salt('bf', 8)), NULL, NULL, 1, NOW());
