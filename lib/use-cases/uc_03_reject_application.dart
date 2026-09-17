import '../models/claim.dart';
import '../models/claim_status.dart';
import '../models/notice.dart';
import '../repository/claim_repository.dart';
import '../repository/notice_repository.dart';
import 'claim_rules.dart';
import 'clock.dart';

/// What the person may do after a refusal.
sealed class RejectionResponse {
  const RejectionResponse();
}

/// Flow 3c: the claim returns for review. The refusal stays on the record.
class AppealStarted extends RejectionResponse {
  const AppealStarted(this.claim);

  final Claim claim;
}

/// Flow 3b: a new claim starts and points back to the refused one.
class ResubmissionStarted extends RejectionResponse {
  const ResubmissionStarted(this.newClaim, this.previous);

  final Claim newClaim;
  final Claim previous;
}

/// The appeal period is over, so neither route is open.
class AppealPeriodOver extends RejectionResponse {
  const AppealPeriodOver(this.closedOn);

  final DateTime closedOn;
}

/// UC-03 · Reject Application.
///
/// The claim closes as not covered. The person reads the decision in the
/// application, with the reason, the record it was decided from, and the
/// route to appeal or to resubmit.
///
/// This class holds the part of UC-03 that the person drives. The officer
/// part belongs to the console and arrives with phase P4.
class RejectApplication {
  const RejectApplication({
    required this.claims,
    required this.notices,
    required this.clock,
  });

  final ClaimRepository claims;
  final NoticeRepository notices;
  final Clock clock;

  /// Step 3: the person opened the notice.
  ///
  /// The deck says to record that the notice was read.
  Future<Claim> markNoticeRead(Claim claim) async {
    final rejection = claim.rejection;
    if (rejection == null || rejection.isRead) {
      return claim;
    }
    return claims.save(
      claim.copyWith(rejection: rejection.copyWith(readAt: clock())),
    );
  }

  /// Flow 3c: the person appeals.
  ///
  /// BR-08 says to keep the refused claim. The refusal becomes a superseded
  /// decision and is not deleted.
  Future<RejectionResponse> appeal(Claim claim) async {
    final DateTime now = clock();
    final DateTime? closesOn = claim.rejection?.appealClosesOn;
    if (closesOn != null && now.isAfter(closesOn)) {
      return AppealPeriodOver(closesOn);
    }

    final Claim appealed = await claims.save(
      claim.moveTo(ClaimStatus.appealed),
    );

    await notices.save(
      Notice(
        id: 'NTC-${appealed.claimNumber}-APL',
        claimNumber: appealed.claimNumber,
        kind: NoticeKind.eligibilityResult,
        title: 'Your appeal is with an officer',
        body:
            'Claim ${appealed.claimNumber} returns for review. The earlier '
            'decision stays on the record.',
        sentAt: now,
      ),
    );

    return AppealStarted(appealed);
  }

  /// Flow 3b: the person sends a new claim with new evidence.
  ///
  /// The new claim points back to the refused one, so the history stays
  /// linked.
  Future<RejectionResponse> resubmit(Claim claim) async {
    final DateTime now = clock();
    final DateTime? closesOn = claim.rejection?.appealClosesOn;
    if (closesOn != null && now.isAfter(closesOn)) {
      return AppealPeriodOver(closesOn);
    }

    final String number = await claims.nextClaimNumber();
    final Claim fresh = await claims.save(
      Claim(
        claimNumber: number,
        personId: claim.personId,
        injury: claim.injury,
        documents: claim.documents,
        status: ClaimStatus.draft,
        createdAt: now,
        reopenedFrom: claim.claimNumber,
      ),
    );

    final Claim previous = await claims.save(
      claim.copyWith(supersededBy: number),
    );

    return ResubmissionStarted(fresh, previous);
  }

  /// The number of days that the person still has to appeal (BR-09).
  int daysLeftToAppeal(Claim claim) {
    final DateTime? closesOn = claim.rejection?.appealClosesOn;
    if (closesOn == null) {
      return ClaimRules.appealDays;
    }
    final int days = closesOn.difference(clock()).inDays;
    return days < 0 ? 0 : days;
  }
}
