import 'package:flutter_test/flutter_test.dart';
import 'package:sso_plus_plus/legacy/models/claim.dart';
import 'package:sso_plus_plus/legacy/models/claim_document.dart';
import 'package:sso_plus_plus/legacy/models/claim_status.dart';
import 'package:sso_plus_plus/legacy/models/injury_details.dart';
import 'package:sso_plus_plus/legacy/repository/memory/seed_data.dart';
import 'package:sso_plus_plus/legacy/use-cases/uc_01_submit_injury_application.dart';

import '../support/test_context.dart';

void main() {
  late TestContext context;
  late SubmitInjuryApplication useCase;

  setUp(() {
    context = TestContext();
    useCase = SubmitInjuryApplication(
      claims: context.claims,
      notices: context.notices,
      clock: context.clock,
    );
  });

  /// A complete injury form for an injury that no seeded claim covers.
  InjuryDetails completeInjury() => InjuryDetails(
    date: DateTime(2026, 9, 2),
    time: '08:30',
    place: 'Loading bay 1',
    cause: 'Struck by a falling box',
    bodyPart: 'Left hand',
    employer: SeedData.person.employer,
    category: InjuryCategory.fracture,
  );

  List<ClaimDocument> allDocuments() => const <ClaimDocument>[
    ClaimDocument(type: DocumentType.medicalCertificate, fileName: 'cert.pdf'),
    ClaimDocument(type: DocumentType.employerStatement, fileName: 'form.jpg'),
    ClaimDocument(type: DocumentType.identification, fileName: 'id.jpg'),
  ];

  test('registers a complete claim and starts the eligibility check', () async {
    final SubmitResult result = await useCase(
      person: SeedData.person,
      injury: completeInjury(),
      documents: allDocuments(),
    );

    expect(result, isA<Submitted>());
    final Claim claim = (result as Submitted).claim;

    // The deck says the claim carries a number and waits for UC-02.
    expect(claim.claimNumber, 'CLM-2569-0144');
    expect(claim.status, ClaimStatus.awaitingVerification);
    expect(claim.submittedAt, isNotNull);

    // The person is told that the claim arrived.
    final notices = await context.notices.forPerson(context.personId);
    expect(notices.first.claimNumber, claim.claimNumber);
  });

  test('flow 2a: refuses the claim while a field is empty', () async {
    final SubmitResult result = await useCase(
      person: SeedData.person,
      injury: completeInjury().copyWith(place: ''),
      documents: allDocuments(),
    );

    expect(result, isA<MissingRequiredFields>());
    expect(
      (result as MissingRequiredFields).fields,
      contains('Place of injury'),
    );
  });

  test('flow 3a: keeps the claim a draft while a document is absent', () async {
    final SubmitResult result = await useCase(
      person: SeedData.person,
      injury: completeInjury(),
      documents: const <ClaimDocument>[
        ClaimDocument(
          type: DocumentType.medicalCertificate,
          fileName: 'cert.pdf',
        ),
        ClaimDocument(type: DocumentType.employerStatement),
        ClaimDocument(type: DocumentType.identification),
      ],
    );

    expect(result, isA<SavedAsDraft>());
    final SavedAsDraft draft = result as SavedAsDraft;

    // BR-03: the claim is not registered until the checklist is complete.
    expect(draft.claim.status, ClaimStatus.draft);
    expect(draft.outstanding.length, 2);
  });

  test('flow 4a: offers the open claim for the same injury', () async {
    // The seed holds an open claim for an injury on 8 September 2026.
    final SubmitResult result = await useCase(
      person: SeedData.person,
      injury: completeInjury().copyWith(date: DateTime(2026, 9, 8)),
      documents: allDocuments(),
    );

    expect(result, isA<DuplicateOpenClaim>());
    expect(
      (result as DuplicateOpenClaim).existing.claimNumber,
      'CLM-2569-0143',
    );
  });

  test('keeps a draft so that nothing the person entered is lost', () async {
    final Claim draft = await useCase.saveDraft(
      person: SeedData.person,
      injury: completeInjury().copyWith(cause: ''),
      documents: allDocuments(),
    );

    expect(draft.status, ClaimStatus.draft);
    final Claim? stored = await context.claims.byNumber(draft.claimNumber);
    expect(stored?.injury.place, 'Loading bay 1');
  });
}
