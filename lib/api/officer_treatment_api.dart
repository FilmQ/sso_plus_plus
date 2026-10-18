import 'api_client.dart';

/// The officer side of server TreatmentController (O5.1, O5.2; D-052).
class OfficerTreatmentApi {
  const OfficerTreatmentApi(this.api);

  final ApiClient api;

  /// QO5.1: the claims with a filed report.
  Future<List<Map<String, Object?>>> getClaimsForTreatment() async =>
      ((await api.get('/o5/claims'))['claims']! as List<Object?>).cast<Map<String, Object?>>();

  /// QO5.2: the hours of [facility] from [from] to [to] ('yyyy-MM-dd').
  Future<List<Map<String, Object?>>> getAvailableTimes(String facility, String from, String to) async =>
      ((await api.get('/o5/available-times?facility=${Uri.encodeQueryComponent(facility)}&from=$from&to=$to'))['slots']!
              as List<Object?>)
          .cast<Map<String, Object?>>();

  /// QO5.3 and QN.1. Gives treatment_id and treatment_date.
  Future<Map<String, Object?>> bookTreatment(int claimId, Map<String, Object?> details) =>
      api.post('/o5/claims/$claimId/treatment', details);

  /// QO5.4 and QN.4.
  Future<Map<String, Object?>> closeWithoutTreatment(int claimId) => api.post('/o5/claims/$claimId/no-treatment');
}
