import 'claim.dart';
import 'claim_status.dart';

/// The state of one step in the claim tracker on screen M1.
enum ClaimStepState { done, active, waiting }

/// One row of the claim tracker.
class ProgressStep {
  const ProgressStep({
    required this.label,
    required this.state,
    this.detail = '',
  });

  final String label;

  final ClaimStepState state;

  /// The second line. It holds a time stamp, or the words `Not started`.
  final String detail;
}

/// The five stages that the tracker shows.
///
/// The design fixes these five rows. They are a summary of the claim states,
/// not a copy of them.
enum ProgressStage {
  submitted('Claim submitted'),
  verified('Section 33 eligibility verified'),
  appointment('Appointment proposed'),
  consultation('Consultation'),
  treatment('Treatment');

  const ProgressStage(this.label);

  final String label;
}

/// Turns a claim state into the five rows of the tracker.
///
/// The tracker is a read model. It holds no rule of its own, so it stays with
/// the entities and not with the use cases.
abstract final class ClaimProgress {
  /// The position of each stage in the sequence of claim states.
  static const Map<ProgressStage, List<ClaimStatus>> _reachedAt =
      <ProgressStage, List<ClaimStatus>>{
        ProgressStage.submitted: <ClaimStatus>[
          ClaimStatus.submitted,
          ClaimStatus.awaitingVerification,
        ],
        ProgressStage.verified: <ClaimStatus>[
          ClaimStatus.verifiedCovered,
          ClaimStatus.needsReview,
          ClaimStatus.verifiedNotCovered,
          ClaimStatus.rejected,
          ClaimStatus.appealed,
        ],
        ProgressStage.appointment: <ClaimStatus>[
          ClaimStatus.appointmentProposed,
          ClaimStatus.appointmentConfirmed,
        ],
        ProgressStage.consultation: <ClaimStatus>[
          ClaimStatus.consultationCompleted,
          ClaimStatus.reportSigned,
        ],
        ProgressStage.treatment: <ClaimStatus>[
          ClaimStatus.treatmentScheduled,
          ClaimStatus.closed,
        ],
      };

  static const List<ProgressStage> _order = ProgressStage.values;

  /// The index of the stage that the claim has reached.
  static int _reachedIndex(ClaimStatus status) {
    for (int i = _order.length - 1; i >= 0; i--) {
      if (_reachedAt[_order[i]]!.contains(status)) {
        return i;
      }
    }
    return -1;
  }

  /// Builds the five rows for [claim].
  ///
  /// [details] supplies the second line for a stage where one is known.
  static List<ProgressStep> stepsFor(
    Claim claim, {
    Map<ProgressStage, String> details = const <ProgressStage, String>{},
  }) {
    final int reached = _reachedIndex(claim.status);

    return <ProgressStep>[
      for (int i = 0; i < _order.length; i++)
        ProgressStep(
          label: _order[i].label,
          state: i < reached
              ? ClaimStepState.done
              : i == reached
              ? ClaimStepState.active
              : ClaimStepState.waiting,
          detail: details[_order[i]] ?? (i > reached ? 'Not started' : ''),
        ),
    ];
  }
}
