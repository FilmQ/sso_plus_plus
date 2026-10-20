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

  /// QC1.1 and QC1.2: the Schedule Page, with the "Recent changes" card.
  Future<ConsultantSchedule> getSchedule() async {
    final Map<String, Object?> body = await api.get('/c1/appointments');
    List<Map<String, Object?>> rows(String key) =>
        ((body[key] as List<Object?>?) ?? const <Object?>[]).cast<Map<String, Object?>>();
    return (appointments: rows('appointments'), recentChanges: rows('recent_changes'));
  }

  /// QC2.1: the consultations that wait for a report.
  Future<List<Map<String, Object?>>> getPendingConsultations() async =>
      ((await api.get('/c2/consultations'))['consultations']! as List<Object?>).cast<Map<String, Object?>>();

  /// QC2.2 and QC2.3: the report page of a consultation.
  Future<Map<String, Object?>> openReport(int appointmentId) async =>
      _page(await api.post('${_base(appointmentId)}/open'));

  /// QC2.4 or QC2.5: "Finish the draft" with the text or one file, and the
  /// recommended treatment.
  Future<Map<String, Object?>> saveDraft(int appointmentId,
      {String? content, ({String name, Uint8List bytes})? file, String? recommendedTreatment}) async {
    final Map<String, Object?> body = await api.postMultipart(
      '${_base(appointmentId)}/draft',
      fields: <String, String>{'report_content': ?content, 'recommended_treatment': ?recommendedTreatment},
      files: <http.MultipartFile>[
        if (file != null) http.MultipartFile.fromBytes('file', file.bytes, filename: file.name),
      ],
    );
    return _page(body);
  }

  /// QC2.6: "Confirm" on the signature card, with the drawn signature as a
  /// PNG image.
  Future<Map<String, Object?>> signReport(int appointmentId, Uint8List signaturePng) async {
    final Map<String, Object?> body = await api.postMultipart(
      '${_base(appointmentId)}/sign',
      fields: const <String, String>{},
      files: <http.MultipartFile>[http.MultipartFile.fromBytes('signature', signaturePng, filename: 'signature.png')],
    );
    return _page(body);
  }

  /// QC2.8: "User did not attend" (C2.1 Alternate Case 3). Gives
  /// appointment_id and claim_id.
  Future<Map<String, Object?>> markNoShow(int appointmentId) async =>
      (await api.post('${_base(appointmentId)}/no-show'))['no_show']! as Map<String, Object?>;

  /// QC2.7: "File the report".
  Future<Map<String, Object?>> fileReport(int appointmentId) async =>
      _page(await api.post('${_base(appointmentId)}/file-report'));

  /// The attached file of the draft.
  Future<({Uint8List bytes, String? mimeType})> openDraftFile(int appointmentId) =>
      api.getBytes('${_base(appointmentId)}/draft-file');

  /// The stored signature image of the report (R-048).
  Future<({Uint8List bytes, String? mimeType})> openSignature(int appointmentId) =>
      api.getBytes('${_base(appointmentId)}/signature');
}

/// C1 Schedule Page: the QC1.1 appointments and the QC1.2 messages.
typedef ConsultantSchedule = ({List<Map<String, Object?>> appointments, List<Map<String, Object?>> recentChanges});
