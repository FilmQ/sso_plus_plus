import 'package:flutter_test/flutter_test.dart';
import 'package:sso_plus_plus/models/appointment.dart';
import 'package:sso_plus_plus/models/appointment_slot.dart';
import 'package:sso_plus_plus/models/claim_status.dart';
import 'package:sso_plus_plus/use-cases/claim_rules.dart';
import 'package:sso_plus_plus/use-cases/uc_06_confirm_appointment_by_phone.dart';
import 'package:sso_plus_plus/use-cases/uc_07_reschedule_appointment.dart';

import '../support/test_context.dart';

void main() {
  late TestContext context;
  late ConfirmAppointmentByPhone phone;
  late RescheduleAppointment reschedule;

  setUp(() {
    context = TestContext();
    phone = ConfirmAppointmentByPhone(
      scheduling: context.scheduling,
      claims: context.claims,
      clock: context.clock,
    );
    reschedule = RescheduleAppointment(
      scheduling: context.scheduling,
      notices: context.notices,
      clock: context.clock,
    );
  });

  /// An appointment that nobody answered, with no call made yet.
  Future<Appointment> fresh() async =>
      (await context.scheduling.byId('APT-0122-1'))!;

  /// An appointment whose permitted calls are already used.
  Future<Appointment> exhausted() async =>
      (await context.scheduling.byId('APT-0105-1'))!;

  test('the worklist holds only appointments past their deadline', () async {
    final List<Appointment> waiting = await context.scheduling.pastDeadline(
      context.clock(),
    );

    expect(waiting, isNotEmpty);
    for (final Appointment appointment in waiting) {
      expect(appointment.hasExpiredAt(context.clock()), isTrue);
    }
    // The patient claim still has time, so it is not here yet.
    expect(waiting.map((Appointment a) => a.id), isNot(contains('APT-0143-1')));
  });

  test('BR-13: an officer-recorded reply names its channel', () async {
    final PhoneResult result = await phone.recordReply(
      appointment: await fresh(),
      reply: PhoneReply.confirmed,
      officerName: 'P. Chaiyaporn',
      note: 'The patient confirmed on the call.',
    );

    expect(result, isA<ReplyRecorded>());
    final Appointment after = (await context.scheduling.byId('APT-0122-1'))!;

    expect(after.status, AppointmentStatus.confirmed);
    // BR-18: the same standing as a self-confirmation, but distinguishable.
    expect(after.channel, ConfirmationChannel.telephone);
    expect(after.recordedBy, 'P. Chaiyaporn');

    expect(
      (await context.claims.byNumber('CLM-2569-0122'))?.status,
      ClaimStatus.appointmentConfirmed,
    );
  });

  test('every call is logged, answered or not', () async {
    await phone.logAttempt(
      appointment: await fresh(),
      officerName: 'P. Chaiyaporn',
    );

    final attempts = await phone.attemptsFor('APT-0122-1');
    expect(attempts.length, 1);
  });

  test('BR-17: the case escalates when the attempts are used', () async {
    // Two calls are already on the record for this appointment.
    final PhoneResult result = await phone.logAttempt(
      appointment: await exhausted(),
      officerName: 'P. Chaiyaporn',
    );

    expect(result, isA<EscalateToReschedule>());
  });

  test('flow 3a: a refusal releases the slot to the pool', () async {
    final Appointment appointment = await fresh();
    final slot = (await context.scheduling.freeSlots()).first;
    await context.scheduling.save(appointment.copyWith(slotId: slot.id));
    await context.scheduling.saveSlot(
      slot.copyWith(state: SlotState.held, heldForClaim: 'CLM-2569-0122'),
    );

    await phone.recordReply(
      appointment: (await context.scheduling.byId('APT-0122-1'))!,
      reply: PhoneReply.declined,
      officerName: 'P. Chaiyaporn',
      note: 'The patient abandoned the treatment.',
    );

    // BR-19: a released slot returns to the pool at once.
    expect((await context.scheduling.slotById(slot.id))?.isFree, isTrue);
  });

  test('UC-07: a reschedule sets a provisional date and counts it', () async {
    final Appointment appointment = await exhausted();
    final AppointmentSlot newSlot = (await reschedule.replacementSlotsFor(
      appointment,
    )).first;

    final RescheduleResult result = await reschedule.reschedule(
      appointment: appointment,
      newSlot: newSlot,
      officerName: 'P. Chaiyaporn',
    );

    expect(result, isA<Rescheduled>());
    final Appointment moved = (result as Rescheduled).appointment;

    // BR-21: the date is marked unconfirmed wherever it is shown.
    expect(moved.provisional, isTrue);
    expect(moved.status, AppointmentStatus.awaitingConfirmation);
    expect(moved.rescheduleCount, 1);
    expect(moved.start, newSlot.start);
  });

  test('BR-20: the office may not move a date without limit', () async {
    final Appointment appointment = (await exhausted()).copyWith(
      rescheduleCount: ClaimRules.maxReschedules,
    );
    await context.scheduling.save(appointment);

    final RescheduleResult result = await reschedule.reschedule(
      appointment: appointment,
      newSlot: (await context.scheduling.freeSlots()).first,
      officerName: 'P. Chaiyaporn',
    );

    expect(result, isA<RescheduleLimitReached>());
  });
}
