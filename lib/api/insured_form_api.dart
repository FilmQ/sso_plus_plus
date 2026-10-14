import 'dart:convert';

import 'package:http/http.dart' as http;

import '../pages/user/injury_form/injury_form_data.dart';
import 'api_client.dart';

/// The page side of server InsuredFormController (U1, D-002).
class InsuredFormApi {
  const InsuredFormApi(this.api);

  final ApiClient api;

  /// submitInjuryForm(form, files). Gives token, session and claim (U1-5).
  /// Throws ApiException 422 with `fields` and `already_registered` (U1-3, U1-4).
  Future<Map<String, Object?>> submitInjuryForm(InjuryFormData form) => api.postMultipart(
        '/u1/injury-forms',
        fields: <String, String>{'form': jsonEncode(form.toJson())},
        files: <http.MultipartFile>[
          for (final MapEntry<String, PickedFile> f in form.files.entries)
            http.MultipartFile.fromBytes(f.key, f.value.bytes, filename: f.value.name),
        ],
      );
}
