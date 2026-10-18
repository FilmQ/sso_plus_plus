import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/report_api.dart';
import '../../../session/session_providers.dart';

final Provider<ReportApi> reportApiProvider = Provider<ReportApi>((Ref ref) => ReportApi(ref.watch(apiClientProvider)));

/// O6 step 2 (QO6.1): the report list and the count in the navigation.
/// Empty for a consultant.
final FutureProvider<List<Map<String, Object?>>> reportListProvider =
    FutureProvider<List<Map<String, Object?>>>((Ref ref) async {
  final bool officer = ref.watch(sessionProvider).value?.isOfficer ?? false;
  return officer ? ref.read(reportApiProvider).getReportList() : const <Map<String, Object?>>[];
});

/// O6 step 2.1 (QO6.2): one report.
final reportProvider =
    FutureProvider.family<Map<String, Object?>, int>((Ref ref, int id) => ref.read(reportApiProvider).getReport(id));
