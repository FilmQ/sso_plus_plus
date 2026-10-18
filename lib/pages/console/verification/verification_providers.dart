import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/verification_api.dart';
import '../../../session/session_providers.dart';

final Provider<VerificationApi> verificationApiProvider =
    Provider<VerificationApi>((Ref ref) => VerificationApi(ref.watch(apiClientProvider)));

/// O1 step 2 (QO1.1, QO1.2): the Verification Page and the count in the
/// navigation. Empty for a consultant.
final FutureProvider<Map<String, Object?>> verificationListProvider =
    FutureProvider<Map<String, Object?>>((Ref ref) async {
  final bool officer = ref.watch(sessionProvider).value?.isOfficer ?? false;
  return officer ? ref.read(verificationApiProvider).getVerificationList() : const <String, Object?>{};
});

/// O1 step 4 (QO1.3 to QO1.5): the Eligibility Decision Page of a claim.
final claimDetailProvider =
    FutureProvider.family<Map<String, Object?>, int>(
        (Ref ref, int claimId) => ref.read(verificationApiProvider).getClaimDetail(claimId));

/// O3 step 2 (QO1.6): the rejection reasons.
final FutureProvider<List<Map<String, Object?>>> rejectionReasonsProvider =
    FutureProvider<List<Map<String, Object?>>>((Ref ref) => ref.read(verificationApiProvider).getRejectionReasons());
