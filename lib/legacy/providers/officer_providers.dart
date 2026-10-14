import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/appointment.dart';
import '../models/appointment_slot.dart';
import '../models/claim.dart';
import '../models/claim_status.dart';
import '../models/consultant.dart';
import '../models/consultation_session.dart';
import '../models/eligibility.dart';
import '../models/insured_person.dart';
import '../models/register_record.dart';
import 'repository_providers.dart';
import 'use_case_providers.dart';

/// The claims that wait for a Section 33 decision (D1).
final FutureProvider<List<Claim>> verificationWorklistProvider =
    FutureProvider<List<Claim>>((Ref ref) async {
      return ref.watch(claimRepositoryProvider).byStatuses(<ClaimStatus>{
        ClaimStatus.awaitingVerification,
        ClaimStatus.needsReview,
        ClaimStatus.appealed,
      });
    });

/// The claims that are covered and still need a date (D3).
final FutureProvider<List<Claim>> schedulingWorklistProvider =
    FutureProvider<List<Claim>>((Ref ref) async {
      return ref.watch(claimRepositoryProvider).byStatuses(<ClaimStatus>{
        ClaimStatus.verifiedCovered,
      });
    });

/// The appointments that passed their reply deadline (D4).
final FutureProvider<List<Appointment>> unconfirmedWorklistProvider =
    FutureProvider<List<Appointment>>((Ref ref) async {
      final now = ref.watch(demoStoreProvider).now;
      return ref.watch(schedulingRepositoryProvider).pastDeadline(now);
    });

/// The confirmed appointments that still need a session (D5).
final FutureProvider<List<Claim>> consultationWorklistProvider =
    FutureProvider<List<Claim>>((Ref ref) async {
      final List<Claim> confirmed = await ref
          .watch(claimRepositoryProvider)
          .byStatuses(<ClaimStatus>{ClaimStatus.appointmentConfirmed});

      final consultation = ref.watch(consultationRepositoryProvider);
      final List<Claim> waiting = <Claim>[];
      for (final Claim claim in confirmed) {
        final ConsultationSession? session = await consultation.sessionForClaim(
          claim.claimNumber,
        );
        if (session == null) {
          waiting.add(claim);
        }
      }
      return waiting;
    });

/// One row of the verification worklist (D1).
///
/// The screen needs the claimant and the register answer beside the claim,
/// so the provider assembles them once.
class VerificationRow {
  const VerificationRow({
    required this.claim,
    required this.person,
    required this.record,
    required this.automatic,
  });

  final Claim claim;
  final InsuredPerson? person;
  final RegisterRecord record;
  final EligibilityResult automatic;

  String get claimantLine =>
      '${person?.fullName ?? 'Unknown'} · ${claim.injury.employer}';

  /// `3 / 3`, as the design shows it.
  String get documentCount =>
      '${claim.documents.where((d) => d.isAttached).length} / '
      '${claim.documents.length}';

  /// The words in the Status column.
  String get statusLine {
    if (!record.available) {
      return 'Retry queued';
    }
    if (automatic == EligibilityResult.needsReview &&
        record.employerInRegister != claim.injury.employer) {
      return 'Employer differs';
    }
    return 'Awaiting officer';
  }
}

/// The rows of screen D1.
final FutureProvider<List<VerificationRow>> verificationRowsProvider =
    FutureProvider<List<VerificationRow>>((Ref ref) async {
      final List<Claim> claims = await ref.watch(
        verificationWorklistProvider.future,
      );
      final register = ref.watch(insuredRegisterRepositoryProvider);
      final useCase = ref.watch(verifyEligibilityProvider);

      final List<VerificationRow> rows = <VerificationRow>[];
      for (final Claim claim in claims) {
        final InsuredPerson? person = await register.byId(claim.personId);
        final RegisterRecord record = await useCase.lookup(claim);
        rows.add(
          VerificationRow(
            claim: claim,
            person: person,
            record: record,
            automatic: useCase.automaticResultFor(record, claim),
          ),
        );
      }
      return rows;
    });

/// The free slots of one consultant, for screen D3.
class ConsultantSlots {
  const ConsultantSlots(this.consultant, this.slots);

