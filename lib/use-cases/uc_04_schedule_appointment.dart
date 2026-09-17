import '../models/appointment.dart';
import '../models/appointment_slot.dart';
import '../models/claim.dart';
import '../models/claim_status.dart';
import '../models/consultant.dart';
import '../models/notice.dart';
import '../repository/claim_repository.dart';
import '../repository/notice_repository.dart';
import '../repository/scheduling_repository.dart';
import 'claim_rules.dart';
import 'clock.dart';

/// What UC-04 can answer.
sealed class ScheduleResult {
  const ScheduleResult();
}

/// The main flow: the appointment is offered to the claimant.
class AppointmentOffered extends ScheduleResult {
  const AppointmentOffered(this.appointment);

  final Appointment appointment;
}

/// Flow 2b: the slot was taken between the display and the confirmation.
class SlotNoLongerFree extends ScheduleResult {
  const SlotNoLongerFree();
}

/// Flow 2a: no suitable slot, so the claim goes on the waiting list.
class PlacedOnWaitingList extends ScheduleResult {
  const PlacedOnWaitingList(this.claim);

  final Claim claim;
}

/// UC-04 · Schedule Appointment.
///
/// The officer gives an eligible claim a consultation slot from live
/// availability. The proposed appointment goes to the application of the
/// claimant, and the confirmation cycle of UC-05 starts.
class ScheduleAppointment {
  const ScheduleAppointment({
    required this.scheduling,
    required this.claims,
    required this.notices,
    required this.clock,
  });

  final SchedulingRepository scheduling;
  final ClaimRepository claims;
  final NoticeRepository notices;
  final Clock clock;

  /// The slots that match the injury category of the claim (BR-11).
  Future<List<AppointmentSlot>> slotsFor(Claim claim) {
    return scheduling.freeSlots(specialty: claim.injury.category?.specialty);
  }

  /// Step 3: the officer confirms the slot.
  Future<ScheduleResult> offer({
    required Claim claim,
    required AppointmentSlot slot,
    required String officerName,
  }) async {
    // Flow 2b: check the slot again before it is held (BR-12).
    final AppointmentSlot? current = await scheduling.slotById(slot.id);
    if (current == null || !current.isFree) {
      return const SlotNoLongerFree();
    }

    await scheduling.saveSlot(
      current.copyWith(state: SlotState.held, heldForClaim: claim.claimNumber),
    );

    final Consultant? consultant = await scheduling.consultantById(
      slot.consultantId,
    );
    final DateTime now = clock();

    final Appointment appointment = await scheduling.save(
      Appointment(
        id: 'APT-${claim.claimNumber.split('-').last}-${now.millisecond}',
        claimNumber: claim.claimNumber,
        kind: AppointmentKind.consultation,
        start: slot.start,
        end: slot.end,
        status: AppointmentStatus.awaitingConfirmation,
        // BR-14: the window closes a fixed period before the slot.
        replyBy: ClaimRules.replyDeadlineFor(slot.start),
        consultantName: consultant?.name ?? '',
        specialty: consultant?.specialty ?? '',
        facility: slot.facility,
        room: slot.room,
        slotId: slot.id,
      ),
    );

    if (claim.status == ClaimStatus.verifiedCovered) {
      await claims.save(claim.moveTo(ClaimStatus.appointmentProposed));
    }

    await notices.save(
      Notice(
        id: 'NTC-${appointment.id}-O',
        claimNumber: claim.claimNumber,
        kind: NoticeKind.appointmentProposed,
        title: 'Confirm your appointment',
        body:
            'An officer proposed a consultation. Reply before the deadline, '
            'or an officer will telephone you.',
        sentAt: now,
      ),
    );

    return AppointmentOffered(appointment);
  }

  /// Flow 2a: no slot falls inside the service target (BR-10).
  Future<ScheduleResult> addToWaitingList(Claim claim) async {
    return PlacedOnWaitingList(claim);
  }

  /// The last date that meets the service target (BR-10).
  DateTime serviceTargetEndsOn(Claim claim) {
    final DateTime from = claim.verification?.decidedAt ?? clock();
    return from.add(ClaimRules.serviceTarget);
  }
}
