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

/// Inserts a Pending appointment (QO4.3) for claim 155 with consultant 3.
Future<int> insertTestAppointment(
  AppointmentRepository appointments, {
  required String date,
  String time = '11:00',
  int claimId = 155,
  int consultantId = 3,
}) =>
    appointments.insertAppointment(
      claimId: claimId,
      officerId: 1,
      consultantId: consultantId,
      appointmentType: 'Onsite',
      scheduleDate: date,
      scheduleTime: time,
      location: 'Building C, Floor 1, Room 104',
    );