  final Consultant consultant;
  final List<AppointmentSlot> slots;
}

/// The availability that matches the injury category of a claim (BR-11).
final slotsForClaimProvider =
    FutureProvider.family<List<ConsultantSlots>, String>((
      Ref ref,
      String claimNumber,
    ) async {
      final Claim? claim = await ref
          .watch(claimRepositoryProvider)
          .byNumber(claimNumber);
      if (claim == null) {
        return <ConsultantSlots>[];
      }

      final scheduling = ref.watch(schedulingRepositoryProvider);
      final String? specialty = claim.injury.category?.specialty;

      final List<Consultant> matching = await scheduling.consultants(
        specialty: specialty,
      );
      final List<AppointmentSlot> free = await scheduling.freeSlots(
        specialty: specialty,
      );

      return <ConsultantSlots>[
        for (final Consultant consultant in matching)
          ConsultantSlots(
            consultant,
            free
                .where((AppointmentSlot s) => s.consultantId == consultant.id)
                .toList(),
          ),
      ];
    });

/// The person who lodged one claim.
final personForClaimProvider = FutureProvider.family<InsuredPerson?, String>((
  Ref ref,
  String claimNumber,
) async {
  final Claim? claim = await ref
      .watch(claimRepositoryProvider)
      .byNumber(claimNumber);
  if (claim == null) {
    return null;
  }
  return ref.watch(insuredRegisterRepositoryProvider).byId(claim.personId);
});

/// The appointment that a claim waits on.
final appointmentForClaimProvider = FutureProvider.family<Appointment?, String>(
  (Ref ref, String claimNumber) async {
    final List<Appointment> all = await ref
        .watch(schedulingRepositoryProvider)
        .forClaim(claimNumber);
    for (final Appointment appointment in all) {
      if (appointment.kind == AppointmentKind.consultation) {
        return appointment;
      }
    }
    return all.isEmpty ? null : all.first;
  },
);

/// The four figures at the head of screen D1.
class VerificationCounts {
  const VerificationCounts({
    required this.awaiting,
    required this.needsReview,
    required this.registerDown,
    required this.verifiedThisWeek,
  });

  final int awaiting;
  final int needsReview;
  final int registerDown;

  /// Open point 5 of IMPLEMENTATION.md: the deck names no source for this
  /// figure. The demonstration counts the claims that an officer decided in
  /// the seven days before the demo clock.
  final int verifiedThisWeek;
}

final FutureProvider<VerificationCounts> verificationCountsProvider =
    FutureProvider<VerificationCounts>((Ref ref) async {
      final claims = ref.watch(claimRepositoryProvider);
      final DateTime now = ref.watch(demoStoreProvider).now;

      // The tiles count the rows of the table below them, so the head of the
      // screen and its body always agree.
      final List<VerificationRow> rows = await ref.watch(
        verificationRowsProvider.future,
      );

      final int needsReview = rows
          .where(
            (VerificationRow r) =>
                r.record.available &&
                r.automatic == EligibilityResult.needsReview,
          )
          .length;
      final int registerDown = rows
          .where((VerificationRow r) => !r.record.available)
          .length;

      final DateTime weekAgo = now.subtract(const Duration(days: 7));
      final List<Claim> decided = await claims.byStatuses(<ClaimStatus>{
        ClaimStatus.verifiedCovered,
        ClaimStatus.verifiedNotCovered,
        ClaimStatus.rejected,
        ClaimStatus.appointmentProposed,
        ClaimStatus.appointmentConfirmed,
        ClaimStatus.consultationCompleted,
        ClaimStatus.reportSigned,
        ClaimStatus.treatmentScheduled,
        ClaimStatus.closed,
      });
      final int verifiedThisWeek = decided
          .where(
            (Claim c) =>
                c.verification != null &&
                c.verification!.decidedAt.isAfter(weekAgo),
          )
          .length;

      return VerificationCounts(
        awaiting: rows.length,
        needsReview: needsReview,
        registerDown: registerDown,
        verifiedThisWeek: verifiedThisWeek,
      );
    });
