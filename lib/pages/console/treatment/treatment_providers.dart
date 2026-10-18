import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/officer_treatment_api.dart';
import '../../../session/session_providers.dart';

final Provider<OfficerTreatmentApi> officerTreatmentApiProvider =
    Provider<OfficerTreatmentApi>((Ref ref) => OfficerTreatmentApi(ref.watch(apiClientProvider)));

/// O5.1 step 2 (QO5.1): the claims of the Treatment page and the count in the
/// navigation. Empty for a consultant.
final FutureProvider<List<Map<String, Object?>>> claimsForTreatmentProvider =
    FutureProvider<List<Map<String, Object?>>>((Ref ref) async {
  final bool officer = ref.watch(sessionProvider).value?.isOfficer ?? false;
  return officer ? ref.read(officerTreatmentApiProvider).getClaimsForTreatment() : const <Map<String, Object?>>[];
});

/// O5.1 step 2.1 (QO5.2): the hours of a facility, for the key
/// 'facility|from|to'.
final availableTimesProvider = FutureProvider.family<List<Map<String, Object?>>, String>((Ref ref, String key) {
  final List<String> k = key.split('|');
  return ref.read(officerTreatmentApiProvider).getAvailableTimes(k[0], k[1], k[2]);
});

/// The choices of "Treatment to book". The report has no lists of types,
/// durations or facilities, so the page offers the values of the data
/// dictionary examples and the seed (D-052, R-044).
abstract final class TreatmentOptions {
  static const List<String> types = <String>['Physiotherapy', 'Occupational therapy'];
  static const List<int> durations = <int>[30, 45, 60, 90, 120];
  static const List<String> facilities = <String>['SSO Rehabilitation Center'];

  /// The days that "Available Times" shows: from tomorrow, 14 days.
  static const int days = 14;
}
