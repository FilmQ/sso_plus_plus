import 'dart:convert';

import 'package:shelf/shelf.dart';

const _type = {'Content-Type': 'application/json; charset=utf-8'};

Response jsonOk(Object? body) => Response.ok(_encode(body), headers: _type);

Response jsonCreated(Object? body) => Response(201, body: _encode(body), headers: _type);

Response jsonError(int status, String message, {Map<String, Object?>? extra}) =>
    Response(status, body: _encode({'error': message, ...?extra}), headers: _type);

/// Reads a JSON object from the request body.
Future<Map<String, Object?>> readJson(Request request) async {
  final text = await request.readAsString();
  if (text.isEmpty) return {};
  final value = jsonDecode(text);
  if (value is! Map<String, Object?>) {
    throw const FormatException('The body must be a JSON object');
  }
  return value;
}

String _encode(Object? body) => jsonEncode(body, toEncodable: _toEncodable);

/// The database gives DateTime values. JSON has no date type, so send ISO 8601.
Object? _toEncodable(Object? value) =>
    value is DateTime ? value.toIso8601String() : value.toString();
