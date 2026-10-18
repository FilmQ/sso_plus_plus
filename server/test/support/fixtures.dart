import 'package:sst_server/db/db_connector.dart';
import 'package:sst_server/repository/appointment_repository.dart';
import 'package:sst_server/repository/claim_repository.dart';

/// A date [offset] days from today, as 'yyyy-MM-dd'.
/// Tests use dates near today, because many queries compare with NOW().
String day(int offset) => addDays(_iso(DateTime.now()), offset);

/// The first weekday (Monday to Friday) on or after [day] of [offset].
/// QO5.2, QU4.2 and QU4.5 accept only weekdays.
String weekday(int offset) {
  var d = day(offset);
  while (!isWeekday(d)) {
    d = addDays(d, 1);
  }
  return d;
}

bool isWeekday(String date) => DateTime.parse(date).weekday <= DateTime.friday;

/// [date] ('yyyy-MM-dd') plus [days] calendar days.
String addDays(String date, int days) {
  final d = DateTime.parse(date);
  return _iso(DateTime(d.year, d.month, d.day + days));
}

String _iso(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)}';
}

/// Inserts a new claim of the seed person 105 (Q1.6, Q1.9, Q1.10), with an
/// automatic Section 33 check on coverage 205. Gives the claim_id.
Future<int> insertTestClaim(ClaimRepository claims, {String result = 'Covered'}) async {
  final claimId = await claims.insertClaim(
    insuredId: 105,
    employerId: 15,
    injuryDatetime: '${day(-2)} 08:30',
    injuryPlace: 'Cold storage, Khlong Luang, Pathum Thani',
    injuryCause: 'Slipped on ice',
    bodyPart: 'right knee',
    injuryCategory: 'Sprain',
    registerResult: result,
  );
  await claims.insertAutoEligibility(
    claimId: claimId,
    coverageId: result == 'Covered' ? 205 : null,
    registerResult: result,
    evidenceRef: 'REG-TEST',
  );
  await claims.insertFirstStatus(claimId);
  return claimId;
}

/// Inserts a Pending Onsite appointment of officer 1 at the consultant's
/// office, for claim 155 with consultant 3 by default. A plain INSERT, not
/// QO4.3: QO4.3 refuses most test rows (a claim that is not Covered, a past
/// date, a weekend). The test of QO4.3 itself uses the repository.
Future<int> insertTestAppointment(
  AppointmentRepository appointments, {
  required String date,
  String time = '11:00',
  int claimId = 155,
  int consultantId = 3,
}) async =>
    (await appointments.db.performQuery('''
INSERT INTO Appointment (claim_id, officer_id, consultant_id, appointment_type, schedule_date, schedule_time,
  location, appointment_status, confirm_deadline, created_at)
SELECT :claim_id, 1, c.consultant_id, 'Onsite', :date::date, :time::time, c.office_location, 'Pending',
  :date::date + :time::time - INTERVAL '24 hours', NOW()
FROM Consultant c WHERE c.consultant_id = :consultant_id
RETURNING appointment_id''', {'claim_id': claimId, 'consultant_id': consultantId, 'date': date, 'time': time}))
        .rows
        .single['appointment_id']! as int;

/// Inserts a treatment at SSO Rehabilitation Center (officer 2, report 86 of
/// claim 149 by default). A plain INSERT, not QO5.3, for the same reason as
/// [insertTestAppointment].
Future<int> insertTestTreatment(
  DBConnector db, {
  required String date,
  String time = '15:00',
  int claimId = 149,
  int reportId = 86,
  int duration = 45,
  String type = 'Occupational therapy',
  String status = 'Pending',
}) async =>
    (await db.performQuery('''
INSERT INTO Treatment (claim_id, report_id, officer_id, treatment_type, duration_minutes, facility_name,
  scheduled_date, scheduled_time, treatment_status, created_at)
VALUES (:claim_id, :report_id, 2, :type, :duration, 'SSO Rehabilitation Center', :date::date, :time::time,
  :status, NOW())
RETURNING treatment_id''', {
      'claim_id': claimId,
      'report_id': reportId,
      'type': type,
      'duration': duration,
      'date': date,
      'time': time,
      'status': status,
    }))
        .rows
        .single['treatment_id']! as int;
