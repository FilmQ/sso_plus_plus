import '../models/appointment.dart';
import '../models/appointment_slot.dart';
import '../models/claim.dart';
import '../models/claim_status.dart';
import '../models/consultation_report.dart';
import '../models/notice.dart';
import '../repository/claim_repository.dart';
import '../repository/notice_repository.dart';
import '../repository/scheduling_repository.dart';
import 'claim_rules.dart';
import 'clock.dart';

/// What UC-11 can answer.
sealed class TreatmentResult {
  const TreatmentResult();
}

/// The main flow: the treatment date exists and the claimant can see it.
class TreatmentBooked extends TreatmentResult {
  const TreatmentBooked(this.appointment);

  final Appointment appointment;
}

/// Flow 1a: the consultant recorded that no treatment is necessary.
class NoTreatmentRequired extends TreatmentResult {
  const NoTreatmentRequired(this.claim);

  final Claim claim;
}

/// BR-31: a treatment must come from a signed report.
class ReportNotSigned extends TreatmentResult {
  const ReportNotSigned();
}

/// BR-33: the claim must be covered and open.
class ClaimNotOpen extends TreatmentResult {
  const ClaimNotOpen();
}

/// The chosen slot is no longer free.
class TreatmentSlotTaken extends TreatmentResult {
  const TreatmentSlotTaken();
}

/// UC-11 · Schedule Treatment.
///
/// The consultant books the treatment from the signed report. BR-32 says
/// that the date is written into the application of the claimant at the
/// moment of the booking. There is no separate step by hand.
class ScheduleTreatment {
  const ScheduleTreatment({
    required this.scheduling,
    required this.claims,
    required this.notices,
    required this.clock,
  });

  final SchedulingRepository scheduling;
  final ClaimRepository claims;
  final NoticeRepository notices;
  final Clock clock;

  /// The free treatment slots that screen D8 offers.
  Future<List<AppointmentSlot>> slots() =>
      scheduling.freeSlots(treatment: true);

  /// Step 3: the consultant confirms the booking.
  Future<TreatmentResult> book({
    required ConsultationReport report,
    required AppointmentSlot slot,
    required String treatmentType,
    Duration duration = const Duration(minutes: 60),
  }) async {
    // BR-31: the treatment must be traceable to a signed report.
    if (!report.isSigned) {
      return const ReportNotSigned();
    }

    final Claim? claim = await claims.byNumber(report.claimNumber);
    // BR-33: treatment is booked only for a covered and open claim.
    if (claim == null ||
        claim.status == ClaimStatus.closed ||
        claim.status == ClaimStatus.rejected) {
      return const ClaimNotOpen();
    }

    final AppointmentSlot? current = await scheduling.slotById(slot.id);
    if (current == null || !current.isFree) {
      return const TreatmentSlotTaken();
    }

    await scheduling.saveSlot(
      current.copyWith(
        state: SlotState.booked,
        heldForClaim: claim.claimNumber,
      ),
    );

    final DateTime now = clock();

    final Appointment treatment = await scheduling.save(
      Appointment(
        id: 'APT-${claim.claimNumber.split('-').last}-T${now.millisecond}',
        claimNumber: claim.claimNumber,
        kind: AppointmentKind.treatment,
        start: slot.start,
        end: slot.start.add(duration),
        status: AppointmentStatus.awaitingConfirmation,
        // UC-11 (3a): the confirmation cycle of UC-05 applies here too.
        replyBy: ClaimRules.replyDeadlineFor(slot.start),
        consultantName: report.consultantName,
        specialty: report.specialty,
        facility: slot.facility,
        room: slot.room,
        treatmentType: treatmentType,
        reportId: report.id,
        slotId: slot.id,
      ),
    );

    if (claim.status == ClaimStatus.reportSigned) {
      await claims.save(claim.moveTo(ClaimStatus.treatmentScheduled));
    }

    // BR-32: the date reaches the claimant at the moment it is booked.
    await notices.save(
      Notice(
        id: 'NTC-${treatment.id}-B',
        claimNumber: claim.claimNumber,
        kind: NoticeKind.treatmentBooked,
        title: 'Treatment booked',
        body:
            'Your consultant booked $treatmentType. The date is in your '
            'appointments now.',
        sentAt: now,
      ),
    );

    return TreatmentBooked(treatment);
  }

  /// Flow 1a: no treatment is necessary, so the claim closes as completed.
  Future<TreatmentResult> recordNoTreatment(ConsultationReport report) async {
    final Claim? claim = await claims.byNumber(report.claimNumber);
    if (claim == null) {
      return const ClaimNotOpen();
    }

    final Claim closed = await claims.save(claim.moveTo(ClaimStatus.closed));

    await notices.save(
      Notice(
        id: 'NTC-${closed.claimNumber}-N',
        claimNumber: closed.claimNumber,
        kind: NoticeKind.reportAvailable,
        title: 'No treatment is necessary',
        body:
            'Your consultant recorded that no treatment is necessary. The '
            'claim is complete, and the report is its outcome.',
        sentAt: clock(),
      ),
    );

    return NoTreatmentRequired(closed);
  }
}
