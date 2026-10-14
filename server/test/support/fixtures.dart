import 'package:sst_server/repository/appointment_repository.dart';
import 'package:sst_server/repository/claim_repository.dart';

/// A date [offset] days from today, as 'yyyy-MM-dd'.
/// Tests use dates near today, because many queries compare with NOW().
String day(int offset) {
  final d = DateTime.now().add(Duration(days: offset));
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
