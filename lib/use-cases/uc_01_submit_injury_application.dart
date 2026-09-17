import '../models/claim.dart';
import '../models/claim_document.dart';
import '../models/claim_status.dart';
import '../models/injury_details.dart';
import '../models/insured_person.dart';
import '../models/notice.dart';
import '../repository/claim_repository.dart';
import '../repository/notice_repository.dart';
import 'clock.dart';

/// What UC-01 can answer.
///
/// Each member is one ending of the deck: the main flow, or one of the
/// alternate flows 2a, 3a and 4a.
sealed class SubmitResult {
  const SubmitResult();
}

/// The main flow: the claim is registered.
class Submitted extends SubmitResult {
  const Submitted(this.claim);

  final Claim claim;
}

/// Flow 2a: a field is empty, so the application refuses the claim.
class MissingRequiredFields extends SubmitResult {
  const MissingRequiredFields(this.fields);

  final List<String> fields;
}

/// Flow 3a: a document is absent, so the claim stays a draft (BR-03).
class SavedAsDraft extends SubmitResult {
  const SavedAsDraft(this.claim, this.outstanding);

  final Claim claim;
  final List<ClaimDocument> outstanding;
}

/// Flow 4a: a claim for the same injury is already open.
class DuplicateOpenClaim extends SubmitResult {
  const DuplicateOpenClaim(this.existing);

  final Claim existing;
}

/// UC-01 · Submit Injury Application.
///
/// The person completes the injury form and its documents, and sends them as
/// one claim. The application checks that the claim is complete, registers
/// it, and then starts the Section 33 check (UC-02).
class SubmitInjuryApplication {
  const SubmitInjuryApplication({
    required this.claims,
    required this.notices,
    required this.clock,
  });

  final ClaimRepository claims;
  final NoticeRepository notices;
  final Clock clock;

  /// Keeps what the person entered, without a check.
  ///
  /// The minimal guarantee of the deck says that no entered data is lost.
  Future<Claim> saveDraft({
    required InsuredPerson person,
    required InjuryDetails injury,
    required List<ClaimDocument> documents,
    Claim? draft,
  }) async {
    final Claim claim =
        draft?.copyWith(injury: injury, documents: documents) ??
        Claim(
          claimNumber: await claims.nextClaimNumber(),
          personId: person.id,
          injury: injury,
          documents: documents,
          status: ClaimStatus.draft,
          createdAt: clock(),
        );
    return claims.save(claim);
  }

  /// Runs the main flow of UC-01.
  Future<SubmitResult> call({
    required InsuredPerson person,
    required InjuryDetails injury,
    required List<ClaimDocument> documents,
    Claim? draft,
    bool mergeWithExisting = false,
  }) async {
    // Step 2a: the application marks what is missing and refuses to send.
    if (!injury.isComplete) {
      return MissingRequiredFields(injury.missingFields);
    }

    // Step 4a: one injury must not produce two claims.
    if (!mergeWithExisting && draft == null) {
      final Claim? open = await claims.openClaimForInjury(
        person.id,
        injury.date!,
      );
      if (open != null) {
        return DuplicateOpenClaim(open);
      }
    }

    final Claim claim = await saveDraft(
      person: person,
      injury: injury,
      documents: documents,
      draft: draft,
    );

    // Step 3a and BR-03: the checklist must be complete before registration.
    if (!claim.hasAllDocuments) {
      return SavedAsDraft(claim, claim.missingDocuments);
    }

    // Step 4: register the claim and give it its number.
    final DateTime now = clock();
    final Claim submitted = claim
        .moveTo(ClaimStatus.submitted)
        .copyWith(submittedAt: now);

    // Step 5: UC-01 «include» UC-02. The check starts at once. An officer
    // confirms the result later, so the claim waits here.
    final Claim waiting = await claims.save(
      submitted.moveTo(ClaimStatus.awaitingVerification),
    );

    await notices.save(
      Notice(
        id: 'NTC-${waiting.claimNumber}',
        claimNumber: waiting.claimNumber,
        kind: NoticeKind.claimReceived,
        title: 'We received your claim',
        body:
            'Your claim ${waiting.claimNumber} is registered. The Section 33 '
            'check runs now. An officer confirms the result.',
        sentAt: now,
      ),
    );

    return Submitted(waiting);
  }
}
