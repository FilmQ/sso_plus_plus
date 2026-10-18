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
    // QC1.1
    ..get('/c1/appointments', (Request r) async => jsonOk({'appointments': await appointments(r).getSchedule()}))
    // QC2.1
    ..get('/c2/consultations', (Request r) async =>
        jsonOk({'consultations': await reports(r).getPendingConsultations()}))
    // QC2.2, QC2.3
    ..post('$base/open', (Request r, String a) => page(reports(r).openReport(int.parse(a))))
    // QC2.4 or QC2.5. multipart/form-data: `report_content` (text) or `file` (one file).
    ..post('$base/draft', (Request r, String a) async {
      final form = r.formData();
      if (form == null) throw const FormatException('Send multipart/form-data');
      String? content;
      ({String fileName, Uint8List bytes})? file;
      await for (final part in form.formData) {
        if (part.name == 'report_content') {
          content = await part.part.readString(utf8);
        } else if (part.name == 'file' && part.filename != null) {
          file = (fileName: part.filename!, bytes: await part.part.readBytes());
        } else {
          await part.part.drain<void>();
        }
      }
      return page(reports(r).saveDraft(int.parse(a), content: content, file: file));
    })
    // QC2.6
    ..post('$base/sign', (Request r, String a) => page(reports(r).signReport(int.parse(a))))
    // QC2.7
    ..post('$base/file-report', (Request r, String a) => page(reports(r).fileReport(int.parse(a))))
    // The attached file of the draft (no SQL).
    ..get('$base/draft-file', (Request r, String a) async {
      final file = await reports(r).openDraftFile(int.parse(a));
      return Response.ok(file.bytes, headers: {'content-type': file.mimeType});
    });
}
