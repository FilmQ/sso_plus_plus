import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'api_client.dart';

/// The consultant side of server AppointmentController and ReportController
/// (C1, C2.1 to C2.3; D-057).
class ConsultantApi {
  const ConsultantApi(this.api);

  final ApiClient api;

  String _base(int appointmentId) => '/c2/consultations/$appointmentId';

  Map<String, Object?> _page(Map<String, Object?> body) => body['report']! as Map<String, Object?>;

  /// QC1.1: the Schedule Page.
  Future<List<Map<String, Object?>>> getSchedule() async =>
      ((await api.get('/c1/appointments'))['appointments']! as List<Object?>).cast<Map<String, Object?>>();

  /// QC2.1: the consultations that wait for a report.
  Future<List<Map<String, Object?>>> getPendingConsultations() async =>
      ((await api.get('/c2/consultations'))['consultations']! as List<Object?>).cast<Map<String, Object?>>();

  /// QC2.2 and QC2.3: the report page of a consultation.
  Future<Map<String, Object?>> openReport(int appointmentId) async =>
      _page(await api.post('${_base(appointmentId)}/open'));

  /// QC2.4 or QC2.5: "Finish the draft" with the text or one file.
  Future<Map<String, Object?>> saveDraft(int appointmentId,
      {String? content, ({String name, Uint8List bytes})? file}) async {
    final Map<String, Object?> body = await api.postMultipart(
      '${_base(appointmentId)}/draft',
      fields: <String, String>{'report_content': ?content},
      files: <http.MultipartFile>[
        if (file != null) http.MultipartFile.fromBytes('file', file.bytes, filename: file.name),
      ],
    );
    return _page(body);
  }

  /// QC2.6: "Confirm" on the signature card.
  Future<Map<String, Object?>> signReport(int appointmentId) async =>
      _page(await api.post('${_base(appointmentId)}/sign'));

  /// QC2.7: "File the report".
  Future<Map<String, Object?>> fileReport(int appointmentId) async =>
      _page(await api.post('${_base(appointmentId)}/file-report'));

  /// The attached file of the draft.
  Future<({Uint8List bytes, String? mimeType})> openDraftFile(int appointmentId) =>
      api.getBytes('${_base(appointmentId)}/draft-file');
}
