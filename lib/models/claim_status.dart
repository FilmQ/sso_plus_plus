/// The state of a claim through its life.
///
/// The deck gives this sequence. Section 4.2 of IMPLEMENTATION.md holds the
/// same diagram.
enum ClaimStatus {
  draft('Draft'),
  submitted('Submitted'),
  awaitingVerification('Awaiting verification'),
  verifiedCovered('Covered'),
  needsReview('Needs review'),
  verifiedNotCovered('Not covered'),
  rejected('Rejected'),
  appealed('Appeal in review'),
  appointmentProposed('Appointment proposed'),
  appointmentConfirmed('Appointment confirmed'),
  consultationCompleted('Consultation completed'),
  reportSigned('Report signed'),
  treatmentScheduled('Treatment scheduled'),
  closed('Closed');

  const ClaimStatus(this.label);

  /// The words that the screens show for this state.
  final String label;
}

/// The moves that a claim is allowed to make.
///
/// A move that is not in this table is a fault in the application, not a
/// choice of the user. `ClaimStatusTransition.check` throws on such a move.
const Map<ClaimStatus, Set<ClaimStatus>>
_allowed = <ClaimStatus, Set<ClaimStatus>>{
  ClaimStatus.draft: <ClaimStatus>{ClaimStatus.submitted},
  ClaimStatus.submitted: <ClaimStatus>{ClaimStatus.awaitingVerification},
  ClaimStatus.awaitingVerification: <ClaimStatus>{
    ClaimStatus.verifiedCovered,
    ClaimStatus.verifiedNotCovered,
    ClaimStatus.needsReview,
  },
  ClaimStatus.needsReview: <ClaimStatus>{
    ClaimStatus.verifiedCovered,
    ClaimStatus.verifiedNotCovered,
  },
  ClaimStatus.verifiedCovered: <ClaimStatus>{ClaimStatus.appointmentProposed},
  ClaimStatus.verifiedNotCovered: <ClaimStatus>{ClaimStatus.rejected},
  ClaimStatus.rejected: <ClaimStatus>{ClaimStatus.appealed},
  ClaimStatus.appealed: <ClaimStatus>{ClaimStatus.awaitingVerification},
  ClaimStatus.appointmentProposed: <ClaimStatus>{
    ClaimStatus.appointmentConfirmed,
    // UC-07 gives the claim a new date. The state does not change.
    ClaimStatus.appointmentProposed,
    ClaimStatus.closed,
  },
  ClaimStatus.appointmentConfirmed: <ClaimStatus>{
    ClaimStatus.consultationCompleted,
    // UC-09 (2a): the patient does not attend, so a new date is needed.
    ClaimStatus.appointmentProposed,
  },
  ClaimStatus.consultationCompleted: <ClaimStatus>{ClaimStatus.reportSigned},
  ClaimStatus.reportSigned: <ClaimStatus>{
    ClaimStatus.treatmentScheduled,
    // UC-11 (1a): no treatment is necessary, so the claim closes.
    ClaimStatus.closed,
  },
  ClaimStatus.treatmentScheduled: <ClaimStatus>{ClaimStatus.closed},
  ClaimStatus.closed: <ClaimStatus>{},
};

/// The error that an illegal move causes.
class IllegalClaimTransition implements Exception {
  const IllegalClaimTransition(this.from, this.to);

  final ClaimStatus from;
  final ClaimStatus to;

  @override
  String toString() =>
      'IllegalClaimTransition: a claim cannot move from ${from.name} to '
      '${to.name}.';
}

/// The rules for a change of claim state.
abstract final class ClaimStatusTransition {
  /// Returns true if the claim is allowed to move from [from] to [to].
  static bool isAllowed(ClaimStatus from, ClaimStatus to) =>
      _allowed[from]?.contains(to) ?? false;

  /// Throws [IllegalClaimTransition] if the move is not allowed.
  static void check(ClaimStatus from, ClaimStatus to) {
    if (!isAllowed(from, to)) {
      throw IllegalClaimTransition(from, to);
    }
  }
}
