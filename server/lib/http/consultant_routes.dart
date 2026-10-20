import 'dart:convert';
import 'dart:typed_data';

import 'package:shelf/shelf.dart';
import 'package:shelf_multipart/shelf_multipart.dart';
import 'package:shelf_router/shelf_router.dart';

import '../controller/appointment_controller.dart';
import '../controller/report_controller.dart';
import 'json.dart';

/// C1 View Appointment Schedule and C2.1 to C2.3 Create Consultation Report.
void addConsultantRoutes(
  Router router,
  AppointmentController Function(Request) appointments,
  ReportController Function(Request) reports,
) {
  const base = '/c2/consultations/<appointment|[0-9]+>';
  Future<Response> page(Future<Map<String, Object?>> report) async => jsonOk({'report': await report});

  router
    // QC1.1 and QC1.2 (the "Recent changes" card)
    ..get('/c1/appointments', (Request r) async {
      final schedule = await appointments(r).getSchedule();
      return jsonOk({'appointments': schedule.appointments, 'recent_changes': schedule.recentChanges});
    })
    // QC2.1
    ..get('/c2/consultations', (Request r) async =>
        jsonOk({'consultations': await reports(r).getPendingConsultations()}))
    // QC2.2, QC2.3
    ..post('$base/open', (Request r, String a) => page(reports(r).openReport(int.parse(a))))
    // QC2.4 or QC2.5. multipart/form-data: `report_content` (text) or `file`
    // (one file), and `recommended_treatment`.
    ..post('$base/draft', (Request r, String a) async {
      final form = await _readForm(r);
      return page(reports(r).saveDraft(int.parse(a),
          content: form.fields['report_content'],
          file: form.files['file'],
          recommendedTreatment: form.fields['recommended_treatment']));
    })
    // QC2.8 (Alternate Case 3 [User did not attend])
    ..post('$base/no-show', (Request r, String a) async =>
        jsonOk({'no_show': await reports(r).markNoShow(int.parse(a))}))
    // QC2.6. multipart/form-data: `signature` (the drawn signature as a PNG file).
    ..post('$base/sign', (Request r, String a) async {
      final form = await _readForm(r);
      return page(reports(r).signReport(int.parse(a), form.files['signature']?.bytes));
    })
    // QC2.7
    ..post('$base/file-report', (Request r, String a) => page(reports(r).fileReport(int.parse(a))))
    // The attached file of the draft (no SQL).
    ..get('$base/draft-file', (Request r, String a) async {
      final file = await reports(r).openDraftFile(int.parse(a));
      return Response.ok(file.bytes, headers: {'content-type': file.mimeType});
    })
    // The signature image of the report (no SQL, R-048).
    ..get('$base/signature', (Request r, String a) async {
      final file = await reports(r).openDraftSignature(int.parse(a));
      return Response.ok(file.bytes, headers: {'content-type': file.mimeType});
    });
}

/// The text fields and the files of a multipart/form-data request.
Future<({Map<String, String> fields, Map<String, ({String fileName, Uint8List bytes})> files})> _readForm(
    Request r) async {
  final form = r.formData();
  if (form == null) throw const FormatException('Send multipart/form-data');
  final fields = <String, String>{};
  final files = <String, ({String fileName, Uint8List bytes})>{};
  await for (final part in form.formData) {
    if (part.filename != null) {
      files[part.name] = (fileName: part.filename!, bytes: await part.part.readBytes());
    } else {
      fields[part.name] = await part.part.readString(utf8);
    }
  }
  return (fields: fields, files: files);
}
