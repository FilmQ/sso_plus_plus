import 'package:sst_server/repository/appointment_repository.dart';
import 'package:sst_server/repository/treatment_repository.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../support/http.dart';
import '../support/test_db.dart';

/// U5 and U6: the two tabs of the Schedule Page, through the HTTP routes.
void main() {
  final db = useTestDb();

  String dayText(int offset) {
    final d = DateTime.parse(day(offset));
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September',
      'October', 'November', 'December'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  test('U5 Normal Case: the upcoming Pending and Confirmed appointments, the nearest first', () =>
      inRollback(db, () async {
        final appointments = AppointmentRepository(db);
        await insertTestAppointment(appointments, claimId: 160, consultantId: 3, date: day(40), time: '09:00');
        final cancelled = await insertTestAppointment(appointments, claimId: 160, consultantId: 3, date: day(41));
        await appointments.cancelAppointment(cancelled);
        final c = TestClient(db);
        await c.login('1350100678904'); // person 106, claim 160

        final rows = ((await c.get('/u5/appointments')).json['appointments'] as List).cast<Map>(); // QU5.1
        expect(rows.last, {
          'consultant_name': 'นพ. วีระ ทองดี',
          'office_location': 'Building C, Floor 1, Room 104',
          'appointment_date': '${dayText(40)} : 09:00',
          'claim_no': 'SST-2026-000160',
          'injury': 'Laceration, left forearm',
          'injury_date': '7 October 2026',
        });
        expect(rows.where((r) => (r['appointment_date'] as String).startsWith(dayText(41))), isEmpty,
            reason: 'a Cancelled appointment is not shown');
      }));

  test('U5: a user without appointments sees an empty list', () => inRollback(db, () async {
        final c = TestClient(db);
        await c.login('1209800456789'); // person 104, claim 151 Rejected
        expect((await c.get('/u5/appointments')).json['appointments'], isEmpty);
      }));

  test('U6 Normal Case: the upcoming Pending and Accepted treatments, the nearest first', () =>
      inRollback(db, () async {
        final repo = TreatmentRepository(db);
        Future<int> book(String date) => repo.insertTreatment(
              claimId: 149,
              reportId: 86,
              officerId: 2,
              treatmentType: 'Occupational therapy',
              facilityName: 'SSO Rehabilitation Center',
              scheduledDate: date,
              scheduledTime: '14:00',
            );
        final accepted = await book(day(50));
        await repo.updateStatusAccepted(accepted, 149);
        final pending = await book(day(45));
        await book(day(-3)); // in the past: not shown
        final c = TestClient(db);
        await c.login('1100800345672'); // person 103, claim 149

        final rows = ((await c.get('/u6/treatments')).json['treatments'] as List).cast<Map>(); // Q6.1
        final ids = [for (final r in rows) r['treatment_id']];
        expect(ids.indexOf(pending), lessThan(ids.indexOf(accepted)));
        expect(rows.firstWhere((r) => r['treatment_id'] == accepted)['treatment_status'], 'Accepted');
        expect(rows.every((r) => r['treatment_status'] != 'Cancelled'), isTrue);
        expect(rows.firstWhere((r) => r['treatment_id'] == pending)['facility_name'], 'SSO Rehabilitation Center');
      }));

  test('U5, U6: the Schedule Page needs a signed-in user (401)', () async {
    final c = TestClient(db);
    expect((await c.get('/u5/appointments')).status, 401);
    expect((await c.get('/u6/treatments')).status, 401);
  });
}
