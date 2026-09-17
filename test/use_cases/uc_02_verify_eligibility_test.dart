import 'package:flutter_test/flutter_test.dart';
import 'package:sso_plus_plus/models/claim.dart';
import 'package:sso_plus_plus/models/claim_status.dart';
import 'package:sso_plus_plus/models/eligibility.dart';
import 'package:sso_plus_plus/models/register_record.dart';
import 'package:sso_plus_plus/use-cases/uc_02_verify_section_33_eligibility.dart';

import '../support/test_context.dart';

void main() {
  late TestContext context;
  late VerifySection33Eligibility useCase;

  setUp(() {
    context = TestContext();
    useCase = VerifySection33Eligibility(
      claims: context.claims,
      register: context.register,
      notices: context.notices,
      clock: context.clock,
    );
  });

  Future<Claim> claim(String number) async =>
      (await context.claims.byNumber(number))!;

  test('proposes "covered" when the register agrees with the claim', () async {
    final Claim found = await claim('CLM-2569-0131');
    final RegisterRecord record = await useCase.lookup(found);

    expect(record.available, isTrue);
    expect(
      useCase.automaticResultFor(record, found),
      EligibilityResult.covered,
    );
  });

  test('flow 2b: proposes "needs review" when the employer differs', () async {
    // The claim names a branch office; the register names the company.
    final Claim found = await claim('CLM-2569-0139');
    final RegisterRecord record = await useCase.lookup(found);

    expect(
      useCase.automaticResultFor(record, found),
      EligibilityResult.needsReview,
    );
  });

  test('flow 2a: proposes "not covered" when contributions lapsed', () async {
    final Claim found = await claim('CLM-2569-0137');
    final RegisterRecord record = await useCase.lookup(found);

    expect(record.unbroken, isFalse);
    expect(
      useCase.automaticResultFor(record, found),
      EligibilityResult.notCovered,
    );
  });

  test('flow *a: holds the claim when the register does not answer', () async {
    final Claim found = await claim('CLM-2569-0128');
    final RegisterRecord record = await useCase.lookup(found);
    expect(record.available, isFalse);

    final result = await useCase.confirm(
      claim: found,
      result: EligibilityResult.covered,
      automaticResult: EligibilityResult.needsReview,
      officerName: 'P. Chaiyaporn',
      record: record,
    );

    expect(result, isA<RegisterUnavailable>());
    // The claim does not move while the register is silent.
    final Claim after = await claim('CLM-2569-0128');
    expect(after.status, ClaimStatus.awaitingVerification);
  });

  test('stores the confirmed result and releases the claim', () async {
    final Claim found = await claim('CLM-2569-0131');
    final RegisterRecord record = await useCase.lookup(found);

    final result = await useCase.confirm(
      claim: found,
      result: EligibilityResult.covered,
      automaticResult: EligibilityResult.covered,
      officerName: 'P. Chaiyaporn',
      record: record,
    );

    expect(result, isA<EligibilityVerified>());
    final Claim after = await claim('CLM-2569-0131');

    // BR-05: the result is stored and used again for the life of the claim.
    expect(after.status, ClaimStatus.verifiedCovered);
    expect(after.verification?.officerName, 'P. Chaiyaporn');
    expect(after.verification?.evidence, contains('insured register'));
  });

  test('BR-06: an override without a written reason is refused', () async {
    final Claim found = await claim('CLM-2569-0131');
    final RegisterRecord record = await useCase.lookup(found);

    final result = await useCase.confirm(
      claim: found,
      // The officer disagrees with the automatic "covered".
      result: EligibilityResult.notCovered,
      automaticResult: EligibilityResult.covered,
      officerName: 'P. Chaiyaporn',
      record: record,
    );

    expect(result, isA<OverrideNeedsReason>());
    expect(
      (await claim('CLM-2569-0131')).status,
      ClaimStatus.awaitingVerification,
    );
  });

  test('BR-06: an override with a reason keeps the reason', () async {
    final Claim found = await claim('CLM-2569-0131');
    final RegisterRecord record = await useCase.lookup(found);

    await useCase.confirm(
      claim: found,
      result: EligibilityResult.notCovered,
      automaticResult: EligibilityResult.covered,
      officerName: 'P. Chaiyaporn',
      record: record,
      overrideReason: 'The employer statement contradicts the register.',
    );

    final Claim after = await claim('CLM-2569-0131');
    expect(after.status, ClaimStatus.verifiedNotCovered);
    expect(after.verification?.overrideReason, isNotNull);
  });
}
