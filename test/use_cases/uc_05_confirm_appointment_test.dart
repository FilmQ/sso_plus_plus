import 'package:flutter_test/flutter_test.dart';
import 'package:sso_plus_plus/models/appointment.dart';
import 'package:sso_plus_plus/models/claim.dart';
import 'package:sso_plus_plus/models/claim_status.dart';
import 'package:sso_plus_plus/use-cases/uc_05_confirm_appointment.dart';

import '../support/test_context.dart';

void main() {
  late TestContext context;
  late ConfirmAppointment useCase;

  setUp(() {
    context = TestContext();
    useCase = ConfirmAppointment(
      scheduling: context.scheduling,
      claims: context.claims,
      notices: context.notices,
      clock: context.clock,
    );
  });

  /// The seeded consultation that waits for an answer.
  Future<Appointment> waiting() async =>
      (await context.scheduling.byId('APT-0143-1'))!;

  test('records the channel and the moment of a self-confirmation', () async {
    final ConfirmResult result = await useCase.confirm(await waiting());

    expect(result, isA<AppointmentConfirmed>());
    final Appointment confirmed = (result as AppointmentConfirmed).appointment;

    // BR-13: a self-confirmation must stay different from one that an
    // officer recorded by telephone.
    expect(confirmed.status, AppointmentStatus.confirmed);
    expect(confirmed.channel, ConfirmationChannel.selfService);
    expect(confirmed.confirmedAt, isNotNull);
  });

  test('moves the claim on when the consultation is confirmed', () async {
    await useCase.confirm(await waiting());

    final Claim? claim = await context.claims.byNumber('CLM-2569-0143');
    expect(claim?.status, ClaimStatus.appointmentConfirmed);
  });

  test('flow 3a: refuses a confirmation after the window closes', () async {
    // The reply deadline is 16 September 2026. Move the clock past it.
    context.store.advanceBy(const Duration(days: 4));

    final ConfirmResult result = await useCase.confirm(await waiting());

    // BR-15: silence is never a confirmation. UC-06 takes over instead.
    expect(result, isA<ConfirmationWindowClosed>());

    final Appointment? unchanged = await context.scheduling.byId('APT-0143-1');
    expect(unchanged?.status, AppointmentStatus.awaitingConfirmation);
  });

  test('flow 2a: records a request for another date', () async {
    final ConfirmResult result = await useCase.requestAnotherDate(
      await waiting(),
      preferredPeriod: 'Any morning next week',
    );

    expect(result, isA<AnotherDateRequested>());
    final Appointment updated = (result as AnotherDateRequested).appointment;
    expect(updated.status, AppointmentStatus.anotherDateRequested);
    expect(updated.declineReason, 'Any morning next week');
  });

  test('flow 2b: records a refusal with its reason', () async {
    final ConfirmResult result = await useCase.decline(
      await waiting(),
      'I moved to another province.',
    );

    expect(result, isA<AppointmentDeclined>());
    final Appointment updated = (result as AppointmentDeclined).appointment;
    expect(updated.status, AppointmentStatus.declined);
    expect(updated.declineReason, 'I moved to another province.');
  });

  test('confirms a treatment date without changing the claim state', () async {
    final Appointment treatment = (await context.scheduling.byId(
      'APT-0091-2',
    ))!;
    expect(treatment.kind, AppointmentKind.treatment);

    final ConfirmResult result = await useCase.confirm(treatment);

    expect(result, isA<AppointmentConfirmed>());
    // UC-11 says the UC-05 cycle applies to treatment too, but the claim has
    // already reached "Treatment scheduled", so its state does not move.
    final Claim? claim = await context.claims.byNumber('CLM-2569-0091');
    expect(claim?.status, ClaimStatus.treatmentScheduled);
  });
}
