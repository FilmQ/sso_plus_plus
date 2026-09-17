import 'claim_document.dart';
import 'claim_status.dart';
import 'eligibility.dart';
import 'injury_details.dart';
import 'rejection_notice.dart';

/// An injury claim and everything that the office decided about it.
///
/// This is the root of the case. Every appointment, report and treatment
/// points back to its claim number.
class Claim {
  const Claim({
    required this.claimNumber,
    required this.personId,
    required this.injury,
    required this.documents,
    required this.status,
    this.createdAt,
    this.submittedAt,
    this.verification,
    this.rejection,
    this.reopenedFrom,
    this.supersededBy,
  });

  /// The number that the application assigns at submission,
  /// for example `CLM-2569-0143`.
  final String claimNumber;

  final String personId;
  final InjuryDetails injury;
  final List<ClaimDocument> documents;
  final ClaimStatus status;
  final DateTime? createdAt;
  final DateTime? submittedAt;
  final EligibilityVerification? verification;
  final RejectionNotice? rejection;

  /// The claim that this one replaces after a resubmission (UC-03, 3b).
  final String? reopenedFrom;

  /// The claim that replaces this one.
  final String? supersededBy;

  bool get isDraft => status == ClaimStatus.draft;

  /// The documents that the checklist still wants (BR-03).
  List<ClaimDocument> get missingDocuments =>
      documents.where((ClaimDocument d) => !d.isAttached).toList();

  bool get hasAllDocuments => missingDocuments.isEmpty;

  /// True while the person may still send the claim.
  bool get isReadyToSubmit => injury.isComplete && hasAllDocuments;

  /// Moves the claim to a new state.
  ///
  /// Throws [IllegalClaimTransition] if the deck does not allow the move.
  Claim moveTo(ClaimStatus next) {
    ClaimStatusTransition.check(status, next);
    return copyWith(status: next);
  }

  Claim copyWith({
    String? claimNumber,
    String? personId,
    InjuryDetails? injury,
    List<ClaimDocument>? documents,
    ClaimStatus? status,
    DateTime? createdAt,
    DateTime? submittedAt,
    EligibilityVerification? verification,
    RejectionNotice? rejection,
    String? reopenedFrom,
    String? supersededBy,
  }) {
    return Claim(
      claimNumber: claimNumber ?? this.claimNumber,
      personId: personId ?? this.personId,
      injury: injury ?? this.injury,
      documents: documents ?? this.documents,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      submittedAt: submittedAt ?? this.submittedAt,
      verification: verification ?? this.verification,
      rejection: rejection ?? this.rejection,
      reopenedFrom: reopenedFrom ?? this.reopenedFrom,
      supersededBy: supersededBy ?? this.supersededBy,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Claim) {
      return false;
    }
    if (other.documents.length != documents.length) {
      return false;
    }
    for (int i = 0; i < documents.length; i++) {
      if (other.documents[i] != documents[i]) {
        return false;
      }
    }
    return other.claimNumber == claimNumber &&
        other.personId == personId &&
        other.injury == injury &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.submittedAt == submittedAt &&
        other.verification == verification &&
        other.rejection == rejection &&
        other.reopenedFrom == reopenedFrom &&
        other.supersededBy == supersededBy;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    claimNumber,
    personId,
    injury,
    status,
    createdAt,
    submittedAt,
    verification,
    rejection,
    reopenedFrom,
    supersededBy,
    ...documents,
  ]);
}
