import 'package:flutter_test/flutter_test.dart';
import 'package:sso_plus_plus/legacy/models/claim.dart';
import 'package:sso_plus_plus/legacy/models/claim_status.dart';
import 'package:sso_plus_plus/legacy/use-cases/uc_03_reject_application.dart';

import '../support/test_context.dart';

void main() {
  late TestContext context;
  late RejectApplication useCase;

  setUp(() {
    context = TestContext();
    useCase = RejectApplication(
      claims: context.claims,
      notices: context.notices,
      clock: context.clock,
    );
  });

  /// The seeded claim that an officer refused.
  Future<Claim> refused() async =>
      (await context.claims.byNumber('CLM-2569-0118'))!;

  test('flow 3c: an appeal returns the claim for review', () async {
    final RejectionResponse result = await useCase.appeal(await refused());

    expect(result, isA<AppealStarted>());
    expect((result as AppealStarted).claim.status, ClaimStatus.appealed);

    // BR-08: the refused claim is kept, not deleted.
    final Claim? stored = await context.claims.byNumber('CLM-2569-0118');
    expect(stored, isNotNull);
    expect(stored?.rejection?.reasonCode, 'E-33-02');
  });

  test('flow 3b: a resubmission creates a claim that refers back', () async {
    final Claim previous = await refused();
    final RejectionResponse result = await useCase.resubmit(previous);

    expect(result, isA<ResubmissionStarted>());
    final ResubmissionStarted started = result as ResubmissionStarted;

    // The history stays linked in both directions.
    expect(started.newClaim.reopenedFrom, 'CLM-2569-0118');
    expect(started.newClaim.status, ClaimStatus.draft);

    final Claim? old = await context.claims.byNumber('CLM-2569-0118');
    expect(old?.supersededBy, started.newClaim.claimNumber);
  });

  test('refuses both routes after the appeal period closes', () async {
    // The decision was on 21 August 2026, and BR-09 allows 30 days.
    context.store.advanceBy(const Duration(days: 40));

    expect(await useCase.appeal(await refused()), isA<AppealPeriodOver>());
    expect(await useCase.resubmit(await refused()), isA<AppealPeriodOver>());
  });

  test('counts the days that are left to appeal', () async {
    final Claim claim = await refused();

    // The demonstration starts on 14 September 2026 and the period closes on
    // 20 September 2026.
    expect(useCase.daysLeftToAppeal(claim), 6);

    context.store.advanceBy(const Duration(days: 40));
    expect(useCase.daysLeftToAppeal(claim), 0);
  });

  test('records that the person opened the notice', () async {
    final Claim claim = await refused();
    expect(claim.rejection?.isRead, isFalse);

    final Claim updated = await useCase.markNoticeRead(claim);
    expect(updated.rejection?.isRead, isTrue);
  });
}
