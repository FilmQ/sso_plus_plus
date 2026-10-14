import '../models/claim.dart';
import '../models/claim_status.dart';
import '../models/eligibility.dart';
import '../models/notice.dart';
import '../models/register_record.dart';
import '../repository/claim_repository.dart';
import '../repository/insured_register_repository.dart';
import '../repository/notice_repository.dart';
import 'clock.dart';

/// What UC-02 can answer.
sealed class VerificationResult {
  const VerificationResult();
}

/// The officer confirmed the result, and the claim moves on.
class EligibilityVerified extends VerificationResult {
  const EligibilityVerified(this.claim);

  final Claim claim;
}

/// Flow \*a: the register did not answer, so the claim waits.
class RegisterUnavailable extends VerificationResult {
  const RegisterUnavailable(this.claim);

  final Claim claim;
}

/// Flow 4a: an override carries no written reason (BR-06).
class OverrideNeedsReason extends VerificationResult {
  const OverrideNeedsReason();
}

/// UC-02 · Verify Section 33 Eligibility.
///
/// The system reads the register and proposes a result. The Evaluation
/// Officer reviews it and confirms it. BR-05 says that the confirmed result
/// is stored and used again for the life of the claim.
class VerifySection33Eligibility {
  const VerifySection33Eligibility({
    required this.claims,
    required this.register,
    required this.notices,
    required this.clock,
  });

  final ClaimRepository claims;
  final InsuredRegisterRepository register;
  final NoticeRepository notices;
  final Clock clock;

  /// Steps 1 to 3: read the register and propose a result.
  ///
  /// This is the automatic part. It changes no state, so the officer can run
  /// it again while the claim waits.
  Future<RegisterRecord> lookup(Claim claim) async {
    final person = await register.byId(claim.personId);
    if (person == null || claim.injury.date == null) {
      return RegisterRecord(available: true, queriedAt: clock());
    }
    return register.lookup(person.nationalId, claim.injury.date!);
  }

  /// Turns a register record into the result that the screen proposes.
  EligibilityResult automaticResultFor(RegisterRecord record, Claim claim) {
    if (!record.available) {
      return EligibilityResult.needsReview;
    }
    if (!record.found) {
      return EligibilityResult.notCovered;
    }
    // Flow 2b: the employer on the claim differs from the register.
    if (record.employerInRegister != claim.injury.employer) {
      return EligibilityResult.needsReview;
    }
    return EligibilityResult.covered;
  }

  /// Step 5: the officer confirms the result.
  ///
  /// BR-06 says that an override must carry a written reason and the
  /// identity of the officer.
  Future<VerificationResult> confirm({
    required Claim claim,
    required EligibilityResult result,
    required EligibilityResult automaticResult,
    required String officerName,
    required RegisterRecord record,
    String? overrideReason,
  }) async {
    if (!record.available) {
      return RegisterUnavailable(claim);
    }

    final bool isOverride = result != automaticResult;
    if (isOverride && (overrideReason == null || overrideReason.isEmpty)) {
      return const OverrideNeedsReason();
    }

    final DateTime now = clock();

    final Claim verified = await claims.save(
      claim
          .moveTo(_statusFor(result))
          .copyWith(
            verification: EligibilityVerification(
              result: result,
              decidedAt: now,
              officerName: officerName,
              evidence: 'SSO insured register · ${record.coverSummary}',
              overrideReason: isOverride ? overrideReason : null,
            ),
          ),
    );

    // The claimant sees every state change in the application.
    if (result != EligibilityResult.notCovered) {
      await notices.save(
        Notice(
          id: 'NTC-${verified.claimNumber}-V',
          claimNumber: verified.claimNumber,
          kind: NoticeKind.eligibilityResult,
          title: result == EligibilityResult.covered
              ? 'Your claim is covered'
              : 'Your claim needs more evidence',
          body: result == EligibilityResult.covered
              ? 'An officer verified your Section 33 cover. The claim moves '
                    'to appointment scheduling.'
              : 'An officer needs more evidence before a decision. The claim '
                    'waits.',
          sentAt: now,
        ),
      );
    }

    return EligibilityVerified(verified);
  }

  static ClaimStatus _statusFor(EligibilityResult result) => switch (result) {
    EligibilityResult.covered => ClaimStatus.verifiedCovered,
    EligibilityResult.notCovered => ClaimStatus.verifiedNotCovered,
    EligibilityResult.needsReview => ClaimStatus.needsReview,
  };
}
