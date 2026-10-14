import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

/// The HTTP gate from the Pages to the server Controllers (D-002).
///
/// Set the server address at build time:
///   flutter run --dart-define=API_BASE_URL=http://localhost:8080
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ??
            const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8080');

  final http.Client _client;
  final String baseUrl;

  /// The login token. The session state sets it.
  String? token;

  Future<Map<String, Object?>> get(String path) => _send(http.Request('GET', _uri(path)));

  Future<Map<String, Object?>> post(String path, [Map<String, Object?>? body]) {
    final request = http.Request('POST', _uri(path));
    if (body != null) {
      request.headers['content-type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    return _send(request);
  }

  /// Sends a multipart form: [fields] as text parts, [files] as file parts.
  Future<Map<String, Object?>> postMultipart(
    String path, {
    required Map<String, String> fields,
    required List<http.MultipartFile> files,
  }) {
    final request = http.MultipartRequest('POST', _uri(path))
      ..fields.addAll(fields)
      ..files.addAll(files);
    return _send(request);
  }

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<Map<String, Object?>> _send(http.BaseRequest request) async {
    if (token != null) request.headers['authorization'] = 'Bearer $token';
    final http.Response response;
    try {
      response = await http.Response.fromStream(await _client.send(request));
    } on Exception {
      throw const ApiException(0, 'Cannot connect to the server. Make sure that it runs.');
    }
    final text = utf8.decode(response.bodyBytes);
    final body = text.isEmpty ? <String, Object?>{} : jsonDecode(text) as Map<String, Object?>;
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, (body['error'] as String?) ?? 'Error ${response.statusCode}', body);
    }
    return body;
  }
}
