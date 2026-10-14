import '../models/appointment.dart';
import '../models/claim_status.dart';
import '../models/notice.dart';
import '../repository/claim_repository.dart';
import '../repository/notice_repository.dart';
import '../repository/scheduling_repository.dart';
import 'claim_rules.dart';
import 'clock.dart';

/// What UC-05 can answer.
sealed class ConfirmResult {
  const ConfirmResult();
}

/// The main flow: the person accepted the date.
class AppointmentConfirmed extends ConfirmResult {
  const AppointmentConfirmed(this.appointment);

  final Appointment appointment;
}

/// Flow 2a: the person wants another date, so UC-04 runs again.
class AnotherDateRequested extends ConfirmResult {
  const AnotherDateRequested(this.appointment);

  final Appointment appointment;
}

/// Flow 2b: the person will not attend.
class AppointmentDeclined extends ConfirmResult {
  const AppointmentDeclined(this.appointment);

  final Appointment appointment;
}

/// Flow 3a: the window closed, so UC-06 applies. An officer telephones.
///
/// BR-15 says that silence is never a confirmation.
class ConfirmationWindowClosed extends ConfirmResult {
  const ConfirmationWindowClosed(this.appointment);

  final Appointment appointment;
}

/// UC-05 · Confirm Appointment.
///
/// The person accepts or refuses the proposed date in the application. This
/// is the intended path. The telephone call of UC-06 is the exception.
///
/// UC-11 says that a treatment date uses this same cycle, so this use case
/// serves both kinds of appointment.
class ConfirmAppointment {
  const ConfirmAppointment({
    required this.scheduling,
    required this.claims,
    required this.notices,
    required this.clock,
  });

  final SchedulingRepository scheduling;
  final ClaimRepository claims;
  final NoticeRepository notices;
  final Clock clock;

  /// Step 3: the person accepts the date.
  Future<ConfirmResult> confirm(Appointment appointment) async {
    final DateTime now = clock();

    if (appointment.hasExpiredAt(now)) {
      return ConfirmationWindowClosed(appointment);
    }

    // BR-13: record the channel and the moment, so that a self-confirmation
    // stays different from an officer-recorded one.
    final Appointment confirmed = await scheduling.save(
      appointment.copyWith(
        status: AppointmentStatus.confirmed,
        channel: ConfirmationChannel.selfService,
        confirmedAt: now,
        provisional: false,
      ),
    );

    await _moveClaimToConfirmed(confirmed);

    await notices.save(
      Notice(
        id: 'NTC-${confirmed.id}-C',
        claimNumber: confirmed.claimNumber,
        kind: NoticeKind.appointmentConfirmed,
        title: 'Appointment confirmed',
        body:
            'You confirmed the appointment of ${confirmed.title.toLowerCase()}'
            '. A reminder follows before the date.',
        sentAt: now,
      ),
    );

    return AppointmentConfirmed(confirmed);
  }

  /// Flow 2a: the person asks for another date.
  ///
  /// The held slot returns to the pool (BR-19) and UC-04 runs again.
  Future<ConfirmResult> requestAnotherDate(
    Appointment appointment, {
    String? preferredPeriod,
  }) async {
    final Appointment updated = await scheduling.save(
      appointment.copyWith(
        status: AppointmentStatus.anotherDateRequested,
        declineReason: preferredPeriod,
      ),
    );
    return AnotherDateRequested(updated);
  }

  /// Flow 2b: the person states that they will not attend.
  Future<ConfirmResult> decline(Appointment appointment, String reason) async {
    final Appointment updated = await scheduling.save(
      appointment.copyWith(
        status: AppointmentStatus.declined,
        declineReason: reason,
      ),
    );
    return AppointmentDeclined(updated);
  }

  /// The last moment at which the person may answer (BR-14).
  DateTime deadlineFor(Appointment appointment) =>
      ClaimRules.replyDeadlineFor(appointment.start);

  /// Moves the claim on, but only for a consultation.
  ///
  /// A treatment date arrives after the claim already reached
  /// `treatmentScheduled`, so its confirmation changes no claim state.
  Future<void> _moveClaimToConfirmed(Appointment appointment) async {
    if (appointment.kind != AppointmentKind.consultation) {
      return;
    }
    final claim = await claims.byNumber(appointment.claimNumber);
    if (claim == null || claim.status != ClaimStatus.appointmentProposed) {
      return;
    }
    await claims.save(claim.moveTo(ClaimStatus.appointmentConfirmed));
  }
}
