import 'package:flutter_test/flutter_test.dart';
import 'package:sso_plus_plus/models/claim.dart';
import 'package:sso_plus_plus/models/claim_status.dart';
import 'package:sso_plus_plus/models/injury_details.dart';

void main() {
  group('The claim transition table', () {
    test('allows the sequence that the deck describes', () {
      expect(
        ClaimStatusTransition.isAllowed(
          ClaimStatus.draft,
          ClaimStatus.submitted,
        ),
        isTrue,
      );
      expect(
        ClaimStatusTransition.isAllowed(
          ClaimStatus.awaitingVerification,
          ClaimStatus.verifiedCovered,
        ),
        isTrue,
      );
      expect(
        ClaimStatusTransition.isAllowed(
          ClaimStatus.verifiedNotCovered,
          ClaimStatus.rejected,
        ),
        isTrue,
      );
      expect(
        ClaimStatusTransition.isAllowed(
          ClaimStatus.reportSigned,
          ClaimStatus.treatmentScheduled,
        ),
        isTrue,
      );
    });

    test('refuses a jump over the eligibility check', () {
      expect(
        ClaimStatusTransition.isAllowed(
          ClaimStatus.submitted,
          ClaimStatus.appointmentProposed,
        ),
        isFalse,
      );
    });

    test('refuses a move out of a closed claim', () {
      expect(
        ClaimStatusTransition.isAllowed(
          ClaimStatus.closed,
          ClaimStatus.submitted,
        ),
        isFalse,
      );
    });

    test('throws when a claim makes an illegal move', () {
      const Claim claim = Claim(
        claimNumber: 'CLM-0001',
        personId: 'USR-001',
        injury: InjuryDetails(),
        documents: <Never>[],
        status: ClaimStatus.draft,
      );

      expect(
        () => claim.moveTo(ClaimStatus.treatmentScheduled),
        throwsA(isA<IllegalClaimTransition>()),
      );
    });

    test('lets a refused claim go to appeal but not straight to treatment', () {
      expect(
        ClaimStatusTransition.isAllowed(
          ClaimStatus.rejected,
          ClaimStatus.appealed,
        ),
        isTrue,
      );
      expect(
        ClaimStatusTransition.isAllowed(
          ClaimStatus.rejected,
          ClaimStatus.treatmentScheduled,
        ),
        isFalse,
      );
    });
  });
}
