import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:sst_server/app.dart';
import 'package:sst_server/config.dart';
import 'package:sst_server/db/db_connector.dart';

/// Calls the server handler in this process (no network).
class TestClient {
  TestClient(DBConnector db, {String storageDir = 'build/test-storage'})
      : handler = app(db, storageDir: storageDir).handler;

  /// The server object that the test requests go to.
  static App app(DBConnector db, {String storageDir = 'build/test-storage'}) =>
      App(Config({'STORAGE_DIR': storageDir}), db);

  final Handler handler;
  String? token;

  Future<TestResponse> get(String path) => _send(Request('GET', _uri(path), headers: _headers()));

  Future<TestResponse> post(String path, [Object? json]) => _send(Request(
        'POST',
        _uri(path),
        headers: {..._headers(), 'content-type': 'application/json'},
        body: json == null ? null : jsonEncode(json),
      ));

  Future<TestResponse> send(Request request) => _send(request);

  Map<String, String> _headers() => {if (token != null) 'authorization': 'Bearer $token'};

  Uri _uri(String path) => Uri.parse('http://localhost$path');

  Future<TestResponse> _send(Request request) async {
    final response = await handler(request);
    final text = await response.readAsString();
    return TestResponse(response.statusCode, text.isEmpty ? null : jsonDecode(text));
  }

  /// Signs in and keeps the token for the next requests.
  Future<TestResponse> login(String loginName, {String password = 'Password123', String app = 'user'}) async {
    final r = await post('/auth/login', {'login_name': loginName, 'password': password, 'app': app});
    if (r.status == 200) token = (r.body as Map)['token'] as String;
    return r;
  }
}

class TestResponse {
  const TestResponse(this.status, this.body);

  final int status;
  final Object? body;

  Map<String, Object?> get json => body as Map<String, Object?>;
}
