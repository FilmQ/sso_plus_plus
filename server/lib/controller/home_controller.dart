import '../auth/user_session.dart';
import '../repository/appointment_repository.dart';
import '../repository/claim_repository.dart';
import 'controller.dart';

/// The cards of U2-1 Home page: "Your claim" and "Next appointment".
/// Not a controller of the report (R-006, D-022).
class HomeController extends Controller {
  HomeController(super.session, this.claims, this.appointments);

  final ClaimRepository claims;
  final AppointmentRepository appointments;

  Future<Map<String, Object?>> getHome() async {
    final insuredId = requireRole(Role.user).insuredId!;
    final claim = await claims.findLatestClaimOf(insuredId);
    // QU5.1 [U5]: the first upcoming appointment.
    final next = (await appointments.findUpcomingAppointments(insuredId)).firstOrNull;
    return {'claim': claim, 'next_appointment': next};
  }
}
