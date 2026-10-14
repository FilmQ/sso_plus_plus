import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_multipart/shelf_multipart.dart';
import 'package:shelf_router/shelf_router.dart';

import '../controller/insured_form_controller.dart';
import '../model/injury_form.dart';
import 'json.dart';

/// U1 Submit Injury Application.
///
/// POST /u1/injury-forms, multipart/form-data with the parts:
/// - `form`: the fields of U1-2 as JSON (see [InjuryForm.fromJson]),
/// - `id_card`, `medical_record`, `injury_form`: the three files.
/// 201 gives the data of U1-5 and a login token. 422 gives the field errors (U1-3, U1-4).
void addU1Routes(Router router, InsuredFormController Function() controller) {
  router.post('/u1/injury-forms', (Request request) async {
    final form = request.formData();
    if (form == null) throw const FormatException('Send multipart/form-data');
    Map<String, Object?> fields = {};
    final files = <UploadedFile>[];
    await for (final part in form.formData) {
      final docTypeId = requiredDocuments[part.name];
      if (part.name == 'form') {
        fields = jsonDecode(await part.part.readString(utf8)) as Map<String, Object?>;
      } else if (docTypeId != null && part.filename != null) {
        files.add(UploadedFile(docTypeId: docTypeId, fileName: part.filename!, bytes: await part.part.readBytes()));
      } else {
        await part.part.drain<void>();
      }
    }
    final result = await controller().submitInjuryForm(InjuryForm.fromJson(fields), files);
    return jsonCreated(result);
  });
}
