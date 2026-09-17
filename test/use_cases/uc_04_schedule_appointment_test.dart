import 'package:flutter_test/flutter_test.dart';
import 'package:sso_plus_plus/models/appointment.dart';
import 'package:sso_plus_plus/models/appointment_slot.dart';
import 'package:sso_plus_plus/models/claim.dart';
import 'package:sso_plus_plus/models/claim_status.dart';
import 'package:sso_plus_plus/use-cases/claim_rules.dart';
import 'package:sso_plus_plus/use-cases/uc_04_schedule_appointment.dart';

import '../support/test_context.dart';

void main() {
  late TestContext context;
  late ScheduleAppointment useCase;

  setUp(() {
    context = TestContext();
    useCase = ScheduleAppointment(
      scheduling: context.scheduling,
      claims: context.claims,
      notices: context.notices,
      clock: context.clock,
    );
  });

  /// The seeded claim that is covered and needs a date.
  Future<Claim> covered() async =>
      (await context.claims.byNumber('CLM-2569-0135'))!;

  test('offers only the slots whose specialty matches the injury', () async {
    final Claim claim = await covered();
    final List<AppointmentSlot> slots = await useCase.slotsFor(claim);

    expect(slots, isNotEmpty);
    // BR-11: the injury is a fracture, so orthopaedic slots answer.
    expect(claim.injury.category?.specialty, 'Orthopaedics');
    for (final AppointmentSlot slot in slots) {
      final consultant = await context.scheduling.consultantById(
        slot.consultantId,
      );
      expect(consultant?.specialty, 'Orthopaedics');
    }
  });

  test('holds the slot and starts the confirmation window', () async {
    final Claim claim = await covered();
    final AppointmentSlot slot = (await useCase.slotsFor(claim)).first;

    final ScheduleResult result = await useCase.offer(
      claim: claim,
      slot: slot,
      officerName: 'P. Chaiyaporn',
    );

    expect(result, isA<AppointmentOffered>());
    final Appointment made = (result as AppointmentOffered).appointment;

    expect(made.status, AppointmentStatus.awaitingConfirmation);
    // BR-14: the window closes a fixed period before the slot.
    expect(made.replyBy, ClaimRules.replyDeadlineFor(slot.start));

    // BR-12: the slot is held against this claim only.
    final AppointmentSlot? held = await context.scheduling.slotById(slot.id);
    expect(held?.state, SlotState.held);
    expect(held?.heldForClaim, claim.claimNumber);

    // The claim moves on, and the claimant is told.
    expect(
      (await context.claims.byNumber(claim.claimNumber))?.status,
      ClaimStatus.appointmentProposed,
    );
    final notices = await context.notices.forPerson(claim.personId);
    expect(notices.first.claimNumber, claim.claimNumber);
  });

  test('flow 2b: refuses a slot that another claim already took', () async {
    final Claim claim = await covered();
    final AppointmentSlot slot = (await useCase.slotsFor(claim)).first;

    // Somebody else holds it between the display and the confirmation.
    await context.scheduling.saveSlot(
      slot.copyWith(state: SlotState.held, heldForClaim: 'CLM-2569-0001'),
    );

    final ScheduleResult result = await useCase.offer(
      claim: claim,
      slot: slot,
      officerName: 'P. Chaiyaporn',
    );

    expect(result, isA<SlotNoLongerFree>());
  });

  test('flow 2a: the waiting list answers when no date suits', () async {
    final ScheduleResult result = await useCase.addToWaitingList(
      await covered(),
    );
    expect(result, isA<PlacedOnWaitingList>());
  });

  test('BR-10: the service target runs from the verification', () async {
    final Claim claim = await covered();
    final DateTime target = useCase.serviceTargetEndsOn(claim);

    expect(target, claim.verification!.decidedAt.add(ClaimRules.serviceTarget));
  });
}
