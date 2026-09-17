import '../models/appointment.dart';
import '../models/claim_status.dart';
import '../models/contact_attempt.dart';
import '../repository/claim_repository.dart';
import '../repository/scheduling_repository.dart';
import 'claim_rules.dart';
import 'clock.dart';

/// The reply that the claimant gave on the telephone.
enum PhoneReply {
  confirmed('Confirmed'),
  anotherDate('Asked for another date'),
  declined('Declined — treatment abandoned'),
  noAnswer('No answer');

  const PhoneReply(this.label);

  final String label;
}

/// What UC-06 can answer.
sealed class PhoneResult {
  const PhoneResult();
}

/// The officer recorded the reply while on the call.
class ReplyRecorded extends PhoneResult {
  const ReplyRecorded(this.appointment, this.reply);

  final Appointment appointment;
  final PhoneReply reply;
}

/// Flow \*a: nobody answered, and attempts remain.
class AttemptLogged extends PhoneResult {
  const AttemptLogged(this.attemptsUsed, this.attemptsAllowed);

  final int attemptsUsed;
  final int attemptsAllowed;

  int get attemptsLeft => attemptsAllowed - attemptsUsed;
}

/// The permitted calls are used, so UC-07 applies (BR-17).
class EscalateToReschedule extends PhoneResult {
  const EscalateToReschedule(this.appointment);

  final Appointment appointment;
}

/// UC-06 · Confirm Appointment by Phone.
///
/// The claimant did not answer in the application, so the officer telephones
/// and keys the reply on their behalf. BR-18 says that this record has the
/// same standing as a self-confirmation, but it must stay distinguishable.
class ConfirmAppointmentByPhone {
  const ConfirmAppointmentByPhone({
    required this.scheduling,
    required this.claims,
    required this.clock,
  });

  final SchedulingRepository scheduling;
  final ClaimRepository claims;
  final Clock clock;

  /// The calls already made against this appointment.
  Future<List<ContactAttempt>> attemptsFor(String appointmentId) =>
      scheduling.attemptsFor(appointmentId);

  /// Step 2: the officer telephones and nobody answers.
  Future<PhoneResult> logAttempt({
    required Appointment appointment,
    required String officerName,
    AttemptOutcome outcome = AttemptOutcome.noAnswer,
    String note = '',
  }) async {
    final List<ContactAttempt> made = await scheduling.attemptsFor(
      appointment.id,
    );

    await scheduling.addAttempt(
      ContactAttempt(
        id: 'ATT-${appointment.id}-${made.length + 1}',
        appointmentId: appointment.id,
        at: clock(),
        outcome: outcome,
        officerName: officerName,
        note: note,
      ),
    );

    final int used = made.length + 1;
    if (used >= ClaimRules.maxCallAttempts) {
      return EscalateToReschedule(appointment);
    }
    return AttemptLogged(used, ClaimRules.maxCallAttempts);
  }

  /// Step 4: the officer records the reply while still on the call.
  Future<PhoneResult> recordReply({
    required Appointment appointment,
    required PhoneReply reply,
    required String officerName,
    String note = '',
  }) async {
    final DateTime now = clock();
    final List<ContactAttempt> made = await scheduling.attemptsFor(
      appointment.id,
    );

    // BR-16 and BR-17: every call is on the record, answered or not.
    await scheduling.addAttempt(
      ContactAttempt(
        id: 'ATT-${appointment.id}-${made.length + 1}',
        appointmentId: appointment.id,
        at: now,
        outcome: AttemptOutcome.answered,
        officerName: officerName,
        note: note.isEmpty ? reply.label : note,
      ),
    );

    final Appointment updated = switch (reply) {
      PhoneReply.confirmed => appointment.copyWith(
        status: AppointmentStatus.confirmed,
        // BR-13: the channel keeps this apart from a self-confirmation.
        channel: ConfirmationChannel.telephone,
        confirmedAt: now,
        recordedBy: officerName,
        provisional: false,
      ),
      PhoneReply.anotherDate => appointment.copyWith(
        status: AppointmentStatus.anotherDateRequested,
        recordedBy: officerName,
        declineReason: note,
      ),
      PhoneReply.declined => appointment.copyWith(
        status: AppointmentStatus.declined,
        recordedBy: officerName,
        declineReason: note.isEmpty ? 'Treatment abandoned' : note,
      ),
      PhoneReply.noAnswer => appointment,
    };

    if (reply == PhoneReply.noAnswer) {
      return logAttempt(
        appointment: appointment,
        officerName: officerName,
        note: note,
      );
    }

    final Appointment saved = await scheduling.save(updated);

    if (reply == PhoneReply.confirmed) {
      final claim = await claims.byNumber(saved.claimNumber);
      if (claim != null && claim.status == ClaimStatus.appointmentProposed) {
        await claims.save(claim.moveTo(ClaimStatus.appointmentConfirmed));
      }
    }

    // Flow 3a: the slot is free again for another claim (BR-19).
    if (reply == PhoneReply.declined && saved.slotId != null) {
      final slot = await scheduling.slotById(saved.slotId!);
      if (slot != null) {
        await scheduling.saveSlot(slot.released());
      }
    }

    return ReplyRecorded(saved, reply);
  }
}
