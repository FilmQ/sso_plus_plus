import '../models/appointment.dart';
import '../models/appointment_slot.dart';
import '../models/notice.dart';
import '../repository/notice_repository.dart';
import '../repository/scheduling_repository.dart';
import 'claim_rules.dart';
import 'clock.dart';

/// What UC-07 can answer.
sealed class RescheduleResult {
  const RescheduleResult();
}

/// The main flow: a new date exists and the confirmation cycle starts again.
class Rescheduled extends RescheduleResult {
  const Rescheduled(this.appointment);

  final Appointment appointment;
}

/// Flow 3a: the limit is reached, so the claim is suspended (BR-20).
class RescheduleLimitReached extends RescheduleResult {
  const RescheduleLimitReached(this.appointment);

  final Appointment appointment;
}

/// The chosen slot is no longer free.
class RescheduleSlotTaken extends RescheduleResult {
  const RescheduleSlotTaken();
}

/// UC-07 · Reschedule Appointment.
///
/// Neither the application nor the telephone reached the claimant. The old
/// slot returns to the pool and a new date is established, so the case does
/// not stall. The new date is provisional until the claimant agrees (BR-21).
class RescheduleAppointment {
  const RescheduleAppointment({
    required this.scheduling,
    required this.notices,
    required this.clock,
  });

  final SchedulingRepository scheduling;
  final NoticeRepository notices;
  final Clock clock;

  /// Step 3 and step 4: release the old slot and take a new one.
  Future<RescheduleResult> reschedule({
    required Appointment appointment,
    required AppointmentSlot newSlot,
    required String officerName,
  }) async {
    // BR-20: no more than the permitted number of moves.
    if (appointment.rescheduleCount >= ClaimRules.maxReschedules) {
      return RescheduleLimitReached(appointment);
    }

    final AppointmentSlot? current = await scheduling.slotById(newSlot.id);
    if (current == null || !current.isFree) {
      return const RescheduleSlotTaken();
    }

    // BR-19: the old slot returns to the pool at once.
    if (appointment.slotId != null) {
      final AppointmentSlot? old = await scheduling.slotById(
        appointment.slotId!,
      );
      if (old != null) {
        await scheduling.saveSlot(old.released());
      }
    }

    await scheduling.saveSlot(
      current.copyWith(
        state: SlotState.held,
        heldForClaim: appointment.claimNumber,
      ),
    );

    final DateTime now = clock();

    final Appointment moved = await scheduling.save(
      appointment.copyWith(
        start: newSlot.start,
        end: newSlot.end,
        slotId: newSlot.id,
        status: AppointmentStatus.awaitingConfirmation,
        replyBy: ClaimRules.replyDeadlineFor(newSlot.start),
        // BR-21: the date is marked unconfirmed wherever it is displayed.
        provisional: true,
        rescheduleCount: appointment.rescheduleCount + 1,
        recordedBy: officerName,
      ),
    );

    // The claimant is told on every channel on file.
    await notices.save(
      Notice(
        id: 'NTC-${moved.id}-R',
        claimNumber: moved.claimNumber,
        kind: NoticeKind.appointmentProposed,
        title: 'Your appointment moved',
        body:
            'We could not reach you, so the office set a new date. It is '
            'provisional until you confirm it.',
        sentAt: now,
      ),
    );

    return Rescheduled(moved);
  }

  /// The slots that may replace the current date.
  Future<List<AppointmentSlot>> replacementSlotsFor(Appointment appointment) {
    return scheduling.freeSlots(specialty: appointment.specialty);
  }
}
