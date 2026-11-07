import 'package:sst_server/db/migrator.dart';
import 'package:test/test.dart';

import '../support/test_db.dart';

/// `make db-demo` (D-066): the extra rows load and agree with the rules of the
/// app. The next test file loads the test database again without these rows.
void main() {
  final db = useTestDb();

  setUpAll(() => Migrator(db).loadDemoData());

  Future<int> count(String sql) async => (await db.performQuery(sql)).rows.single.values.single! as int;

  test('each claim status has the planned quantity of claims', () async {
    final rows = (await db.performQuery('''
      SELECT claim_status, COUNT(*)::int AS n FROM InjuryClaim WHERE claim_id > 164 GROUP BY claim_status''')).rows;
    expect({for (final r in rows) r['claim_status']: r['n']}, {
      'Awaiting verification': 12,
      'Register unavailable': 3,
      'Covered': 59,
      'Rejected': 5,
      'No treatment required': 3,
      'Withdrawn': 4,
    });
  });

  test('no two active appointments use the same consultant and slot', () async {
    expect(await count('''
      SELECT COUNT(*)::int FROM (
        SELECT 1 FROM Appointment WHERE appointment_status IN ('Pending', 'Confirmed')
        GROUP BY consultant_id, schedule_date, schedule_time HAVING COUNT(*) > 1) d'''), 0);
  });

  test('appointments and treatments are on weekdays in the allowed hours', () async {
    expect(await count('''
      SELECT COUNT(*)::int FROM Appointment WHERE appointment_id > 513 AND (EXTRACT(ISODOW FROM schedule_date) > 5
        OR schedule_time NOT IN (TIME '09:00', TIME '10:00', TIME '11:00', TIME '13:00', TIME '14:00', TIME '15:00'))'''), 0);
    expect(await count('''
      SELECT COUNT(*)::int FROM Treatment WHERE treatment_id > 403 AND (EXTRACT(ISODOW FROM scheduled_date) > 5
        OR scheduled_date + scheduled_time + make_interval(mins => duration_minutes)
           > scheduled_date + CASE WHEN scheduled_time < TIME '12:00' THEN TIME '12:00' ELSE TIME '17:00' END)'''), 0);
  });

  test('no two active treatments overlap', () async {
    expect(await count('''
      SELECT COUNT(*)::int FROM Treatment a JOIN Treatment b ON a.treatment_id < b.treatment_id
      WHERE a.treatment_status IN ('Pending', 'Accepted') AND b.treatment_status IN ('Pending', 'Accepted')
        AND a.scheduled_date + a.scheduled_time < b.scheduled_date + b.scheduled_time + make_interval(mins => b.duration_minutes)
        AND b.scheduled_date + b.scheduled_time < a.scheduled_date + a.scheduled_time + make_interval(mins => a.duration_minutes)'''), 0);
  });

  test('AutoCancelJob finds no Pending treatment to cancel', () async {
    expect(await count("SELECT COUNT(*)::int FROM Treatment WHERE treatment_status = 'Pending' AND scheduled_date <= CURRENT_DATE"), 0);
  });

  test('no event has a time in the future, except for planned dates', () async {
    for (final (table, column) in const [
      ('InjuryClaim', 'submitted_at'),
      ('EligibilityCheck', 'checked_at'),
      ('ClaimStatusHistory', 'changed_at'),
      ('Appointment', 'created_at'),
      ('AppointmentConfirmation', 'recorded_at'),
      ('ConsultationReport', 'delivered_at'),
      ('ConsultationReport', 'read_at'),
      ('Treatment', 'created_at'),
      ('Notification', 'sent_at'),
      ('Notification', 'read_at'),
    ]) {
      expect(await count('SELECT COUNT(*)::int FROM $table WHERE $column > NOW()'), 0, reason: '$table.$column');
    }
  });

  test('a treatment is booked before its date, and the cancel message comes after the booking message', () async {
    expect(await count('''
      SELECT COUNT(*)::int FROM Treatment
      WHERE treatment_id > 403 AND created_at >= scheduled_date + scheduled_time'''), 0);
    expect(await count('''
      SELECT COUNT(*)::int FROM Notification b JOIN Notification c ON c.claim_id = b.claim_id
      WHERE b.claim_id > 164 AND b.subject = 'Treatment booked' AND c.subject = 'Treatment cancelled' AND c.sent_at <= b.sent_at'''), 0);
  });

  test('the Recent changes card of consultant 1 stays short', () async {
    expect(await count('''
      SELECT COUNT(*)::int FROM Notification
      WHERE consultant_id = 1 AND sent_at >= NOW() - INTERVAL '14 days' '''), lessThanOrEqualTo(12));
  });

  test('each list of the demo has rows', () async {
    for (final sql in const [
      "SELECT COUNT(*)::int FROM InjuryClaim ic WHERE ic.claim_status = 'Covered' AND NOT EXISTS (SELECT 1 FROM Appointment a WHERE a.claim_id = ic.claim_id AND a.appointment_status IN ('Pending', 'Confirmed'))",
      "SELECT COUNT(*)::int FROM Appointment WHERE consultant_id = 1 AND appointment_status = 'Confirmed' AND schedule_date >= CURRENT_DATE",
      "SELECT COUNT(*)::int FROM ConsultationReport WHERE delivered_at IS NOT NULL AND read_at IS NULL",
      "SELECT COUNT(*)::int FROM ConsultationReport WHERE signed_at IS NULL",
      "SELECT COUNT(*)::int FROM Treatment WHERE treatment_status = 'Pending' AND treatment_id > 403",
    ]) {
      expect(await count(sql), greaterThan(0), reason: sql);
    }
  });

  test('a new claim gets the next free number, and each demo person can sign in', () async {
    expect(await count("SELECT nextval(pg_get_serial_sequence('injuryclaim', 'claim_id'))::int"), 251);
    expect(await count('SELECT COUNT(*)::int FROM InsuredPerson p WHERE NOT EXISTS (SELECT 1 FROM UserAccount u WHERE u.insured_id = p.insured_id)'), 0);
    expect(await count("SELECT COUNT(*)::int FROM UserAccount WHERE login_name = '1777700000001' AND password_hash = crypt('Password123', password_hash)"), 1);
  });
}
