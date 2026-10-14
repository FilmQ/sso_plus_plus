import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sso_plus_plus/api/api_client.dart';
import 'package:sso_plus_plus/session/session_providers.dart';
import 'package:sso_plus_plus/sst_app.dart';

typedef Route = Future<http.Response> Function(http.Request request);

/// A fake server for widget tests. Add a handler for 'METHOD /path'.
class FakeServer {
  final Map<String, Route> routes = <String, Route>{};
  final List<http.Request> requests = <http.Request>[];

  void on(String key, Route route) => routes[key] = route;

  void json(String key, Object body, {int status = 200}) => on(key, (_) async => reply(body, status: status));

  static http.Response reply(Object body, {int status = 200}) => http.Response.bytes(
        utf8.encode(jsonEncode(body)),
        status,
        headers: <String, String>{'content-type': 'application/json'},
      );

  ApiClient client() => ApiClient(
        baseUrl: 'http://test',
        client: MockClient((http.Request request) async {
          requests.add(request);
          final Route? route = routes['${request.method} ${request.url.path}'];
          return route == null ? reply(<String, Object>{'error': 'No fake route'}, status: 404) : route(request);
        }),
      );

  /// A signed-in user session body, as POST /auth/login gives it.
  static Map<String, Object?> session({String name = 'นาย สมชาย ประเสริฐ', String first = 'สมชาย'}) =>
      <String, Object?>{
        'token': 'test-token',
        'session': <String, Object?>{
          'account_id': 1,
          'role': 'USER',
          'display_name': name,
          'first_name': first,
          'insured_id': 101,
        },
      };
}

/// Starts an app with the fake server and no kept token.
Widget testApp(FakeServer server, Provider<GoRouter> router, {String app = 'user', List<Object> extra = const <Object>[]}) {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  return ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(server.client()),
      appKindProvider.overrideWithValue(app),
      ...extra.cast(),
    ],
    child: SstApp(title: 'Test', router: router),
  );
}
