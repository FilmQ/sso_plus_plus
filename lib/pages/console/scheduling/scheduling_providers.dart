import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/scheduling_api.dart';
import '../../../session/session_providers.dart';

final Provider<SchedulingApi> schedulingApiProvider =
    Provider<SchedulingApi>((Ref ref) => SchedulingApi(ref.watch(apiClientProvider)));

/// O4 step 2 (QO4.1): the claims of the Scheduling page and the count in the
/// navigation. Empty for a consultant.
final FutureProvider<List<Map<String, Object?>>> claimsToScheduleProvider =
    FutureProvider<List<Map<String, Object?>>>((Ref ref) async {
  final bool officer = ref.watch(sessionProvider).value?.isOfficer ?? false;
  return officer ? ref.read(schedulingApiProvider).getClaimsToSchedule() : const <Map<String, Object?>>[];
});

/// O4 step 2.1 (QO4.2): the consultant availability of a date ('yyyy-MM-dd').
final availabilityProvider = FutureProvider.family<List<Map<String, Object?>>, String>(
    (Ref ref, String date) => ref.read(schedulingApiProvider).getAvailability(date));

/// One QO4.2 row as the page uses it.
extension SlotRow on Map<String, Object?> {
  /// 'yyyy-MM-dd' and 'HH:mm' of slot_at (an ISO text, wall-clock time).
  String get slotDate => (this['slot_at']! as String).substring(0, 10);
  String get slotTime => (this['slot_at']! as String).substring(11, 16);
  int get consultantId => this['consultant_id']! as int;
  String get state => this['slot_state']! as String;
}
