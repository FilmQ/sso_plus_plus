import 'api_client.dart';

/// The page side of server TreatmentController (U4.1, U4.2, U6).
class TreatmentApi {
  const TreatmentApi(this.api);

  final ApiClient api;

  String _base(int treatmentId) => '/u4/treatments/$treatmentId';

  Map<String, Object?> _row(Map<String, Object?> body) => body['treatment']! as Map<String, Object?>;

  /// Q6.1: the Treatments tab of the Schedule Page (getTreatmentSchedule).
  Future<List<Map<String, Object?>>> getTreatmentSchedule() async =>
      ((await api.get('/u6/treatments'))['treatments']! as List<Object?>).cast<Map<String, Object?>>();

  /// QU4.4: the Confirm Treatment page.
  Future<Map<String, Object?>> getTreatment(int treatmentId) async => _row(await api.get(_base(treatmentId)));

  /// QU4.1
  Future<Map<String, Object?>> acceptTreatment(int treatmentId) async =>
      _row(await api.post('${_base(treatmentId)}/accept', const <String, Object?>{}));

  /// QU4.5: the free weekdays, each with slot_date ('yyyy-MM-dd') and
  /// date_label (for example 'Tue 27 October 2026').
  Future<List<Map<String, Object?>>> getAvailableDates(int treatmentId) async =>
      ((await api.get('${_base(treatmentId)}/available-dates'))['dates']! as List<Object?>)
          .cast<Map<String, Object?>>();

  /// QU4.2: the new date counts as accepting, so the treatment comes back Accepted.
  Future<Map<String, Object?>> changeDate(int treatmentId, String newDate) async =>
      _row(await api.post('${_base(treatmentId)}/change-date', <String, Object?>{'new_date': newDate}));
}
