import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/consultant_api.dart';
import '../../../session/session_providers.dart';

final Provider<ConsultantApi> consultantApiProvider =
    Provider<ConsultantApi>((Ref ref) => ConsultantApi(ref.watch(apiClientProvider)));

bool _consultant(Ref ref) => ref.watch(sessionProvider).value?.isConsultant ?? false;

/// C1 steps 2 and 2.1 (QC1.1, QC1.2): the Schedule Page with the "Recent
/// changes" card, and the count in the navigation. Empty for an officer.
final FutureProvider<ConsultantSchedule> consultantScheduleProvider =
    FutureProvider<ConsultantSchedule>((Ref ref) async => _consultant(ref)
        ? ref.read(consultantApiProvider).getSchedule()
        : (appointments: const <Map<String, Object?>>[], recentChanges: const <Map<String, Object?>>[]));

/// C2.1 step 2 (QC2.1): the consultations that wait for a report, and the
/// count in the navigation. Empty for an officer.
final FutureProvider<List<Map<String, Object?>>> pendingConsultationsProvider =
    FutureProvider<List<Map<String, Object?>>>((Ref ref) async =>
        _consultant(ref) ? ref.read(consultantApiProvider).getPendingConsultations() : const <Map<String, Object?>>[]);
